# frozen_string_literal: true

require 'json'
require 'rack'

module VPNDetection
  module Rails
    # Rack middleware that classifies the visitor and optionally refuses the
    # request.
    #
    # Being Rack rather than Rails-specific is deliberate: the same object works
    # in Sinatra, Hanami, Roda or a bare Rack app, and the Railtie below is only
    # what saves a Rails user from inserting it by hand.
    #
    # Without a `block_condition` this only enriches the request and never
    # refuses one, leaving the decision to your own controllers. The answer is
    # on `request.env['vpndetection']`, or `VPNDetection::Rails.lookup(request)`.
    class Middleware
      ENV_KEY = 'vpndetection'

      def initialize(app, **options)
        @app = app
        @on_blocked = options.delete(:on_blocked) || method(:refuse)
        # Only the default selector reads Rails' remote_ip, or Rack's ip.
        @check_forgery = !options.key?(:ip_selector)
        @check_passed_through = @check_forgery
        @on_warn = options[:on_warn]
        @core = VPNDetection::Middleware::Core.new(
          Rails.default_ip_selector, **options
        )
      end

      def call(env)
        request = ::Rack::Request.new(env)
        warn_forgeable(request) if @check_forgery
        warn_passed_through(request) if @check_passed_through
        lookup = @core.evaluate(request)
        return @app.call(env) if lookup.nil?

        env[ENV_KEY] = lookup
        return @on_blocked.call(request, lookup) if lookup.blocked?

        @app.call(env)
      end

      private

      # Once: the setup is the same on every request.
      def warn_forgeable(request)
        peer = Rails.forgeable_peer(request)
        return if peer.nil?

        @check_forgery = false
        message = "a request carrying #{Rails.forwarding_header(request)} came from #{peer}, a public " \
                  'address outside config.action_dispatch.trusted_proxies, so Rails takes the visitor ' \
                  'from that header, which anyone connecting directly can set. If a proxy sits in front of this app, ' \
                  'add its addresses to trusted_proxies; if nothing does, pass ' \
                  'ip_selector: ->(request) { request.ip }.'
        say(message)
      end

      # Once, as above.
      def warn_passed_through(request)
        proxy = Rails.passed_through_forwarded(request)
        return if proxy.nil?

        @check_passed_through = false
        message = "a request through #{proxy} carries Forwarded beside X-Forwarded-For, and Rack " \
                  'reads Forwarded first. A proxy that writes only X-Forwarded-For, as nginx does, ' \
                  "passes a visitor's own Forwarded through, and that names the address looked up. " \
                  'If yours does, clear the header there (nginx: proxy_set_header Forwarded "";), ' \
                  'or set Rack::Request.forwarded_priority = [:x_forwarded] in config.ru.'
        say(message)
      end

      def say(message)
        @on_warn ? @on_warn.call(message) : Kernel.warn("[vpndetection] #{message}")
      end

      def refuse(_request, _lookup)
        body = JSON.generate({ 'error' => 'access denied' })
        [403, { 'content-type' => 'application/json' }, [body]]
      end
    end

    module_function

    # What the middleware found out about this visitor, or nil when it has not
    # run for this request or `skip` claimed it.
    def lookup(request)
      env = request.respond_to?(:env) ? request.env : request
      env[Middleware::ENV_KEY]
    end
  end
end
