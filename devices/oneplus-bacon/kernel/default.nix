{
  mobile-nixos
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, buildPackages
, dtbTool
}:

(mobile-nixos.kernel-builder-gcc6 {
  configfile = ./config.armv7l;

  version = "3.4.113";

  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_oppo_msm8974";
    rev = "c21df703d58f2292af3afaf7d8993e0db889035c"; # lineageos-17.1
    sha256 = "sha256-qVaH2F+9d+mVxlKjjl7t8nUrPAf8iTodkMTud2k/8GU=";
  };
  patches = [
    ./0001-fix-video-argb-setting.patch
    ./02_gpu-msm-fix-gcc5-compile.patch
    ./mdss_fb_refresh_rate.patch
    #./0003-arch-arm-Add-config-option-to-fix-bootloader-cmdli.patch
    ./90_dtbs-install.patch
    ./99_framebuffer.patch
  ];

  enableRemovingWerror = true;
  enableCompilerGcc6Quirk = true;
  isCompressed = true;
  isQcdt = true;
  enableParallelBuilding=false; # fixdep: error opening depfile: arch/arm/boot/compressed/.lib1funcs.o.d: No such file or directory
  isImageGzDtb = true;
  isModular = false;

}).overrideAttrs({ postInstall ? "", ... }@o: {
  preConfigure = ''
    makeFlagsArray+=("CONFIG_NO_ERROR_ON_MISMATCH=y")
    buildFlagsArray+=("CONFIG_NO_ERROR_ON_MISMATCH=y")
  '';
})
