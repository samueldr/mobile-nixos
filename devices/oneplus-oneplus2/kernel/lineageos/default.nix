{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder-gcc6 {
  configfile = ./config.aarch64;

  version = "3.18.140";
  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_device_oneplus_oneplus2 ";
    rev = "lineage-18.0";
    # FIXME(Krey): Has to be set
    sha256 = "1ni2fihmrxj85211k8n2igqgykmw62lc18sn51znm5saccbcz0r7";
  };

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;
}
