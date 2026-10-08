# frozen_string_literal: true

module VPNDetection
  module Rails
    # Inserts the middleware for a Rails app, configured from
    # `config.vpndetection`.
    #
    # Placed right after Rails' own RemoteIp, so `request.ip` already means
    # what your `trusted_proxies` say it means, and before the router, so a
    # refusal costs no controller work.
    class Railtie < ::Rails::Railtie
      config.vpndetection = ActiveSupport::OrderedOptions.new

      initializer 'vpndetection.middleware' do |app|
        options = app.config.vpndetection.to_h
        next if options.delete(:enabled) == false

        app.middleware.insert_after(
          ActionDispatch::RemoteIp, VPNDetection::Rails::Middleware, **options
        )
      end
    end
  end
end
