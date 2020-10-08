{
  mobile-nixos
, fetchFromGitHub, fetchpatch
, kernelPatches ? [] # FIXME
, buildPackages
, lz4
}:

let
  inherit (buildPackages) dtc;
in

(mobile-nixos.kernel-builder-clang_11 { # wip
  configfile = ./config.aarch64;
  version = "4.9.223";
  
  enableRemovingWerror = true;
  isImageGzDtb = true;
  isCompressed = "lz4";
  isModular = false;

  src = fetchFromGitHub {
    owner = "android-linux-stable";
    repo = "bluecross";
    rev = "03867dba971b550ab1546e3147942227d224ddd3";
    sha256 = "sha256-ia6gTRT52Suz7jqqRN9gwU9T1UQ6i93qj0RqVxndfkc=";
  };

  nativeBuildInputs = [ lz4 ];

  # installTargets = [ "Image.gz" ]; # not working yet: https://github.com/NixOS/mobile-nixos/pull/191#discussion_r501421726

  # patches = [
  #   (fetchpatch {
  #     url = "https://gitlab.com/postmarketOS/pmaports/-/raw/e735c3f00823436c969eb883212dfcbddfd4ed78/device/linux-google-crosshatch/init-initramfs-disable-do_skip_initramfs.patch";
  #     sha256 = "";
  #   })
  # ];

  #patches = [
  #  ./0001-Revert-four-tty-related-commits.patch
  #  ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
  #  ./99_framebuffer.patch
  #];

})