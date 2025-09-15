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
    let(:location_id) { 'some-location-id' }
    let(:location_record) do
      { 'code' => 'ABC' }
    end

    it 'returns nil when the given location_id is nil' do
      expect(instance.find_location_record(location_id: nil)).to eq(nil)
    end

    context 'for a valid location id' do
      before do
        allow(instance).to receive(:get).with(
          "/locations/#{location_id}"
        ).and_return(location_record)
      end

      it 'returns the location data' do
        expect(instance.find_location_record(location_id: location_id)).to eq(location_record)
      end
    end

    context 'for a location id that cannot be resolved to a valid location' do
      before do
        allow(instance).to receive(:get).with(
          "/locations/#{location_id}"
        ).and_raise(Faraday::ResourceNotFound)
      end

      it 'returns nil' do
        expect(instance.find_location_record(location_id: location_id)).to eq(nil)
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
