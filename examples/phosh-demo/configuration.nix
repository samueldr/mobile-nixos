{ config, lib, pkgs, ... }:

let
  terminal = pkgs.kgx.override { genericBranding = true; };

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
        extraGroups = [ "wheel" "networkmanager" "video" "feedbackd" ];
        uid = 1000;
      };

      users.users.root.password  = "nixos";

      # FIXME: highly insecure!
      # FIXME: Figure out why this breaks...
      #services.openssh.extraConfig = "PermitEmptyPasswords yes";
    }

    # "Desktop" environment configuration
    {
      powerManagement.enable = true;
      hardware.opengl.enable = true;

      systemd.defaultUnit = "graphical.target";
      systemd.services.phosh = {
        wantedBy = [ "graphical.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.phosh}/bin/phosh";
          User = 1000;
          PAMName = "login";
          WorkingDirectory = "~";

          TTYPath = "/dev/tty7";
          TTYReset = "yes";
          TTYVHangup = "yes";
          TTYVTDisallocate = "yes";

          StandardInput = "tty-fail";
          StandardOutput = "journal";
          StandardError = "journal";

          UtmpIdentifier = "tty7";
          UtmpMode = "user";

          Restart = "always";
        };
      };

      services.xserver.desktopManager.gnome3.enable = true;

      # Unpatched gnome-initial-setup is partially broken in small screens
      services.gnome3.gnome-initial-setup.enable = false;

      programs.phosh.enable = true;
      environment.systemPackages = [ terminal ];
      environment.gnome3.excludePackages = with pkgs.gnome3; [
        gnome-terminal
      ];

      environment.etc."machine-info".text = lib.mkDefault ''
        CHASSIS="handset"
      '';
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
