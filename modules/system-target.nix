{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.mobile.system;
  inherit (config.nixpkgs) localSystem;

  # The platform selected by the configuration
  selectedPlatform = lib.systems.elaborate cfg.system;
in
{
  options.mobile = {
    system.system = mkOption {
      # Known supported target types for Mobile NixOS
      type = types.enum [
        "aarch64-linux"
        "armv7l-linux"
        "x86_64-linux"
        "i686-linux"
      ];
      description = ''
        Defines the kind of target architecture system the device is.

        This will automagically setup cross-compilation where possible.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = (cfg.system == "i686-linux" && pkgs.targetPlatform.system == "x86_64-linux") || pkgs.targetPlatform.system == cfg.system;
        message = "pkgs.targetPlatform.system expected to be `${cfg.system}`, is `${pkgs.targetPlatform.system}`";
      }
    ];

    nixpkgs.crossSystem = lib.mkIf
      (
        let
          # i686 on x86_64 can be built "natively", see pkgsi686.
          # None of the other combinations can be mixed.
          result = !(selectedPlatform.system == "i686-linux" && localSystem.system == "x86_64-linux")
            && selectedPlatform.system != localSystem.system
          ;
        in
        builtins.trace
        "Building with crossSystem?: [selected: ${selectedPlatform.system}] on [local: ${localSystem.system}] → ${if result then "using crossSystem" else "building natively"}."
        result
      )
      (
        builtins.trace
        "    crossSystem: config: ${selectedPlatform.config}"
        selectedPlatform
      )
    ;

    # i686 on x86_64 can be built "natively", see pkgsi686.
    nixpkgs.system = lib.mkIf (selectedPlatform.system == "i686-linux") "i686-linux";
  };
}
