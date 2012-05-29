module ActiveZuora
  class Scope

    attr_accessor :selected_field_names, :filters

    delegate :first, :last, :size, :count, :each, :empty?, :any?, :blank?, :present?,
      :to => :all

    def initialize(zobject_class, selected_field_names=[:id])
      @zobject_class, @selected_field_names, @filters = zobject_class, selected_field_names, []
    end

    def dup
      dup = super
      dup.selected_field_names = dup.selected_field_names.dup
      dup.filters = dup.filters.dup
      dup
    end

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

    def to_zql
      select_statement + " from " + @zobject_class.zuora_object_name + " " + where_statement
    end

    def as_hashes
      @zobject_class.connection.query(to_zql)
    end

    def all
      @records ||= as_hashes.map do |attributes|
        # Instantiate the zobject class, but don't track
        # the changes.
        @zobject_class.new(attributes).tap { |record| record.clear_changed_attributes }
      end
    end

    def loaded?
      !@records.nil?
    end

    def reload
      @records = nil
      self
    end

    def update_all(attributes={})
      # Update using an attribute hash, or you can pass a block
      # and update the attributes directly on the objects.
      if block_given?
        all.each { |record| yield record }
      else
        all.each { |record| record.attributes = attributes }
      end
      @zobject_class.update(all)
    end

    def delete_all
      @zobject_class.delete(all.map(&:id))
    end

    private

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
      @zobject_class.get_field!(name).zuora_name
    end

    def escape_filter_value(value)
      if value.nil?
        "null"
      elsif value.is_a?(String)
        "'#{value.gsub("'","\\\\'")}'"
      else
        value
      end
    end

  end
end




    


