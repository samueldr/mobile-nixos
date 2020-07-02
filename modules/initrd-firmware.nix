{ pkgs, lib, config, ... }:

let
  inherit (lib) types;
  inherit (config.mobile.boot.stage-1) firmware;
in
{
  options = {
    mobile.boot.stage-1.firmware = lib.mkOption {
      type = types.listOf types.package;
      default = [];
      description = ''
        List of packages containing firmware files to be included in the
        stage-1 for the device.
      '';
      apply = list: pkgs.buildEnv {
        name = "firmware";
        paths = list;
        pathsToLink = [ "/lib/firmware" ];
        ignoreCollisions = true;
      };
    };
  };
  config = {
    mobile.boot.stage-1.contents = [
      {
        suffix = "/lib/firmware";
        object = firmware;
        symlink = "/lib/firmware";
      }
    ];
  };
}
