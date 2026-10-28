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
    # **With nothing in front of the app server, Rails' answer can be forged**:
    # `RemoteIp` believes `X-Forwarded-For` from any peer outside
    # trusted_proxies, so a visitor names the address looked up. The middleware
    # says so once when it sees that setup.
    #
    # Outside Rails there is no such entry and this falls back to
    # `Rack::Request#ip`. Under Rack 3 that is the peer itself unless the peer
    # is a trusted proxy (loopback or private by default). Rack 2 returned the
    # left-most `X-Forwarded-For` entry after dropping private and loopback
    # addresses, which is whatever the caller sent: there, behind nothing,
    # prefer {.header_ip_selector} or your own.
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

    # @api private
    # The peer, when Rails' RemoteIp let a header that peer sent name the
    # visitor: `X-Forwarded-For`, `Client-IP` or a `Forwarded` Rack reads, from
    # a public address outside the proxies RemoteIp trusts, its defaults or
    # trusted_proxies.
    def forgeable_peer(request)
      remote_ip = request.get_header('action_dispatch.remote_ip')
      return nil if remote_ip.nil? || forwarding_header(request).nil?

      peer = request.get_header('REMOTE_ADDR').to_s
      return nil unless public_address?(peer)

      # RemoteIp's own list, from the object it leaves in env; Rails has kept
      # it there as @proxies since 4.0.
      proxies = remote_ip.instance_variable_get(:@proxies)
      return nil unless proxies.respond_to?(:any?)
      return nil if proxies.any? { |proxy| proxy === peer } # rubocop:disable Style/CaseEquality

      peer
    end

    # @api private
    # The first header on the request that can name the visitor, or nil.
    def forwarding_header(request)
      names = { 'X-Forwarded-For' => 'HTTP_X_FORWARDED_FOR', 'Client-IP' => 'HTTP_CLIENT_IP' }
      names['Forwarded'] = 'HTTP_FORWARDED' if forwarded_priority.include?(:forwarded)
      names.find { |_, key| !request.get_header(key).to_s.empty? }&.first
    end

    # @api private
    # The proxy, when a request through it carries `Forwarded` beside
    # `X-Forwarded-For` and Rack reads `Forwarded` first, as Rack 3 does by
    # default, and so does Rails' RemoteIp, which asks Rack. A proxy writing
    # only `X-Forwarded-For`, as nginx does, passes the visitor's own
    # `Forwarded` through, and that names the address looked up.
    def passed_through_forwarded(request)
      return nil unless forwarded_priority.first == :forwarded
      return nil if %w[HTTP_FORWARDED HTTP_X_FORWARDED_FOR].any? { |name| request.get_header(name).to_s.empty? }

      request.get_header('REMOTE_ADDR').to_s
    end

    # @api private
    # Rack 2 reads only `X-Forwarded-For`, and has no such setting (2.2.24).
    def forwarded_priority
      ::Rack::Request.respond_to?(:forwarded_priority) ? ::Rack::Request.forwarded_priority : [:x_forwarded]
    end

    # @api private
    def public_address?(ip)
      IPAddr.new(ip)
      !VPNDetection::Bogon.bogon?(ip)
    rescue IPAddr::Error
      false
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
