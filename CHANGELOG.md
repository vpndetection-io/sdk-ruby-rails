# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff. Releases before 2.0.4 are described by their release commits.

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
