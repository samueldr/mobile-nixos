{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.13.0-rc2";
  configfile = ./config.aarch64;

  # FIXME: apply patchsets directly on top of mainline
  src = fetchFromGitHub {
    # Mirror of http://git.linaro.org/people/vinod.koul/kernel.git/commit/?h=pixel/gpi_i2c_touch&id=1b3424a2994b82ac38fdf16e2136e7811548fea4
    owner = "samueldr";
    repo = "linux";
    rev = "1b3424a2994b82ac38fdf16e2136e7811548fea4";
    sha256 = "1ml9br4p88z1whgqfmbv9vc0jn94mgy6jyg1p69nmn05h3wzim63";
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
