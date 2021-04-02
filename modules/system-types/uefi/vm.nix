{ config, pkgs, lib, ... }:

let
  # This particular VM module is only enabled for the uefi system type.
  enabled = config.mobile.system.type == "uefi";

  inherit (lib) mkAfter mkIf;
  inherit (config.mobile) device hardware;
  inherit (config.mobile.boot) stage-1;
  inherit (config.system.build) disk-image;

  ram  = toString hardware.ram;
  xres = toString hardware.screen.width;
  yres = toString hardware.screen.height;
in
{
  config = mkIf enabled {
    boot.kernelParams = mkAfter [
      "console=ttyS0"
    ];

    mobile.boot.stage-1.kernel.modules = [
      # Networking
      "e1000"

      # Input within X11
      "uinput" "evdev"

      # Video
      "bochs_drm"
    ];
    system.build = {
      vm = pkgs.writeShellScript "run-vm-${device.name}" ''
        ARGS=(
          -enable-kvm
          -bios   "${pkgs.OVMF.fd}/FV/OVMF.fd"
          -m      "${ram}M"
          -serial "mon:stdio"
          -drive  "file=${disk-image}/${disk-image.filename},format=raw,snapshot=on"

          -device "VGA,edid=on,xres=${xres},yres=${yres}"
          -device "usb-ehci"
          -device "usb-kbd"
          -device "usb-tablet"

          -device "e1000,netdev=net0"
          -netdev "user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::2323-:23,net=172.16.42.0/24,dhcpstart=172.16.42.1"

          -device "e1000,netdev=user.0"
          -netdev "user,id=user.0"
        )

        ${pkgs.qemu}/bin/qemu-system-${pkgs.targetPlatform.qemuArch} "''${ARGS[@]}" "''${@}"
      '';
    };

    mobile.generatedFilesystems.rootfs = lib.mkDefault {
      # Give some headroom in the VM, as it won't be actually resized.
      extraPadding = lib.mkForce (pkgs.imageBuilder.size.MiB 512);
    };
  };
}
