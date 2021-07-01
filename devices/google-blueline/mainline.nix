{ config, lib, pkgs, ... }:

lib.mkIf (config.mobile.boot.stage-1.kernel.provenance == "mainline")
{
  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel-mainline { };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware-mainline {
    vendor-firmware-files = pkgs.callPackage ./firmware-vendor { };
  };
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];
}
