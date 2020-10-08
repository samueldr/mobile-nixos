{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption optionalString types;
  inherit (config.system.build) extraUtils;
  cfg = config.mobile.boot.stage-1.bootlog;
in
{
  options.mobile.boot.stage-1.bootlog = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables bootlogd logging multiplexer.
      '';
    };
    kmsg = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables logging to /dev/kmsg.

        Note that this may render switching to stage-2 inoperable.

      '';
    };
  };

  config.mobile.boot.stage-1 = mkMerge [
    (mkIf cfg.kmsg {
      # This is a bit buggy:
      #  * fast burst of \n-delimited output will not work as expected
      #  * `printk.devkmsg=on` is required on the kernel cmdline for better results
      # A better implementation would be to have a binary who's sole purpose is to
      # duplicate the stdout/stderr to /dev/kmsg while still outputting them to
      # stdout/stderr as they do currently.
      #
      # Reminder: redirecting to kmsg is useful *mainly* for getting data through
      # console_ramoops on devices without serial and without any other means to
      # get the initial data out.
      earlyInitScripts = ''
        ${extraUtils}/bin/mknod /.kmsg c 1 11
        exec > /.kmsg 2>&1
      '';
    })
    (mkIf cfg.enable {
      earlyInitScripts = ''
        (
        set -x
        export LD_LIBRARY_PATH="${extraUtils}/lib"
        export PATH="${extraUtils}/bin"
        echo "Prepping to launch bootlog..."

        # I'd really like *not* to prep mounts here, but bootlogd requires them.
        # If we wait, we'll lose even more output.
        echo "(Preparing /dev for /dev/pts)"
        mkdir -p /dev
        mount -t devtmpfs devtmpfs /dev

        echo "(Preparing /dev/pts to identify console)"
        mkdir -p /dev/pts
        mount -t devpts devpts /dev/pts

        bootlogd &
        # Ugh, bootlogd takes a bit of time to be ready.
        # Let's not drop logs
        sleep 0.5
        )

        echo "Early logging started..."

        echo
        echo "***************************************"
        echo "* Continuing with stage-1...          *"
        echo "***************************************"
        echo
      '';
      tasks = [
        (pkgs.writeText "bootlogd-task.rb" ''
          class Tasks::KickstartBootlogd < SingletonTask
            def initialize()
              add_dependency(:Target, :Environment)
              add_dependency(:Mount, "/proc")
              add_dependency(:Mount, "/dev")
              add_dependency(:Mount, "/run")
              add_dependency(:Mount, "/dev/pts")
              Targets[:Devices].add_dependency(:Task, self)
            end

            def run()
              # bootlogd is already waiting for the file to appear.
              FileUtils.mkdir_p("/run/log/")
              File.write("/run/log/stage-1.log", "")
            end
          end
        '')
      ];
      extraUtils = with pkgs; [
        { package = bootlogd; }
      ];
    })
  ];
  config.boot.postBootCommands = mkIf cfg.enable ''
    echo "Quitting bootlogd"
    ${pkgs.procps}/bin/pkill -x bootlogd
  '';
}
