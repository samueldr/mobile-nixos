{ config, lib, pkgs, ... }:

let
  app = pkgs.callPackage ./app {};
  tdm-gui = "${app}/libexec/app.mrb";
  internalStorageConfigured =
    config.mobile.boot.stage-1.bootConfig ? storage &&
    config.mobile.boot.stage-1.bootConfig.storage ? internal &&
    config.mobile.boot.stage-1.bootConfig.storage.internal != null
  ;

  # Only enable `adb` if we know how to.
  # FIXME: relies on implementation details. Poor separation of concerns.
  enableADB = 
  let
    value =
      config.mobile.usb.mode == "android_usb" ||
      (config.mobile.usb.mode == "gadgetfs" && config.mobile.usb.gadgetfs.functions ? adb)
    ;
  in
    if value then value else
    builtins.trace "warning: unable to enable ADB for this device." value
  ;
in
{
  mobile.boot.stage-1.tasks = [
    (# Slip an assertion here; nixos asserts only operate on `build.toplevel`.
    if !internalStorageConfigured
    then builtins.throw "mobile.boot.stage-1.bootConfig.storage.internal needs to be configured for ${config.mobile.device.name}."
    else ./gui-task.rb)
  ];

  # There is no mounting here.
  fileSystems = lib.mkForce {};

  mobile.boot.stage-1.usb = {
    enable = true;
    features = [ "mass_storage" ];
  };

  mobile.boot.stage-1.contents = with pkgs; [
    {
      object = tdm-gui;
      symlink = "/applets/tdm-gui.mrb";
    }
  ];

  mobile.generatedFilesystems = {
    # Replaces the rootfs with a generated empty disk.
    # Ideally we'd have `lib.mkDelete` here, but that doesn't exist.
    rootfs = lib.mkForce {
      raw = pkgs.runCommandNoCC "empty" {
        filename = "empty.img";
        partitionType = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
        length = 1024;
      } ''
        mkdir -p $out
        touch $out/empty.img
      '';
    };
  };

  system.build = {
    app-simulator = app.simulator;
  };

  mobile.adbd.enable = lib.mkDefault enableADB;
  mobile.boot.stage-1.networking.enable = true;
  mobile.boot.stage-1.ssh.enable = true;
}
