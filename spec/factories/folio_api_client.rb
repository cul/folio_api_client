# frozen_string_literal: true

FactoryBot.define do
  factory :folio_api_client do
    initialize_with do
      new(
        FolioApiClient::Configuration.new(
          url: 'https://okapi-example-url.example.com',
          username: 'example-username',
          password: 'example-password',
          tenant: 'tenant123',
          timeout: 9,
          user_agent: 'CustomFolioApiClient'
        )
      )
    end
  end
end
