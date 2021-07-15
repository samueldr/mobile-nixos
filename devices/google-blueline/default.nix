{ config, pkgs, ... }:

{
  imports = [
    # Implementations of the kernel provenances
    ./mainline.nix
    ./vendor.nix
  ];

  mobile.device.name = "google-blueline";
  mobile.device.identity = {
    name = "Pixel 3";
    manufacturer = "Google";
  };

  mobile.hardware = {
    soc = "qualcomm-sdm845";
    ram = 1024 * 4;
    screen = {
      width = 1080; height = 2160;
    };
  };

  mobile.system.android.device_name = "blueline";
  mobile.system.android = {
    # This device has an A/B partition scheme.
    ab_partitions = true;

    bootimg.flash = {
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00000000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  # List of valid provenances
  mobile.boot.stage-1.kernel.availableProvenances = [
    "mainline"
    "vendor"
  ];

  # TODO: Once mainline works well enough
  # mobile.boot.stage-1.kernel.provenance = lib.mkDefault "mainline";

  # The dynamic partitions retrofit probably break this.
  # The GPT partitions don't map to the actual on-disk partitions anymore.
  # mobile.system.vendor.partition = "/dev/disk/by-partlabel/vendor_a";

  boot.kernelParams = [
    # Extracted from an Android boot image
    "console=ttyMSM0,115200n8"
    "printk.devkmsg=on"
  ];

  mobile.system.type = "android";

  mobile.usb.mode = "gadgetfs";

  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.usb.gadgetfs.functions = {
    adb = "ffs.adb";
    rndis = "rndis.usb0";
  };
}
