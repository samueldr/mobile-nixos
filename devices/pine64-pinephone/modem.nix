{ config, lib, pkgs, ... }:

# This, by default, boots the phone with the modem powered down.
# In addition, the systemd service does not, by default, start the modem.
{

  # Shut down the modem in early boot
  mobile.quirks.u-boot.additionalCommands = ''
    # Properly shut off EG25 by pulling up PWRKEY.
    gpio set 35
    sleep 1
    gpio clear 35
  '';

  # Ensure we have systemd tagging on the modem.
  # Probably is not needed.
  services.udev.extraRules =
    let
      path = "/devices/platform/soc/1c1b000.usb/*/net/wwan0";
    in ''
      ACTION=="add", DEVPATH=="${path}", TAG+="systemd"
      ACTION=="remove", DEVPATH=="${path}", TAG+="systemd"
    ''
  ;
  
  # This service, allows the user to start the modem using a systemd service.
  # In addition, the service status always reflects the current status of the
  # modem; whether it has been turned off or on using systemd or not.
  #
  # If you want it to be disabled by default on boot, use:
  #
  #     systemd.services.modem-control.wantedBy = lib.mkForce [ "sys-subsystem-net-devices-wwan0.device" ];
  #
  systemd.services =
    let
      dotDeviceName = "sys-subsystem-net-devices-wwan0.device";
    in {
    "modem-control" = {
      bindsTo = [ dotDeviceName ];
      wantedBy = [ dotDeviceName "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.writeShellScript "start-modem" ''
          echo 'Powering modem on...'
          echo 1 > /sys/class/modem-power/modem-power/device/powered
        '';

        ExecStop  = pkgs.writeShellScript "stop-modem" ''
          echo 'Powering modem off...'
          echo 0 > /sys/class/modem-power/modem-power/device/powered
        '';
      };
    };
  };
}
