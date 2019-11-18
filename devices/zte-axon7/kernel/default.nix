{
  mobile-nixos
, stdenv
, hostPlatform
, fetchFromGitHub
, kernelPatches ? [] # FIXME
, dtbTool
}:

#
# Note:
# This kernel build is special, it supports both armv7l and aarch64.
# This is because motorola ships an armv7l userspace from stock ROM.
#
# in local.nix:
#  mobile.system.platform = lib.mkForce "armv7a-linux";
#

let
  inherit (stdenv.lib) optionalString;
  cpuName = hostPlatform.parsed.cpu.name;
in
(mobile-nixos.kernel-builder-gcc6 {
  version = "3.18.71";
  configfile = ./. + "/config.${cpuName}";

  file = if (cpuName == "aarch64") then "Image.gz" else "zImage";
  hasDTB = (cpuName == "aarch64");

  src = fetchFromGitHub {
    owner = "LineageOS";
    repo = "android_kernel_zte_msm8996";
    rev = "f94f7af25ec489db2624a2fbf784b08d881c8319"; # lineage-15.1
    sha256 = "1bfc68brz9z9yiasgdvmmkvdkanmbyxqnzxab6gfp50l8dx0x17b";
  };

  patches = [
    ./99_framebuffer.patch
  ];

  isModular = false;

}).overrideAttrs({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "zinstall" "dtbs" ];
  postPatch = postPatch + ''
    cp -v "${./compiler-gcc6.h}" "./include/linux/compiler-gcc6.h"

    # FIXME : factor out
    (
    # Remove -Werror from all makefiles
    local i
    local makefiles="$(find . -type f -name Makefile)
    $(find . -type f -name Kbuild)"
    for i in $makefiles; do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror=/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    )
  '';
  postInstall = postInstall + ''
    mkdir -p "$out/dtbs/"
  ''
  + optionalString (cpuName == "aarch64") ''
    ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "$out/dtbs/zte-axon7.img" "$out/dtbs/qcom/"
  ''
  + optionalString (cpuName == "armv7l") ''
     ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" -o "$out/dtbs/zte-axon7.img" "arch/arm/boot"
  ''
  ;
})
