# Source-License Ruby SDK

A Ruby gem for easy integration with the Source-License platform for license validation and activation.

## Features

- **Simple License Validation**: Check if a license key is valid with one method call
- **License Activation**: Activate licenses on specific machines with automatic machine fingerprinting
- **License Enforcement**: Automatically exit your application if license validation fails
- **Rate Limiting Handling**: Built-in handling of API rate limits with retry information
- **Secure Communication**: Uses HTTPS and handles all Source-License API security requirements
- **Cross-Platform Machine Identification**: Works on Windows, macOS, and Linux

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'source_license_sdk'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install source_license_sdk
```

## Quick Start

### 🚀 Copy-Paste Examples for Instant Setup

#### 1. Simple License Check (Most Common)
Copy-paste this code and replace with your server URL:

```ruby
require 'source_license_sdk'

# Get license key from user (command line, config file, environment variable, etc.)
print "Enter your license key: "
license_key = gets.chomp

# Setup (replace server URL with your actual server)
SourceLicenseSDK.setup(
  server_url: 'http://localhost:4567',     # Your Source-License server
  license_key: license_key                 # License key from user
)

# Validate license
result = SourceLicenseSDK.validate_license
if result.valid?
  puts "✅ License is valid! Application can continue."
else
  puts "❌ License invalid: #{result.error_message}"
  exit 1
end

# Your application code here...
puts "🎉 Your application is running!"
```

#### 2. License Activation (One-Time Setup)
For applications that need to activate on first run:

```ruby
require 'source_license_sdk'

# Get license key from user
print "Enter your license key: "
license_key = gets.chomp

# Setup
SourceLicenseSDK.setup(
  server_url: 'http://localhost:4567',     # Your Source-License server
  license_key: license_key
)

# Generate machine ID for activation
machine_id = SourceLicenseSDK::MachineIdentifier.generate
puts "Machine ID: #{machine_id}"

# Try to activate the license
puts "Activating license..."
result = SourceLicenseSDK.activate_license(license_key, machine_id: machine_id)

if result.success?
  puts "✅ License activated successfully!"
  puts "📊 Activations remaining: #{result.activations_remaining}"
else
  puts "❌ Activation failed: #{result.error_message}"
  exit 1
end
```

#### 3. Complete App Protection (Recommended)
One-liner that handles everything automatically:

```ruby
require 'source_license_sdk'

# Get license key from user (or load from config file)
license_key = ARGV[0] || ENV['LICENSE_KEY'] || begin
  print "Enter your license key: "
  gets.chomp
end

# Setup and enforce in one go - app exits if license is invalid
SourceLicenseSDK.setup(
  server_url: 'http://localhost:4567',     # Your Source-License server
  license_key: license_key
)

# This line will exit your app if license is invalid - no other code needed!
SourceLicenseSDK.enforce_license!

# Your protected application code starts here
puts "🔐 Application running with valid license protection!"
```

#### 4. Custom Machine ID (For Server Applications)
When you need to specify a particular machine identifier:

```ruby
require 'source_license_sdk'

# Get license key from user or environment
license_key = ENV['LICENSE_KEY'] || begin
  print "Enter your license key: "
  gets.chomp
end

# Generate machine ID (recommended) or use custom identifier
machine_id = SourceLicenseSDK::MachineIdentifier.generate
# OR use custom ID: machine_id = 'SERVER-PROD-001'

# Setup
SourceLicenseSDK.setup(
  server_url: 'http://localhost:4567',     # Your Source-License server
  license_key: license_key,
  machine_id: machine_id
)

# Activate with the machine ID
result = SourceLicenseSDK.activate_license(license_key, machine_id: machine_id)
puts result.success? ? "✅ Activated on #{machine_id}" : "❌ #{result.error_message}"
```

### 📋 Core Methods Overview

| Method | Purpose | Returns | Use Case |
|--------|---------|---------|----------|
| `validate_license` | Check if license is valid | `LicenseValidationResult` | Regular license checking |
| `activate_license` | Activate license on machine | `LicenseValidationResult` | First-time setup |
| `enforce_license!` | Validate and exit if invalid | Nothing (exits on failure) | Application protection |

### Method 1: License Validation

Check if a license is valid without activating it:

```ruby
result = SourceLicenseSDK.validate_license

if result.valid?
  puts "License is valid!"
  puts "Expires at: #{result.expires_at}" if result.expires_at
else
  puts "License validation failed: #{result.error_message}"
end
```

### Method 2: License Activation

Activate a license on the current machine:

```ruby
# Generate machine ID for activation
machine_id = SourceLicenseSDK::MachineIdentifier.generate

# Activate with explicit machine ID
result = SourceLicenseSDK.activate_license(license_key, machine_id: machine_id)

if result.success?
  puts "License activated successfully!"
  puts "Activations remaining: #{result.activations_remaining}"
else
  puts "Activation failed: #{result.error_message}"
end
```

### Method 3: License Enforcement

Automatically exit the application if license validation fails:

```ruby
# This will exit the program with code 1 if the license is invalid
SourceLicenseSDK.enforce_license!

# Your application code continues here only if license is valid
puts "Application starting with valid license..."
```

## Advanced Usage

### Custom Configuration

```ruby
SourceLicenseSDK.configure do |config|
  config.server_url = 'https://your-license-server.com'
  config.license_key = 'YOUR-LICENSE-KEY'
  config.machine_id = 'custom-machine-id'
  config.timeout = 30
  config.verify_ssl = true
  config.user_agent = 'MyApp/1.0.0'
end
```

### Manual Machine ID Generation

```ruby
# Generate a unique machine identifier
machine_id = SourceLicenseSDK::MachineIdentifier.generate
puts "Machine ID: #{machine_id}"

# Generate a machine fingerprint (more detailed)
fingerprint = SourceLicenseSDK::MachineIdentifier.generate_fingerprint
puts "Machine Fingerprint: #{fingerprint}"
```

### Error Handling

```ruby
begin
  result = SourceLicenseSDK.validate_license
  
  if result.valid?
    puts "License is valid"
  else
    puts "License invalid: #{result.error_message}"
  end
rescue SourceLicenseSDK::NetworkError => e
  puts "Network error: #{e.message} (Code: #{e.response_code})"
rescue SourceLicenseSDK::RateLimitError => e
  puts "Rate limited. Retry after #{e.retry_after} seconds"
rescue SourceLicenseSDK::ConfigurationError => e
  puts "Configuration error: #{e.message}"
end
```

### Working with Results

```ruby
result = SourceLicenseSDK.validate_license

# Check various result properties
puts "Valid: #{result.valid?}"
puts "Expires at: #{result.expires_at}"
puts "Rate limited: #{result.rate_limited?}"
puts "Rate limit remaining: #{result.rate_limit_remaining}"
puts "Error code: #{result.error_code}" if result.error_code

# Convert to hash
puts result.to_h
```

### Custom License Enforcement

```ruby
# Custom exit code and message
SourceLicenseSDK.enforce_license!(
  exit_code: 2,
  custom_message: "This software requires a valid license to run."
)

# Use specific license key and machine ID
SourceLicenseSDK.enforce_license!(
  'SPECIFIC-LICENSE-KEY',
  machine_id: 'specific-machine-id'
)
```

## Integration Examples

### Ruby on Rails Application

```ruby
# config/initializers/source_license.rb
SourceLicenseSDK.setup(
  server_url: Rails.application.credentials.license_server_url,
  license_key: Rails.application.credentials.license_key
)

# In your application controller or concern
class ApplicationController < ActionController::Base
  before_action :validate_license

  private

  def validate_license
    result = SourceLicenseSDK.validate_license
    
    unless result.valid?
      render json: { error: 'Invalid license' }, status: :forbidden
    end
  end
end
```

### Command Line Tool

```ruby
#!/usr/bin/env ruby
require 'source_license_sdk'

# Setup license checking
SourceLicenseSDK.setup(
  server_url: 'https://license.mycompany.com',
  license_key: ARGV[0] || ENV['LICENSE_KEY']
)

# Enforce license before running
SourceLicenseSDK.enforce_license!(
  custom_message: "Please provide a valid license key to use this tool."
)

# Your application logic here
puts "Tool is running with valid license!"
```

### Desktop Application

```ruby
require 'source_license_sdk'

class MyApplication
  def initialize
    setup_licensing
  end

  private

  def setup_licensing
    SourceLicenseSDK.setup(
      server_url: 'https://licensing.myapp.com',
      license_key: load_license_key,
      auto_generate_machine_id: true
    )

    # Try to activate license if not already done
    activate_license_if_needed
    
    # Validate license on startup
    validate_license!
  end

  def load_license_key
    # Load from config file, registry, etc.
    File.read('license.key').strip
  rescue
    nil
  end

  def activate_license_if_needed
    result = SourceLicenseSDK.validate_license
    
    unless result.valid?
      puts "Activating license..."
      
      # Generate machine ID for activation
      machine_id = SourceLicenseSDK::MachineIdentifier.generate
      license_key = load_license_key
      
      activation_result = SourceLicenseSDK.activate_license(license_key, machine_id: machine_id)
      
      unless activation_result.success?
        puts "Failed to activate license: #{activation_result.error_message}"
        exit 1
      end
    end
  end

  def validate_license!
    SourceLicenseSDK.enforce_license!(
      custom_message: "This application requires a valid license."
    )
  end
end
```

## 🛠️ Troubleshooting & Common Issues

### Quick Diagnostics
Test your setup with this diagnostic snippet:

```ruby
require 'source_license_sdk'

puts "🔍 Source-License SDK Diagnostics"
puts "=================================="

# Test configuration
begin
  SourceLicenseSDK.setup(
    server_url: 'http://localhost:4567',
    license_key: 'VB6K-FSEY-VYWT-HTRJ'
  )
  puts "✅ Configuration: OK"
rescue => e
  puts "❌ Configuration Error: #{e.message}"
end

# Test machine ID generation
begin
  machine_id = SourceLicenseSDK::MachineIdentifier.generate
  puts "✅ Machine ID: #{machine_id}"
rescue => e
  puts "❌ Machine ID Error: #{e.message}"
end

# Test server connectivity
begin
  result = SourceLicenseSDK.validate_license
  puts "✅ Server Connection: OK"
  puts "📊 License Status: #{result.valid? ? 'Valid' : 'Invalid'}"
rescue SourceLicenseSDK::NetworkError => e
  puts "❌ Network Error: #{e.message}"
rescue => e
  puts "❌ Unexpected Error: #{e.message}"
end
```

### Common Problems & Solutions

#### Problem: "Failed to open TCP connection"
```ruby
# ❌ Error: Connection refused
# ✅ Solution: Check your server URL and ensure the server is running

SourceLicenseSDK.setup(
  server_url: 'https://your-actual-domain.com',  # Not localhost in production
  license_key: 'YOUR-KEY'
)
```

#### Problem: "License key is required"
```ruby
# ❌ This will fail
result = SourceLicenseSDK.validate_license(nil)

# ✅ Always provide a license key
SourceLicenseSDK.setup(license_key: 'YOUR-ACTUAL-LICENSE-KEY')
result = SourceLicenseSDK.validate_license
```

#### Problem: "Machine ID is required for activation"
```ruby
# ❌ This might fail
SourceLicenseSDK.setup(auto_generate_machine_id: false)
result = SourceLicenseSDK.activate_license

# ✅ Either enable auto-generation or provide manual ID
SourceLicenseSDK.setup(
  license_key: 'YOUR-KEY',
  machine_id: 'MY-SERVER-001'  # Manual ID
)
# OR
SourceLicenseSDK.setup(
  license_key: 'YOUR-KEY',
  auto_generate_machine_id: true  # Auto-generate (default)
)
```

#### Problem: Rate limiting
```ruby
# Handle rate limits gracefully
begin
  result = SourceLicenseSDK.validate_license
rescue SourceLicenseSDK::RateLimitError => e
  puts "Rate limited. Waiting #{e.retry_after} seconds..."
  sleep(e.retry_after)
  retry  # Try again after waiting
end
```

### 🧪 Testing Your Integration

#### Test Script Template
Save this as `test_license.rb` to verify your setup:

```ruby
#!/usr/bin/env ruby
require 'source_license_sdk'

# Replace these with your actual values
SERVER_URL = 'http://localhost:4567'
LICENSE_KEY = 'VB6K-FSEY-VYWT-HTRJ'

puts "🧪 Testing Source-License Integration"
puts "====================================="

# Setup
SourceLicenseSDK.setup(
  server_url: SERVER_URL,
  license_key: LICENSE_KEY
)

# Test 1: Basic validation
puts "\n1️⃣  Testing license validation..."
result = SourceLicenseSDK.validate_license
if result.valid?
  puts "✅ License is valid"
  puts "   Expires: #{result.expires_at || 'Never'}"
else
  puts "❌ License invalid: #{result.error_message}"
end

# Test 2: Activation (if needed)
puts "\n2️⃣  Testing license activation..."
activation_result = SourceLicenseSDK.activate_license
if activation_result.success?
  puts "✅ Activation successful"
  puts "   Remaining: #{activation_result.activations_remaining}"
else
  puts "ℹ️  Activation result: #{activation_result.error_message}"
end

# Test 3: Machine ID
puts "\n3️⃣  Testing machine identification..."
machine_id = SourceLicenseSDK::MachineIdentifier.generate
puts "🖥️  Machine ID: #{machine_id}"

puts "\n🎉 Integration test complete!"
```

Run it with: `ruby test_license.rb`

## Error Types

The SDK defines several exception types for different error scenarios:

- `SourceLicenseSDK::ConfigurationError` - Invalid SDK configuration
- `SourceLicenseSDK::NetworkError` - HTTP/network related errors  
- `SourceLicenseSDK::LicenseError` - General license validation errors
- `SourceLicenseSDK::RateLimitError` - API rate limiting errors
- `SourceLicenseSDK::LicenseNotFoundError` - License not found
- `SourceLicenseSDK::LicenseExpiredError` - License has expired
- `SourceLicenseSDK::ActivationError` - License activation errors
- `SourceLicenseSDK::MachineError` - Machine identification errors

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `server_url` | String | nil | Source-License server URL (required) |
| `license_key` | String | nil | License key to validate/activate |
| `machine_id` | String | nil | Unique machine identifier |
| `auto_generate_machine_id` | Boolean | true | Auto-generate machine ID if not provided |
| `timeout` | Integer | 30 | HTTP request timeout in seconds |
| `user_agent` | String | "SourceLicenseSDK/VERSION" | HTTP User-Agent header |
| `verify_ssl` | Boolean | true | Verify SSL certificates |

## Development

After checking out the repo, run:

```bash
bundle install
```

To build and install the gem locally:

```bash
gem build source_license_sdk.gemspec
gem install source_license_sdk-*.gem
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This gem is available as open source under the terms of the [GPL-3.0 License](LICENSE).

## Support

For support with this SDK and the Source-License platform, join our Discord community:

**🎮 Discord Server:** [discord.gg/j6v99ZPkrQ](https://discord.gg/j6v99ZPkrQ)

**💬 SDK Support Channel:** [#source-license-support](https://discord.com/channels/1419376086390800474/1419385647394984007)

Our community and developers are active on Discord to help with:
- SDK integration questions
- Troubleshooting license issues  
- Best practices and implementation guidance
- Feature requests and feedback

For urgent issues or enterprise support, please contact your license provider directly.
