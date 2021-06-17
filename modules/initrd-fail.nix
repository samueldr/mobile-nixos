{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.mobile.boot.stage-1.fail;
in
{
  options.mobile = {
    boot.stage-1.fail = {
      reboot = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Reboots the device after a delay on failure.
        '';
      };
      delay = mkOption {
        type = types.int;
        default = 10;
        description = ''
          Duration (in seconds) before a reboot on failure.
        '';
      };
    };
  };
}
