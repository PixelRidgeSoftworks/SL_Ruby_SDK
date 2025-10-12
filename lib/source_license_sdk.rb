# frozen_string_literal: true

require_relative 'source_license_sdk/version'
require_relative 'source_license_sdk/exceptions'
require_relative 'source_license_sdk/machine_identifier'
require_relative 'source_license_sdk/license_validator'
require_relative 'source_license_sdk/client'

module SourceLicenseSDK
  # Configure the SDK with your Source-License server details
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Quick setup method for common use cases
  def self.setup(server_url:, license_key:, machine_id: nil, auto_generate_machine_id: true)
    configure do |config|
      config.server_url = server_url
      config.license_key = license_key
      config.machine_id = machine_id
      config.auto_generate_machine_id = auto_generate_machine_id
    end
  end

  # Validate license (method 1)
  def self.validate_license(license_key = nil, machine_id: nil)
    license_key ||= configuration.license_key
    machine_id ||= configuration.machine_id

    raise SourceLicenseSDK::ConfigurationError, 'License key is required' if license_key.nil? || license_key.empty?

    client = SourceLicenseSDK::Client.new(configuration)
    client.validate_license(license_key, machine_id: machine_id)
  end

  # Activate license (method 2)
  def self.activate_license(license_key = nil, machine_id: nil)
    license_key ||= configuration.license_key
    machine_id ||= configuration.machine_id ||
                   (configuration.auto_generate_machine_id ? SourceLicenseSDK::MachineIdentifier.generate : nil)

    raise SourceLicenseSDK::ConfigurationError, 'License key is required' if license_key.nil? || license_key.empty?

    if machine_id.nil? || machine_id.empty?
      raise SourceLicenseSDK::ConfigurationError,
            'Machine ID is required for activation'
    end

    client = SourceLicenseSDK::Client.new(configuration)
    client.activate_license(license_key, machine_id: machine_id)
  end

  # Enforce license check - exits application if license is invalid (method 3)
  def self.enforce_license!(license_key = nil, machine_id: nil, exit_code: 1, custom_message: nil)
    license_key ||= configuration.license_key
    machine_id ||= configuration.machine_id

    begin
      result = validate_license(license_key, machine_id: machine_id)

      unless result.valid?
        message = custom_message || "License validation failed: #{result.error_message}"
        puts "[LICENSE ERROR] #{message}"
        exit(exit_code)
      end

      result
    rescue SourceLicenseSDK::Error => e
      message = custom_message || "License check failed: #{e.message}"
      puts "[LICENSE ERROR] #{message}"
      exit(exit_code)
    end
  end

  class Configuration
    attr_accessor :server_url, :license_key, :machine_id, :auto_generate_machine_id,
                  :timeout, :user_agent, :verify_ssl

    def initialize
      @server_url = nil
      @license_key = nil
      @machine_id = nil
      @auto_generate_machine_id = true
      @timeout = 30
      @user_agent = "SourceLicenseSDK/#{VERSION}"
      @verify_ssl = true
    end

    def valid?
      !server_url.nil? && !server_url.empty?
    end
  end
end
