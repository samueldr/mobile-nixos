#
# mobile-nixos kernel builder
# ===========================
#
# The goal of this kernel builder is to cover most of the kernels with a
# simpler interface.
#
# Since many kernels will be of older vintages, not supported by NixOS'
# own kernel build infrastructure, this will live as a more limited builder,
# with the goal of building most kernels supported.
#
# It is also an experiments ground for a more ergonomic interface.
#

# This is the callPackage signature.
# These are dependencies for dependency injection.
{ stdenv
, lib
, path
, buildPackages

, writeTextFile
, writeShellScriptBin

, perl
, bc
, nettools
, openssl
, rsync
, gmp
, libmpc
, mpfr
, dtc
, dtbTool
, dtbTool-exynos
, ufdt-apply-overlay

, cpio
, elfutils
, libelf
, utillinux

, bison
, flex

# For menuconfig
, ncurses
, pkgconfig
, runtimeShell
}:

let
  # For now this is a no-op.
  modDirify = v: v;

  # Shortcuts
  inherit (lib) optionals optional optionalString;
  platform = stdenv.hostPlatform;

  maybeString = str: optionalString (str != null) str;
in

# This is the builder function signature.
{
# We have to be provided with a source
  src
# And a version
, version
, modDirVersion ? modDirify version

# Additionally, a config file is required.
, configfile

# Handling of QCDT dt.img
, isQcdt ? false
, qcdt_dtbs ? "arch/${platform.linuxArch}/boot/"

# Handling of Exynos dt.img
, isExynosDT ? false
, exynos_dtbs ? "arch/${platform.linuxArch}/boot/dts/*.dtb"
, exynos_platform ? "0x50a6"
, exynos_subtype  ? "0x217584da"

# Enable support for android-specific "Image.gz-dtb" appended images
, isImageGzDtb ? false

# Mark the kernel as compressed, assumes .gz
, isCompressed ? "gz"

# Enable build of dtbo.img
, dtboImg ? false

# Linux logo centering (as a boot logo)
, enableCenteredLinuxLogo ? true

# Linux logo replacement
, enableLinuxLogoReplacement ? true
, linuxLogo224PPMFile ? ./logo_linux_clut224.ppm

# Mainly to mask issues with newer compilers
, enableRemovingWerror ? false

# Older kernels don't know about gcc6+, and this is needed
, enableCompilerGcc6Quirk ? false

# Some kernels, mainly prior to 4.4, will rebuild the kernel from scratch when
# installing. Work around the issue by using only one make invocation.
, enableCombiningBuildAndInstallQuirk ? (builtins.compareVersions "4.4" version > 0)

# The usual mkDerivation option
, enableParallelBuilding ? true

# File name for the final kernel file
# Generally left null, a sane default is used.
, kernelFile ? null

# Usual stdenv arguments we are also setting.
# Use the ones given by the user for composition.
, nativeBuildInputs ? []
, patches ? []
, makeFlags ? []
, prePatch ? null
, postPatch ? null
, preInstall ? null
, postInstall ? null
, installTargets ? []

# Part of the usual NixOS kernel builder API
, installsFirmware ? true
, isModular ? true
, kernelPatches ? []

, ...
} @ inputArgs:

let
  # Path within <nixpkgs> to refer to the kernel build system's file.
  nixosKernelPath = path + "/pkgs/os-specific/linux/kernel";

  # Same installer as in <nixpkgs>, though they don't expose it :/.
  installkernel = writeTextFile {
    name = "installkernel";
    executable=true;
    text = ''
      #!${stdenv.shell} -e
      mkdir -p $4
      cp -av $2 $4
      cp -av $3 $4
    '';
  };

  # Inspired from #91991
  # https://github.com/NixOS/nixpkgs/pull/91991
  # (required for menuconfig)
  pkgconfig-helper = writeShellScriptBin "pkg-config" ''
    exec ${buildPackages.pkgconfig}/bin/${buildPackages.pkgconfig.targetPrefix}pkg-config "$@"
  '';

  hasDTB = platform.linux-kernel ? DTB && platform.linux-kernel.DTB;
  kernelFileExtension = if isCompressed != false then ".${isCompressed}" else "";
  kernelTarget = if platform.linux-kernel.target == "Image"
    then "${platform.linux-kernel.target}${kernelFileExtension}"
    else platform.linux-kernel.target;
in

# This `let` block allows us to have a self-reference to this derivation.
# We'll re-use this derivation inside passthru for normalizedConfig and menuconfig.
let kernelDerivation =

stdenv.mkDerivation (inputArgs // {
  pname = "linux";
  inherit src version;
  inherit qcdt_dtbs exynos_dtbs exynos_platform exynos_subtype;
  inherit enableParallelBuilding;

  # Allows disabling the kernel config normalization.
  # Set to false when normalizing the kernel config.
  forceNormalizedConfig = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ perl bc nettools openssl rsync gmp libmpc mpfr ]
    ++ optional (platform.linux-kernel.target == "uImage") buildPackages.ubootTools
    ++ optional (lib.versionAtLeast version "4.14" && lib.versionOlder version "5.8") libelf
    ++ optional (lib.versionAtLeast version "4.15") utillinux
    ++ optionals (lib.versionAtLeast version "4.16") [ bison flex ]
    ++ optionals (lib.versionAtLeast version "4.16") [ bison flex ]
    ++ optional  (lib.versionAtLeast version "5.2")  cpio
    ++ optional  (lib.versionAtLeast version "5.8")  elfutils
    # Mobile NixOS inputs.
    # While some kernels might not need those, most will.
    ++ [ dtc ]
    ++ optional isQcdt dtbTool
    ++ optional isExynosDT dtbTool-exynos
    ++ optional (dtboImg != false) ufdt-apply-overlay
    ++ nativeBuildInputs
  ;

  patches =
    map (p: p.patch) kernelPatches
    # Required for deterministic builds along with some postPatch magic.
    ++ optional (lib.versionAtLeast version "4.13") (nixosKernelPath + "/randstruct-provide-seed.patch")
    ++ patches
  ;

  prePatch = ''
    for mf in $(find -name Makefile -o -name Makefile.include -o -name install.sh); do
        echo "stripping FHS paths in \`$mf'..."
        sed -i "$mf" -e 's|/usr/bin/||g ; s|/bin/||g ; s|/sbin/||g'
    done
    sed -i Makefile -e 's|= depmod|= ${buildPackages.kmod}/bin/depmod|'
    if [ -e scripts/ld-version.sh ]; then
      sed -i scripts/ld-version.sh -e "s|/usr/bin/awk|${buildPackages.gawk}/bin/awk|"
    fi
  ''
    + maybeString prePatch
  ;

  postPatch = ''
    echo ":: Patching for reproducibility"
    # Set randstruct seed to a deterministic but diversified value. Note:
    # we could have instead patched gen-random-seed.sh to take input from
    # the buildFlags, but that would require also patching the kernel's
    # toplevel Makefile to add a variable export. This would be likely to
    # cause future patch conflicts.
    if [ -f scripts/gcc-plugins/gen-random-seed.sh ]; then
      substituteInPlace scripts/gcc-plugins/gen-random-seed.sh \
        --replace NIXOS_RANDSTRUCT_SEED \
        $(echo ${src} ${configfile} | sha256sum | cut -d ' ' -f 1 | tr -d '\n')
    fi

    echo ":: Removing default OEM-provided certificates"
    rm -vf *.x509

    echo ":: Patching tools/ shebangs"
    patchShebangs tools

  '' + optionalString enableLinuxLogoReplacement ''
    echo ":: Replacing the logo"
    cp ${linuxLogo224PPMFile} drivers/video/logo/logo_linux_clut224.ppm

  '' + optionalString enableCenteredLinuxLogo ''
    # Makes the "logo" option show only one logo and not dependent on cores.
    # This should be "safer" than a patch on a greater range of kernel versions.
    # Also defaults to centering when possible.

    echo ":: Patching for centered linux logo"
    if [ -e drivers/video/fbdev/core/fbmem.c ]; then
      # Force showing only one logo
      sed -i -e 's/num_online_cpus()/1/g' \
        drivers/video/fbdev/core/fbmem.c

      # Force centering logo
      sed -i -e '/^bool fb_center_logo/ s/;/ = true;/' \
        drivers/video/fbdev/core/fbmem.c
    fi

    if [ -e drivers/video/fbmem.c ]; then
      # Force showing only one logo
      sed -i -e 's/num_online_cpus()/1/g' \
        drivers/video/fbmem.c
    fi

  '' + optionalString enableRemovingWerror ''
    echo ":: Removing all -Werror from makefiles"
    (
    for i in $(find . -type f -name Makefile) $(find . -type f -name Kbuild); do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror=/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    )

  '' + optionalString enableCompilerGcc6Quirk ''
    echo ":: Adding GCC6 compiler compatibility shim"
    cp -v "${./compiler-gcc6.h}" "./include/linux/compiler-gcc6.h"

  ''
    + maybeString postPatch
  ;

  configurePhase = ''
    runHook preConfigure

    mkdir build
    export buildRoot="$(pwd)/build"

    echo "manual-config configurePhase buildRoot=$buildRoot pwd=$PWD"

    if [ -f "$buildRoot/.config" ]; then
      echo "Could not link $buildRoot/.config : file exists"
      exit 1
    fi
    ln -sv ${configfile} $buildRoot/.config

    # reads the existing .config file and prompts the user for options in
    # the current kernel source that are not found in the file.
    make $makeFlags "''${makeFlagsArray[@]}" oldconfig
    if [ -n "$forceNormalizedConfig" ]; then
      if [ -e $buildRoot/.config.old ]; then
        # First we strip options that save the exact compiler version.
        # This is first because it will break with cross-compilation.
        # It also will break on minor version bumps.
        # We do not strip options related to compiler features, since
        # compiler features changing is something we want to track, I think.
        (
        cd $buildRoot
        for f in .config{,.old}; do
          sed \
            -e 's;CONFIG_CC_VERSION_TEXT=.*;CONFIG_CC_VERSION_TEXT=;' \
            -e 's;CONFIG_GCC_VERSION=.*;CONFIG_GCC_VERSION=;' \
            -e 's;CONFIG_LD_VERSION=.*;CONFIG_LD_VERSION=;' \
            -e 's;CONFIG_CLANG_VERSION=.*;CONFIG_CLANG_VERSION=;' \
            -e '/CONFIG_DEBUG_INFO_SPLIT/d;' \
            $f > .tmp$f
        done
        )

        if ! diff -q $buildRoot/.tmp.config{.old,}; then
          printf "\n\n--------------------------------\n"
          diff -u $buildRoot/.tmp.config{.old,} || :
          printf "\n--------------------------------\n\n"
          echo 'error: Your configuration does not match once passed through `make oldconfig`.'
          echo '       Use the `bin/kernel-normalize-config` tool to refresh the configuration.'
          echo "       Don't forget to make sure the changed configuration options are good!"
          printf "\n"
          exit 1
        fi
        rm -v $buildRoot/.tmp.config{.old,}
      fi
    fi
    runHook postConfigure

    make $makeFlags "''${makeFlagsArray[@]}" prepare
    actualModDirVersion="$(cat $buildRoot/include/config/kernel.release)"
    if [ "$actualModDirVersion" != "${modDirVersion}" ]; then
      echo "Error: modDirVersion ${modDirVersion} specified in the Nix expression is wrong, it should be: $actualModDirVersion"
      exit 1
    fi

    # We have to keep this around, even when Linux supports this in mainline, as kernel forks might
    # be older than the mainline fix.
    makeFlagsArray+=("KBUILD_BUILD_TIMESTAMP=$(date -u -d @$SOURCE_DATE_EPOCH)")

    cd $buildRoot
  '';

  buildFlags = [
    kernelTarget
    "vmlinux"  # for "perf" and things like that
  ]
    ++ optional isImageGzDtb "${kernelTarget}-dtb"
    ++ optional isModular "modules"
  ;

  # no-op buildPhase if we combine build and install steps
  buildPhase = if enableCombiningBuildAndInstallQuirk then ":" else null;

  installTargets =
    if isCompressed != false then [ "zinstall" ] else [ "install" ]
    ++ installTargets
  ;

  preInstall = optionalString enableCombiningBuildAndInstallQuirk ''
    echo ":: Running preBuild hook before preInstall (combined build/install quirk)"
    runHook preBuild

  '' + optionalString enableParallelBuilding ''
        installFlagsArray+=("-j$NIX_BUILD_CORES")
        installFlagsArray+=("-l$NIX_BUILD_CORES")
  '' + ''
        installFlagsArray+=($buildFlags)
  ''
    + maybeString preInstall
  ;

  postInstall = optionalString enableCombiningBuildAndInstallQuirk ''
    echo ":: Running postBuild hook before postInstall (combined build/install quirk)"
    runHook postBuild

  '' + ''
    echo ":: Copying configuration file"
    # Helpful in cases where the kernel isn't built with /proc/config.gz
    cp -v "$buildRoot/.config" "$out/build.config"

  '' + optionalString hasDTB ''
    echo ":: Installing DTBs"
    mkdir -p $out/dtbs/
    make $makeFlags "''${makeFlagsArray[@]}" dtbs dtbs_install INSTALL_DTBS_PATH=$out/dtbs

  '' + optionalString isQcdt ''
    echo ":: Making and installing QCDT dt.img"
    mkdir -p $out/
    dtbTool -s 2048 -p "scripts/dtc/" \
      -o "$out/dt.img" \
      "$qcdt_dtbs"

  '' + optionalString isExynosDT ''
    echo ":: Making and installing Exynos dt.img"
    mkdir -p $out/
    dtbTool-exynos -s 2048 \
      --platform "$exynos_platform" \
      --subtype "$exynos_subtype" \
      -o "$out/dt.img" \
      $exynos_dtbs

  '' + optionalString isImageGzDtb ''
    echo ":: Copying platform-specific -dtb image file"
    cp -v "$buildRoot/arch/${platform.linuxArch}/boot/${kernelTarget}-dtb" "$out/"

  '' + optionalString (dtboImg != false) ''
   echo ":: Building dtbo.img"
   mkdtboimg.py create \
     $out/dtbo.img \
     $(find $buildRoot/arch/*/boot/dts/ -iname '*.dtbo' | sort)
  ''
    + maybeString postInstall
  ;

  hardeningDisable = [ "bindnow" "format" "fortify" "stackprotector" "pic" "pie" ];

  makeFlags = [
    "O=$(buildRoot)"
    "CC=${stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc"
    "HOSTCC=${buildPackages.stdenv.cc}/bin/${buildPackages.stdenv.cc.targetPrefix}cc"
    "ARCH=${platform.linuxArch}"
    "DTC_EXT=${buildPackages.dtc}/bin/dtc"
    "KBUILD_BUILD_VERSION=1-mobile-nixos"
  ]
  # Use platform-specific flags
  ++ lib.optionals (platform ? kernelMakeFlags) platform.kernelMakeFlags
  # Mark as cross-compilation
  ++ lib.optional (stdenv.hostPlatform != stdenv.buildPlatform) [ "CROSS_COMPILE=${stdenv.cc.targetPrefix}" ]
  # User-provided makeFlags
  ++ makeFlags
  # Install flags
  ++ [
    "INSTALLKERNEL=${installkernel}"
    "INSTALL_PATH=$(out)"
  ]
  ++ optional isModular "INSTALL_MOD_PATH=$(out)"
  ++ optional installsFirmware "INSTALL_FW_PATH=$(out)/lib/firmware"
  ;


  requiredSystemFeatures = [ "big-parallel" ];
  dontStrip = true;

  passthru = {
    # Used by consumers of the kernel derivation to configure the build
    # appropriately for different quirks.
    inherit isQcdt isExynosDT;

    # Used by consumers to refer to the kernel build product.
    file = if kernelFile != null then kernelFile else  kernelTarget + optionalString isImageGzDtb "-dtb";

    # Derivation with the as-built normalized kernel config
    normalizedConfig = kernelDerivation.overrideAttrs({ ... }: {
      forceNormalizedConfig = false;
      buildPhase = "echo Skipping build phase...";
      installPhase = ''
        cp .config $out
      '';
    });

    # Patching over this configuration to expose menuconfig.
    menuconfig = kernelDerivation.overrideAttrs({nativeBuildInputs ? [] , ...}: {
      nativeBuildInputs = nativeBuildInputs ++ [
        ncurses
        pkgconfig-helper
      ];
      buildFlags = [ "nconfig" "V=1" ];

      # TODO: build `nconfig`, but copy the whole source dir
      buildPhase = ''
        (PS4=" $ "; set -x

        # Hot fixes pkg-config use.
        export PKG_CONFIG_PATH="${buildPackages.ncurses.dev}/lib/pkgconfig"
        if [ -e scripts/kconfig/nconf-cfg.sh ]; then
          sed -i"" \
            -e 's/$(pkg-config --libs $PKG)/-L $(pkg-config --variable=libdir ncursesw) $(pkg-config --libs $PKG)/' \
            scripts/kconfig/nconf-cfg.sh
        fi

        cat >> scripts/kconfig/Makefile <<EOF

        run-nconfig:
        ${"\t"}\$(obj)/nconf \$(silent) \$(Kconfig)
        EOF

        # Stops `make ...config` from starting the application.
        cp scripts/kconfig/Makefile scripts/kconfig/Makefile.old
        sed -i"" -e 's/$< .*$(Kconfig)/echo "no-op"/' scripts/kconfig/Makefile

        # Build the ...config application.
        make $makeFlags "''${makeFlagsArray[@]}" $buildFlags

        mv scripts/kconfig/Makefile.old scripts/kconfig/Makefile
        )
      '';
      configurePhase = ":";
      installFlags = [];

      # For menuconfig, it would be: "scripts/kconfig/mconf"
      # A future optimisation could be to filter unneeded files like .c and .h,
      # and docs. Though generally unneeded, this is a development-only tool.
      installPhase = ''
        (PS4=" $ "; set -x

        cp -prf . $out
        mkdir -p $out/bin

        find $out/ -iname '*.o' -exec 'rm' '{}' ';'

        (set -u
        cat > $out/bin/nconf <<EOF
        #!${runtimeShell}
        set -e
        set -u
        PS4=" $ "; set -x

        if ((\$# < 1)); then
          echo "Usage: \$0 <config.file>"
          exit 1
        fi

        export KERNEL_TREE=\$(mktemp -d)

        function finish {
          rm -rf "\$KERNEL_TREE"
        }
        trap finish EXIT


        rmdir "\$KERNEL_TREE"
        cp -rf $out "\$KERNEL_TREE"
        chmod -R +w "\$KERNEL_TREE"

        export PATH="$PATH:${buildPackages.gnumake}/bin"
        export KCONFIG_CONFIG="\$(readlink -f "\$1")"; shift

        export SRCARCH="${platform.linuxArch}"
        export ARCH="${platform.linuxArch}"
        export KERNELVERSION="${version}"
        cd "\$KERNEL_TREE"
        ${/* We're expanding the builder's makeFlags variable here. This is not a mistake. */""}
        make $makeFlags run-nconfig "\$@"
        EOF
        )

        chmod +x $out/bin/nconf
        )
      '';
    });
  };
});
in kernelDerivation
