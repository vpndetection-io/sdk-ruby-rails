# frozen_string_literal: true

require_relative 'test_helper'
require 'rack/mock_request'

# The Rack middleware, driven through a real Rack stack, plus the shared corpus.
#
# A Rack::MockRequest connects from 127.0.0.1 by default, which is a bogon and
# is answered locally without a request. Anything that needs a served answer
# therefore has to arrive wearing a public address, through a selector.
class MiddlewareTest < Minitest::Test
  include TestHelper

  PUBLIC_IP = '45.83.91.1'
  MIDDLEWARE = TestHelper::CORPUS['middleware']

  APP = ->(env) do
    lookup = VPNDetection::Rails.lookup(env)
    body = JSON.generate(
      'ip' => lookup&.ip,
      'is_vpn' => lookup&.result&.is_vpn,
      'bogon' => lookup&.result&.bogon?,
      'error' => lookup&.error&.class&.name,
      'attached' => !lookup.nil?
    )
    [200, { 'content-type' => 'application/json' }, [body]]
  end

  def setup
    Typhoeus::Expectation.clear
  end

  def teardown
    Typhoeus::Expectation.clear
  end

  def serving(body, status: 200)
    ip = body['ip'] || PUBLIC_IP
    calls = stub_lookups(ip => { status: status, body: body })
    [VPNDetection::Client.new(cache: false, retries: 0), calls]
  end

  # Rack::MockRequest sets NO REMOTE_ADDR, so without this every request would
  # resolve to nothing and exercise the unresolvable path instead of the one
  # under test.
  def call(headers: {}, env: {}, remote_addr: '127.0.0.1', **options)
    stack = VPNDetection::Rails::Middleware.new(APP, **options)
    env_headers = headers.transform_keys { |k| "HTTP_#{k.upcase.tr('-', '_')}" }
    response = Rack::MockRequest.new(stack)
                                .get('/', env_headers.merge(env)
                                                     .merge('REMOTE_ADDR' => remote_addr))
    [response.status, JSON.parse(response.body.empty? ? '{}' : response.body)]
  end

  def test_enriches_the_request_and_leaves_the_decision_to_the_app
    client, calls = serving({ 'ip' => PUBLIC_IP, 'is_vpn' => true })
    status, body = call(client: client, ip_selector: ->(_r) { PUBLIC_IP })

    assert_equal 200, status
    assert body['attached']
    assert body['is_vpn']
    assert_equal PUBLIC_IP, body['ip']
    assert_equal 1, calls.length
  end

  def test_blocks_when_the_condition_matches_and_the_app_never_runs
    client, = serving({ 'ip' => PUBLIC_IP, 'is_vpn' => true })
    status, body = call(client: client, ip_selector: ->(_r) { PUBLIC_IP },
                        block_condition: { 'is_vpn' => true })

    assert_equal 403, status
    assert_equal({ 'error' => 'access denied' }, body)
    assert_nil body['attached'], 'the app answered a blocked request'
  end

  def test_on_blocked_replaces_the_refusal
    client, = serving({ 'ip' => PUBLIC_IP, 'is_vpn' => true,
                        'vpn' => { 'provider' => 'nordvpn' } })
    refusal = lambda do |_request, lookup|
      [451, { 'content-type' => 'application/json' },
       [JSON.generate('why' => lookup.result.vpn['provider'])]]
    end
    status, body = call(client: client, ip_selector: ->(_r) { PUBLIC_IP },
                        block_condition: { 'is_vpn' => true }, on_blocked: refusal)

    assert_equal 451, status
    assert_equal({ 'why' => 'nordvpn' }, body)
  end

  def test_skip_leaves_the_request_untouched
    client, calls = serving({ 'ip' => PUBLIC_IP, 'is_vpn' => true })
    status, body = call(client: client, ip_selector: ->(_r) { PUBLIC_IP },
                        block_condition: { 'is_vpn' => true }, skip: ->(_r) { true })

    assert_equal 200, status
    refute body['attached']
    assert_empty calls
  end

  def test_a_failing_lookup_lets_the_visitor_through
    client, = serving({ 'ip' => PUBLIC_IP, 'error' => 'boom' }, status: 500)
    status, body = call(client: client, ip_selector: ->(_r) { PUBLIC_IP },
                        block_condition: { 'is_vpn' => true })

    assert_equal 200, status
    assert_match(/VPNDetection/, body['error'])
  end

  # Rails' RemoteIp leaves the trusted answer on the env, and Rack::Request#ip
  # does NOT read it - so using Rack's alone would silently ignore whatever
  # trusted_proxies the application configured. This is what makes the Railtie's
  # placement after RemoteIp mean anything.
  def test_rails_own_remote_ip_wins_over_racks
    client, calls = serving({ 'ip' => PUBLIC_IP, 'is_vpn' => true })
    _, body = call(client: client,
                   env: { 'action_dispatch.remote_ip' => PUBLIC_IP },
                   headers: { 'X-Forwarded-For' => '203.0.113.9' })

    assert_equal PUBLIC_IP, body['ip']
    assert_equal 1, calls.length
  end

  # Rack's own `ip` trusts X-Forwarded-For: it returns the left-most entry once
  # private and loopback addresses are dropped, which is whatever the caller
  # sent. Measured, not assumed - and the reason the README says so plainly
  # instead of implying Rack gives you the socket peer.
  def test_racks_default_already_trusts_a_forwarded_header
    client, calls = serving({ 'ip' => PUBLIC_IP, 'is_vpn' => true })
    _, body = call(client: client, headers: { 'X-Forwarded-For' => PUBLIC_IP })

    assert_equal PUBLIC_IP, body['ip']
    assert_equal 1, calls.length

    header_client, header_calls = serving({ 'ip' => '45.83.91.9', 'is_vpn' => true })
    _, body = call(client: header_client,
                   ip_selector: VPNDetection::Rails.header_ip_selector('CF-Connecting-IP'),
                   headers: { 'CF-Connecting-IP' => '45.83.91.9',
                              'X-Forwarded-For' => PUBLIC_IP })

    assert_equal '45.83.91.9', body['ip'], 'a named header must win over the chain'
    assert_equal 1, header_calls.length
  end

  def test_a_header_selector_reads_the_edge_that_writes_it
    client, calls = serving({ 'ip' => '45.83.91.9', 'is_vpn' => true })
    _, body = call(client: client,
                   ip_selector: VPNDetection::Rails.header_ip_selector('CF-Connecting-IP'),
                   headers: { 'CF-Connecting-IP' => '45.83.91.9' })

    assert_equal '45.83.91.9', body['ip']
    assert_equal 1, calls.length
  end

  def test_a_private_client_address_is_answered_locally_and_never_blocks
    client, calls = serving({ 'ip' => PUBLIC_IP, 'is_vpn' => true })
    status, body = call(client: client, block_condition: { 'is_vpn' => true },
                        on_warn: ->(_m) {})

    assert_equal 200, status, 'local development must not lock you out of your own app'
    assert body['bogon']
    assert_empty calls
  end

  def test_a_condition_that_constrains_nothing_is_refused_at_construction
    error = assert_raises(ArgumentError) do
      VPNDetection::Rails::Middleware.new(APP, block_condition: { 'is_vpn' => false })
    end
    assert_match(/constrains nothing/, error.message)
  end

  def test_corpus_conditions
    MIDDLEWARE['conditions'].each do |c|
      why = "#{c['name']}: #{c['why']}"
      ip = c['bogon'] || c['body']['ip']
      client, = serving(c['body'] || { 'ip' => ip })
      warnings = []
      status, = call(client: client, ip_selector: ->(_r) { ip },
                     block_condition: c['condition'], on_warn: ->(m) { warnings << m })

      assert_equal(c['expect']['blocked'] ? 403 : 200, status, why)
      reported = warnings.grep(/does not include/)
      assert_equal(c['expect']['missing'].empty? ? 0 : 1, reported.length, why)
      c['expect']['missing'].each { |m| assert_match(/#{m}/, reported.first, why) }
      Typhoeus::Expectation.clear
    end
  end
end
