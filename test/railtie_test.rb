# frozen_string_literal: true

require_relative 'test_helper'
require 'rails'
require 'action_controller/railtie'
require 'rack/mock_request'
# Loaded here because test_helper required the gem before Rails was defined.
require 'vpndetection/rails/railtie'

# The Railtie, booted as an app configures it. Every other test builds the
# middleware by hand, so a key dropped on its way from `config.vpndetection`
# passed them all.
class RailtieTest < Minitest::Test
  include TestHelper

  GOOGLEBOT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
  WARNINGS = []

  class App < ::Rails::Application
    config.eager_load = false
    config.logger = Logger.new(nil)
    config.secret_key_base = 'x' * 64
    config.hosts.clear
    config.vpndetection = {
      client: VPNDetection::Client.new(cache: false, retries: 0),
      ip_selector: VPNDetection::Rails.header_ip_selector('X-Visitor'),
      block_condition: { is_vpn: true },
      allow_bots: true,
      on_warn: ->(message) { WARNINGS << message },
    }
    routes.append { root to: ->(_env) { [200, {}, ['handler ran']] } }
  end
  App.initialize!

  def teardown
    Typhoeus::Expectation.clear
  end

  def test_the_configured_condition_reaches_the_middleware
    calls = stub_lookups(
      '45.83.91.1' => { body: { 'ip' => '45.83.91.1', 'is_vpn' => true } },
      '45.83.91.2' => { body: { 'ip' => '45.83.91.2', 'is_vpn' => false } },
    )
    blocked = Rack::MockRequest.new(App).get('/', 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_X_VISITOR' => '45.83.91.1')
    allowed = Rack::MockRequest.new(App).get('/', 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_X_VISITOR' => '45.83.91.2')

    assert_equal 403, blocked.status
    assert_equal 200, allowed.status
    assert_equal 'handler ran', allowed.body
    assert_equal 2, calls.length
  end

  # `allow_bots` from config.vpndetection: the request's own User-Agent reaches
  # the API, and a verified crawler passes the condition it meets.
  def test_allow_bots_reaches_the_middleware
    sent = []
    Typhoeus.stub(%r{\A#{Regexp.escape(BASE_URL)}/}).and_return do |request|
      agent = (request.options[:params] || {}).transform_keys(&:to_s)['user_agent']
      ip = address_of(request)
      sent << [ip, agent]
      verdict = ip == '45.83.91.3' ? 'verified' : 'spoofed'
      json_response(200, { 'ip' => ip, 'is_vpn' => true,
                           'user_agent' => { 'agent' => 'Googlebot', 'kind' => 'bot', 'verdict' => verdict } })
    end
    headers = { 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_USER_AGENT' => GOOGLEBOT }
    verified = Rack::MockRequest.new(App).get('/', headers.merge('HTTP_X_VISITOR' => '45.83.91.3'))
    spoofed = Rack::MockRequest.new(App).get('/', headers.merge('HTTP_X_VISITOR' => '45.83.91.4'))

    assert_equal [['45.83.91.3', GOOGLEBOT], ['45.83.91.4', GOOGLEBOT]], sent
    assert_equal 200, verified.status
    assert_equal 'handler ran', verified.body
    assert_equal 403, spoofed.status
  end

  def test_it_sits_right_after_rails_own_remote_ip
    stack = App.middleware.map(&:klass)

    assert_equal stack.index(ActionDispatch::RemoteIp) + 1, stack.index(VPNDetection::Rails::Middleware)
  end
end
