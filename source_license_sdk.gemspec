# frozen_string_literal: true

require_relative 'lib/source_license_sdk/version'

Gem::Specification.new do |spec|
  spec.name          = 'source_license_sdk'
  spec.version       = SourceLicenseSDK::VERSION
  spec.authors       = ['PixelRidge Softworks']
  spec.email         = ['support@pixelridgesoftworks.com']

  spec.summary       = 'Ruby SDK for Source-License platform'
  spec.description   = 'A Ruby gem for easy integration with Source-License platform for license ' \
                       'validation and activation'
  spec.homepage      = 'https://github.com/PixelRidgeSoftworks/Source-License'
  spec.license       = 'GPL-3.0-or-later'
  spec.required_ruby_version = '>= 3.4.4'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/PixelRidgeSoftworks/Source-License/tree/main/SL_Ruby_SDK'
  spec.metadata['changelog_uri'] = 'https://github.com/PixelRidgeSoftworks/Source-License/blob/main/SL_Ruby_SDK/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # Use cross-platform compatible file detection
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    README.md
    CHANGELOG.md
    LICENSE
    Gemfile
    Rakefile
    source_license_sdk.gemspec
  ]).select { |f| File.file?(f) }.reject { |f| f.match?(/SL_Ruby_SDK_Test/) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'digest', '~> 3.0'
  spec.add_dependency 'json', '~> 2.0'
  spec.add_dependency 'net-http', '~> 0.1'
end
