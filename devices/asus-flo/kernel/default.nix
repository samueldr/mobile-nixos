{
  mobile-nixos
, fetchFromGitHub
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.13.0-rc5-next-20210608"; # ???? next?? ah... localversion-next
  configfile = ./config.armv7;

  # FIXME: apply patchsets directly on top of mainline
  src = fetchFromGitHub {
    owner = "okias";
    repo = "linux";
    # https://github.com/okias/linux/commits/flo-v5.13
    rev = "e50acb2eabbf20837f6e9784c23d222a58529eac";
    sha256 = "1dcmg13z7l9k8yzw1xllhjji2iy84ig43axv8haiwk1560m7mcm0";
  };

  # Using the compiled device tree
  installTargets = [
    "qcom-apq8064-asus-nexus7-flo.dtb"
  ];

  # FIXME: generic mainline build; append per-device...
  postInstall = ''
    echo ':: Copying kernel'
    (PS4=" $ "; set -x
    cp -v \
      $buildRoot/arch/arm/boot/zImage \
      $out/
    )

    echo ':: Appending DTB'
    (PS4=" $ "; set -x
    cat \
      $buildRoot/arch/arm/boot/zImage \
      $buildRoot/arch/arm/boot/dts/qcom-apq8064-asus-nexus7-flo.dtb \
      > $out/zImage-dtb
    )
  '';

  isModular = false;
  isCompressed = "gz";
  kernelFile = "zImage-dtb";
}
