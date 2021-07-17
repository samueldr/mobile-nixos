{ config, lib, pkgs, ... }:

# This module adds system-level workarounds when cross-compiling.
# These workarounds are only expected to be implemented for the *basic* build.
# That is `nix-build ./default.nix`, without additional configuration.
let
  isCross =
    config.nixpkgs.crossSystem != null &&
    config.nixpkgs.localSystem.system != null &&
    config.nixpkgs.crossSystem.system != config.nixpkgs.localSystem.system;

  AArch32Overlay = final: super:
    # Ensure pkgsBuildBuild ends up unmodified, otherwise the canary test will
    # get super expensive to build.
    if super.stdenv.buildPlatform == super.stdenv.hostPlatform then {} else {
    # Works around libselinux failure with python on armv7l.
    # LONG_BIT definition appears wrong for platform
    libselinux = (super.libselinux
      .override({
        enablePython = false;
      }))
      .overrideAttrs (_: {
        preInstall = ":";
      })
    ;
    pipewire = (super.pipewire
      .override({
        gstreamerSupport = false;
      }))
    ;
    # > /nix/store/yyy7wr7r9jwjjqkr1yn643g3wzv010zd-bash-4.4-p23/bin/bash: ./make_hash: cannot execute binary file: Exec format error
    # For full logs, run 'nix log /nix/store/i2hy1b5hxrcdkvk67qv0mwkf68fgykf2-enca-1.19-armv7l-unknown-linux-gnueabihf.drv'.
    # error: 1 dependencies of derivation '/nix/store/264vacl2qln4shnh0jf1zi0jj61hy8fs-libass-0.15.0-armv7l-unknown-linux-gnueabihf.drv' failed to build
    libass = (super.libass
      .override({
        encaSupport = false;
        # > src/meson.build:639:4: ERROR: Problem encountered: Introspection support is requested but it isn't available in cross builds
        # For full logs, run 'nix log /nix/store/b75sp2d0avdzc90248nh81ngacmq67wb-harfbuzz-2.7.2-armv7l-unknown-linux-gnueabihf.drv'.
      }))
    ;

    ffmpeg = (super.ffmpeg
      .override({
        libass = null;
      }))
      .overrideAttrs (o: {
        configureFlags = o.configureFlags ++ [
          "--disable-libass"
        ];
      })
    ;
  };
in
lib.mkIf isCross
{
  # building '/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-fc-cache.drv'...
  # [...]-fontconfig-2.10.2-aarch64-unknown-linux-gnu-bin/bin/fc-cache: cannot execute binary file: Exec format error
  fonts.fontconfig.enable = false;

  # building '/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-mesa-19.3.3-aarch64-unknown-linux-gnu.drv'...
  # meson.build:1537:2: ERROR: Dependency "wayland-scanner" not found, tried pkgconfig
  security.polkit.enable = false;

  # udisks fails due to gobject-introspection being not cross-compilation friendly.
  services.udisks2.enable = false;

  nixpkgs.overlays = lib.mkMerge [
    (lib.mkIf config.nixpkgs.crossSystem.isAarch32 [ AArch32Overlay ])
  ];
}
