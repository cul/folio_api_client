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

    # Retrieve and yield marc records, filtered by the given modified_since and with_965_value parameters.
    # NOTE: This method skips staff-suppressed FOLIO records.
    def find_source_marc_records(modified_since: nil, with_965_value: nil, &block) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # FOLIO does not allow an offset value higher than 9999, but this method needs to be able to retrieve
      # result sets that have more than 9999 results, so we break big queries up into a bunch of smaller
      # queries that split up the results based on the first character of the instance UUIDs.  The first character
      # of a UUID is a hex character (0-9 or a-f), which means that we will perform 16 different searches
      # (i.e. "all of the results that have instance ids that start with a", then "all of the results that have
      # instance ids that start with b", and so on).

      # Since we're splitting up the query into a bunch of different sub-queries, we need to do a
      # non-prefix-filtered query first just to get the total number of results.
      total_query = response = self.get(
        'search/instances',
        marc_records_query(modified_since: modified_since, with_965_value: with_965_value).merge({ limit: 0 })
      )
      total_records = total_query['totalRecords']

      with_uuid_prefixes do |uuid_prefix|
        query = marc_records_query(modified_since: modified_since, with_965_value: with_965_value,
                                   uuid_prefix: uuid_prefix)
        loop do
          response = self.get('search/instances', query)
          process_marc_for_instance(response['instances'], total_records, &block) if block
          break if (query[:offset] + query[:limit]) >= response['totalRecords']

          query[:offset] += query[:limit]
        end
      end
    end

    # UUIDs can start with
    def with_uuid_prefixes(&block)
      (('0'..'9').to_a + ('a'..'f').to_a).each(&block)
    end

    def process_marc_for_instance(instances, total_records, &block)
      instances.each do |instance|
        source_record = find_source_record(instance_record_id: instance['id'])
        next if source_record.nil? # Occasionally, we find an instance record without a source record.  Skip these.

        marc_content = source_record.dig('parsedRecord', 'content')
        yield(marc_content, total_records) if marc_content && block
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

    def marc_records_query(modified_since: nil, with_965_value: nil, uuid_prefix: nil) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity
      params = { limit: 100, offset: 0 }

      if modified_since.nil? && with_965_value.nil?
        raise FolioApiClient::Exceptions::MissingQueryFieldError,
              'Missing query field.  Must supply either modified_since or with_965_value.'
      end

      if modified_since && !modified_since.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
        raise ArgumentError,
              %(Invalid format for modified_since argument. Must be a date string like "2025-10-03T16:49:00Z".)
      end

      query_parts = []
      query_parts << "metadata.updatedDate>=\"#{modified_since}\"" if modified_since
      query_parts << %(identifiers.value="#{with_965_value}") if with_965_value

      # Only include non-staff-suppressed records because staff-suppressed records represent deleted records in FOLIO.
      # Reminder: staff-suppressed records are NOT the same as discovery-suppressed records.  Discovery-suppressed
      # records are ones that aren't displayed to the public, and we DO want to include discovery-suppressed records
      # in the results returned by this query.
      query_parts << 'staffSuppress==false'

      query_parts << %(id="#{uuid_prefix}*") if uuid_prefix

      params[:query] = query_parts.join(' and ')
      params
    end
  end
end
