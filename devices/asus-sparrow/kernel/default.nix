{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

let
  asteroidosPatch = file: sha256: fetchpatch {
    inherit sha256;
    url = let rev = "7d61c170d0ad0256674be21225205b845058a5c7"; in
      "https://raw.githubusercontent.com/AsteroidOS/meta-sparrow-hybris/${rev}/recipes-kernel/linux/linux-sparrow/${file}";
  };
in
mobile-nixos.kernel-builder-gcc49 {
  version = "3.10.40";
  configfile = ./config.armv7;

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "linux";
    rev = "ef67837e3ce5ef5731cb6645de321e7743fd1ef4"; # android-wear-7.1.1_r0.33
    sha256 = "10qz0xzsxrhdvb198hk6hh73xp010sl3m14lg46jplx7653gh0fh";
  };

  patches = [
    ./0001-mobile-nixos-Adds-and-sets-BGRA-as-default.patch
    ./0001-it7260_ts_i2c-Silence.patch
    ./05_dtb-fix.patch
    ./90_dtbs-install.patch
    (asteroidosPatch "0002-static-inline-in-ARM-ftrace.h.patch" "10mk3ynyyilwg5gdkzkp51qwc1yn0wqslxdpkprcmsrca1i8ms3y")
    (asteroidosPatch "0005-Patch-battery-values.patch" "09gpkcxxd388b12sr8lsq6hwkqmnil0p9m6yk6zxhszrk89j7iby")
    (asteroidosPatch "0006-Touch-screen-sleep-resume-patch.patch" "1w53fbi9fsva02bpb043ch1ppqma5xm781iil6i4mxn86fiwavyr")
    (asteroidosPatch "0009-Makefile-patch-fixes-ASUS_SW_VER-error.patch" "0mg54499imrcwhn8qbj1sdysh4q1qc2iwmgy57kwz5wrvg3cr3i0")
    (asteroidosPatch "0011-ARM-uaccess-remove-put_user-code-duplication.patch" "044x5bms8rww4f4l8xkf2g5hashmdknlalk2im9al9b87p1x708m")
    (fetchpatch {
      url = "https://github.com/AsteroidOS/meta-tetra-hybris/raw/5ed4f17ab8bb3e072356da2ce9ef4c65b4e28991/recipes-kernel/linux/linux-tetra/0010-give-up-on-gcc-ilog2-constant-optimizations.patch";
      sha256 = "095yadqq3hvan8m743f4751d2y4lpfxjzx5g59ric1pjxk7vjy3v";
    })
  ];

  isModular = false;
  isQcdt = true;
  qcdt_dtbs = "arch/arm/boot/";

  # Things are seemingly wrong in that kernel build with parallelization...
  enableParallelBuilding = false;
}
