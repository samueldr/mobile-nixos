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
    drihybris = callPackage ./drihybris { };
    drihybrisproto = callPackage ./drihybrisproto { };
    dtbTool = callPackage ./dtbtool { };
    glamor-hybris = callPackage ./glamor-hybris { };
    hard-reboot = callPackage ./misc/hard-reboot.nix { };
    hard-shutdown = callPackage ./misc/hard-shutdown.nix { };
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
    msm-fb-handle = callPackage ./msm-fb-handle { };
    ply-image = callPackage ./ply-image { };
    pulseaudio-modules-droid = callPackage ./pulseaudio-modules-droid { };
    xorg = super.xorg.overrideScope'(self: super: {
      xf86videohwcomposer = callPackage ./xf86-video-hwcomposer { };
    }) # See all-packages.nix for more about this messy composition :/
    // { inherit (self) xlibsWrapper; };

    plasma5 = super.plasma5.overrideScope'(pself: psuper: {
      kwin = psuper.kwin.overrideAttrs(old: {
        cmakeFlags = old.cmakeFlags ++ [
          "-Dhybriseglplatform_INCLUDE_DIR=${self.libhybris}/include"
          "-Dlibhardware_INCLUDE_DIR=${self.android-headers}/include"
        ];
        NIX_CFLAGS_COMPILE = "-I${self.android-headers}/include/android -I${self.libhybris}/include/hybris/eglplatformcommon";
        buildInputs = old.buildInputs ++ [
          self.xorg.libpthreadstubs  # TODO: Upstream
          self.libhybris
          self.qt5.qtwayland
          self.android-headers
        ];
      });
    });

    qt512 = super.qt512.overrideScope'(qself: qsuper: {
      qpa-hwcomposer-plugin = qself.callPackage ./qt5-qpa-hwcomposer-plugin { };
      qtwayland = qsuper.qtwayland.overrideAttrs(old: {
        buildInputs = old.buildInputs ++ [
          self.libhybris
        ];
      });
    });

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

    # Default set of kernel patches.
    defaultKernelPatches = with self.kernelPatches; [
      bridge_stp_helper
      p9_fixes
    ];

    #
    # New software to upstream
    # ------------------------
    #

    make_ext4fs = callPackage ./make_ext4fs {};

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
      virtualization = {
        bios = callPackage ./seabios {};
      };
    };

    imageBuilder = callPackage ../lib/image-builder {};
 }
