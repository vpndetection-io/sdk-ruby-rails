# frozen_string_literal: true

require 'vpndetection'
require 'vpndetection/middleware'

require_relative 'rails/version'
require_relative 'rails/selectors'
require_relative 'rails/middleware'
require_relative 'rails/railtie' if defined?(::Rails::Railtie)
