# frozen_string_literal: true

module SourceLicenseSDK
  # Base exception class for all SDK errors
  class Error < StandardError; end

  # Configuration related errors
  class ConfigurationError < Error; end

  # Network and HTTP related errors
  class NetworkError < Error
    attr_reader :response_code, :response_body

    def initialize(message, response_code: nil, response_body: nil)
      super(message)
      @response_code = response_code
      @response_body = response_body
    end
  end

  # License validation errors
  class LicenseError < Error
    attr_reader :error_code, :retry_after

    def initialize(message, error_code: nil, retry_after: nil)
      super(message)
      @error_code = error_code
      @retry_after = retry_after
    end
  end

  # Rate limiting errors
  class RateLimitError < LicenseError
    def initialize(message = 'Rate limit exceeded', retry_after: nil)
      super(message, error_code: 'RATE_LIMIT_EXCEEDED', retry_after: retry_after)
    end
  end

  # License not found errors
  class LicenseNotFoundError < LicenseError
    def initialize(message = 'License not found')
      super(message, error_code: 'LICENSE_NOT_FOUND')
    end
  end

  # License expired errors
  class LicenseExpiredError < LicenseError
    def initialize(message = 'License has expired')
      super(message, error_code: 'LICENSE_EXPIRED')
    end
  end

  # License activation errors
  class ActivationError < LicenseError
    def initialize(message, error_code: 'ACTIVATION_FAILED')
      super
    end
  end

  # Machine ID related errors
  class MachineError < Error; end
end
