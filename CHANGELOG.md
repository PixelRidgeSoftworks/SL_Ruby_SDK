# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-10-05

### Changed
- Updated gemspec to exclude SL_Ruby_SDK_Test directory from gem builds
- Test suite is now available in repository but not included in distributed gem

## [1.0.1] - 2025-10-05

### Fixed
- Improved test suite reliability and error handling
- Fixed nil license key validation test logic
- Fixed machine ID activation test edge cases
- Enhanced configuration state management in tests

### Added
- Comprehensive test script with 45 test cases covering all SDK functionality
- Better error handling for edge cases in license validation and activation
- Improved test coverage for network errors and rate limiting scenarios

## [1.0.0] - 2025-01-05

### Added
- Initial release of Source-License Ruby SDK
- License validation functionality (`SourceLicenseSDK.validate_license`)
- License activation functionality (`SourceLicenseSDK.activate_license`)  
- License enforcement functionality (`SourceLicenseSDK.enforce_license!`)
- Automatic machine identification for Windows, macOS, and Linux
- Cross-platform machine fingerprinting
- Rate limiting handling with retry information
- Comprehensive error handling and custom exception types
- Support for HTTPS communication with SSL verification
- Configurable timeouts and user agents
- Complete test suite with WebMock integration
- Detailed documentation with usage examples

### Features
- **3 Core Methods**: Simple validation, activation, and enforcement
- **Security**: Secure communication with Source-License API
- **Cross-Platform**: Works on all major operating systems
- **Error Handling**: Detailed error types and messages
- **Rate Limiting**: Built-in handling of API rate limits
- **Machine ID**: Automatic generation of unique machine identifiers
- **Flexibility**: Configurable for different deployment scenarios

### Dependencies
- Ruby >= 3.4.4
- net-http ~> 0.1
- json ~> 2.0
- digest ~> 3.0

### Development Dependencies
- rspec ~> 3.0
- webmock ~> 3.0
- rubocop ~> 1.0
- rake ~> 13.0
