# frozen_string_literal: true

RSpec.describe FolioApiClient::Configuration do
  let(:url) { 'https://okapi-example-url.example.com' }
  let(:username) { 'example-username' }
  let(:password) { 'example-password' }
  let(:tenant) { 'tenant123' }
  let(:timeout) { 9 }
  let(:user_agent) { 'CustomFolioApiClient' }

  let(:instance) do
    described_class.new(
      url: url,
      username: username,
      password: password,
      tenant: tenant,
      timeout: timeout,
      user_agent: user_agent
    )
  end

  it 'can be instantiated' do
    expect(instance).to be_a(described_class)
  end

  describe '#initialize' do
    it 'sets the expected defaults when only the required arguments are given' do
      config = described_class.new(
        url: url,
        username: username,
        password: password,
        tenant: tenant
      )
      expect(config.timeout).to eq(described_class::DEFAULT_TIMEOUT)
      expect(config.user_agent).to eq(described_class::DEFAULT_USER_AGENT)
    end
  end
end
