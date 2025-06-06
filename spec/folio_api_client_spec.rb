# frozen_string_literal: true

require 'faraday'

RSpec.describe FolioApiClient do
  let(:url) { 'https://okapi-example-url.example.com' }
  let(:username) { 'example-username' }
  let(:password) { 'example-password' }
  let(:tenant) { 'tenant123' }
  let(:timeout) { 9 }
  let(:user_agent) { 'CustomFolioApiClient' }

  let(:config) do
    FolioApiClient::Configuration.new(
      url: url,
      username: username,
      password: password,
      tenant: tenant,
      timeout: timeout,
      user_agent: user_agent
    )
  end

  let(:instance) { described_class.new(config) }

  it 'has a version number' do
    expect(FolioApiClient::VERSION).not_to be nil
  end

  it 'can be instantiated' do
    expect(instance).to be_a(described_class)
  end

  describe '#headers_for_connection' do
    it 'returns the correct values based on the config' do
      expect(instance.headers_for_connection).to eq({
        'Accept': 'application/json, text/plain',
        'Content-Type': 'application/json',
        'X-Okapi-Tenant': config.tenant,
        'User-Agent': config.user_agent
      })
    end
  end

  describe '#connection' do
    it 'creates a faraday connection object' do
      connection = instance.connection
      expect(connection).to be_a(Faraday::Connection)
    end

    it 'memoizes the connection, and returns the same object upon subsequent invocations' do
      connection = instance.connection
      expect(instance.connection).to be(connection)
    end
  end

  describe '#refresh_auth_token!' do
    let(:token) { 'token123' }

    it 'retrieves a new auth token and caches it in the internal config object' do
      allow(instance).to receive(:retrieve_new_auth_token).and_return(token)
      expect(instance.config).to receive(:token=).with(token)
      instance.refresh_auth_token!
    end
  end

  describe '#retrieve_new_auth_token' do
    let(:token) { 'token123' }
    let(:response) do
      resp = instance_double(Faraday::Response)
      allow(resp).to receive(:body).and_return(JSON.generate({ 'okapiToken' => token }))
      resp
    end

    before do
      allow(instance.connection).to receive(:post).with(
        '/authn/login',
        JSON.generate({ username: username, password: password })
      ).and_return(response)
    end

    it 'retrieves a new auth token and caches it in the internal config object' do
      expect(instance.retrieve_new_auth_token).to eq(token)
    end
  end

  describe '#with_token_refresh_attempt_when_unauthorized' do
    let(:request_path) { '/path/does/not/matter/for/this/test' }

    it "refreshes the token when the config object's token value is nil" do
      expect(instance).to receive(:refresh_auth_token!)
      allow(instance).to receive(:get) # allow `get` without raising any exception
      instance.with_token_refresh_attempt_when_unauthorized { instance.get(request_path) }
    end

    context 'when the token has already been set' do
      before do
        instance.config.token = 'existing-token-value'
      end

      it  'does not refresh the token when the given block runs without raising '\
          'Faraday::UnauthorizedError or Faraday::ForbiddenError' do
        expect(instance).not_to receive(:refresh_auth_token!)
        allow(instance).to receive(:get) # allow `get` without raising any exception
        instance.with_token_refresh_attempt_when_unauthorized { instance.get(request_path) }
      end

      it 'refreshes the token when the given block raises a Faraday::UnauthorizedError' do
        expect(instance).to receive(:refresh_auth_token!)

        raise_error = true # only raise error the first time the mocked method is called
        allow(instance).to receive(:get) {
          if raise_error
            raise_error = false
            raise Faraday::UnauthorizedError
          end
        }.twice

        instance.with_token_refresh_attempt_when_unauthorized { instance.get(request_path) }
      end

      it 'refreshes the token when the given block raises a araday::ForbiddenError' do
        expect(instance).to receive(:refresh_auth_token!)

        raise_error = true # only raise error the first time the mocked method is called
        allow(instance).to receive(:get) {
          if raise_error
            raise_error = false
            raise Faraday::ForbiddenError
          end
        }.twice

        instance.with_token_refresh_attempt_when_unauthorized { instance.get(request_path) }
      end
    end
  end

  describe '#get' do
    let(:path) { '/some/path' }
    let(:params) do
      { param1: 'val1', param2: 'val2' }
    end
    let(:expected_data) do
      { 'jon' => 'arbuckle' }
    end
    let(:response) do
      resp = instance_double(Faraday::Response)
      allow(resp).to receive(:body).and_return(JSON.generate(expected_data))
      resp
    end

    before do
      instance.config.token = 'token123'
      allow(instance.connection).to receive(:get).with(
        path, params, { 'x-okapi-token': config.token }
      ).and_return(response)
    end

    it 'performs the expected get request and returns the expected data' do
      expect(instance.get(path, params)).to eq(expected_data)
    end
  end

  describe '#exec_request_with_body' do
    let(:path) { '/some/path' }
    let(:hash_for_body) do
      { president: true, number: 16, distinguishing_characteristic: 'stovepipe hat' }
    end
    let(:expected_data) do
      { 'abraham' => 'lincoln' }
    end
    let(:expected_data_string) do
      JSON.generate(expected_data)
    end
    let(:http_method) { :post }
    let(:response) do
      resp = instance_double(Faraday::Response)
      allow(resp).to receive(:body).and_return(expected_data_string)
      resp
    end

    before do
      instance.config.token = 'token123'
      expect(instance.connection).to receive(http_method).with(
        path, JSON.generate(hash_for_body), { 'x-okapi-token': config.token, 'content-type': content_type }
      ).and_return(response)
    end

    context 'with object request body' do
      let(:body) { hash_for_body }
      let(:content_type) { 'application/json' }

      it 'performs the expected get request and returns the expected data' do
        expect(instance.exec_request_with_body(http_method, path, body)).to eq(expected_data)
      end
    end

    context 'with string request body' do
      let(:body) { JSON.generate(hash_for_body) }
      let(:content_type) { 'application/json' }

      it 'performs the expected get request and returns the expected data' do
        expect(instance.exec_request_with_body(http_method, path, body)).to eq(expected_data)
      end
    end

    context 'with empty response body' do
      let(:body) { JSON.generate(hash_for_body) }
      let(:content_type) { 'application/json' }
      let(:expected_data_string) { '' }

      it 'returns nil' do
        expect(instance.exec_request_with_body(http_method, path, body)).to eq(nil)
      end
    end
  end

  describe '#post' do
    let(:path) { '/example/path' }
    let(:body) do
      { sponge: 'bob', square: 'pants' }
    end

    it 'performs the expected operation' do
      expect(instance).to receive(:exec_request_with_body).with(:post, path, body, content_type: 'application/json')
      instance.post(path, body, content_type: 'application/json')
    end
  end

  describe '#put' do
    let(:path) { '/example/path' }
    let(:body) do
      { sponge: 'bob', square: 'pants' }
    end

    it 'performs the expected operation' do
      expect(instance).to receive(:exec_request_with_body).with(:put, path, body, content_type: 'application/json')
      instance.put(path, body, content_type: 'application/json')
    end
  end

  describe '#delete' do
    let(:path) { '/example/path' }
    let(:body) do
      { sponge: 'bob', square: 'pants' }
    end

    it 'performs the expected operation' do
      expect(instance).to receive(:exec_request_with_body).with(:delete, path, body, content_type: 'application/json')
      instance.delete(path, body, content_type: 'application/json')
    end
  end
end
