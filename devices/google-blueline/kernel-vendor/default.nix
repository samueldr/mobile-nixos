{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ufdt-apply-overlay
, ...
}:

mobile-nixos.kernel-builder-clang_9 {
  configfile = ./config.aarch64;

  version = "4.9.248";
  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_google_msm-4.9";
    rev = "f6433030c1d97f4658748782174a06e308b42038"; # lineage-18.1
    sha256 = "1h0p66wpw9wfhhg46fyql1p3vfvpd6w8a0m8k3bgvdvkrq77364f";
  };

  patches = [
    ./0001-mobile-nixos-Workaround-selected-processor-does-not-.patch
    ./0003-arch-arm64-Add-config-option-to-fix-bootloader-cmdli.patch
    ./0001-HACK-touchscreen-Skip-loading-firmware.patch
  ];

  nativeBuildInputs = [
    ufdt-apply-overlay
  ];

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isCompressed = "lz4";
  isModular = false;
  dtboImg = true;
}
