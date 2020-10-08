{
  mobile-nixos
, fetchFromGitHub, fetchpatch
, kernelPatches ? [] # FIXME
, buildPackages
}:

let
  inherit (buildPackages) dtc;
in

(mobile-nixos.kernel-builder-clang_11 { # wip
  configfile = ./config.aarch64;
  version = "4.9.200-lineageos";
  
  enableRemovingWerror = true;
  isImageGzDtb = true;
  isCompressed = "lz4";
  isModular = false;

  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_google_msm-4.9";
    rev = "d6cae0bddcfc25ce897d43a11a4d3c5d07777831";
    sha256 = "sha256-Ly2FnRqyMlWlXQa0P+sz2YDycrrPw+kPxlfTMS8cp3Y=";
  };

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