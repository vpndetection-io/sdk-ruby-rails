# [<img src="https://s3.vpndetection.io/vpndetection-public/brand/mark.svg" alt="VPNDetection" width="24"/>](https://vpndetection.io/) VPNDetection Rails Middleware

[![Gem](https://img.shields.io/gem/v/vpndetection-rails.svg)](https://rubygems.org/gems/vpndetection-rails)
[![license](https://img.shields.io/github/license/vpndetection-io/sdk-ruby-rails.svg)](LICENSE)

The official Rails middleware for the [VPNDetection](https://vpndetection.io) API.

It classifies the visitor behind each request — VPN, residential proxy, Tor, hosting, CDN, relay — and hands the answer to your controllers. Blocking is opt-in.

It is Rack middleware, so it works in Sinatra, Hanami, Roda or a bare Rack app too; the Railtie is only what saves a Rails user from inserting it by hand.

## Getting Started

```bash
bundle add vpndetection-rails
```

Requires Ruby 3.1 or newer.

You need an API key. Create one in the [console](https://app.vpndetection.io); the free tier's allowance is counted per source address, and a server is a single source address, so a key is what makes this usable in production rather than optional.

```ruby
# config/application.rb
config.vpndetection = { api_key: ENV["VPNDETECTION_API_KEY"] }
```

```ruby
class HomeController < ApplicationController
  def index
    lookup = VPNDetection::Rails.lookup(request)
    render plain: lookup&.result&.vpn? ? "Hello, VPN user" : "Hello"
  end
end
```

In a non-Rails Rack app, insert it yourself:

```ruby
use VPNDetection::Rails::Middleware, api_key: ENV["VPNDETECTION_API_KEY"]
```

By default nothing is blocked. Every request gets an answer and your own code decides what that means — which is usually what you want, because whether a VPN visitor is a problem depends entirely on what they are doing.

## Blocking

Set a `block_condition` and a matching request is answered with `403` and never reaches your controllers.

```ruby
config.vpndetection = { api_key: ENV["VPNDETECTION_API_KEY"], block_condition: { is_vpn: true } }
```

A condition is written in the shape of an answer, and only the members you name are considered. That lets it reach the evidence, not just the flags:

```ruby
{ is_vpn: true, vpn: { provider: "nordvpn" } }         # one provider
{ is_resproxy: true, resproxy: { hits: { gte: 5 } } }  # a numeric threshold
{ vpn: { confidence: %w[high medium] } }               # any of these
[{ is_tor: true }, { is_resproxy: true }]              # a list is OR
```

Symbol and string keys both work. Values are matched by equality, strings without regard to case. An Array means any-of. A Hash of `gte`/`gt`/`lte`/`lt` compares numbers, and every bound you give must hold, so two of them are a range. Members set to `false` or `nil` are ignored, so a condition states the signals you act on; one that constrains nothing would match every request, and is refused when the middleware is built rather than silently blocking all your traffic.

Replace the refusal with `on_blocked`, which returns a Rack triplet:

```ruby
on_blocked: ->(request, lookup) { [303, { "location" => "/no-vpn" }, []] }
```

## Where the client address comes from

This is the setting that decides whether any of the above works, and it is the one thing only you can get right.

**In Rails**, the default reads `env["action_dispatch.remote_ip"]` — the answer `ActionDispatch::RemoteIp` computed from `X-Forwarded-For` minus your `config.action_dispatch.trusted_proxies`. That is the right fix behind a load balancer: tell Rails which proxies are yours and it resolves the visitor for you. `Rack::Request#ip` does *not* read that entry, so reading Rails' own is what makes your `trusted_proxies` mean anything here.

**In a bare Rack app** there is no such entry and the default falls back to `Rack::Request#ip`. Be aware that Rack's `ip` **already trusts `X-Forwarded-For`**: it returns the left-most entry once private and loopback addresses are dropped, which is whatever the caller sent. That is measured, not assumed, and the test suite pins it. Behind nothing, or behind an edge that appends rather than overwrites, name your edge's header instead:

```ruby
ip_selector: VPNDetection::Rails.header_ip_selector("CF-Connecting-IP")
```

`VPNDetection::Rails.xff_ip_selector` reads `X-Forwarded-For` directly, and `xff_ip_selector(1)` counts one trusted hop from the right. Anything else, pass your own callable — it receives the Rack request and returns an address.

If the address resolves to a private one, the middleware says so once. That is expected locally and is the signal to fix your configuration anywhere else.

## When a lookup fails

The request is let through, and the reason is on `lookup.error`. Our outage should not become yours, so a network failure, an exhausted quota or a rejected key all fail open. Pass `fail_closed: true` to block instead. Private addresses are answered locally and never fail, so this will not lock you out in development.

## Cost and latency

Answers are cached for an hour, so a returning visitor costs nothing, and private addresses never leave the process. A cache miss is one request to our API, bounded at 2.5 seconds by default and not retried — on a request path, failing open quickly beats holding a visitor while we try again.

Skip what you do not care about:

```ruby
skip: ->(request) { request.path.start_with?("/assets") }
```

Beyond a few million distinct visitors a day, stop calling the API per request: [download the dataset](https://vpndetection.io/databases) and look addresses up locally instead.

## Absent is not false

Only `ip` and `is_vpn` come back on every plan. A member your plan does not include is `nil`, which means "not in your plan" rather than "checked, and no" — and Ruby makes that easy to lose, since `nil` and `false` are both falsy.

```ruby
lookup.result.hosting?            # true or false, never nil
lookup.result.is_hosting          # nil when your plan does not include it
lookup.result.included?(:is_hosting)
```

A `block_condition` naming a member your plan does not serve can never match, so the middleware warns once instead of failing silently. Pass `on_missing_field: :raise` to make it an error.

## Other Libraries

There are official VPNDetection client libraries available for many languages including PHP, Python, Go, Java, Ruby, and many popular frameworks such as Django, Rails, and Laravel. See our GitHub at https://github.com/vpndetection-io for more.

## About VPNDetection

VPN Detection API: Accurate anonymity detection identifying VPNs, residential proxies, hosting servers, Tor nodes, CDNs, relays and more.

[<img src="https://s3.vpndetection.io/vpndetection-public/brand/mark.svg" alt="VPNDetection" width="96"/>](https://vpndetection.io/)

## License

This project is licensed under the [MIT License](LICENSE).
