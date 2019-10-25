module ActiveZuora
  class Relation

    attr_accessor :selected_field_names, :filters, :order_attribute, :order_direction

    attr_reader :zobject_class

    def initialize(zobject_class, selected_field_names=[:id])
      @zobject_class, @selected_field_names, @filters = zobject_class, selected_field_names, []

      if field?(:created_date)
        @order_attribute, @order_direction = :created_date, :asc
      end
    end

    def dup
      dup = super
      dup.selected_field_names = dup.selected_field_names.dup
      dup.filters = dup.filters.dup
      dup.unload
      dup
    end

    #
    # Conditions / Selecting
    #

    def select(*field_names)
      dup.tap { |dup| dup.selected_field_names = field_names.flatten }
    end

    def where(conditions)
      dup.tap { |dup| dup.filters << ['and', conditions] }
    end

    alias :and :where

    def or(conditions)
      dup.tap { |dup| dup.filters << ['or', conditions] }\
    end

    def order(attribute, direction = :asc)
      dup.tap do |dup|
        dup.order_attribute = attribute
        dup.order_direction = direction
      end
    end

    def scoped
      # Account.select(:id).where(:status => "Draft") do
      #   Account.all # => select id from Account where status = "Draft"
      # end
      previous_scope, zobject_class.current_scope = zobject_class.current_scope, self
      yield
    ensure
      zobject_class.current_scope = previous_scope
    end

    def merge(relation)
      if relation.is_a?(Hash)
        where(relation)
      else
        dup.tap do |dup|
          dup.filters.concat relation.filters
          dup.filters.uniq!
          dup.order_attribute = relation.order_attribute
          dup.order_direction = relation.order_direction
        end
      end
    end

    #
    # Finding / Loading
    #

    def to_zql
      select_statement + " from " + zobject_class.zuora_object_name + " " + where_statement
    end

    def find(id)
      return nil if id.blank?
      where(:id => id).first
    end

    def find_each(&block)
      # Iterate through each item, but don't save the results in memory.
      if loaded?
        # If we're already loaded, iterate through the cached records.
        to_a.each(&block)
      else
        query.each(&block)
      end
    end

    def to_a
      @records ||= query
    end

    alias :all :to_a

    def loaded?
      !@records.nil?
    end

    def unload
      @records = nil
      self
    end

    def reload
      unload.to_a
      self
    end

    def query(&block)
      # Keep querying until all pages are retrieved.
      # Throws an exception for an invalid query.
      response = zobject_class.connection.request(:query){ |soap| soap.body = { :query_string => to_zql } }
      query_response = response[:query_response]
      records = objectify_query_results(query_response[:result][:records])
      records.each(&:block) if block_given?
      # If there are more pages of records, keep fetching
      # them until done.
      until query_response[:result][:done]
        query_response = zobject_class.connection.request(:query_more) do |soap|
          soap.body = { :query_locator => query_response[:result][:query_locator] }
        end[:query_more_response]
        more_records = objectify_query_results(query_response[:result][:records])
        more_records.each(&:block) if block_given?
        records.concat more_records
      end
      sort_records!(records)
    rescue Savon::SOAP::Fault => exception
      # Add the zql to the exception message and re-raise.
      exception.message << ": #{to_zql}"
      raise
    end

    #
    # Updating / Deleting
    #

    def update_all(attributes={})
      # Update using an attribute hash, or you can pass a block
      # and update the attributes directly on the objects.
      if block_given?
        to_a.each { |record| yield record }
      else
        to_a.each { |record| record.attributes = attributes }
      end
      zobject_class.update(to_a)
    end

    def delete_all
      zobject_class.delete(to_a.map(&:id))
    end

    protected

    def method_missing(method, *args, &block)
      # This is how the chaing can happen on class methods or named scopes on the
      # ZObject class.
      if Array.method_defined?(method)
        to_a.send(method, *args, &block)
      elsif zobject_class.respond_to?(method)
        scoped { zobject_class.send(method, *args, &block) }
      else
        super
      end
    end

    #
    # Helper methods to build the ZQL.
    #

    def select_statement
      "select " + selected_field_names.map { |field_name| zuora_field_name(field_name) }.join(', ')
    end

    def where_statement
      return '' if @filters.empty?
      tokens = []
      @filters.each do |logical_operator, conditions|
        if conditions.is_a?(Hash)
          conditions.each do |field_name, comparisons|
            zuora_field_name = zuora_field_name(field_name)
            comparisons = { '=' => comparisons } unless comparisons.is_a?(Hash)
            comparisons.each do |operator, value|
              tokens.concat [logical_operator, zuora_field_name, operator, escape_filter_value(value)]
            end
          end
        else
          tokens.concat [logical_operator, conditions.to_s]
        end
      end
      tokens[0] = "where"
      tokens.join ' '
    end

    def zuora_field_name(name)
      zobject_class.get_field!(name).zuora_name
    end

    def escape_filter_value(value)
      if value.nil?
        "null"
      elsif value.is_a?(String)
        "'#{value.gsub("'","\\\\'")}'"
      elsif value.is_a?(DateTime) || value.is_a?(Time)
        # If we already have a DateTime or Time, use the zone it already has.
        escape_filter_value(value.strftime("%FT%T%:z")) # 2007-11-19T08:37:48-06:00
      elsif value.is_a?(Date)
        # Create a DateTime from the date using Zuora's timezone.
        escape_filter_value(value.to_datetime.change(:offset => "+0800"))
      else
        value
      end
    end

    def objectify_query_results(results)
      return [] if results.blank?
      # Sometimes Zuora will return only a single record, not in an array.
      results = [results] unless results.is_a?(Array)
      results.map do |attributes|
        # Strip any noisy attributes from the results that have to do with
        # SOAP namespaces.
        attributes.delete_if { |key, value| key.to_s.start_with? "@" }
        # Instantiate the zobject class, but don't track the changes.
        if ActiveSupport.version.to_s.to_f >= 5.2
          zobject_class.new(attributes).tap { |record| record.clear_changes_information }
        else
          zobject_class.new(attributes).tap { |record| record.changed_attributes.clear }
        end
      end
    end

    def sort_records!(records)
      return records unless order_attribute.present?
      records.sort! do |a, b|
        if a.nil?
          -1
        elsif b.nil?
          1
        else
          a.send(order_attribute) <=> b.send(order_attribute)
        end
      end
      records.reverse! if order_direction == :desc
      records
    end

  end
end







