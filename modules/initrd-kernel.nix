{ config, lib, options, pkgs, ... }:

let

  inherit (lib)
    mergeEqualOption
    mkDefault
    mkIf
    mkOption
    types
  ;
  cfg = config.mobile.boot.stage-1.kernel;
  device_config = config.mobile.device;

  modulesClosure = pkgs.makeModulesClosure {
    kernel = cfg.package;
    allowMissing = true;
    rootModules = cfg.modules ++ cfg.additionalModules;
    firmware = cfg.firmwares;
  };

  inherit (config.mobile.quirks) supportsStage-0;
in
{
  # Note: These options are provided  *instead* of `boot.initrd.*`, as we are
  # not re-using the `initrd` options.
  options.mobile.boot.stage-1.kernel = {
    modular = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether the kernel is built with modules or not.
        This will enable modules closure generation and listing modules
        to bundle and load.
      '';
    };
    modules = mkOption {
      type = types.listOf types.str;
      default = [
      ];
      description = ''
        Module names to add to the closure.
        They will be modprobed.
      '';
    };
    additionalModules = mkOption {
      type = types.listOf types.str;
      default = [
      ];
      description = ''
        Module names to add to the closure.
        They will not be modprobed.
      '';
    };
    firmwares = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Firmwares to add to the closure.
      '';
    };
    # We cannot use `linuxPackagesFor` as older kernels cause eval-time assertions...
    # This is bad form, but is already in nixpkgs :(.
    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        Kernel to be used by the system-type to boot into the Mobile NixOS
        stage-1.

        This is not using a kernelPackages attrset, but a kernel derivation directly.
      '';
    };

    availableProvenances = mkOption {
      type = types.listOf types.str;
      default = [];
      internal = true;
      description = ''
        Devices implementation with multiple kernels to select from should list
        available provenances, and *handle switching kernel* and necessary options.
      '';
    };

    provenance = mkOption {
      type = types.enum cfg.availableProvenances;
      # This forces a "better" error message when unset.
      #
      # error: A definition for option `mobile.boot.stage-1.kernel.provenance' is not of type `one of "mainline", "vendor"'. Definition values:
      # vs.
      # error: The option `mobile.boot.stage-1.kernel.provenance' is used but not defined.
      #
      # The former being with a "wrong" default, we get the valid values.
      default = null;
      description = ''
        Some devices allow selecting different kernels.

        Generally this will allow selecting between vendor or mainline kernels.

        The default value depends on the device implementation. Some will choose
        the better kernel, some will force a user to select, when e.g. none of
        the options are markedly better.

        When required, and not set, the error message will list valid values.
      '';
    };
  };

  config.mobile.boot.stage-1 = (mkIf cfg.modular {
    firmware = [ modulesClosure ];
    contents = [
      { object = "${modulesClosure}/lib/modules"; symlink = "/lib/modules"; }
    ];
    kernel.modules = [
      # Basic always-needed kernel modules.
      "loop"

      # Filesystems
      "nls_cp437"
      "nls_iso8859-1"
      "fat"
      "vfat"

      "ext4"
      "crc32c"
    ];
  });

  config.boot.kernelPackages = mkDefault (
    if (supportsStage-0 && config.mobile.rootfs.shared.enabled) || cfg.package == null
    then let
      self = {
        # This must look legit enough so that NixOS thinks it's a kernel attrset.
        stdenv = pkgs.stdenv;
        # callPackage so that override / overrideAttrs exist.
        kernel = pkgs.callPackage (
          { runCommandNoCC, ... }: runCommandNoCC "dummy" { version = "99"; } "mkdir $out; touch $out/dummy"
        ) {};
        # Fake having `extend` available... probably dumb... but is it more
        # dumb than faking a kernelPackages package set for eval??
        extend = _: self;
      };
    in self
    else (pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor cfg.package))
  );

  config.system.boot.loader.kernelFile = mkIf (cfg.package != null && cfg.package ? file) (
    mkDefault cfg.package.file
  );

  # Disable kernel config checks as it's EXTREMELY nixpkgs-kernel centric.
  # We're duplicating that good work for the time being.
  config.system.requiredKernelConfig = lib.mkForce [];
}

