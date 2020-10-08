class Tasks::SwitchRoot < SingletonTask
  # Relative to root.
  DEFAULT_SYSTEM_LINK = "/nix/var/nix/profiles/system"

  # Where the system will be mounted.
  SYSTEM_MOUNT_POINT = "/mnt"

  def initialize()
    add_dependency(:Target, :SwitchRoot)
    @target = SYSTEM_MOUNT_POINT
  end

  # Creates the generation selection list.
  def generate_selection()
    FileUtils.mkdir_p("/run/boot/")
    base = File.join(SYSTEM_MOUNT_POINT, DEFAULT_SYSTEM_LINK)
    selection = [
      base,
      *(Dir.glob(base + "-*").sort do |a, b|
        File.lstat(a).mtime <=> File.lstat(b).mtime
      end.reverse)
    ].map do |path|
      if path == base then
        {
          id: "$default",
          name: "Mobile NixOS - Default",
        }
      else
        date = File.lstat(path).mtime.strftime("%F")
        version_file = File.join(path, "nixos-version")
        version =
          if File.exist?(version_file)
            File.read(version_file)
          else
            nil
          end
        num = path.split("-")[-2]
        details = [
          date,
          version,
        ].compact.join(" - ")

        name = "Mobile NixOS ##{num} (#{details})"

        # This is the path we want to switch_root into.
        path = File.readlink(path)

        {
          id: path,
          name: name,
        }
      end
    end

    File.write("/run/boot/selection.json", selection.to_json)
  end

  # Boot the default generation.
  # This does either of:
  #  * Booting the default system link.
  #  * Find the generation store path that needs to be rehydrated.
  #
  # This is *always* a sane default to fallback on.
  def default_generation()
    # The default generation
    if File.symlink?(File.join(@target, DEFAULT_SYSTEM_LINK))
      return DEFAULT_SYSTEM_LINK
    end

    # Otherwise, we need to re-hydrate a system!
    registration = File.join(@target, "nix-path-registration")
    if File.exist?(registration)
      path = File.read(registration)
        .split("\n")
        .grep(%r{^/nix/store/[a-z0-9]+-nixos-system-})
        .first
      return path if path
    end

    System.failure("init_not_found", "Could not find init path for stage-2", color: "FF00FF")
  end

  # May pause the boot to allow the user to select a generation.
  def selected_generation()
    if false
      generate_selection()
      # FIXME: In the future, boot GUIs will be launched async, before this
      # task is ran.
      System.run(LOADER, "/applets/boot-selection.mrb")
      generation = File.read("/run/boot/choice")
      # Why "$default" rather than passing a path?
      # Because there may be no generations folder. It's easier to cheat and
      # use "$default" and rely on the existing default "maybe rehydrate"
      # codepath.
      if generation == "$default"
        default_generation()
      else
        generation
      end
    else
      default_generation()
    end
  end

  def boot_as_recovery_wants_recovery()
    # "Boot as recovery" systems do not have a discrete recovery partition.
    # For those systems, when `[s_]kip_initramfs` is in the kernel cmdline, we
    # know the intent is to boot the normal system.
    # Is a "boot as recovery" device, and Is `[s_]kip_initramfs` missing?
    Configuration["device"]["boot_as_recovery"] and
      !File.read("/proc/cmdline").split(/\s+/).grep(/[s_]kip_initramfs/).any?
  end

  def is_recovery()
    # Check in /etc/boot/config for `is_recovery`, it's assumed to be set, and
    # true, for recovery.img.
    Configuration["is_recovery"] or
      boot_as_recovery_wants_recovery
  end

  def is_boot_interrupted()
    keys = [
      "KEY_VOLUMEUP",
      "KEY_VOLUMEDOWN",
      "KEY_LEFTCTRL",
      "KEY_RIGHTCTRL",
      "KEY_LEFTSHIFT",
      "KEY_RIGHTSHIFT",
      "KEY_ESC", # QEMU doesn't pass through CTRL and SHIFT as expected here...
    ]

    # Do *not* use System.run as it would fail the boot on return value != 0
    system(LOADER, "/applets/key-held.mrb", *keys)

    # It returns `0` on key being held.
    $?.exitstatus == 0
  end

  # Checks if the user wants to select a generation.
  def user_wants_selection()
    [
      # Booted a recovery partition.
      is_recovery,
      # Or signaling the boot selection menu should be shown.
      is_boot_interrupted,
    ].any?
  end

  def run()
    init = "#{selected_generation}/init"

    # This is the traditional way we printed the init path.
    # This is still helpful to take vertical real estate when visually looking
    # through the log.
    log("")
    log("***")
    log("")
    log("Switching root to #{init}")
    log("")
    log("***")
    log("")

    [
      "/proc",
      "/sys",
      "/dev",
      "/run",
    ].each do |mount_point|
      new_location = File.join(@target, mount_point)
      FileUtils.mkdir_p(new_location)
      System.run("mount", "--move", mount_point, new_location)
    end

    switch_root = System.which("switch_root")
    System.exec({}, switch_root, @target, init)
  end
end
