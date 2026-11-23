# frozen_string_literal: true

require_relative 'test_helper'
require 'rack/builder'
require 'rack/mock_request'

# `allow_bots`, through a real Rack stack built as the README builds it: the
# request's own User-Agent reaches the API, and a crawler the answer calls
# `verified` is never refused. Every request comes from a public peer, since a
# bogon is answered locally with nothing sent.
class AllowBotsTest < Minitest::Test
  include TestHelper

  PEER = '66.249.66.1'
  GOOGLEBOT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

  APP = ->(env) do
    lookup = VPNDetection::Rails.lookup(env)
    body = JSON.generate('verdict' => lookup&.result&.user_agent&.fetch('verdict'),
                         'is_hosting' => lookup&.result&.is_hosting)
    [200, { 'content-type' => 'application/json' }, [body]]
  end

  # Answers every lookup as a hosting address, with `verdict` for the agent it
  # was sent, or none, and returns the user_agent query each lookup carried.
  def origin(verdict)
    sent = []
    Typhoeus.stub(%r{\A#{Regexp.escape(BASE_URL)}/}).and_return do |request|
      agent = (request.options[:params] || {}).transform_keys(&:to_s)['user_agent']
      sent << agent
      body = { 'ip' => PEER, 'is_vpn' => false, 'is_hosting' => true }
      body['user_agent'] = { 'agent' => 'Googlebot', 'kind' => 'bot', 'verdict' => verdict } if agent && verdict
      json_response(200, body)
    end
    sent
  end

  def teardown
    Typhoeus::Expectation.clear
  end

  # The README's Rack form, with a fresh cache each time.
  def readme_app(**extra)
    Rack::Builder.new do
      use VPNDetection::Rails::Middleware, api_key: 'k_readme', block_condition: { is_hosting: true }, **extra
      run APP
    end
  end

  def get(app, user_agent = GOOGLEBOT)
    env = { 'REMOTE_ADDR' => PEER }
    env['HTTP_USER_AGENT'] = user_agent unless user_agent.nil?
    response = Rack::MockRequest.new(app).get('/', env)
    [response.status, response.status == 200 ? JSON.parse(response.body) : nil]
  end

  def test_a_verified_crawler_passes_with_its_answer_attached
    sent = origin('verified')
    status, body = get(readme_app(allow_bots: true))

    assert_equal [GOOGLEBOT], sent, "the request's own User-Agent reaches the API"
    assert_equal 200, status
    assert_equal({ 'verdict' => 'verified', 'is_hosting' => true }, body)
  end

  def test_a_spoofed_or_not_bot_crawler_is_refused
    %w[spoofed not_bot].each do |verdict|
      sent = origin(verdict)
      status, = get(readme_app(allow_bots: true))

      assert_equal 403, status, verdict
      assert_equal [GOOGLEBOT], sent, verdict
      Typhoeus::Expectation.clear
    end
  end

  def test_off_by_default_no_user_agent_is_sent
    sent = origin('verified')
    status, = get(readme_app)

    assert_equal [nil], sent
    assert_equal 403, status
  end

  def test_no_or_an_empty_user_agent_sends_none
    sent = origin('verified')
    get(readme_app(allow_bots: true), nil)
    get(readme_app(allow_bots: true), '')

    assert_equal [nil, nil], sent
  end

  def test_a_condition_on_the_verdict_refuses_a_forged_crawler
    origin('spoofed')
    app = Rack::Builder.new do
      use VPNDetection::Rails::Middleware, api_key: 'k_readme', allow_bots: true,
                                           block_condition: { user_agent: { verdict: 'spoofed' } }
      run APP
    end

    assert_equal 403, get(app).first
  end

  # Keyless, or past a free key's trial, no answer carries a verdict.
  def test_an_answer_without_a_verdict_warns_once
    origin(nil)
    warnings = []
    app = readme_app(allow_bots: true, on_warn: ->(m) { warnings << m })
    2.times { assert_equal 403, get(app).first }

    assert_equal 1, warnings.length
    assert_match(/no user_agent verdict/, warnings.first)
  end
end
