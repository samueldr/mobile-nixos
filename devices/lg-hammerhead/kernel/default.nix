{
  mobile-nixos
, fetchFromGitHub
, fetchgit
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.2.0";
  configfile = ./config.armv7;

  file = "zImage";
  hasDTB = true;

  src = fetchFromGitHub {
    owner = "masneyb";
    repo = "linux";
    rev = "33fee68163e501634338b40aac2ebe279bf7787b";
    sha256 = "1n40vcd4gdppg29n63asbvasd0ybcwldmi044kk9j0lrksga1p5d";
  };

  patches = [
  # ./90_dtbs-install.patch
  # ./99_framebuffer.patch
  ];

  isModular = false;
}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "zinstall" ];
  postPatch = postPatch + ''
    cp -v "${./compiler-gcc6.h}" "./include/linux/compiler-gcc6.h"
  '';
  postInstall = postInstall + ''
    mkdir -p "$out/boot"

    # FIXME factor this out properly
    # Copies all potential output files.
    for f in zImage-dtb Image.gz-dtb zImage Image.gz Image; do
      f=arch/arm/boot/$f
      [ -e "$f" ] || continue
      echo "zImage found: $f"
      cp -v "$f" "$out/"
      break
    done

    mkdir -p $out/dtb
    for f in arch/*/boot/dts/*.dtb; do
      cp -v "$f" $out/dtb/
    done

  '';
})
