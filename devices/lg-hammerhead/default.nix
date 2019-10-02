{ config, lib, pkgs, ... }:

{
  mobile.device.name = "lg-hammerhead";
  mobile.device.info = rec {
    format_version="0";
    name="Google Nexus 5";
    manufacturer="LG";
    codename="lg-hammerhead";
    date="";
    keyboard="false";
    nonfree="false";
    append_dtb="true";
    modules_initfs="";
    external_storage="false";
    flash_method="fastboot";
    arch="armv7";
    # Fastboot related
    generate_bootimg="true";
    flash_offset_base="0";
    flash_offset_kernel="0x00008000";
    flash_offset_ramdisk="0x2900000";
    flash_offset_second="0x00f00000";
    flash_offset_tags="0x02700000";
    kernel_cmdline="console=tty0 console=ttyMSM0,115200,n8";
    flash_pagesize="2048";
    dev_touchscreen = "";
    dev_touchscreen_calibration = "";
    dev_keyboard = "";
    bootimg_qcdt = true;
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
    dtb = "${kernel}/dtbs/qcom-msm8974-lge-nexus5-hammerhead.dtb";
  };
  mobile.hardware = {
    soc = "qualcomm-msm8974";
    ram = 1024 * 2;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.system.type = "android";
}
