# frozen_string_literal: true

require 'time'

# Represents the result of a license validation or activation request
class SourceLicenseSDK::LicenseValidationResult
  attr_reader :valid, :success, :error_message, :error_code, :expires_at,
              :activations_remaining, :retry_after, :token, :timestamp,
              :rate_limit_remaining, :rate_limit_reset_at

  def initialize(data)
    @data = data

    initialize_validation_fields
    initialize_activation_fields
    initialize_common_fields
    initialize_rate_limit_fields
  end

  def valid?
    @valid == true
  end

  def success?
    @success == true
  end

  def expired?
    return false unless @expires_at

    @expires_at < Time.now
  end

  def rate_limited?
    @error_message&.downcase&.include?('rate limit') ||
      @error_code == 'RATE_LIMIT_EXCEEDED'
  end

  def to_h
    {
      valid: @valid,
      success: @success,
      error_message: @error_message,
      error_code: @error_code,
      expires_at: @expires_at,
      activations_remaining: @activations_remaining,
      retry_after: @retry_after,
      token: @token,
      timestamp: @timestamp,
      rate_limit_remaining: @rate_limit_remaining,
      rate_limit_reset_at: @rate_limit_reset_at,
    }
  end

  def inspect
    "#<#{self.class.name} valid=#{@valid} success=#{@success} error='#{@error_message}'>"
  end

  private

  def initialize_validation_fields
    @valid = extract_value(:valid, false)
    @token = extract_value(:token)
  end

  def initialize_activation_fields
    @success = extract_value(:success, false)
    @activations_remaining = extract_value(:activations_remaining)
  end

  def initialize_common_fields
    @error_message = extract_error_message
    @error_code = extract_value(:error_code)
    @expires_at = parse_datetime(extract_value(:expires_at))
    @retry_after = extract_value(:retry_after)
    @timestamp = parse_datetime(extract_value(:timestamp))
  end

  def initialize_rate_limit_fields
    @rate_limit_remaining = extract_rate_limit_value(:remaining)
    @rate_limit_reset_at = parse_datetime(extract_rate_limit_value(:reset_at))
  end

  def extract_value(key, default = nil)
    @data[key] || @data[key.to_s] || default
  end

  def extract_error_message
    extract_value(:error) || extract_value(:message)
  end

  def extract_rate_limit_value(key)
    @data[:rate_limit]&.dig(key) || @data['rate_limit']&.dig(key.to_s)
  end

  def parse_datetime(value)
    return nil if value.nil?
    return value if value.is_a?(Time)
    return Time.at(value) if value.is_a?(Numeric)

    Time.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
