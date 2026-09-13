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
        @core = VPNDetection::Middleware::Core.new(
          Rails.default_ip_selector, **options
        )
      end

      def call(env)
        request = ::Rack::Request.new(env)
        lookup = @core.evaluate(request)
        return @app.call(env) if lookup.nil?

        env[ENV_KEY] = lookup
        return @on_blocked.call(request, lookup) if lookup.blocked?

        @app.call(env)
      end

      private

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
