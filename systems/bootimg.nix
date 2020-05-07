{ device_config
, initrd
, pkgs
, name ? "boot.img"
}:
let
  inherit (pkgs) buildPackages;
  inherit (device_info) kernel dtb;
  device_name = device_config.name;
  device_info = device_config.info;

  with_qcdt = device_info ? bootimg_qcdt && device_info.bootimg_qcdt;
  kernel_file = if device_info ? kernel_file then device_info.kernel_file else "${kernel}/${kernel.file}";

  # TODO : Allow appending / prepending
  cmdline = device_info.kernel_cmdline;
in
pkgs.stdenv.mkDerivation {
  name = "mobile-nixos_${device_name}_${name}";

  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  nativeBuildInputs = [
    buildPackages.mkbootimg
    buildPackages.dtbTool
  ];

  installPhase = ''
	echo Using kernel: ${kernel_file}
(
PS4=" $ "
set -x
    mkdir -pv $out/nix-support
    mkbootimg \
      --kernel  ${kernel_file} \
      ${
        if with_qcdt then
          "--dt ${dtb}"
        else
          ""
      } \
      --ramdisk ${initrd} \
      --cmdline       "${cmdline}" \
      --base           ${device_info.flash_offset_base   } \
      --kernel_offset  ${device_info.flash_offset_kernel } \
      --second_offset  ${device_info.flash_offset_second } \
      --ramdisk_offset ${device_info.flash_offset_ramdisk} \
      --tags_offset    ${device_info.flash_offset_tags   } \
      --pagesize       ${device_info.flash_pagesize      } \
      -o $out/nix-support/${device_name}_boot.img
      cat <<EOF > $out/nix-support/hydra-build-products
      file bootimage $out/nix-support/${device_name}_boot.imgo
      EOF
)
  '';
}
