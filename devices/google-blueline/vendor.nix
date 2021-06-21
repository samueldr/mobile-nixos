{ config, lib, pkgs, ... }:

lib.mkIf (config.mobile.boot.stage-1.kernel.provenance == "vendor")
{
  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel-vendor { };
  };
}
