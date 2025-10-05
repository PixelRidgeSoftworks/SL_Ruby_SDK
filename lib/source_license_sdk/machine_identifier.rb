# frozen_string_literal: true

require 'digest'
require 'socket'

# Generates unique machine identifiers for license activation
class SourceLicenseSDK::MachineIdentifier
  class << self
    # Generate a unique machine identifier
    def generate
      components = []

      # Get hostname
      components << hostname

      # Get MAC addresses
      components.concat(mac_addresses)

      # Get CPU info if available
      components << cpu_info if cpu_info

      # Get motherboard info if available
      components << motherboard_info if motherboard_info

      # Get disk serial if available
      components << disk_serial if disk_serial

      # Create hash from all components
      raw_id = components.compact.join('|')
      Digest::SHA256.hexdigest(raw_id)[0..31] # First 32 characters
    end

    # Generate machine fingerprint (more detailed than machine ID)
    def generate_fingerprint
      components = []

      # Basic system info
      components << hostname
      components << ruby_version
      components << platform

      # Network info
      components.concat(mac_addresses)
      components << local_ip

      # Hardware info
      components << cpu_info if cpu_info
      components << memory_info if memory_info
      components << disk_info if disk_info

      # Environment info
      components << environment_hash

      raw_fingerprint = components.compact.join('|')
      Digest::SHA256.hexdigest(raw_fingerprint)
    end

    private

    def hostname
      Socket.gethostname
    rescue StandardError
      'unknown-host'
    end

    def mac_addresses
      addresses = []

      case RUBY_PLATFORM
      when /darwin/i
        # macOS
        output = `ifconfig 2>/dev/null`
        addresses = output.scan(/ether ([a-f0-9:]{17})/i).flatten
      when /linux/i
        # Linux
        output = `ip link show 2>/dev/null || ifconfig 2>/dev/null`
        addresses = output.scan(/(?:ether|HWaddr)\s+([a-f0-9:]{17})/i).flatten
      when /mswin|mingw|cygwin/i
        # Windows
        output = `getmac /fo csv /nh 2>nul`
        addresses = output.scan(/"([A-F0-9-]{17})"/i).flatten.map { |addr| addr.tr('-', ':').downcase }
      end

      # Filter out virtual/invalid addresses
      addresses.select { |addr| addr && !addr.start_with?('00:00:00') && addr != '02:00:00:00:00:00' }
    rescue StandardError
      []
    end

    def cpu_info
      case RUBY_PLATFORM
      when /darwin/i
        `sysctl -n machdep.cpu.brand_string 2>/dev/null`.strip
      when /linux/i
        info = `cat /proc/cpuinfo 2>/dev/null | grep "model name" | head -1`.strip
        info.split(':').last&.strip if info.include?(':')
      when /mswin|mingw|cygwin/i
        `wmic cpu get name /value 2>nul | findstr "Name="`.strip.split('=').last
      end
    rescue StandardError
      nil
    end

    def motherboard_info
      case RUBY_PLATFORM
      when /darwin/i
        `system_profiler SPHardwareDataType 2>/dev/null | grep "Serial Number"`.strip
      when /linux/i
        `sudo dmidecode -s baseboard-serial-number 2>/dev/null`.strip
      when /mswin|mingw|cygwin/i
        `wmic baseboard get serialnumber /value 2>nul | findstr "SerialNumber="`.strip.split('=').last
      end
    rescue StandardError
      nil
    end

    def disk_serial
      case RUBY_PLATFORM
      when /darwin/i
        `diskutil info / 2>/dev/null | grep "Volume UUID"`.strip.split(':').last&.strip
      when /linux/i
        `lsblk -dno SERIAL 2>/dev/null | head -1`.strip
      when /mswin|mingw|cygwin/i
        `wmic diskdrive get serialnumber /value 2>nul | findstr "SerialNumber="`.strip.split('=').last
      end
    rescue StandardError
      nil
    end

    def ruby_version
      RUBY_VERSION
    end

    def platform
      RUBY_PLATFORM
    end

    def local_ip
      # Get local IP by connecting to a remote address (doesn't actually send data)
      Socket.ip_address_list.find(&:ipv4_private?)&.ip_address
    rescue StandardError
      '127.0.0.1'
    end

    def memory_info
      case RUBY_PLATFORM
      when /darwin/i
        `sysctl -n hw.memsize 2>/dev/null`.strip
      when /linux/i
        `cat /proc/meminfo 2>/dev/null | grep MemTotal`.strip.split.last
      when /mswin|mingw|cygwin/i
        output = `wmic computersystem get TotalPhysicalMemory /value 2>nul | findstr "TotalPhysicalMemory="`
        output.strip.split('=').last
      end
    rescue StandardError
      nil
    end

    def disk_info
      case RUBY_PLATFORM
      when /darwin/i, /linux/i
        `df -h / 2>/dev/null | tail -1`.strip.split.first
      when /mswin|mingw|cygwin/i
        `wmic logicaldisk get size,caption /value 2>nul | findstr "Size=" | head -1`.strip.split('=').last
      end
    rescue StandardError
      nil
    end

    def environment_hash
      # Hash of relevant environment variables (non-sensitive)
      env_vars = %w[HOME USER USERNAME PATH SHELL]
      env_data = env_vars.map { |var| "#{var}=#{ENV.fetch(var, nil)}" }.join('|')
      Digest::SHA256.hexdigest(env_data)[0..15] # First 16 characters
    rescue StandardError
      'unknown-env'
    end
  end
end
