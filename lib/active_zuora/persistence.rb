module ActiveZuora
  module Persistence

    extend ActiveSupport::Concern

    def new_record?
      id.blank?
    end

    def save
      new_record? ? create : update
    end

    def save!
      raise "Could Not Save Zuora Object: #{errors.full_messages.join ', '}" unless save
    end

    def update_attributes(attributes)
      self.attributes = attributes
      save
    end

    def update_attributes!(attributes)
      self.attributes = attributes
      save!
    end

    def delete
      self.class.delete(id) > 0
    end

    def reload
      raise ArgumentError.new("You can't reload a new record") if new_record?
      self.untracked_attributes = self.class.find(id).attributes
      self
    end

    def xml_field_names
      # If we're rendering an existing record, always include the id.
      new_record? ? super : ([:id] + super).uniq
    end

    private

    def create
      return false unless new_record? && valid?
      result = self.class.connection.request(:create) do |soap|
        soap.body do |xml|
          build_xml(xml, soap, 
            :namespace => soap.namespace, 
            :element_name => :zObjects,
            :force_type => true)
        end
      end[:create_response][:result]
      if result[:success]
        self.id = result[:id]
        clear_changed_attributes
        true
      else
        errors.add(:base, result[:errors][:message]) if result[:errors]
        false
      end
    end

    def update
      self.class.update(self)
      self.errors.blank?
    end

    module ClassMethods

      def create(attributes={})
        new(attributes).tap(&:save)
      end

      def create!(attributes={})
        new(attributes).tap(&:save!)
      end

      def update(*zobjects)
        zobjects = zobjects.flatten.select do |zobject|
          !zobject.new_record? && zobject.changed.present? && zobject.valid?
        end
        # Don't hit the API if none of our objects qualify.
        return 0 if zobjects.empty?
        results = connection.request(:update) do |soap|
          soap.body do |xml|
            zobjects.map do |zobject|
              zobject.build_xml(xml, soap,
                :namespace => soap.namespace,
                :element_name => :zObjects,
                :force_type => true,
                :nil_strategy => :fields_to_nil)
            end.last
          end
        end[:update_response][:result]
        results = [results] unless results.is_a?(Array)
        zobjects.each do |zobject|
          result = results.find { |r| r[:id] == zobject.id } || 
            { :errors => { :message => "No result returned." } }
          if result[:success]
            zobject.clear_changed_attributes
          else
            zobject.add_zuora_errors result[:errors]
          end
        end
        # Return the count of updates that succeeded.
        results.select{ |result| result[:success] }.size
      end

      def delete(*ids)
        ids.flatten!
        results = connection.request(:delete) do |soap|
          qualifier = soap.namespace_by_uri(soap.namespace)
          soap.body do |xml|
            xml.tag!(qualifier, :type, zuora_object_name)
            ids.map { |id| xml.tag!(qualifier, :ids, id) }.last
          end
        end[:delete_response][:result]
        results = [results] unless results.is_a?(Array)
        # Return the count of deletes that succeeded.
        results.select{ |result| result[:success] }.size
      end

    end

  end
end