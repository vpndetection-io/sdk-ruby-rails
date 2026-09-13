# frozen_string_literal: true

module VPNDetection
  module Rails
    # The client-address selectors, bound to a Rack request.
    #
    # There is no portable default, so this is yours to choose - but Rails
    # already has an answer for the common case, and it is the one to reach for
    # first.
    SELECTORS = VPNDetection::Middleware::Selectors.new do |request|
      VPNDetection::Middleware::RequestView.new(
        header: ->(name) { request.get_header("HTTP_#{name.upcase.tr('-', '_')}") },
        framework_ip: -> { framework_ip(request) }
      )
    end

    module_function

    # Rails' own answer where there is one, and Rack's otherwise.
    #
    # `ActionDispatch::RemoteIp` computes the visitor from `X-Forwarded-For`
    # minus your `config.action_dispatch.trusted_proxies` and leaves it on
    # `env['action_dispatch.remote_ip']`. That is the right fix behind a load
    # balancer, so it is read first - `Rack::Request#ip` does NOT consult it,
    # and using Rack's alone would silently ignore the trusted_proxies you
    # configured.
    #
    # Outside Rails there is no such entry and this falls back to
    # `Rack::Request#ip`. **Be aware that Rack's own `ip` already trusts
    # `X-Forwarded-For`**: it returns the left-most entry after dropping
    # private and loopback addresses, which is whatever the caller sent.
    # Measured, not assumed. In a bare Rack app behind nothing, prefer
    # {.header_ip_selector} or your own.
    def default_ip_selector
      SELECTORS.default
    end

    # @api private
    def framework_ip(request)
      # `to_s` because RemoteIp leaves a lazily-resolving object here, not a
      # String, and a lookup needs the address.
      rails = request.get_header('action_dispatch.remote_ip')
      return rails.to_s unless rails.nil?

      request.ip
    end

    # An address from `X-Forwarded-For`, ignoring Rails' trusted-proxy list.
    #
    # The LEFT-MOST entry (depth 0) is whatever the caller sent, because proxies
    # append to this header. Prefer `trusted_proxies`; reach for this only when
    # you cannot express your topology there.
    def xff_ip_selector(depth = 0)
      SELECTORS.xff(depth)
    end

    # An address from a single-value header your edge writes -
    # `header_ip_selector('CF-Connecting-IP')` behind Cloudflare. Falls back to
    # the Rails accessor when the header is absent.
    def header_ip_selector(name)
      SELECTORS.header(name)
    end
  end
end
