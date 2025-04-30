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

      item_record_id = item_search_results.first['id']
      self.get("/item-storage/items/#{item_record_id}")
    end

    def find_location_record(location_id:)
      self.get("/locations/#{location_id}")
    end

    def find_holdings_record(holdings_record_id:)
      self.get("/holdings-storage/holdings/#{holdings_record_id}")
    end

    def find_instance_record(instance_record_id:)
      self.get("/instance-storage/instances/#{instance_record_id}")
    end

    # Find a MARC::Record by its instance record id or instance record hrid
    def find_marc_record(instance_record_id: nil, instance_record_hrid: nil)
      source_record_search_results = self.get(
        '/source-storage/source-records',
        marc_record_query(instance_record_id: instance_record_id, instance_record_hrid: instance_record_hrid)
      )
      return nil if source_record_search_results['totalRecords'].zero?

      bib_record_marc_hash = source_record_search_results['sourceRecords'].first['parsedRecord']['content']
      MARC::Record.new_from_hash(bib_record_marc_hash)
    end

    def marc_record_query(instance_record_id: nil, instance_record_hrid: nil)
      return { instanceId: instance_record_id } if instance_record_id
      return { instanceHrid: instance_record_hrid } if instance_record_hrid

      raise FolioApiClient::Exceptions::MissingQueryFieldError,
            'Missing query field.  Must supply either an instance_record_id or instance_record_hrid.'
    end
  end
end
