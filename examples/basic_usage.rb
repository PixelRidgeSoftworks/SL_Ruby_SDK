#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the lib directory to the load path for development
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'source_license_sdk'

# Example: Basic usage of the Source-License Ruby SDK
puts 'Source-License Ruby SDK Example'
puts '=' * 40

# Configuration
SERVER_URL = 'https://your-license-server.com'
LICENSE_KEY = 'EXAMPLE-1234-ABCD-5678'

# Setup the SDK
puts 'Setting up SDK...'
SourceLicenseSDK.setup(
  server_url: SERVER_URL,
  license_key: LICENSE_KEY,
  auto_generate_machine_id: true
)

# Generate machine identifiers
puts "\nMachine Information:"
machine_id = SourceLicenseSDK::MachineIdentifier.generate
fingerprint = SourceLicenseSDK::MachineIdentifier.generate_fingerprint

puts "Machine ID: #{machine_id}"
puts "Machine Fingerprint: #{fingerprint[0..32]}..." # Show partial for security

# Example 1: License Validation
puts "\n1. License Validation Example:"
puts '-' * 30

begin
  result = SourceLicenseSDK.validate_license

  if result.valid?
    puts '✓ License is valid!'
    puts "  Token: #{result.token[0..20]}..." if result.token
    puts "  Expires: #{result.expires_at}" if result.expires_at
  else
    puts "✗ License validation failed: #{result.error_message}"
  end
rescue SourceLicenseSDK::NetworkError => e
  puts "✗ Network error: #{e.message}"
rescue SourceLicenseSDK::ConfigurationError => e
  puts "✗ Configuration error: #{e.message}"
end

# Example 2: License Activation
puts "\n2. License Activation Example:"
puts '-' * 30

begin
  result = SourceLicenseSDK.activate_license

  if result.success?
    puts '✓ License activated successfully!'
    puts "  Activations remaining: #{result.activations_remaining}" if result.activations_remaining
    puts "  Expires: #{result.expires_at}" if result.expires_at
  else
    puts "✗ Activation failed: #{result.error_message}"
  end
rescue SourceLicenseSDK::ActivationError => e
  puts "✗ Activation error: #{e.message}"
rescue SourceLicenseSDK::NetworkError => e
  puts "✗ Network error: #{e.message}"
end

# Example 3: License Enforcement (commented out to avoid exit)
puts "\n3. License Enforcement Example:"
puts '-' * 30
puts '# This would normally exit the program if license is invalid:'
puts '# SourceLicenseSDK.enforce_license!'
puts "# puts 'Application continues with valid license...'"

# Example 4: Error Handling
puts "\n4. Advanced Error Handling:"
puts '-' * 30

begin
  # Try with invalid license key to demonstrate error handling
  result = SourceLicenseSDK.validate_license('INVALID-KEY')
  puts "Result: #{result.inspect}"
rescue SourceLicenseSDK::LicenseNotFoundError => e
  puts "License not found: #{e.message}"
rescue SourceLicenseSDK::RateLimitError => e
  puts "Rate limited: #{e.message} (retry after #{e.retry_after}s)"
rescue SourceLicenseSDK::LicenseError => e
  puts "License error: #{e.message} (code: #{e.error_code})"
rescue SourceLicenseSDK::Error => e
  puts "SDK error: #{e.message}"
end

puts "\nExample completed!"
puts "Note: This example will show network errors since it's not connected to a real server."
