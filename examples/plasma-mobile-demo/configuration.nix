{ config, lib, pkgs, ... }:

let
  # This script will run *only once*, even if changed.
  # https://develop.kde.org/docs/plasma/scripting/#update-scripts
  # This will not work through userSetupScript, it seems that plasma mobile on
  # first initialization forcibly resets some of the configurations.
  # Running last (ZZZ) ensures it can do whatever initialization it needs to do.
  plamoInitialDefaults = pkgs.writeTextDir "share/plasma/shells/org.kde.plasma.phoneshell/contents/updates/ZZZ-Mobile-NixOS-initial-defaults.js" ''
    var allDesktops = desktops();
    for (i=0; i<allDesktops.length; i++) {
      d = allDesktops[i];
      d.wallpaperPlugin = "org.kde.image";
      d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
      d.writeConfig("Image", "file://${wallpaper}")
    }
  '';

  # Those configs are found in the file named as `--file`, with
  # `--group` being [like][these].
  userSetupScript = pkgs.writeScript "userInitialConfiguration" ''
    #!${pkgs.runtimeShell}
    ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 \
      --file kscreenlockerrc \
      --group Greeter \
      --group Wallpaper \
      --group org.kde.image \
      --group General \
      --key Image "file://${wallpaper}"
  '';

  # Why copy them all?
  # Because otherwise the wallpaper picker will default to /nix/store as a path
  # and this could get messy with the amazing amount of files there are in there.
  # Why copy only pngs?
  # Rendering of `svg` is hard! Not that it's costly in cpu time, but that the
  # rendering might not be as expected depending on what renders it.
  # The SVGs in that directory are used as an authoring format files, not files
  # to be used as they are. They need to be pre-rendered.
  wallpapers = pkgs.runCommandNoCC "wallpapers" {} ''
    mkdir -p $out/
    cp ${../../artwork/wallpapers}/*.png $out/
  '';

  wallpaper="${wallpapers}/mobile-nixos-19.09.png";

  # One-stop shop to customize the default username before building.
  defaultUserName = "alice";
in
{
  config = lib.mkMerge [
    # INSECURE STUFF FIRST
    # Users and hardcoded passwords.
    {
      # Forcibly set a password on users...
      # Note that a numeric password is currently required to unlock a session
      # with the plasma mobile shell :/
      users.users.${defaultUserName} = {
        isNormalUser = true;
        # Numeric pin makes it **possible** to input on the lockscreen.
        password = "1234";
        home = "/home/${defaultUserName}";
        extraGroups = [ "wheel" "networkmanager" "video" ];
        uid = 1000;
      };

      users.users.root.password  = "nixos";

      # FIXME: highly insecure!
      # FIXME: Figure out why this breaks...
      #services.openssh.extraConfig = "PermitEmptyPasswords yes";
    }

    # "Desktop" environment configuration
    {
      services.xserver = {
        enable = true;

        libinput.enable = true;
        videoDrivers = lib.mkDefault [ "modesetting" "fbdev" ];

        displayManager.sddm = {
          enable = true;
        };

        # Automatically login as defaultUserName.
        displayManager.autoLogin = {
          enable = true;
          user = defaultUserName;
        };

        displayManager.defaultSession = "plasma-mobile";

        desktopManager.plasma5 = {
          enable = true;
          mobile.enable = true;
        };
      };
      powerManagement.enable = true;
      hardware.pulseaudio.enable = true;

      # Force some initial configuration
      system.activationScripts.userInitialConfiguration = let
        homeDir = config.users.users.${defaultUserName}.home;
      in ''
        echo ":: Mobile NixOS initial configuration..."
        if [ ! -e ${homeDir}/.config ]; then
          echo "Assuming first boot!"
          echo "Creating home dir"
          mkdir -p ${homeDir}
          chown ${defaultUserName} ${homeDir}
          echo "Configuring things"
          ${pkgs.sudo}/bin/sudo -u "${defaultUserName}" "${userSetupScript}"
        else
          echo "Assuming any other boring normal boot..."
          echo "Doing nothing..."
        fi
      '';

      environment.systemPackages = [
        plamoInitialDefaults
      ];
    }

    # Networking, modem and misc.
    {
      networking.wireless.enable = false;
      networking.networkmanager.enable = true;

      # FIXME : configure usb rndis through networkmanager in the future.
      # Currently this relies on stage-1 having configured it.
      networking.networkmanager.unmanaged = [ "rndis0" "usb0" ];

      # Setup USB gadget networking in initrd...
      mobile.boot.stage-1.networking.enable = lib.mkDefault true;

      # Required for modem access
      users.users.${defaultUserName}.extraGroups = [ "dialout" ];
    }

    # Bluetooth
    {
      hardware.bluetooth.enable = true;
    }

    # SSH
    {
      # Start SSH by default...
      # Not a good idea given the fact it's insecure.
      services.openssh = {
        enable = true;
        permitRootLogin = "yes";
      };

      # Don't start it in stage-1 though.
      # (Currently doesn't quit on switch root)
      # mobile.boot.stage-1.ssh.enable = true;
    }

    # Default quirks
    {
      # Ensures this demo rootfs is useable for platforms requiring FBIOPAN_DISPLAY.
      mobile.quirks.fb-refresher.enable = true;

      # Okay, systemd-udev-settle times out... no idea why yet...
      # Though, it seems fine to simply disable it.
      # FIXME : figure out why systemd-udev-settle doesn't work.
      systemd.services.systemd-udev-settle.enable = false;

      # Force userdata for the target partition. It is assumed it will not
      # fit in the `system` partition.
      mobile.system.android.system_partition_destination = "userdata";
    }
  ];
}
