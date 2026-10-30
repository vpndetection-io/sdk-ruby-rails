# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff. Releases before 2.0.4 are described by their release commits.

## 2.1.11 - 2026-10-30

### Fixes

- Require vpndetection 5.11.2: a lowercase t or z in a date-time reads ([`9aa8e0b`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/9aa8e0bac5cdb46354391307c6286c904da7152a))

## 2.1.10 - 2026-10-28

### Fixes

- Warn when a forged Forwarded header can name the visitor ([`3b273ac`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/3b273ac014d43d3ca3b3ff9e90c406c4522809dc))

## 2.1.9 - 2026-10-26

### Fixes

- Require vpndetection 5.11.1: re-pinned to the 2026.10.25 spec ([`e77f6c7`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/e77f6c7ec5db78340a0ee0133fc710d057f46623))

## 2.1.8 - 2026-10-22

### Fixes

- Require vpndetection 5.11.0: a key trimmed, and oauth.register ([`bb3449b`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/bb3449b9fa21e28d0fc2cbef2ea6bed47efcdf58))

## 2.1.7 - 2026-10-21

### Fixes

- Require vpndetection 5.10.1, which reads a date only in its RFC 3339 form ([`9ea370f`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/9ea370fe212d62fbf3ef0d6237794d8696f5eaee))

## 2.1.6 - 2026-10-20

### Features

- Require vpndetection 5.10.0: lookup results carry location and asn ([`80b9e13`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/80b9e13cf7bdc721be73250d116acddb90dc5611))

## 2.1.5 - 2026-10-20

### Fixes

- Require vpndetection 5.9.1: a member of the wrong type or a null is refused ([`62f29dd`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/62f29ddf2bfa939dc861929c5974c6960b640998))

## 2.1.4 - 2026-10-19

### Fixes

- Require vpndetection 5.9.0: num_ports and num_proxies in the pubproxy detail ([`d394370`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/d394370123d1f7bf48e45edca9fa3478256683fc))

## 2.1.3 - 2026-10-18

### Fixes

- Require vpndetection 5.8.0: is_pubproxy and the pubproxy detail ([`c6ebc38`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/c6ebc382f401ebbf870313e163e48fcb78e06102))

## 2.1.2 - 2026-10-17

### Features

- Require vpndetection 5.7.0: OauthMetadata carries registration_endpoint ([`ad23c5f`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/ad23c5fa4ea2c97b1ace8a771822276c58821be3))

## 2.1.1 - 2026-10-16

### Fixes

- Require vpndetection 5.6.4: the spec re-pinned to 2026.10.15 ([`cce7eef`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/cce7eef498fe820554c59964a6874694832031bc))

## 2.1.0 - 2026-10-13

### Features

- Warn once when a visitor can choose the address Rails reports ([`d75b866`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/d75b86699ca99fc400c889f9fa85acb34fa55f45))

## 2.0.12 - 2026-10-10

### Fixes

- Require vpndetection 5.6.3: the spec re-pinned to 2026.10.09 ([`430c30c`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/430c30cb383a9b0b9fc5ec06901b356f417530c9))

## 2.0.11 - 2026-10-08

### Fixes

- Require vpndetection 5.6.2: every answer a call cannot read is retried ([`9153abc`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/9153abc13d8c14910a715aae79cf6394140b883a))

## 2.0.10 - 2026-10-06

### Fixes

- Require vpndetection 5.6.1: an unreadable 2xx is a retried server_error ([`662d9cf`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/662d9cfb202b44ad5cec087955e4a3b99cf1f282))

## 2.0.9 - 2026-10-05

### Features

- Require vpndetection 5.6.0: the authorization code sign-in ([`186991e`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/186991e65131f765fd49725e5ddb52dde4c5e841))

## 2.0.8 - 2026-10-04

### Fixes

- Require vpndetection 5.5.2, re-pinned to spec 2026.10.03 ([`8170372`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/81703725bbf17345674f205b320b52c9472d9570))

## 2.0.7 - 2026-09-29

### Fixes

- Require vpndetection 5.5.1: IPv4-mapped visitors are looked up, not waved through ([`230d068`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/230d06806702d85ea7dac79458d4e2772fb171fb))

## 2.0.6 - 2026-09-27

### Features

- Require vpndetection 5.5.0: OauthMetadata carries client_id_metadata_document_supported ([`cf94dec`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/cf94dece39a09200f6a97090eea2f1d0b89b7632))

## 2.0.5 - 2026-09-26

### Fixes

- Require vpndetection 5.4.3: concurrent lookups share one request ([`c5fbc52`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/c5fbc52613ecd7bb74beaed7f0a97f2a7bd133b6))

## 2.0.4 - 2026-09-24

### Fixes

- Raise the base floor to vpndetection 5.4.2 ([`bcfd872`](https://github.com/vpndetection-io/sdk-ruby-rails/commit/bcfd8727238891a32ab28d967e342cac60eb09e1))
