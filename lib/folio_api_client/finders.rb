# frozen_string_literal: true

class FolioApiClient
  module Finders
    def find_item_record(barcode:)
      item_search_results = self.get('/item-storage/items', { query: "barcode==#{barcode}", limit: 2 })['items']
      return nil if item_search_results.empty?

      if item_search_results.length > 1
        raise FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError,
              'Only expected one item with this barcode, but found more than one.'
      end

      item_search_results.first
    end

    def find_location_record(location_id:)
      self.get("/locations/#{location_id}")
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

    # Find a MARC::Record by its instance record id or instance record hrid
    # @return [Marc::Record, Hash] An array of length two, with the first element being the MARC::Record and the
    # # second being the Source Record that holds the MARC record.
    def find_marc_record(instance_record_id: nil, instance_record_hrid: nil)
      source_record_search_results = self.get(
        '/source-storage/source-records',
        source_record_query(instance_record_id: instance_record_id, instance_record_hrid: instance_record_hrid)
      )
      total_records = source_record_search_results['totalRecords']
      return nil if total_records.zero?

      if total_records > 1
        raise FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError,
              'Only expected one record with this '\
              "#{instance_record_id ? 'instance_record_id' : 'instance_record_hrid'}, "\
              'but found more than one.'
      end

      source_record = source_record_search_results['sourceRecords'].first
      bib_record_marc_hash = source_record['parsedRecord']['content']
      [MARC::Record.new_from_hash(bib_record_marc_hash), source_record]
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
  end
end
