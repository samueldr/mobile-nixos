{ config, lib, pkgs, ... }:

let
  inherit (lib.strings) makeBinPath;

  app = pkgs.callPackage ./app {};
  hello-gui = pkgs.mobile-nixos.stage-1.script-loader.wrap {
    name = "hello-gui";
    applet = "${app}/libexec/app.mrb";
    env = {
      PATH = "${makeBinPath (with pkgs;[
        systemd     # journalctl
        glibc       # iconv
        utillinux   # lsblk
        input-utils # lsinput
      ])}:$PATH";
    };
  };

  tmpfsConf = {
    device = "tmpfs";
    fsType = "tmpfs";
    neededForBoot = true;
  };

  # Only enable `adb` if we know how to.
  # FIXME: relies on implementation details. Poor separation of concerns.
  enableADB = 
  let
    value =
      config.mobile.usb.mode == "android_usb" ||
      (config.mobile.usb.mode == "gadgetfs" && config.mobile.usb.gadgetfs.functions ? adb)
    ;
  in
    if value then value else
    builtins.trace "warning: unable to enable ADB for this device." value
  ;
in
{
  imports = [
    ./workaround-v4l_id-hang.nix
  ];

  environment.systemPackages = with pkgs; [
    hello-gui
    input-utils
  ];

  # Make the system rootfs different enough that mixing stage-1 and stage-2
  # will fail and not have weird unexpected behaviours.
  mobile.generatedFilesystems = {
    rootfs = lib.mkDefault {
      label = lib.mkForce "MOBILE_HELLO";
      id    = lib.mkForce "12345678-1324-1234-0000-D00D00000001";
    };
  };

  fileSystems = {
    "/" = lib.mkDefault {
      autoResize = lib.mkForce false;
    };
    # Nothing is saved, except for the nix store being rehydrated.
    "/tmp" = tmpfsConf;
    "/var/log" = tmpfsConf;
    "/home" = tmpfsConf;
  };
 
  mobile.boot.stage-1.bootConfig = {
    # This will be useful for debugging boot issues over serial in the default
    # configuration.
    log.level = "DEBUG";
  };

  # Ensure hello-gui isn't trampled over by the TTY
  systemd.services."getty@tty1" = {
    enable = false;
  };
  systemd.services.hello-gui = {
    description = "GUI for the hello example of Mobile NixOS";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      SyslogIdentifier = "hello-gui";
      ExecStart = ''
        ${hello-gui}/bin/hello-gui
      '';
    };
  };

  mobile.adbd.enable = lib.mkDefault enableADB;

  boot.postBootCommands = lib.mkOrder (-1) ''
    brightness=10
    echo "Setting brightness to $brightness"
    if [ -e /sys/class/backlight/backlight/brightness ]; then
      echo $(($(cat /sys/class/backlight/backlight/max_brightness) * brightness / 100)) > /sys/class/backlight/backlight/brightness
    elif [ -e /sys/class/leds/lcd-backlight/max_brightness ]; then
      echo $(($(cat /sys/class/leds/lcd-backlight/max_brightness)  * brightness / 100)) > /sys/class/leds/lcd-backlight/brightness
    elif [ -e /sys/class/leds/lcd-backlight/brightness ]; then
      # Assumes max brightness is 100... probably wrong, but good enough, eh.
      echo $brightness > /sys/class/leds/lcd-backlight/brightness
    fi
  '';

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkForce false;
  };

  services.mingetty.autologinUser = "nixos";

  # The LVGUI interface can be used with volume keys for selecting
  # and power to activate an option.
  # Without this, logind just powers off :).
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

  system.build = {
    app-simulator = app.simulator;
  };

  # Override stage-0 support for this example app.
  # It's only noise, and the current stage-0 is not able to boot anything else
  # than a system it was built for anyway.
  mobile.quirks.supportsStage-0 = lib.mkForce false;
}
