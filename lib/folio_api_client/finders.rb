# frozen_string_literal: true

class FolioApiClient
  module Finders # rubocop:disable Metrics/ModuleLength
    def find_item_record(barcode:)
      item_search_results = self.get('/item-storage/items', { query: "barcode==#{barcode}", limit: 2 })['items']
      return nil if item_search_results.empty?

      if item_search_results.length > 1
        raise FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError,
              'Only expected one item with this barcode, but found more than one.'
      end

      item_search_results.first
    end

    def find_location_record(location_id: nil, code: nil) # rubocop:disable Metrics/MethodLength
      if location_id
        return self.get("/locations/#{location_id}")
      elsif code
        location_record_search_results = self.get(
          '/locations',
          location_record_query(code: code)
        )['locations']

        return nil if location_record_search_results.empty?

        if location_record_search_results.length > 1
          raise FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError,
                'Only expected one location with this code, but found more than one.'
        end

        return location_record_search_results.first
      end

      nil
    rescue Faraday::ResourceNotFound
      nil
    end

    def find_material_type_record(material_type_id:)
      return nil if material_type_id.nil?

      self.get("/material-types/#{material_type_id}")
    rescue Faraday::ResourceNotFound
      nil
    end

    def find_loan_type_record(loan_type_id:)
      self.get("/loan-types/#{loan_type_id}")
    end

    def find_holdings_record(holdings_record_id:)
      self.get("/holdings-storage/holdings/#{holdings_record_id}")
    end

    def find_instance_record(instance_record_id: nil, instance_record_hrid: nil)
      instance_search_results = self.get(
        '/instance-storage/instances',
        instance_record_query(instance_record_id: instance_record_id, instance_record_hrid: instance_record_hrid)
      )['instances']
      return nil if instance_search_results.empty?

      if instance_search_results.length > 1
        raise FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError,
              'Only expected one instance with this '\
              "#{instance_record_id ? 'instance_record_id' : 'instance_record_hrid'}, "\
              'but found more than one.'
      end

      instance_search_results.first
    end

    # Find a source record by its instance record id or instance record hrid.
    # @return [Hash] A Source Record (which can hold data for a MARC record).
    def find_source_record(instance_record_id: nil, instance_record_hrid: nil)
      source_record_search_results = self.get(
        '/source-storage/source-records',
        source_record_query(instance_record_id: instance_record_id, instance_record_hrid: instance_record_hrid)
      )
      return nil if source_record_search_results['totalRecords'].zero?

      if source_record_search_results['totalRecords'] > 1
        raise FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError,
              'Only expected one record with this '\
              "#{instance_record_id ? 'instance_record_id' : 'instance_record_hrid'}, "\
              'but found more than one.'
      end

      source_record_search_results['sourceRecords'].first
    end

    def find_source_marc_records(modified_since)
      query = marc_records_query(modified_since: modified_since)

      loop do
        response = self.get('source-storage/source-records', query)

        if block_given?
          response['sourceRecords'].each do |source_record|
            marc_content = source_record.dig('parsedRecord', 'content')
            yield(marc_content) if marc_content
          end
        end

        break if (query[:offset] + query[:limit]) >= response['totalRecords']

        query[:offset] += query[:limit]
      end
    end

    def source_record_query(instance_record_id: nil, instance_record_hrid: nil)
      return { instanceId: instance_record_id } if instance_record_id
      return { instanceHrid: instance_record_hrid } if instance_record_hrid

      raise FolioApiClient::Exceptions::MissingQueryFieldError,
            'Missing query field.  Must supply either an instance_record_id or instance_record_hrid.'
    end

    def instance_record_query(instance_record_id: nil, instance_record_hrid: nil)
      return { query: "id==#{instance_record_id}", limit: 2 } if instance_record_id
      return { query: "hrid==#{instance_record_hrid}", limit: 2 } if instance_record_hrid

      raise FolioApiClient::Exceptions::MissingQueryFieldError,
            'Missing query field.  Must supply either an instance_record_id or instance_record_hrid.'
    end

    def location_record_query(code: nil)
      return { query: "code==#{code}", limit: 2 } if code

      raise FolioApiClient::Exceptions::MissingQueryFieldError,
            'Missing query field.  Must supply a code.'
    end

    def marc_records_query(modified_since: nil)
      params = { limit: 100, offset: 0 }
      params[:updatedAfter] = modified_since if modified_since
      params
    end
  end
end
