# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# HTTP client for communicating with Source-License API
class SourceLicenseSDK::Client
  attr_reader :config

  def initialize(config)
    @config = config
    validate_config!
  end

  # Validate a license key
  def validate_license(license_key, machine_id: nil, machine_fingerprint: nil)
    machine_fingerprint ||= SourceLicenseSDK::MachineIdentifier.generate_fingerprint if machine_id

    path = "/api/license/#{license_key}/validate"
    params = {}
    params[:machine_id] = machine_id if machine_id
    params[:machine_fingerprint] = machine_fingerprint if machine_fingerprint

    response = make_request(:get, path, params: params)
    SourceLicenseSDK::LicenseValidationResult.new(response)
  rescue SourceLicenseSDK::NetworkError => e
    handle_network_error(e)
  end

  # Activate a license on this machine
  def activate_license(license_key, machine_id:, machine_fingerprint: nil)
    machine_fingerprint ||= SourceLicenseSDK::MachineIdentifier.generate_fingerprint

    path = "/api/license/#{license_key}/activate"
    body = {
      machine_id: machine_id,
      machine_fingerprint: machine_fingerprint,
    }

    response = make_request(:post, path, body: body)
    SourceLicenseSDK::LicenseValidationResult.new(response)
  rescue SourceLicenseSDK::NetworkError => e
    handle_network_error(e)
  end

  private

  def validate_config!
    raise SourceLicenseSDK::ConfigurationError, 'Server URL is required' unless config.server_url
    raise SourceLicenseSDK::ConfigurationError, 'Invalid server URL format' unless valid_url?(config.server_url)
  end

  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def make_request(method, path, params: {}, body: nil)
    uri = build_uri(path, params)
    http = create_http_client(uri)
    request = create_request(method, uri, body)

    response = http.request(request)
    handle_response(response)
  end

  def build_uri(path, params = {})
    base_uri = URI.parse(config.server_url)
    base_uri.path = path

    base_uri.query = URI.encode_www_form(params) if params.any?

    base_uri
  end

  def create_http_client(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.verify_mode = config.verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    http.read_timeout = config.timeout
    http.open_timeout = config.timeout
    http
  end

  def create_request(method, uri, body)
    request_class = case method
                    when :get then Net::HTTP::Get
                    when :post then Net::HTTP::Post
                    when :put then Net::HTTP::Put
                    when :delete then Net::HTTP::Delete
                    else raise ArgumentError, "Unsupported HTTP method: #{method}"
                    end

    request = request_class.new(uri)
    request['User-Agent'] = config.user_agent
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json' if body

    if body
      request.body = body.is_a?(String) ? body : JSON.generate(body)
    end

    request
  end

  def handle_response(response)
    case response.code.to_i
    when 200..299
      parse_json_response(response.body)
    when 400
      data = parse_json_response(response.body)
      raise_license_error(data, response.code.to_i)
    when 404
      data = parse_json_response(response.body)
      raise SourceLicenseSDK::LicenseNotFoundError, data['error'] || 'License not found'
    when 429
      data = parse_json_response(response.body)
      retry_after = response['Retry-After']&.to_i || data['retry_after']
      raise SourceLicenseSDK::RateLimitError.new(data['error'] || 'Rate limit exceeded', retry_after: retry_after)
    when 500..599
      raise SourceLicenseSDK::NetworkError.new('Server error occurred', response_code: response.code.to_i, response_body: response.body)
    else
      raise SourceLicenseSDK::NetworkError.new("Unexpected response: #{response.code}", response_code: response.code.to_i,
                                                                      response_body: response.body)
    end
  end

  def parse_json_response(body)
    return {} if body.nil? || body.empty?

    JSON.parse(body)
  rescue JSON::ParserError
    raise SourceLicenseSDK::NetworkError.new('Invalid JSON response from server', response_body: body)
  end

  def raise_license_error(data, _status_code)
    error_message = data['error'] || data['message'] || 'License validation failed'

    case error_message.downcase
    when /expired/
      raise SourceLicenseSDK::LicenseExpiredError, error_message
    when /rate limit/
      retry_after = data['retry_after']
      raise SourceLicenseSDK::RateLimitError.new(error_message, retry_after: retry_after)
    when /not found/
      raise SourceLicenseSDK::LicenseNotFoundError, error_message
    when /activation/
      raise SourceLicenseSDK::ActivationError, error_message
    else
      raise SourceLicenseSDK::LicenseError.new(error_message, error_code: data['error_code'])
    end
  end

  def handle_network_error(error)
    # Convert network errors to license validation results for consistency
    case error
    when SourceLicenseSDK::RateLimitError
      SourceLicenseSDK::LicenseValidationResult.new(
        valid: false,
        success: false,
        error: error.message,
        error_code: error.error_code,
        retry_after: error.retry_after
      )
    when SourceLicenseSDK::LicenseNotFoundError, SourceLicenseSDK::LicenseExpiredError, SourceLicenseSDK::ActivationError
      SourceLicenseSDK::LicenseValidationResult.new(
        valid: false,
        success: false,
        error: error.message,
        error_code: error.error_code
      )
    else
      # Re-raise other network errors
      raise error
    end
  end
end
