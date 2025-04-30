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

        allow(instance).to receive(:get).with(
          "/item-storage/items/#{item_record1['id']}"
        ).and_return(item_record1)
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

    before do
      allow(instance).to receive(:get).with(
        "/locations/#{location_id}"
      ).and_return(location_record)
    end

    it 'returns the location data' do
      expect(instance.find_location_record(location_id: location_id)).to eq(location_record)
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
    let(:instance_record_id) { 'some-instance-id' }
    let(:instance_record) do
      { 'code' => 'ABC' }
    end

    before do
      allow(instance).to receive(:get).with(
        "/instance-storage/instances/#{instance_record_id}"
      ).and_return(instance_record)
    end

    it 'returns the instance record data' do
      expect(instance.find_instance_record(instance_record_id: instance_record_id)).to eq(instance_record)
    end
  end

  describe '#find_marc_record' do
    let(:instance_record_id) { 'some-instance-id' }

    before do
      allow(instance).to receive(:get).with(
        '/source-storage/source-records', { instanceId: instance_record_id }
      ).and_return(source_record_search_results)
    end

    context 'when at least one source record search result is found' do
      let(:marc_001_value) { '15484475' }
      let(:marc_json) do
        { 'fields' => [{ '001' => marc_001_value }, { '005' => '20240625231052.0' }] }
      end
      let(:source_record_search_results) do
        {
          'totalRecords' => 1,
          'sourceRecords' => [
            { 'parsedRecord' => { 'content' => marc_json } }
          ]
        }
      end

      it 'returns the expected MARC record' do
        marc_record = instance.find_marc_record(instance_record_id: instance_record_id)
        expect(marc_record).to be_a(MARC::Record)
        expect(marc_record['001'].value).to eq(marc_001_value)
      end
    end

    context 'when no source record search results are found' do
      let(:source_record_search_results) do
        { 'totalRecords' => 0, 'sourceRecords' => [] }
      end

      it 'returns nil' do
        expect(instance.find_marc_record(instance_record_id: instance_record_id)).to eq(nil)
      end
    end
  end
end
