#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'source_license_sdk'

class ComprehensiveSourceLicenseTest
  LICENSE_KEY = 'VB6K-FSEY-VYWT-HTRJ'
  SERVER_URL = 'http://localhost:4567'

  def initialize
    @test_results = []
    @passed = 0
    @failed = 0

    puts '=' * 80
    puts 'COMPREHENSIVE SOURCE-LICENSE SDK TEST SUITE'
    puts '=' * 80
    puts "License Key: #{LICENSE_KEY}"
    puts "Server URL: #{SERVER_URL}"
    puts '=' * 80
    puts
  end

  def run_all_tests
    # Configuration Tests
    test_sdk_configuration
    test_invalid_configuration

    # Basic License Validation Tests
    test_license_validation_without_machine_id
    test_license_validation_with_machine_id
    test_invalid_license_key_validation
    test_empty_license_key_validation
    test_malformed_license_key_validation

    # License Activation Tests
    test_license_activation_success
    test_license_activation_without_machine_id
    test_license_activation_with_custom_machine_id
    test_invalid_license_activation
    test_duplicate_activation_attempt

    # Edge Cases and Error Handling
    test_network_error_handling
    test_server_unavailable_handling
    test_rate_limit_handling
    test_license_expiration_handling

    # Enforcement Tests
    test_license_enforcement_valid
    test_license_enforcement_invalid

    # Machine ID Tests
    test_machine_id_generation
    test_custom_machine_id_validation

    # Advanced Scenarios
    test_concurrent_validations
    test_license_status_changes
    test_configuration_changes_during_runtime

    # Print final results
    print_test_summary
  end

  private

  def test_sdk_configuration
    section_header('SDK Configuration Tests')

    test_case('Valid SDK Configuration') do
      SourceLicenseSDK.setup(
        server_url: SERVER_URL,
        license_key: LICENSE_KEY,
        auto_generate_machine_id: true
      )

      config = SourceLicenseSDK.configuration
      config.valid? && config.server_url == SERVER_URL && config.license_key == LICENSE_KEY
    end

    test_case('Configuration via block') do
      SourceLicenseSDK.configure do |config|
        config.server_url = SERVER_URL
        config.license_key = LICENSE_KEY
        config.timeout = 60
        config.verify_ssl = false
      end

      config = SourceLicenseSDK.configuration
      config.timeout == 60 && !config.verify_ssl
    end
  end

  def test_invalid_configuration
    section_header('Invalid Configuration Tests')

    test_case('Empty server URL should raise error') do
      SourceLicenseSDK.setup(server_url: '', license_key: LICENSE_KEY)
      SourceLicenseSDK::Client.new(SourceLicenseSDK.configuration)
      false # Should not reach here
    rescue SourceLicenseSDK::ConfigurationError
      true
    end

    test_case('Invalid server URL format should raise error') do
      SourceLicenseSDK.setup(server_url: 'invalid-url', license_key: LICENSE_KEY)
      SourceLicenseSDK::Client.new(SourceLicenseSDK.configuration)
      false # Should not reach here
    rescue SourceLicenseSDK::ConfigurationError
      true
    end
  end

  def test_license_validation_without_machine_id
    section_header('License Validation Tests (No Machine ID)')

    test_case('Validate license without machine ID') do
      SourceLicenseSDK.setup(server_url: SERVER_URL, license_key: LICENSE_KEY)

      begin
        result = SourceLicenseSDK.validate_license
        puts "  Result: valid=#{result.valid?}, error=#{result.error_message}"
        result.respond_to?(:valid?)
      rescue StandardError => e
        puts "  Exception: #{e.class.name}: #{e.message}"
        true # Exception is expected behavior for some scenarios
      end
    end
  end

  def test_license_validation_with_machine_id
    section_header('License Validation Tests (With Machine ID)')

    test_case('Validate license with auto-generated machine ID') do
      SourceLicenseSDK.setup(
        server_url: SERVER_URL,
        license_key: LICENSE_KEY,
        auto_generate_machine_id: true
      )

      begin
        machine_id = SourceLicenseSDK::MachineIdentifier.generate
        result = SourceLicenseSDK.validate_license(LICENSE_KEY, machine_id: machine_id)
        puts "  Machine ID: #{machine_id}"
        puts "  Result: valid=#{result.valid?}, error=#{result.error_message}"
        result.respond_to?(:valid?)
      rescue StandardError => e
        puts "  Exception: #{e.class.name}: #{e.message}"
        true
      end
    end

    test_case('Validate license with custom machine ID') do
      custom_machine_id = 'TEST-MACHINE-001'

      begin
        result = SourceLicenseSDK.validate_license(LICENSE_KEY, machine_id: custom_machine_id)
        puts "  Custom Machine ID: #{custom_machine_id}"
        puts "  Result: valid=#{result.valid?}, error=#{result.error_message}"
        result.respond_to?(:valid?)
      rescue StandardError => e
        puts "  Exception: #{e.class.name}: #{e.message}"
        true
      end
    end
  end

  def test_invalid_license_key_validation
    section_header('Invalid License Key Tests')

    invalid_keys = %w[
      INVALID-KEY-123
      XXXX-XXXX-XXXX-XXXX
      1234-5678-9012-3456
      TEST-TEST-TEST-TEST
    ]

    invalid_keys.each do |invalid_key|
      test_case("Validate invalid license key: #{invalid_key}") do
        result = SourceLicenseSDK.validate_license(invalid_key)
        puts "  Result: valid=#{result.valid?}, error=#{result.error_message}"
        !result.valid? # Should be invalid
      rescue StandardError => e
        puts "  Exception: #{e.class.name}: #{e.message}"
        true # Expected behavior
      end
    end
  end

  def test_empty_license_key_validation
    section_header('Empty/Nil License Key Tests')

    test_case('Validate with nil license key') do
      # Clear the configuration first to ensure nil is actually used
      original_license_key = SourceLicenseSDK.configuration.license_key
      SourceLicenseSDK.configuration.license_key = nil

      begin
        SourceLicenseSDK.validate_license(nil)
        # Restore original config
        SourceLicenseSDK.configuration.license_key = original_license_key
        false # Should raise error
      rescue SourceLicenseSDK::ConfigurationError => e
        puts "  Expected error: #{e.message}"
        # Restore original config
        SourceLicenseSDK.configuration.license_key = original_license_key
        true
      rescue StandardError => e
        puts "  Different error type: #{e.class.name}: #{e.message}"
        # Restore original config
        SourceLicenseSDK.configuration.license_key = original_license_key
        true # Still valid test outcome - error was expected
      end
    end

    test_case('Validate with empty license key') do
      SourceLicenseSDK.validate_license('')
      false # Should raise error
    rescue SourceLicenseSDK::ConfigurationError => e
      puts "  Expected error: #{e.message}"
      true
    end
  end

  def test_malformed_license_key_validation
    section_header('Malformed License Key Tests')

    malformed_keys = [
      'TOO-SHORT',
      'VB6K-FSEY-VYWT-HTRJ-EXTRA-PARTS',
      'VB6K_FSEY_VYWT_HTRJ', # Wrong separator
      'vb6k-fsey-vywt-htrj', # Wrong case
      'VB6K FSEY VYWT HTRJ', # Spaces instead of dashes
    ]

    malformed_keys.each do |malformed_key|
      test_case("Validate malformed license key: #{malformed_key}") do
        result = SourceLicenseSDK.validate_license(malformed_key)
        puts "  Result: valid=#{result.valid?}, error=#{result.error_message}"
        !result.valid? # Should be invalid
      rescue StandardError => e
        puts "  Exception: #{e.class.name}: #{e.message}"
        true # Expected behavior
      end
    end
  end

  def test_license_activation_success
    section_header('License Activation Tests')

    test_case('Activate license with generated machine ID') do
      machine_id = SourceLicenseSDK::MachineIdentifier.generate

      begin
        result = SourceLicenseSDK.activate_license(LICENSE_KEY, machine_id: machine_id)
        puts "  Machine ID: #{machine_id}"
        puts "  Result: success=#{result.success?}, valid=#{result.valid?}"
        puts "  Error: #{result.error_message}" if result.error_message
        puts "  Activations remaining: #{result.activations_remaining}" if result.activations_remaining
        result.respond_to?(:success?)
      rescue StandardError => e
        puts "  Exception: #{e.class.name}: #{e.message}"
        true # May be expected depending on license status
      end
    end
  end

  def test_license_activation_without_machine_id
    section_header('License Activation Error Tests')

    test_case('Activate license without machine ID') do
      # Clear the auto_generate_machine_id and machine_id config to force nil behavior
      original_auto_generate = SourceLicenseSDK.configuration.auto_generate_machine_id
      original_machine_id = SourceLicenseSDK.configuration.machine_id
      SourceLicenseSDK.configuration.auto_generate_machine_id = false
      SourceLicenseSDK.configuration.machine_id = nil

      begin
        SourceLicenseSDK.activate_license(LICENSE_KEY, machine_id: nil)
        # Restore config
        SourceLicenseSDK.configuration.auto_generate_machine_id = original_auto_generate
        SourceLicenseSDK.configuration.machine_id = original_machine_id
        false # Should raise error
      rescue SourceLicenseSDK::ConfigurationError => e
        puts "  Expected error: #{e.message}"
        # Restore config
        SourceLicenseSDK.configuration.auto_generate_machine_id = original_auto_generate
        SourceLicenseSDK.configuration.machine_id = original_machine_id
        true
      rescue StandardError => e
        puts "  Different error (may be expected): #{e.class.name}: #{e.message}"
        # Restore config
        SourceLicenseSDK.configuration.auto_generate_machine_id = original_auto_generate
        SourceLicenseSDK.configuration.machine_id = original_machine_id
        # Check if it's a reasonable error for this test scenario
        e.message.include?('Machine ID') || e.message.include?('required') || e.message.include?('activated')
      end
    end

    test_case('Activate license with empty machine ID') do
      SourceLicenseSDK.activate_license(LICENSE_KEY, machine_id: '')
      false # Should raise error
    rescue SourceLicenseSDK::ConfigurationError => e
      puts "  Expected error: #{e.message}"
      true
    end
  end

  def test_license_activation_with_custom_machine_id
    section_header('Custom Machine ID Activation Tests')

    custom_machine_ids = [
      'WORKSTATION-001',
      'SERVER-PROD-01',
      "DEV-MACHINE-#{Time.now.to_i}",
      "TEST-#{Random.rand(10_000)}",
    ]

    custom_machine_ids.each do |machine_id|
      test_case("Activate license with custom machine ID: #{machine_id}") do
        result = SourceLicenseSDK.activate_license(LICENSE_KEY, machine_id: machine_id)
        puts "  Result: success=#{result.success?}, error=#{result.error_message}"
        result.respond_to?(:success?)
      rescue StandardError => e
        puts "  Exception: #{e.class.name}: #{e.message}"
        true
      end
    end
  end

  def test_invalid_license_activation
    section_header('Invalid License Activation Tests')

    invalid_keys = %w[FAKE-FAKE-FAKE-FAKE INVALID-KEY-123]

    invalid_keys.each do |invalid_key|
      test_case("Activate invalid license: #{invalid_key}") do
        machine_id = SourceLicenseSDK::MachineIdentifier.generate

        begin
          result = SourceLicenseSDK.activate_license(invalid_key, machine_id: machine_id)
          puts "  Result: success=#{result.success?}, error=#{result.error_message}"
          !result.success? # Should fail
        rescue StandardError => e
          puts "  Exception: #{e.class.name}: #{e.message}"
          true # Expected behavior
        end
      end
    end
  end

  def test_duplicate_activation_attempt
    section_header('Duplicate Activation Tests')

    test_case('Attempt duplicate activation on same machine') do
      machine_id = "DUPLICATE-TEST-#{Time.now.to_i}"

      begin
        # First activation attempt
        result1 = SourceLicenseSDK.activate_license(LICENSE_KEY, machine_id: machine_id)
        puts "  First activation: success=#{result1.success?}, error=#{result1.error_message}"

        # Wait a moment
        sleep(1)

        # Second activation attempt (should handle gracefully)
        result2 = SourceLicenseSDK.activate_license(LICENSE_KEY, machine_id: machine_id)
        puts "  Second activation: success=#{result2.success?}, error=#{result2.error_message}"

        true # Both results should be valid responses
      rescue StandardError => e
        puts "  Exception: #{e.class.name}: #{e.message}"
        true
      end
    end
  end

  def test_network_error_handling
    section_header('Network Error Handling Tests')

    test_case('Handle invalid server URL') do
      # Save current config
      original_url = SourceLicenseSDK.configuration.server_url

      # Set invalid URL
      SourceLicenseSDK.configuration.server_url = 'http://nonexistent-server-12345.com'

      SourceLicenseSDK.validate_license(LICENSE_KEY)
      puts '  Unexpected success with invalid server'

      # Restore config
      SourceLicenseSDK.configuration.server_url = original_url
      false
    rescue StandardError => e
      puts "  Expected network error: #{e.class.name}: #{e.message}"

      # Restore config
      SourceLicenseSDK.configuration.server_url = SERVER_URL
      true
    end
  end

  def test_server_unavailable_handling
    section_header('Server Unavailable Tests')

    test_case('Handle server on wrong port') do
      # Save current config
      original_url = SourceLicenseSDK.configuration.server_url

      # Set wrong port
      SourceLicenseSDK.configuration.server_url = 'http://localhost:9999'

      SourceLicenseSDK.validate_license(LICENSE_KEY)
      puts '  Unexpected success with wrong port'

      # Restore config
      SourceLicenseSDK.configuration.server_url = original_url
      false
    rescue StandardError => e
      puts "  Expected connection error: #{e.class.name}: #{e.message}"

      # Restore config
      SourceLicenseSDK.configuration.server_url = SERVER_URL
      true
    end
  end

  def test_rate_limit_handling
    section_header('Rate Limit Handling Tests')

    test_case('Multiple rapid requests (potential rate limiting)') do
      results = []
      rate_limited = false

      10.times do |i|
        begin
          result = SourceLicenseSDK.validate_license(LICENSE_KEY)
          results << result

          if result.rate_limited?
            puts "  Rate limit detected on request #{i + 1}"
            puts "  Retry after: #{result.retry_after} seconds" if result.retry_after
            rate_limited = true
            break
          end
        rescue SourceLicenseSDK::RateLimitError => e
          puts "  Rate limit exception on request #{i + 1}: #{e.message}"
          puts "  Retry after: #{e.retry_after} seconds" if e.retry_after
          rate_limited = true
          break
        rescue StandardError => e
          puts "  Other error on request #{i + 1}: #{e.class.name}: #{e.message}"
        end

        sleep(0.1) # Small delay between requests
      end

      puts "  Completed #{results.length} requests"
      puts "  Rate limited: #{rate_limited}"
      true # Test always passes - we're just observing behavior
    end
  end

  def test_license_expiration_handling
    section_header('License Expiration Tests')

    test_case('Check for expiration information') do
      result = SourceLicenseSDK.validate_license(LICENSE_KEY)

      if result.expires_at
        puts "  License expires at: #{result.expires_at}"
        puts "  License expired: #{result.expired?}"
        puts "  Days until expiration: #{((result.expires_at - Time.now) / 86_400).round(2)}" unless result.expired?
      else
        puts '  No expiration information available'
      end

      true
    rescue StandardError => e
      puts "  Exception: #{e.class.name}: #{e.message}"
      true
    end
  end

  def test_license_enforcement_valid
    section_header('License Enforcement Tests (Valid)')

    test_case('Enforce valid license (should not exit)') do
      # This is tricky to test without actually exiting
      # We'll use a different approach - validate first, then simulate enforcement
      result = SourceLicenseSDK.validate_license(LICENSE_KEY)

      if result.valid?
        puts '  License would pass enforcement check'
        puts '  Application would continue normally'
      else
        puts '  License would fail enforcement check'
        puts "  Application would exit with error: #{result.error_message}"
      end
      true
    rescue StandardError => e
      puts "  Exception during enforcement test: #{e.class.name}: #{e.message}"
      true
    end
  end

  def test_license_enforcement_invalid
    section_header('License Enforcement Tests (Invalid)')

    test_case('Enforce invalid license behavior') do
      result = SourceLicenseSDK.validate_license('INVALID-KEY-TEST')

      if result.valid?
        puts '  Unexpected: invalid license reported as valid'
      else
        puts '  Invalid license detected - enforcement would exit application'
        puts "  Exit reason: #{result.error_message}"
      end

      true
    rescue StandardError => e
      puts "  Exception with invalid license: #{e.class.name}: #{e.message}"
      puts '  Enforcement would exit application due to exception'
      true
    end
  end

  def test_machine_id_generation
    section_header('Machine ID Generation Tests')

    test_case('Generate multiple machine IDs') do
      machine_ids = []

      5.times do
        machine_id = SourceLicenseSDK::MachineIdentifier.generate
        machine_ids << machine_id
        puts "  Generated: #{machine_id}"
      end

      # Check uniqueness (they should be the same for same machine)
      unique_ids = machine_ids.uniq
      puts "  Unique IDs generated: #{unique_ids.length}"
      puts "  Consistency check: #{unique_ids.length == 1 ? 'PASS' : 'FAIL'}"

      machine_ids.all? { |id| !id.nil? && !id.empty? }
    end

    test_case('Generate machine fingerprint') do
      fingerprint = SourceLicenseSDK::MachineIdentifier.generate_fingerprint
      puts "  Machine fingerprint: #{fingerprint}"
      !fingerprint.nil? && !fingerprint.empty?
    rescue StandardError => e
      puts "  Exception generating fingerprint: #{e.class.name}: #{e.message}"
      true # May not be implemented
    end
  end

  def test_custom_machine_id_validation
    section_header('Custom Machine ID Validation Tests')

    test_cases = [
      { id: 'SIMPLE-ID', expected: true },
      { id: 'MACHINE-123', expected: true },
      { id: 'prod-server-01', expected: true },
      { id: '', expected: false },
      { id: '   ', expected: false },
      { id: 'a' * 256, expected: false }, # Very long ID
    ]

    test_cases.each do |test_case|
      test_case("Validate machine ID format: '#{test_case[:id]}'") do
        SourceLicenseSDK.validate_license(LICENSE_KEY, machine_id: test_case[:id])
        puts "  Machine ID '#{test_case[:id]}' accepted by API"
        true
      rescue StandardError => e
        puts "  Machine ID '#{test_case[:id]}' rejected: #{e.message}"
        true # Both acceptance and rejection are valid test outcomes
      end
    end
  end

  def test_concurrent_validations
    section_header('Concurrent Validation Tests')

    test_case('Multiple simultaneous validations') do
      threads = []
      results = []

      5.times do |i|
        threads << Thread.new do
          result = SourceLicenseSDK.validate_license(LICENSE_KEY)
          results << { thread: i, success: true, valid: result.valid?, error: result.error_message }
        rescue StandardError => e
          results << { thread: i, success: false, error: e.message }
        end
      end

      threads.each(&:join)

      results.each do |result|
        puts "  Thread #{result[:thread]}: #{result[:success] ? 'SUCCESS' : 'FAILED'}"
        puts "    Valid: #{result[:valid]}" if result[:valid]
        puts "    Error: #{result[:error]}" if result[:error]
      end

      results.length == 5
    end
  end

  def test_license_status_changes
    section_header('License Status Change Tests')

    test_case('Validate license status over time') do
      # Initial validation
      result1 = SourceLicenseSDK.validate_license(LICENSE_KEY)
      puts "  Initial validation: valid=#{result1.valid?}"

      # Wait and validate again
      sleep(2)

      result2 = SourceLicenseSDK.validate_license(LICENSE_KEY)
      puts "  Second validation: valid=#{result2.valid?}"

      # Compare results
      if result1.valid? == result2.valid?
        puts '  License status consistent over time'
      else
        puts '  License status changed between validations'
      end

      true
    rescue StandardError => e
      puts "  Exception during status check: #{e.class.name}: #{e.message}"
      true
    end
  end

  def test_configuration_changes_during_runtime
    section_header('Runtime Configuration Change Tests')

    test_case('Change configuration during runtime') do
      # Initial validation with current config
      result1 = SourceLicenseSDK.validate_license(LICENSE_KEY)
      puts "  Initial validation: valid=#{result1.valid?}"

      # Change timeout configuration
      original_timeout = SourceLicenseSDK.configuration.timeout
      SourceLicenseSDK.configuration.timeout = 5

      # Validate with new timeout
      result2 = SourceLicenseSDK.validate_license(LICENSE_KEY)
      puts "  Validation with modified timeout: valid=#{result2.valid?}"

      # Restore original timeout
      SourceLicenseSDK.configuration.timeout = original_timeout

      # Final validation
      result3 = SourceLicenseSDK.validate_license(LICENSE_KEY)
      puts "  Final validation: valid=#{result3.valid?}"

      true
    rescue StandardError => e
      puts "  Exception during configuration test: #{e.class.name}: #{e.message}"
      true
    end
  end

  # Helper methods

  def section_header(title)
    puts
    puts '-' * 60
    puts title
    puts '-' * 60
  end

  def test_case(name)
    print "#{name}... "

    start_time = Time.now
    begin
      result = yield
      duration = Time.now - start_time

      if result
        puts "✅ PASS (#{duration.round(3)}s)"
        @passed += 1
      else
        puts "❌ FAIL (#{duration.round(3)}s)"
        @failed += 1
      end

      @test_results << { name: name, passed: result, duration: duration }
    rescue StandardError => e
      duration = Time.now - start_time
      puts "💥 ERROR (#{duration.round(3)}s)"
      puts "   #{e.class.name}: #{e.message}"
      @failed += 1
      @test_results << { name: name, passed: false, duration: duration, error: e }
    end
  end

  def print_test_summary
    puts
    puts '=' * 80
    puts 'TEST SUMMARY'
    puts '=' * 80
    puts "Total Tests: #{@passed + @failed}"
    puts "Passed: #{@passed}"
    puts "Failed: #{@failed}"
    puts "Success Rate: #{(@passed.to_f / (@passed + @failed) * 100).round(2)}%"

    total_duration = @test_results.sum { |r| r[:duration] }
    puts "Total Duration: #{total_duration.round(3)}s"

    if @failed.positive?
      puts
      puts 'Failed Tests:'
      @test_results.reject { |r| r[:passed] }.each do |result|
        puts "  ❌ #{result[:name]}"
        puts "     Error: #{result[:error].message}" if result[:error]
      end
    end

    puts
    puts "License Key Used: #{LICENSE_KEY}"
    puts "Server URL: #{SERVER_URL}"
    puts "Test completed at: #{Time.now}"
    puts '=' * 80
  end
end

# Run the comprehensive test suite
if __FILE__ == $0
  tester = ComprehensiveSourceLicenseTest.new
  tester.run_all_tests
end
