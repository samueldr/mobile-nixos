{ config, lib, pkgs, ... }:

{
  mobile.device.name = "oneplus-bacon";
  mobile.device.identity = {
    name = "OnePlus One";
    manufacturer = "OnePlus";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8974";
    ram = 1024 * 3;
    screen = {
      width = 1080; height = 1920;
    };
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
    "console=ttyMSM0,115200,n8"
    "androidboot.hardware=bacon"
    "user_debug=31"
    "ehci-hcd.park=3"
  ];

  mobile.usb.mode = "android_usb";
  mobile.usb.idVendor = "05c6";
  mobile.usb.idProduct = "6769";

  mobile.system.type = "android";

  mobile.quirks.qualcomm.dwc3-otg_switch.enable = true;
}
