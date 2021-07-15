{ config, lib, pkgs, ... }:

let
  # Reduced set of firmware files, only for the touch panel.
  # This helps fix a broken touch panel firmware storage from testing mainline.
  firmware-stage-1 = pkgs.runCommandNoCC "google-blueline-firmware-stage-1" {} ''
    mkdir -p $out/lib/firmware/
    cp -vt $out/lib/firmware/ ${config.mobile.device.firmware}/lib/firmware/ftm5*.ftb
  '';
in

lib.mkIf (config.mobile.boot.stage-1.kernel.provenance == "vendor")
{
  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel-vendor { };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware-vendor { };
  mobile.boot.stage-1.firmware = [
    firmware-stage-1
  ];
}
