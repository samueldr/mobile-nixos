{ config, pkgs, lib, utils, ... }:

let
  inherit (pkgs)
    busybox
    makeInitrd
    mkExtraUtils
    runCommandNoCC
    udev
    writeText
  ;
  inherit (lib)
    concatMap
    concatStringsSep
    filter
    flatten
    getBin
    mapAttrsToList
    mkIf
    mkOption
    optionalString
    optionals
    types
  ;
  inherit (builtins)
    listToAttrs
    toJSON
  ;

  JSONValue = with lib.types; let
    valueType = nullOr (oneOf [
      bool
      int
      float
      str
      (lazyAttrsOf valueType)
      (listOf valueType)
    ]) // {
      description = "JSON value";
      emptyValue.value = {};
    };
  in valueType;

  inherit (config.mobile.boot.stage-1) earlyInitScripts;

  # TODO: define as an option
  withStrace = false;

  device_config = config.mobile.device;
  device_name = device_config.name;

  stage-1 = config.mobile.boot.stage-1;

  mobile-nixos-init = pkgs.callPackage ../boot/init {
    inherit (config.mobile.boot.stage-1) tasks;
  };

  initWrapper = pkgs.writeScript "init-wrapper" ''
    #!${extraUtils}/bin/sh

    echo
    echo "***************************************"
    echo "* Mobile NixOS stage-${toString config.mobile.boot.stage-1.stage} script wrapper *"
    echo "***************************************"
    echo

    ${earlyInitScripts}
    export LD_LIBRARY_PATH="${extraUtils}/lib"

    echo
    echo "***************************************"
    echo "* Continuing with stage-${toString config.mobile.boot.stage-1.stage}...          *"
    echo "***************************************"
    echo

    exec ${optionalString withStrace "${extraUtils}/bin/strace -f"} \
      /loader /init.mrb
  '';

  bootConfigFile = writeText "${device_name}-boot-config" (toJSON config.mobile.boot.stage-1.bootConfig);

  contents =
    (optionals (stage-1 ? contents) (flatten stage-1.contents))
    ++ [
      # Populate /bin/sh to stay POSIXLY compliant.
      { suffix="/bin/sh"; object = extraUtils; symlink = "/bin/sh"; }

      # The mostly device-specific configuration for the bootloader.
      { object = bootConfigFile; symlink = "/etc/boot/config"; }

      # FIXME: udev/udevRules module.
      { object = udevRules; symlink = "/etc/udev/rules.d"; }

      # Init components
      { suffix="/bin/loader"; object = extraUtils; symlink = "/loader"; }
      { object = initWrapper; symlink = "/init"; }
      { suffix="/libexec/init.mrb"; object = mobile-nixos-init; symlink = "/init.mrb"; }
    ]
  ;

  # The initrd only has to mount `/` or any FS marked as necessary for
  # booting (such as the FS containing `/nix/store`, or an FS needed for
  # mounting `/`, like `/` on a loopback).
  bootFileSystems' = filter utils.fsNeededForBoot config.system.build.fileSystems;
  # Converts from list of attrsets, to an attrset indexed by mountPoint.
  bootFileSystems = listToAttrs (map (item: { name = item.mountPoint; value = item; }) bootFileSystems');

  # These 00-env rules are used both by udev to set the environment, and by
  # our bespoke init. This makes it a one-stop-shop for preparing the
  # init environment.
  envRules = writeText "00-env.rules" (
    concatStringsSep "\n"
    (mapAttrsToList (k: v: ''ENV{${k}}="${v}"'') config.mobile.boot.stage-1.environment)
  );

  extraUdevRules = writeText "99-extra.rules" config.mobile.boot.stage-1.extraUdevRules;

  udevRules = runCommandNoCC "udev-rules" {
    allowedReferences = [ extraUtils ];
    preferLocalBuild = true;
  } ''
    mkdir -p $out

    cp -v ${envRules} $out/00-env.rules
    cp -v ${udev}/lib/udev/rules.d/60-cdrom_id.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-input-id.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-persistent-input.rules $out/
    cp -v ${udev}/lib/udev/rules.d/60-persistent-storage.rules $out/
    cp -v ${udev}/lib/udev/rules.d/70-touchpad.rules $out/
    cp -v ${udev}/lib/udev/rules.d/80-drivers.rules $out/
    cp -v ${pkgs.lvm2}/lib/udev/rules.d/*.rules $out/
    cp -v ${extraUdevRules} $out/99-extra.rules

    for i in $out/*.rules; do
        substituteInPlace $i \
          --replace ata_id ${extraUtils}/bin/ata_id \
          --replace scsi_id ${extraUtils}/bin/scsi_id \
          --replace cdrom_id ${extraUtils}/bin/cdrom_id \
          --replace ${pkgs.coreutils}/bin/basename ${extraUtils}/bin/basename \
          --replace ${pkgs.utillinux}/bin/blkid ${extraUtils}/bin/blkid \
          --replace ${getBin pkgs.lvm2}/bin ${extraUtils}/bin \
          --replace ${pkgs.mdadm}/sbin ${extraUtils}/sbin \
          --replace ${pkgs.bash}/bin/sh ${extraUtils}/bin/sh \
          --replace ${udev}/bin/udevadm ${extraUtils}/bin/udevadm
    done

    # Work around a bug in QEMU, which doesn't implement the "READ
    # DISC INFORMATION" SCSI command:
    #   https://bugzilla.redhat.com/show_bug.cgi?id=609049
    # As a result, `cdrom_id' doesn't print
    # ID_CDROM_MEDIA_TRACK_COUNT_DATA, which in turn prevents the
    # /dev/disk/by-label symlinks from being created.  We need these
    # in the NixOS installation CD, so use ID_CDROM_MEDIA in the
    # corresponding udev rules for now.  This was the behaviour in
    # udev <= 154.  See also
    #   http://www.spinics.net/lists/hotplug/msg03935.html
    substituteInPlace $out/60-persistent-storage.rules \
      --replace ID_CDROM_MEDIA_TRACK_COUNT_DATA ID_CDROM_MEDIA
  ''; # */

  extraUtils = mkExtraUtils {
    name = "${device_name}-extra-utils";
    packages = [
      busybox
    ]
    ++ optionals (stage-1 ? extraUtils) stage-1.extraUtils
    ++ [{
      package = runCommandNoCC "empty" {} "mkdir -p $out";
      extraCommand =
      let
        inherit (pkgs) udev;
      in
        ''
          # Copy udev.
          copy_bin_and_libs ${udev}/bin/udevadm
          for BIN in ${udev}/lib/udev/*_id; do
            copy_bin_and_libs $BIN
          done
          ln -sf udevadm $out/bin/systemd-udevd
        ''
      ;
    }]
    ++ [
      { package = pkgs.mobile-nixos.stage-1.script-loader; }
    ]
    ++ optionals withStrace [
      {
        # Remove libunwind, allows us to skip requiring libgcc_s
        package = pkgs.strace.overrideAttrs(old: { buildInputs = []; });
      }
    ]
    ;
  };

  initrd = makeInitrd {
    name = "initrd-${device_config.name}";
    inherit contents;

    compressor =  {
      # Default from <nixpkgs/pkgs/build-support/kernel/make-initrd.nix>
      gzip = "gzip -9n";

      # The `--check` option is required since the kernel's implementation is minimal.
      # `-e` trades CPU runtime at compression to find the best compression possible.
      xz = "xz -9 -e --check=crc32";
    }.${config.mobile.boot.stage-1.compression};
  };

  # ncdu -f result/initrd.ncdu
  initrd-meta = pkgs.runCommandNoCC "initrd-${device_config.name}-meta" {
    nativeBuildInputs = with pkgs.buildPackages; [
      ncdu
      cpio
      tree
    ];
  } ''
    mkdir initrd
    (
    cd initrd
    ${if config.mobile.boot.stage-1.compression == "gzip" then "gzip -cd ${initrd}/initrd"
      else if config.mobile.boot.stage-1.compression == "xz" then "xz -cd ${initrd}/initrd"
      else throw "Cannot decompress ${config.mobile.boot.stage-1.compression} for initrd-meta."
    } | cpio -i
    )

    mkdir -p $out
    ncdu -0x -o $out/initrd.ncdu ./initrd
    tree -a ./initrd > $out/tree
  '';
in
  {
    options = {
      mobile.boot.stage-1.stage = mkOption {
        type = types.enum [ 0 1 ];
        default = 1;
        description = ''
          Used with a "specialization" of the config to build the "stage-0"
          init which can kexec into another kernel+initrd found on the system.

          This serves as a replacement to a "proper" bootloader.
        '';
        internal = true;
      };
      mobile.boot.stage-1.compression = mkOption {
        type = types.enum [ "gzip" "xz" ];
        default = "gzip";
        description = ''
          The compression method for the stage-1 (initrd).

          This may be set as a default by some devices requiring specific
          compression methods. Most likely to work around size limitations.
        '';
      };
      mobile.boot.stage-1.tasks = mkOption {
        type = with types; listOf (either package path);
        default = [];
        internal = true;
        description = "
          Add tasks to the boot/init program.
          The build system for boot/init will `find -iname '*.rb'` the given paths.
        ";
      };
      mobile.boot.stage-1.bootConfig = mkOption {
        type = JSONValue;
        default = {};
        internal = true;
        description = ''
          The things being put in the JSON configuration file in stage-1.
        '';
      };
      mobile.boot.stage-1.crashToBootloader = mkOption {
        type = types.bool;
        default = false;
        description = ''
          When the stage-1 bootloader crashes, prefer rebooting directly to
          bootloader rather than panic by killing init.

          This may be preferrable for devices with direct serial access.

          Note that console ramoops requires the kernel to panic, this should
          be set to false if you rely on console ramoops to debug issues.
        '';
      };
      mobile.boot.stage-1.earlyInitScripts = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional shell commands to run before the actual init.

          Prefer writing a task. This should be used mainly to redirect logging,
          or do setup that is otherwise impossible in the init, like running it
          against strace.
        '';
        internal = true;
      };
      mobile.boot.stage-1.environment = mkOption {
        type = types.attrsOf types.str;
        description = ''
          Environment variables present for the whole stage-1.
          Keep this as minimal as needed.
        '';
        internal = true;
      };
      mobile.boot.stage-1.extraUdevRules = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional udev rules for stage-1.
        '';
        internal = true;
      };
    };

    config = {
      system.build.extraUtils = extraUtils;
      system.build.initrd = "${initrd}/initrd";
      system.build.initrd-meta = initrd-meta;

      system.build.initialRamdisk =
        if config.mobile.rootfs.shared.enabled
        then pkgs.runCommandNoCC "dummy" {} "touch $out"
        else initrd
      ;

      mobile.boot.stage-1.bootConfig = {
        inherit (config.mobile.boot.stage-1) stage;
        device = {
          inherit (device_config) name;
        };
        kernel = {
          inherit (config.mobile.boot.stage-1.kernel) modules;
        };

        # Literally transmit some nixos configurations.
        nixos = {
          boot.specialFileSystems = config.boot.specialFileSystems;
        };

        inherit bootFileSystems;

        boot = {
          inherit (config.mobile.boot.stage-1) fail crashToBootloader;
          inherit (config.mobile.boot.stage-1.shell) shellOnFail;
        };

        # Transmit all of the mobile NixOS HAL options.
        HAL = config.mobile.HAL;
      };
      mobile.boot.stage-1.environment = {
        LD_LIBRARY_PATH = "${extraUtils}/lib";
        PATH = "${extraUtils}/bin";
      };
    };
  }
