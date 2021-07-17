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
    owner = "mukul2259";
    repo = "stealth_oneplus2";
    rev = " 1.2";
    # FIXME(Krey): Has to be set
    sha256 = "1ni2fihmrxj85211k8n2igqgykmw62lc18sn51znm5saccbcz0r7";
  };

  enableRemovingWerror = true;
  isImageGzDtb = true;
  isModular = false;
}
