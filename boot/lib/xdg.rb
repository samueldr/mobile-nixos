# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# While we're making this for NixOS, we're still following the spec in the
# actual source. Any deviation will be elsewhere.
module XDG
  extend self

  def config_dirs()
    dirs = ENV["XDG_CONFIG_DIRS"]
    dirs ||= "/etc/xdg"
    dirs.split(":")
  end

  def data_dirs()
    dirs = ENV["XDG_DATA_DIRS"]
    dirs ||= "/usr/local/share/:/usr/share/"
    dirs.split(":")
  end
end
