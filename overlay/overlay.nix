self: super:

let
  fetchpatch = self.fetchpatch;
  callPackage = self.callPackage;
  # FIXME : upstream fix for .a in "lib" instead of this hack.
  # This is used to "re-merge" the split gcc package.
  # Static libraries (.a) aren't available in the "lib" package.
  # libtool, reading the `.la` files in the "lib" package expects `.a`
  # to be in the "lib" package; they are in out.
  merged_gcc7 = super.wrapCC (self.symlinkJoin {
    name = "gcc7-merged";
    paths = with super.buildPackages.gcc7.cc; [ out lib ];
  });
in
  {
    # Misc. tools.
    # Keep sorted.
    adbd = callPackage ./adbd { };
    android-headers = callPackage ./android-headers { };
    dtbTool = callPackage ./dtbtool { };
    dtbTool-exynos = callPackage ./dtbtool-exynos { };
    libhybris = callPackage ./libhybris {
      # FIXME : verify how it acts on native aarch64 build.
      stdenv = if self.buildPlatform != self.targetPlatform then
        self.stdenv
      else
        with self; overrideCC stdenv (merged_gcc7)
      ;
    };
    mkbootimg = callPackage ./mkbootimg { };
    msm-fb-refresher = callPackage ./msm-fb-refresher { };
    ply-image = callPackage ./ply-image { };
    ufdt-apply-overlay = callPackage ./ufdt-apply-overlay {};

    # Extra "libs"
    mkExtraUtils = import ./lib/extra-utils.nix {
      inherit (self)
        runCommandCC
        glibc
        buildPackages
        writeShellScriptBin
      ;
      inherit (self.buildPackages)
        nukeReferences
      ;
    };

    #
    # New software to upstream
    # ------------------------
    #

    android-partition-tools = callPackage ./android-partition-tools {
      stdenv = with self; overrideCC stdenv buildPackages.clang_11;
    };
    make_ext4fs = callPackage ./make_ext4fs {};
    hardshutdown = callPackage ./hardshutdown {};
    bootlogd = callPackage ./bootlogd {};

    #
    # Hacks
    # -----
    #
    # Totally not upstreamable stuff.
    #

    xorg = super.xorg.overrideScope'(self: super: {
      xf86videofbdev = super.xf86videofbdev.overrideAttrs({patches ? [], ...}: {
        patches = patches ++ [
          ./xserver/0001-HACK-fbdev-don-t-bail-on-mode-initialization-fail.patch
        ];
      });
    }) # See all-packages.nix for more about this messy composition :/
    // { inherit (self) xlibsWrapper; };

    #
    # Fixes to upstream
    # -----------------
    #
    # All that follows will have to be cleaned and then upstreamed.
    #

    vboot_reference = super.vboot_reference.overrideAttrs(attrs: {
      # https://github.com/NixOS/nixpkgs/pull/69039
      postPatch = ''
        substituteInPlace Makefile \
          --replace "ar qc" '${self.stdenv.cc.bintools.targetPrefix}ar qc'
      '';
    });

    ubootTools = super.ubootTools.overrideAttrs({ buildInputs ? [], patches ? [], ... }: {
      # Needed for cross-compiling ubootTools
      buildInputs = buildInputs ++ [
        self.openssl
      ];
      patches = patches ++ [
        ./u-boot/0001-mobile-nixos-work-around-ubootTools-cross-compilatio.patch
        (fetchpatch {
          # https://patchwork.ozlabs.org/project/uboot/patch/20210210194309.07d1dec7@DUFFMAN/
          url = "https://patchwork.ozlabs.org/series/229060/mbox/";
          sha256 = "1d3h1wh5227lqvqlxvnljbkmy89b9wmf52qfsx5jhpfa9g260xql";
        })
      ];
    });


    # Things specific to mobile-nixos.
    # Not necessarily internals, but they probably won't go into <nixpkgs>.
    mobile-nixos = {
      kernel-builder = callPackage ./mobile-nixos/kernel/builder.nix {};
      kernel-builder-gcc49 = callPackage ./mobile-nixos/kernel/builder.nix {
        stdenv = with self; overrideCC stdenv buildPackages.gcc49;
      };
      kernel-builder-gcc6 = callPackage ./mobile-nixos/kernel/builder.nix {
        stdenv = with self; overrideCC stdenv buildPackages.gcc6;
      };
      kernel-builder-clang_8 = callPackage ./mobile-nixos/kernel/builder.nix {
        stdenv = with self; overrideCC stdenv buildPackages.clang_8;
      };
      kernel-builder-clang_9 = callPackage ./mobile-nixos/kernel/builder.nix {
        stdenv = with self; overrideCC stdenv buildPackages.clang_9;
      };

      stage-1 = {
        script-loader = callPackage ../boot/script-loader {};
        boot-recovery-menu = callPackage ../boot/recovery-menu {};
        boot-error = callPackage ../boot/error {};
        boot-splash = callPackage ../boot/splash {};
      };

      # Flashable zip binaries are always static.
      android-flashable-zip-binaries = self.pkgsStatic.callPackage ./mobile-nixos/android-flashable-zip-binaries {};

      autoport = callPackage ./mobile-nixos/autoport {};

      boot-recovery-menu-simulator = self.mobile-nixos.stage-1.boot-recovery-menu.simulator;
      boot-splash-simulator = self.mobile-nixos.stage-1.boot-splash.simulator;

      fdt-forward = callPackage ./mobile-nixos/fdt-forward {};

      gui-assets = callPackage ./mobile-nixos/gui-assets {};

      make-flashable-zip = callPackage ./mobile-nixos/android-flashable-zip/make-flashable-zip.nix {};

      map-dtbs = callPackage ./mobile-nixos/map-dtbs {};

      mkLVGUIApp = callPackage ./mobile-nixos/lvgui {};

      cross-canary-test = callPackage ./mobile-nixos/cross-canary/test.nix {};
      cross-canary-test-static = self.pkgsStatic.callPackage ./mobile-nixos/cross-canary/test.nix {};
    };

    imageBuilder = callPackage ../lib/image-builder {};
 }
