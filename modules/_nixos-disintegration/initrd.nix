{ pkgs, lib, config, ... }:

let
  dummy = pkgs.runCommandNoCC "dummy" {} "touch $out";
in
{
  disabledModules = [
    "modules/tasks/encrypted-devices.nix"
    "modules/tasks/filesystems/zfs.nix"
  ];

  config = {
    # This isn't even used in our initrd...
    boot.supportedFilesystems = lib.mkOverride 10 [ ];
    boot.initrd.supportedFilesystems = lib.mkOverride 10 [];

    # And disable the initrd outright!
    boot.initrd.enable = false;
    system.build.initialRamdisk = dummy;
    system.build.initialRamdiskSecretAppender = dummy;
  };
}
