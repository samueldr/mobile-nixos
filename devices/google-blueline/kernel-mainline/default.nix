{
  mobile-nixos
, fetchurl
, fetchpatch
, ...
}:

let
  major = "5.13";
  minor = "0";
  downloadVersion = major;
in
mobile-nixos.kernel-builder rec {
  version = "${major}.${minor}";
  configfile = ./config.aarch64;

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v5.x/linux-${downloadVersion}.tar.xz";
    sha256 = "1nc9didbjlycs9h8xahny1gwl8m8clylybnza6gl663myfbslsrz";
  };

  patches = [
    ./0001-HACK-Add-back-TEXT_OFFSET-in-the-built-image.patch
  ];

  # TODO: generic mainline build; append per-device...
  postInstall = ''
    echo ':: Copying kernel'
    (PS4=" $ "; set -x
    cp -v \
      $buildRoot/arch/arm64/boot/Image.${isCompressed} \
      $out/
    )

    echo ':: Appending DTB'
    (PS4=" $ "; set -x
    cat \
      $buildRoot/arch/arm64/boot/Image.${isCompressed} \
      $buildRoot/arch/arm64/boot/dts/qcom/sdm845-blueline.dtb \
      > $out/Image.${isCompressed}-dtb
    )
  '';

  isModular = false;
  isCompressed = "gz";
  kernelFile = "Image.${isCompressed}-dtb";
}
