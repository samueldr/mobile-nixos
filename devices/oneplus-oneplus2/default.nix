{ config, lib, pkgs, ... }:

{
  mobile.device.name = "oneplus-oneplus2";
  mobile.device.identity = {
    name = "OnePlus 2";
    manufacturer = "OnePlus";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8994";
    # FIXME(Krey): This devices also has 3GB LPDDR4 version
    ram = 1024 * 4;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "OnePlus2";
  mobile.system.android.bootimg = {
    flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  boot.kernelParams = [
    "androidboot.hardware=qcom"
    "user_debug=31"
    "msm_rtb.filter=0x237"
    "ehci-hcd.park=3"
    "lpm_levels.sleep_disabled=1"
    "cma=32M@0-0xffffffff"
    "androidboot.selinux=permissive"
    "buildvariant=eng"
  ];

  mobile.usb.mode = "android_usb";
  mobile.usb.idVendor = "18D1";
  mobile.usb.idProduct = "4ee2";

  mobile.system.type = "android";

  mobile.quirks.qualcomm.dwc3-otg_switch.enable = true;

  mobile.quirks.qualcomm.wcnss-wlan.enable = true;
  mobile.quirks.wifi.disableMacAddressRandomization = true;
}
