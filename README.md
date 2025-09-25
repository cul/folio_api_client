# FolioApiClient

A Ruby interface for making requests to the FOLIO ILS API (https://folio.org), including some convenience methods that have been useful for the Columbia University Libraries.

## Installation

```bash
bundle add folio_api_client
```

If bundler is not being used to manage dependencies, you can install the gem by running:

```bash
gem install folio_api_client
```

## Usage

```
# Create a client
client = FolioApiClient.new(FolioApiClient::Configuration.new(
  url: 'https://development.example.com',
  username: 'username',
  password: 'password',
  tenant: 'abc123',
  timeout: 10
))

# Make some requests

instance_record_id = '65e07045-4d68-4a07-835e-33f0c80482ab'
instance_record_response = client.get("/instance-storage/instances/#{instance_record_id}")
puts JSON.parse(instance_record_response.body)

holdings_record_id = 'b2e9946b-82fe-4cfb-ad4c-b3c452379dae'
holdings_record_response = client.get("/holdings-storage/holdings/#{holdings_record_id}")
puts JSON.parse(holdings_record_response.body)

# Generic request syntax for any FOLIO REST endpoint:

client.get(path, params)
client.post(path, body, content_type: 'application/json'))
client.put(path, body, content_type: 'application/json'))
client.delete(path, body, content_type: 'application/json'))

# Other convenience methods:

client.find_item_record(barcode: 'some-barcode')
client.find_location_record(location_id: 'some-location-id')
client.find_location_record(code: 'some-location-code')
client.find_material_type_record(material_type_id: 'some-material-type-id')
client.find_holdings_record(holdings_record_id: 'some-holdings-record-id')
client.find_instance_record(instance_record_id: 'some-instance-record-id')
client.find_instance_record(instance_record_hrid: 'some-instance-record-hrid')
client.find_source_record(instance_record_id: 'some-instance-record-id')
client.find_source_record(instance_record_hrid: 'some-instance-record-hrid')

# Convert a FOLIO MARC source record to a marc gem MARC::Record object:
source_record = client.find_source_record(instance_record_id: 'some-instance-record-id')
marc_record = MARC::Record.new_from_hash(source_record['parsedRecord']['content'])
```

See [https://dev.folio.org/reference/api/](https://dev.folio.org/reference/api/) for the full list of available FOLIO API endpoints.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version of this gem, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at: https://github.com/cul/folio_api_client
