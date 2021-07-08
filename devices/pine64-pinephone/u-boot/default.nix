{ lib
, writeText
, callPackage
, buildUBoot
, armTrustedFirmwareAllwinner
, crustFirmware
, fetchpatch
, fetchurl
, fetchFromGitHub
, buildPackages
}:

let
  pw = id: sha256: fetchpatch {
    inherit sha256;
    name = "${id}.patch";
    url = "https://patchwork.ozlabs.org/patch/${id}/raw/";
  };

  pine64Patch = rev: sha256: fetchpatch {
    inherit sha256;
    name = "pine64-${rev}.patch";
    url = "https://gitlab.com/pine64-org/u-boot/-/commit/${rev}.patch";
  };
in
(buildUBoot {
  defconfig = "pinephone_defconfig";
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${armTrustedFirmwareAllwinner}/bl31.bin";
  SCP = "${crustFirmware}/scp.bin";

  extraPatches = [
    # usb: Make USB_MUSB_PIO_ONLY selected by USB_MUSB_SUNXI
    # https://patchwork.ozlabs.org/patch/1202024
    (pw "1202024" "0c196zk1s3pq3wdv909sxmjgqpll2hwb817bpbghkfkyyknl96vg")

    # sunxi: support asymmetric dual rank DRAM on A64/R40
    # https://patchwork.ozlabs.org/patch/1312857
    (pw "1312857" "0w8caf936y7f1r2lvdqar9n3dfkm461lm3k5hfwxd7biwyd386nk")

    # sunxi: Add arm64 FEL support
    # https://patchwork.ozlabs.org/patch/1402908
    (pw "1402908" "1pm6zr7xgafw04rb95237q1mxb8xa6k2lmhzfsj0x0gxal96rw2v")

    # sunxi: dram: h6: Improve DDR3 config detection
    # https://patchwork.ozlabs.org/patch/1410521
    (pw "1410521" "1vmalpf3wl3ii592qsh57g11qfrkmx40hlg8mza1330np2xfgb7v")

    # Enable led on boot to notify user of boot status
    # https://gitlab.com/pine64-org/u-boot/-/commit/1a72bd9f5b0d75361b0852ed515d40a47c1e9bfe
    (pine64Patch "1a72bd9f5b0d75361b0852ed515d40a47c1e9bfe" "0z6md01qcsf6xwb6hyn4cgxjz2d0dhv05k5hrqp9kwsh9yghchqq")

    # pinephone: Add volume_key environment variable
    # https://gitlab.com/pine64-org/u-boot/-/commit/2ce71f93c215bf87a9a64a93c3b2c28a86158e5b
    (pine64Patch "2ce71f93c215bf87a9a64a93c3b2c28a86158e5b" "1x5p0p6zyd4y7yigyikhlwhrywqmd0kpkdnb38583svqzadbr9gw")

    # sunxi: DT: A64: Add wifi to PinePhone DTS
    # https://gitlab.com/pine64-org/u-boot/-/commit/b2f2ff6913788437dddf64fa9bcef875e260ec1e
    (pine64Patch "b2f2ff6913788437dddf64fa9bcef875e260ec1e" "0rj3nx067r4y1n7s7l953v8y23l17vc0w5j47dqx3fim8frnq7j3")
  ];

  filesToInstall = ["u-boot-sunxi-with-spl.bin" "u-boot.img" "u-boot.dtb"];

  # The current u-boot build doesn't know about the USB controllers.
  # When it will, ths will allow enabling usb mass storage gadget.
  #  CONFIG_USB_MUSB_GADGET=y
  #  CONFIG_CMD_USB_MASS_STORAGE=y
  extraConfig = ''
    # The default autoboot doesn't *wait*.
    # Though any input before will cancel it.
    # This is because we re-invest the 2s in our own menu.
    CONFIG_AUTOBOOT_KEYED_CTRLC=y
    CONFIG_BOOTDELAY=0
    CONFIG_REGEX=y
  '';
}).overrideAttrs(old: rec {
  version = "2021.01";
  src = fetchurl {
    url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
    sha256 = "0m04glv9kn3bhs62sn675w60wkrl4m3a4hnbnnw67s3l198y21xl";
  };
  postInstall = ''
    cp .config $out/build.config
  '';
  postPatch = old.postPatch + ''
    cat $extraConfigPath >> configs/$defconfig
  '';
  nativeBuildInputs = [
    (buildPackages.python3.withPackages(p: [
      p.libfdt
      p.setuptools # for pkg_resources
    ]))
  ] ++ old.nativeBuildInputs;
})
