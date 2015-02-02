module ActiveZuora
  module Persistence

    extend ActiveSupport::Concern

    MAX_BATCH_SIZE = 50

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

      # Takes an array of zobjects and batch saves new and updated records separately
      def save(*zobjects)
        new_records = 0
        updated_records = 0

        # Get all new objects
        new_objects = zobjects.flatten.select do |zobject|
          zobject.new_record? && zobject.changed.present? && zobject.valid?
        end

        # Get all updated objects
        updated_objects = zobjects.flatten.select do |zobject|
          !zobject.new_record? && zobject.changed.present? && zobject.valid?
        end

        # Make calls in batches of 50
        new_objects.each_slice(MAX_BATCH_SIZE) do |batch|
          new_records += process_save(batch, :create)
        end

        updated_objects.each_slice(MAX_BATCH_SIZE) do |batch|
          updated_records += process_save(batch, :update)
        end

        new_records + updated_records
      end

      # For backwards compatability
      def update(*zobjects)
        save(zobjects)
      end

      def process_save(zobjects, action)
        unless [:create, :update].include? action
          raise "Invalid action type for saving. Must be create or update." 
        end

        return 0 if zobjects.empty?

        results = connection.request(action) do |soap|
          soap.body do |xml|
            zobjects.map do |zobject|
              zobject.build_xml(xml, soap,
                :namespace => soap.namespace,
                :element_name => :zObjects,
                :force_type => true,
                :nil_strategy => :fields_to_null)
            end.last
          end
        end["#{action.to_s}_response".to_sym][:result]

        results = [results] unless results.is_a?(Array)
        zobjects.zip(results).each do |zobject, result|
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
        deleted_records = 0
        ids.each_slice(MAX_BATCH_SIZE) do |batch|
          deleted_records += process_delete(batch)
        end
        deleted_records
      end

      def process_delete(*ids)
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
