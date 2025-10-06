# Source-License Ruby SDK Test Project

This project demonstrates the functionality of the Source-License Ruby SDK with various examples and a comprehensive test suite.

## Files Overview

- **`test_app.rb`** - Comprehensive test suite that demonstrates all SDK features
- **`simple_example.rb`** - Basic license validation example
- **`activation_example.rb`** - License activation demonstration  
- **`enforcement_example.rb`** - License enforcement example
- **`Gemfile`** - Project dependencies

## Setup

1. Make sure your Source-License server is running at `localhost:4567`
2. Install dependencies:
   ```bash
   bundle install
   ```

## Test Configuration

The examples use the following test configuration:
- **Server URL**: `http://localhost:4567`
- **License Key**: `PGP5-R8US-VH4G-Y2W9`

## Running Tests

### Full Test Suite
Run the comprehensive test suite that covers all SDK functionality:
```bash
ruby test_app.rb
```

### Interactive Mode  
Run the test app in interactive mode for manual testing:
```bash
ruby test_app.rb --interactive
```

### Individual Examples

**Simple Validation Example:**
```bash
ruby simple_example.rb
```

**License Activation Example:**
```bash
ruby activation_example.rb
```

**License Enforcement Example:**
```bash
ruby enforcement_example.rb
```

## SDK Features Demonstrated

### Method 1: License Validation
- Basic license validation without activation
- Check if license is valid for the current application
- Retrieve license information (expiration, token, etc.)

### Method 2: License Activation
- Activate license on a specific machine
- Generate unique machine identifiers
- Track activation count and remaining activations

### Method 3: License Enforcement
- Automatically exit application if license is invalid
- Customizable exit codes and messages
- Fail-safe licensing for production applications

## Additional Features

- **Machine Identification**: Automatic generation of unique machine IDs and fingerprints
- **Error Handling**: Comprehensive error types and graceful degradation
- **Rate Limiting**: Built-in handling of API rate limits
- **Configuration Options**: Flexible SDK configuration
- **Result Objects**: Rich result objects with detailed information

## Expected Test Results

When running with a valid license (`PGP5-R8US-VH4G-Y2W9`), you should see:

1. ✅ Machine identification working
2. ✅ License validation successful  
3. ✅ License activation working
4. ✅ Error handling for invalid inputs
5. ✅ License enforcement passing

## Troubleshooting

**Connection Issues:**
- Verify Source-License server is running at `localhost:4567`
- Check network connectivity
- Ensure no firewall is blocking the connection

**License Issues:**
- Verify the license key `PGP5-R8US-VH4G-Y2W9` exists in your Source-License instance
- Check that the license is active and not expired
- Ensure the product associated with the license allows the expected number of activations

**Gem Issues:**
- Run `bundle install` to ensure all dependencies are installed
- Verify the `source_license_sdk` gem is properly installed
- Check that you're running from the correct directory

## SDK Integration Guide

To integrate this SDK into your own Ruby application:

1. Add to your Gemfile:
   ```ruby
   gem 'source_license_sdk', '~> 1.0'
   ```

2. Basic setup in your application:
   ```ruby
   require 'source_license_sdk'
   
   SourceLicenseSDK.setup(
     server_url: 'https://your-license-server.com',
     license_key: 'YOUR-LICENSE-KEY'
   )
   ```

3. Choose your integration method:
   - **Validation**: `SourceLicenseSDK.validate_license`
   - **Activation**: `SourceLicenseSDK.activate_license`  
   - **Enforcement**: `SourceLicenseSDK.enforce_license!`

## Support

For issues with the SDK or Source-License platform, please refer to the main Source-License repository or contact your license provider.
