{ config, lib, pkgs, ... }:

{
  mobile.device.name = "zte-axon7";
  mobile.device.info = rec {
    # Reference: <https://postmarketos.org/deviceinfo>

    format_version = "0";
    name = "ZTE Axon 7 (ailsa_ii)";
    manufacturer = "ZTE";
    codename = "zte-axon7";
    date = "";
    dtb = "";
    modules_initfs = "";
    arch = "aarch64";

    # Device related
    keyboard = false;
    external_storage = true;
    dev_touchscreen = "";
    dev_touchscreen_calibration = "";
    dev_keyboard = "";

    # Bootloader related
    flash_method = "fastboot";
    kernel_cmdline = "androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 cma=32M@0-0xffffffff buildvariant=userdebug";
    generate_bootimg = true;
    bootimg_qcdt = false;
    flash_offset_base = "0x80000000";
    flash_offset_kernel = "0x00008000";
    flash_offset_ramdisk = "0x01000000";
    flash_offset_second = "0x00f00000";
    flash_offset_tags = "0x00000100";
    flash_pagesize = "4096";

    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
  };
  mobile.hardware = {
    soc = "qualcomm-msm8996";
    ram = 1024 * 4;
    screen = {
      width = 1440; height = 2560;
    };
  };

  mobile.system.type = "android";
}
