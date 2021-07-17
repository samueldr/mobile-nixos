{ config, lib, pkgs, ... }:

{
  mobile.device.name = "uefi-i686";
  mobile.device.identity = {
   name = "UEFI build (i686)";
   manufacturer = "Generic";
  };

  mobile.hardware = {
    soc = "generic-i686";
    screen = {
      width = 720;
      height = 1280;
    };
    ram = 1024 * 2 - 1; # qemu-system-i386: at most 2047 MB RAM can be simulated
  };

  boot.kernelParams = [
    "vt.global_cursor_default=0"
  ];

  mobile.system.type = "uefi";

  mobile.boot.stage-1 = {
    kernel = {
      package = let inherit (pkgs.linuxPackages_5_4) kernel; in
        kernel.overrideAttrs({passthru ? {}, ...}: {
          # Using `kernel.passthru` as overrideAttrs on kernel derivations
          # does not work as expected.
          # See https://github.com/NixOS/nixpkgs/issues/111504
          passthru = kernel.passthru // {
            file = "bzImage";
          };
        })
      ;
      modular = true;
      # Sync with <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-base.nix>
      #  and with <nixpkgs/nixos/modules/system/boot/kernel.nix>
      modules = [
        # Some SATA/PATA stuff.
        "ahci"
        "sata_nv"
        "sata_via"
        "sata_sis"
        "sata_uli"
        "ata_piix"
        "pata_marvell"

        # Standard SCSI stuff.
        "sd_mod"
        "sr_mod"

        # SD cards and internal eMMC drives.
        "mmc_block"

        # Support USB keyboards, in case the boot fails and we only have
        # a USB keyboard, or for LUKS passphrase prompt.
        "uhci_hcd"
        "ehci_hcd"
        "ehci_pci"
        "ohci_hcd"
        "ohci_pci"
        "xhci_hcd"
        "xhci_pci"
        "usbhid"
        "hid_generic" "hid_lenovo" "hid_apple" "hid_roccat"
        "hid_logitech_hidpp" "hid_logitech_dj"

        # Misc. x86 keyboard stuff.
        "pcips2" "atkbd" "i8042"

        # x86 RTC needed by the stage 2 init script.
        "rtc_cmos"

        # For LVM.
        "dm_mod"

        # SATA/PATA support.
        "ahci"

        "ata_piix"

        "sata_inic162x" "sata_nv" "sata_promise" "sata_qstor"
        "sata_sil" "sata_sil24" "sata_sis" "sata_svw" "sata_sx4"
        "sata_uli" "sata_via" "sata_vsc"

        "pata_ali" "pata_amd" "pata_artop" "pata_atiixp" "pata_efar"
        "pata_hpt366" "pata_hpt37x" "pata_hpt3x2n" "pata_hpt3x3"
        "pata_it8213" "pata_it821x" "pata_jmicron" "pata_marvell"
        "pata_mpiix" "pata_netcell" "pata_ns87410" "pata_oldpiix"
        "pata_pcmcia" "pata_pdc2027x" "pata_qdi" "pata_rz1000"
        "pata_serverworks" "pata_sil680" "pata_sis"
        "pata_sl82c105" "pata_triflex" "pata_via"
        "pata_winbond"

        # SCSI support (incomplete).
        "3w-9xxx" "3w-xxxx" "aic79xx" "aic7xxx" "arcmsr"

        # USB support, especially for booting from USB CD-ROM
        # drives.
        "uas"

        # Firewire support.  Not tested.
        "ohci1394" "sbp2"

        # Virtio (QEMU, KVM etc.) support.
        "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_balloon" "virtio_console"

        # VMware support.
        "mptspi" "vmw_balloon" "vmwgfx" "vmw_vmci" "vmw_vsock_vmci_transport" "vmxnet3" "vsock"

        # Hyper-V support.
        "hv_storvsc"

        # Mouse
        "mousedev"
      ];
    };
  };

  mobile.quirks.supportsStage-0 = true;
}
