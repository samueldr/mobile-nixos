{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-sparrow";
  mobile.device.identity = {
    name = "Zenwatch 2 WI501Q";
    manufacturer = "Asus";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8226";
    ram = 512;
    screen = {
      width = 320; height = 320;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android.bootimg = {
    flash = {
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x02000000";
      offset_second = "0x00f00000";
      offset_tags = "0x01e00000";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    #"console=ttyHSL0,115200,n8"
    #"androidboot.console=ttyHSL0"
    "androidboot.hardware=sparrow"
    #"user_debug=31"
    #"maxcpus=4"
    #"msm_rtb.filter=0x3F"
    "pm_levels.sleep_disabled=1"
    "selinux=0"
  ];

  mobile.usb.mode = "android_usb";
  # ASUSTek Computer, Inc.
  mobile.usb.idVendor = "0B05";
  mobile.usb.idProduct = "7771";

  mobile.system.type = "android";
}
