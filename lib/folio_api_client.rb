# frozen_string_literal: true

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

require 'faraday'
require 'marc'

# A client used for making http requests (get/post/etc.) to the FOLIO ILS REST API.
class FolioApiClient
  include Finders

  attr_reader :config

  def initialize(config)
    @config = config
  end

  def headers_for_connection
    {
      'Accept': 'application/json, text/plain',
      'Content-Type': 'application/json',
      'X-Okapi-Tenant': config.tenant,
      'User-Agent': config.user_agent
    }
  end

  def connection
    @connection ||= Faraday.new(
      headers: headers_for_connection,
      url: config.url,
      request: { timeout: config.timeout }
    ) do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.use Faraday::Response::RaiseError
    end
  end

  def retrieve_new_auth_token
    response = connection.post('/authn/login', JSON.generate({ username: config.username, password: config.password }))
    response_data = JSON.parse(response.body)
    response_data['okapiToken']
  end

  def refresh_auth_token!
    config.token = retrieve_new_auth_token
  end

  def with_token_refresh_attempt_when_unauthorized
    refresh_auth_token! if config.token.nil?
    yield
  rescue Faraday::UnauthorizedError, Faraday::ForbiddenError
    # Tokens are sometimes invalidated by FOLIO data refreshes, so we'll attempt to refresh our token
    # one time in responde to a 401 or 403.
    refresh_auth_token!

    # Re-run block
    yield
  rescue Faraday::ConnectionFailed
    # If we make too many rapid requests in a row, FOLIO sometimes disconnects.
    # If this happens, we'll sleep for a little while and retry the request.
    sleep 5
    # Re-run block
    yield
  end

  def get(path, params = {})
    response = with_token_refresh_attempt_when_unauthorized do
      connection.get(path, params, { 'x-okapi-token': config.token })
    end

    JSON.parse(response.body)
  end

  def exec_request_with_body(method, path, body = nil, content_type: 'application/json')
    body = JSON.generate(body) if content_type == 'application/json' && !body.is_a?(String)
    response = with_token_refresh_attempt_when_unauthorized do
      connection.send(method, path, body, { 'x-okapi-token': config.token, 'content-type': content_type })
    end

    response.body.nil? || response.body == '' ? nil : JSON.parse(response.body)
  end

  def post(path, body = nil, content_type: 'application/json')
    exec_request_with_body(:post, path, body, content_type: content_type)
  end

  def put(path, body = nil, content_type: 'application/json')
    exec_request_with_body(:put, path, body, content_type: content_type)
  end

  def delete(path, body = nil, content_type: 'application/json')
    exec_request_with_body(:delete, path, body, content_type: content_type)
  end
end
