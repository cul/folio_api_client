# frozen_string_literal: true

RSpec.describe FolioApiClient::Finders do
  let(:instance) do
    build(:folio_api_client)
  end

  before do
    allow(instance).to receive(:retrieve_new_auth_token).and_return('some-token')
  end

  it 'FolioApiClient includes this module' do
    expect(instance.class.ancestors).to include(described_class)
  end

  describe '#find_item_record' do
    let(:barcode) { 'ABC12345' }
    let(:item_record1) do
      { 'id' => '9242ef9e-12bd-4a0a-9ec6-a600d44798d5' }
    end
    let(:item_record2) do
      { 'id' => '18f1b4e1-bac2-440f-a5c5-466541cdcb32' }
    end

    context 'when the barcode resolves to only one item record' do
      before do
        allow(instance).to receive(:get).with(
          '/item-storage/items', { query: "barcode==#{barcode}", limit: 2 }
        ).and_return({ 'items' => [item_record1] })
      end

      it 'returns the expected item record data' do
        expect(instance.find_item_record(barcode: barcode)).to eq(item_record1)
      end
    end

    context 'when the barcode resolves to zero item records' do
      before do
        allow(instance).to receive(:get).with(
          '/item-storage/items', { query: "barcode==#{barcode}", limit: 2 }
        ).and_return({ 'items' => [] })
      end

      it 'returns nil' do
        expect(instance.find_item_record(barcode: barcode)).to eq(nil)
      end
    end

    context 'when the barcode resolves to more than one item record' do
      before do
        allow(instance).to receive(:get).with(
          '/item-storage/items', { query: "barcode==#{barcode}", limit: 2 }
        ).and_return({ 'items' => [item_record1, item_record2] })
      end

      it 'raises an exception' do
        expect {
          instance.find_item_record(barcode: barcode)
        }.to raise_error(FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError)
      end
    end
  end

  describe '#find_location_record' do
    let(:valid_location_id) { 'some-valid-location-id' }
    let(:invalid_location_id) { 'some-invalid-location-id' }
    let(:valid_code) { 'some-valid-code' }
    let(:invalid_code) { 'some-invalid-code' }

    let(:location_record) do
      { 'id' => valid_location_id, 'code' => valid_code }
    end
    let(:other_location_record) do
      { 'id' => 'another-id', 'code' => 'another-code' }
    end

    it 'returns nil when the given location_id and code are nil' do
      expect(instance.find_location_record(location_id: nil, code: nil)).to eq(nil)
    end

    context 'searching by location_id' do
      before do
        allow(instance).to receive(:get).with(
          "/locations/#{valid_location_id}"
        ).and_return(location_record)

        allow(instance).to receive(:get).with(
          "/locations/#{invalid_location_id}"
        ).and_raise(Faraday::ResourceNotFound)
      end

      it 'returns the location data for a valid location_id' do
        expect(instance.find_location_record(location_id: valid_location_id)).to eq(location_record)
      end

      it 'returns the nil for an invalid location_id' do
        expect(instance.find_location_record(location_id: invalid_location_id)).to eq(nil)
      end
    end

    context 'searching by code' do
      let(:location_api_search_results) { [location_record] }

      before do
        allow(instance).to receive(:get).with(
          '/locations', { limit: 2, query: "code==#{valid_code}" }
        ).and_return({ 'locations' => location_api_search_results })

        allow(instance).to receive(:get).with(
          '/locations', { limit: 2, query: "code==#{invalid_code}" }
        ).and_return({ 'locations' => [] })
      end

      it 'returns the location data for a valid location_id, selecting the location with the exact code match '\
          'when there are multiple results returned from the underlying location search' do
        expect(instance.find_location_record(code: valid_code)).to eq(location_record)
      end

      it 'returns the nil for an invalid location_id' do
        expect(instance.find_location_record(code: invalid_code)).to eq(nil)
      end

      context 'when multiple location search results are found for a given code' do
        let(:location_api_search_results) { [location_record, other_location_record] }

        it 'raises an error' do
          expect {
            instance.find_location_record(code: valid_code)
          }.to raise_error(
            FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError
          )
        end
      end
    end
  end

  describe '#find_material_type_record' do
    let(:material_type_id) { 'some-material-type-id' }
    let(:material_type_record) do
      {
        'id' => '16d485ae-9fa3-469d-920a-d4264670636f',
        'name' => 'Book',
        'source' => 'local',
        'metadata' => {
          'createdDate' => '2025-01-01T01:02:03.123+00:00',
          'createdByUserId' => '1e3444ea-9d6d-408d-97be-38139bc08789',
          'updatedDate' => '2025-02-02T04:05:06.456+00:00',
          'updatedByUserId' => '08e3baf4-18b4-4789-9105-209fc76fa70az'
        }
      }
    end

    it 'returns nil when the given material_type_id is nil' do
      expect(instance.find_material_type_record(material_type_id: nil)).to eq(nil)
    end

    context 'for a valid material type' do
      before do
        allow(instance).to receive(:get).with(
          "/material-types/#{material_type_id}"
        ).and_return(material_type_record)
      end

      it 'returns the material type data' do
        expect(instance.find_material_type_record(material_type_id: material_type_id)).to eq(material_type_record)
      end
    end

    context 'for a material type id that cannot be resolved to a valid material type' do
      before do
        allow(instance).to receive(:get).with(
          "/material-types/#{material_type_id}"
        ).and_raise(Faraday::ResourceNotFound)
      end

      it 'returns nil' do
        expect(instance.find_material_type_record(material_type_id: material_type_id)).to eq(nil)
      end
    end
  end

  describe '#find_loan_type_record' do
    let(:loan_type_id) { 'some-loan-type-record-id' }
    let(:loan_type_record) do
      { 'id' => loan_type_id, 'name' => 'general circulating' }
    end

    before do
      allow(instance).to receive(:get).with(
        "/loan-types/#{loan_type_id}"
      ).and_return(loan_type_record)
    end

    it 'returns the loan type data' do
      expect(instance.find_loan_type_record(loan_type_id: loan_type_id)).to eq(loan_type_record)
    end
  end

  describe '#find_holdings_record' do
    let(:holdings_record_id) { 'some-holdings-id' }
    let(:holdings_record) do
      { 'code' => 'ABC' }
    end

    before do
      allow(instance).to receive(:get).with(
        "/holdings-storage/holdings/#{holdings_record_id}"
      ).and_return(holdings_record)
    end

    it 'returns the holdings record data' do
      expect(instance.find_holdings_record(holdings_record_id: holdings_record_id)).to eq(holdings_record)
    end
  end

  describe '#find_instance_record' do
    let(:instance_record) do
      { 'code' => 'ABC' }
    end

    context 'searching by instance_record_id' do
      let(:instance_record_id) { 'some-instance-id' }

      before do
        allow(instance).to receive(:get).with(
          '/instance-storage/instances', { limit: 2, query: "id==#{instance_record_id}" }
        ).and_return({ 'instances' => [instance_record] })
      end

      it 'returns the instance record data' do
        expect(instance.find_instance_record(instance_record_id: instance_record_id)).to eq(instance_record)
      end
    end

    context 'searching by instance_record_hrid' do
      let(:instance_record_hrid) { 'some-instance-id' }

      before do
        allow(instance).to receive(:get).with(
          '/instance-storage/instances', { limit: 2, query: "hrid==#{instance_record_hrid}" }
        ).and_return({ 'instances' => [instance_record] })
      end

      it 'returns the instance record data' do
        expect(instance.find_instance_record(instance_record_hrid: instance_record_hrid)).to eq(instance_record)
      end
    end
  end

  describe '#find_source_record' do
    let(:instance_record_id) { 'some-instance-id' }
    let(:instance_record_hrid) { 'some-instance-hrid' }

    let(:marc_001_value) { '15484475' }
    let(:marc_json_hash) do
      { 'fields' => [{ '001' => marc_001_value }, { '005' => '20240625231052.0' }] }
    end
    let(:source_record) do
      { 'parsedRecord' => { 'content' => marc_json_hash } }
    end
    let(:source_record_response_data) do
      {
        'totalRecords' => 1,
        'sourceRecords' => [source_record]
      }
    end

    context 'searching by instance_record_id' do
      before do
        allow(instance).to receive(:get).with(
          '/source-storage/source-records', { instanceId: instance_record_id }
        ).and_return(source_record_response_data)
      end

      it 'returns the expected source record when one source record is found' do
        source_record = instance.find_source_record(instance_record_id: instance_record_id)
        expect(source_record).to have_key('parsedRecord')
      end

      context 'when no source record search results are found' do
        let(:source_record_response_data) do
          {
            'totalRecords' => 0,
            'sourceRecords' => []
          }
        end

        it 'returns nil' do
          expect(instance.find_source_record(instance_record_id: instance_record_id)).to eq(nil)
        end
      end

      context 'when multiple source record search results are found' do
        let(:other_source_record) do
          { 'parsedRecord' => { 'content' => { 'fake' => 'content' } } }
        end
        let(:source_record_response_data) do
          {
            'totalRecords' => 2,
            'sourceRecords' => [source_record, other_source_record]
          }
        end

        before do
          allow(instance).to receive(:get).with(
            '/source-storage/source-records', { instanceId: instance_record_id }
          ).and_return(source_record_response_data)
        end

        it 'raises an error' do
          expect {
            instance.find_source_record(instance_record_id: instance_record_id)
          }.to raise_error(
            FolioApiClient::Exceptions::UnexpectedMultipleRecordsFoundError
          )
        end
      end
    end

    context 'searching by instance_record_hrid' do
      before do
        allow(instance).to receive(:get).with(
          '/source-storage/source-records', { instanceHrid: instance_record_hrid }
        ).and_return(source_record_response_data)
      end

      it 'returns the expected source record when one source record is found' do
        source_record = instance.find_source_record(instance_record_hrid: instance_record_hrid)
        expect(source_record).to have_key('parsedRecord')
      end
    end
  end

  describe '#find_source_marc_records' do
    let(:modified_since) { '2025-01-01T00:00:00Z' }
    let(:marc_content) { { 'fields' => [{ '001' => '12345' }] } }
    let(:instance_record) { { 'id' => 'instance-123' } }
    let(:instances_response) { { 'totalRecords' => 1, 'instances' => [instance_record] } }

    before do
      allow(instance).to receive(:find_source_record).and_return({ 'parsedRecord' => { 'content' => marc_content } })
    end

    context 'with modified_since parameter' do
      before do
        allow(instance).to receive(:get).with(
          'search/instances', { query: "metadata.updatedDate>=\"#{modified_since}\"", limit: 100, offset: 0 }
        ).and_return(instances_response)
      end

      it 'yields MARC content for each source record' do
        yielded_records = []
        instance.find_source_marc_records(modified_since) { |record| yielded_records << record }
        expect(yielded_records).to eq([marc_content])
      end
    end

    context 'with has_965hyacinth parameter' do
      before do
        allow(instance).to receive(:get).with(
          'search/instances', { query: 'identifiers.value="965hyacinth"', limit: 100, offset: 0 }
        ).and_return(instances_response)
      end

      it 'uses the correct query' do
        instance.find_source_marc_records(nil, has_965hyacinth: true) { |_| }
        expect(instance).to have_received(:get).with(
          'search/instances', { query: 'identifiers.value="965hyacinth"', limit: 100, offset: 0 }
        )
      end
    end

    context 'with both parameters' do
      before do
        allow(instance).to receive(:get).with(
          'search/instances', {
            query: "metadata.updatedDate>=\"#{modified_since}\" and identifiers.value=\"965hyacinth\"",
            limit: 100, offset: 0
          }
        ).and_return(instances_response)
      end

      it 'combines both filters' do
        instance.find_source_marc_records(modified_since, has_965hyacinth: true) { |_| }
        expect(instance).to have_received(:get).with(
          'search/instances', {
            query: "metadata.updatedDate>=\"#{modified_since}\" and identifiers.value=\"965hyacinth\"",
            limit: 100, offset: 0
          }
        )
      end
    end

    it 'raises error when no parameters provided' do
      expect {
        instance.find_source_marc_records(nil) { |_| }
      }.to raise_error(FolioApiClient::Exceptions::MissingQueryFieldError)
    end
  end

  describe '#source_record_query' do
    let(:instance_record_id) { 'instance-record-id' }
    let(:instance_record_hrid) { 'instance-record-hrid' }

    it 'returns the expected hash when an instance_record_id is given' do
      expect(instance.source_record_query(instance_record_id: instance_record_id)).to eq(
        { instanceId: instance_record_id }
      )
    end

    it 'returns the expected hash when an instance_record_hrid is given' do
      expect(instance.source_record_query(instance_record_hrid: instance_record_hrid)).to eq(
        { instanceHrid: instance_record_hrid }
      )
    end

    it 'raises an exception when no identifier parameter is given' do
      expect { instance.source_record_query }.to raise_error(FolioApiClient::Exceptions::MissingQueryFieldError)
    end
  end
end
