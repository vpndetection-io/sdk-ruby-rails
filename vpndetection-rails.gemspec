# frozen_string_literal: true

require_relative 'lib/vpndetection/rails/version'

Gem::Specification.new do |spec|
  spec.name = 'vpndetection-rails'
  spec.version = VPNDetection::Rails::VERSION
  spec.authors = ['Mslm Dev']
  spec.email = ['support@vpndetection.io']

  spec.summary = 'Official Rails and Rack middleware for the VPNDetection API.'
  spec.description = 'Classifies the visitor behind each request - VPN, residential ' \
                     'proxy, Tor, hosting, CDN, relay - and hands the answer to your ' \
                     'controllers. Rack middleware, so it works in Sinatra, Hanami and ' \
                     'Roda too; a Railtie inserts it for you in Rails.'
  spec.homepage = 'https://vpndetection.io'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/vpndetection-io/sdk-ruby-rails'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb'] + %w[LICENSE README.md]
  spec.require_paths = ['lib']

  spec.add_dependency 'rack', '>= 2.2'
  spec.add_dependency 'vpndetection', '>= 5.3', '< 6'
end
