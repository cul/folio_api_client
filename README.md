# FolioApiClient

A Ruby interface for making requests to the FOLIO ILS API (https://folio.org), including some convenience methods that have been useful for the Columbia University Libraries.

## Installation

At this time, this gem is only available on GitHub and has not been published to RubyGems yet.  You can include it in your Gemfile using this syntax:

`gem 'folio_api_client', github: 'cul/folio_api_client', branch: 'main'`

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
```

See [https://dev.folio.org/reference/api/](https://dev.folio.org/reference/api/) for the full list of available FOLIO API endpoints.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version of this gem, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at: https://github.com/cul/folio_api_client
