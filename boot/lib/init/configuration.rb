# Handles lazy-loading the configuration, and giving a value for a given key.
module Configuration
  def self.[](key)
    @configuration ||=
      if File.exist?("/etc/boot/config")
        JSON.parse(File.read("/etc/boot/config"))
      else
        {}
      end
    @configuration[key]
  end
end
