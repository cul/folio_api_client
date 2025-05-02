# frozen_string_literal: true

require_relative 'lib/folio_api_client/version'

Gem::Specification.new do |spec|
  spec.name = 'folio_api_client'
  spec.version = FolioApiClient::VERSION
  spec.authors = ["Eric O'Hanlon"]
  spec.email = ['elo2112@columbia.edu']

  spec.summary = 'A Ruby interface for making requests to the FOLIO ILS API.'
  spec.description =  'This gem provides an interface for making requests to the FOLIO ILS API, '\
                      'and makes session management easier.'
  spec.homepage = 'https://www.github.com/cul/folio_api_client'
  spec.license = 'Apache-2.0'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://www.github.com/cul/folio_api_client'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 2.13'
  spec.add_dependency 'marc', '~> 1.3'
  spec.add_dependency 'zeitwerk', '~> 2.7'
end
