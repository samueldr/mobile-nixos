{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-flo";
  mobile.device.identity = {
    name = "Nexus 7 2013 Wifi";
    manufacturer = "Asus";
  };

  mobile.hardware = {
    soc = "qualcomm-apq8064-1aa";
    ram = 1024 * 2;
    screen = {
      width = 1200; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android.device_name = "flo";
  mobile.system.android.bootimg = {
    flash = {
      offset_base = "0x80200000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x02000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = lib.mkMerge [
    # This is a hack to work around the fact that the bootloader ignores some
    # of the initial bytes of the kernel command line.
    (lib.mkOrder 0 [
      "xxxxxxxxxxxxxxxxxxxxxxxxxx"
    ])
    [
      "console=ttyMSM0,115200,n8"
      "user_debug=31"
      "msm_rtb.filter=0x3F"
      "ehci-hcd.park=3"
      "vmalloc=340M"
    ]
  ];

  mobile.system.type = "android";

  # Mainline kernel uses gadgetfs!
  mobile.usb.mode = "gadgetfs";

  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.usb.gadgetfs.functions = {
    rndis = "rndis.usb0";
    adb = "ffs.adb";
  };
}
