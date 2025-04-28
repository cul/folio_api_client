# frozen_string_literal: true

class FolioApiClient
  # Data structure that stores FolioApiClient configuration options.
  class Configuration
    DEFAULT_TIMEOUT = 60
    DEFAULT_USER_AGENT = 'FolioApiClient'

    attr_reader :url, :username, :password, :tenant, :timeout, :user_agent
    attr_accessor :token

    def initialize(url:, username:, password:, tenant:, timeout: DEFAULT_TIMEOUT, user_agent: DEFAULT_USER_AGENT)
      @url = url
      @username = username
      @password = password
      @tenant = tenant
      @timeout = timeout
      @user_agent = user_agent
    end
  end
end
