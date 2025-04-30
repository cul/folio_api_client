# frozen_string_literal: true

class FolioApiClient
  module Exceptions
    class Error < StandardError; end
    class UnexpectedMultipleRecordsFoundError < Error; end
    class MissingQueryFieldError < Error; end
  end
end
