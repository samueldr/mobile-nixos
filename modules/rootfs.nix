# This provides `build.rootfs`, which is the rootfs image (ext4) built from
# the current configuration.
{ config, lib, pkgs, ... }:

let
  inherit (config.boot) growPartition;
  inherit (lib) optionalString types;
  inherit (config.mobile._internal) compressLargeArtifacts;
  inherit (pkgs) buildPackages;
  rootfsLabel = config.mobile.generatedFilesystems.rootfs.label;
in
{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;

  boot.growPartition = lib.mkDefault true;

  mobile.generatedFilesystems.rootfs = lib.mkDefault {
    type = "ext4";
    label = "NIXOS_SYSTEM";
    id = "44444444-4444-4444-8888-888888888888";

    populateCommands =
    let
      closureInfo = pkgs.buildPackages.closureInfo { rootPaths = config.system.build.toplevel; };
    in
    ''
      mkdir -p ./nix/store
      echo "Copying system closure..."
      while IFS= read -r path; do
        echo "  Copying $path"
        cp -prf "$path" ./nix/store
      done < "${closureInfo}/store-paths"
      echo "Done copying system closure..."
      cp -v ${closureInfo}/registration ./nix-path-registration
    '';

    # Give some headroom for initial mounting.
    extraPadding = pkgs.imageBuilder.size.MiB 20;

    # FIXME: See #117, move compression into the image builder.
    # Zstd can take a long time to complete successfully at high compression
    # levels. Increasing the compression level could lead to timeouts.
    postProcess = optionalString compressLargeArtifacts ''
      (PS4=" $ "; set -x
      PATH="$PATH:${buildPackages.zstd}/bin"
      cd $out
      ls -lh
      time zstd -10 --rm "$filename"
      ls -lh
      )
    '' + ''
      (PS4=" $ "; set -x
      mkdir $out/nix-support
      cat <<EOF > $out/nix-support/hydra-build-products
      file rootfs${optionalString compressLargeArtifacts "-zstd"} $out/$filename${optionalString compressLargeArtifacts ".zst"}
      EOF
      )
    '';

    zstd = compressLargeArtifacts;
  };

  boot.postBootCommands = ''
    # On the first boot do some maintenance tasks
    if [ -f /nix-path-registration ]; then
      # Register the contents of the initial Nix store
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

      # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
      touch /etc/NIXOS
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

      # Prevents this from running on later boots.
      rm -f /nix-path-registration
    fi
  '';

  fileSystems = {
    "/" = {
      device = lib.mkDefault "/dev/disk/by-label/${rootfsLabel}";
      fsType = lib.mkDefault "ext4";
      autoResize = lib.mkDefault true;
      options = lib.mkDefault [ "noatime" ];
    };
  };

  # FIXME: Move this in a proper module + task for the filesystem.
  # This is a "wrong" assumption, that only holds through since we are setting
  # fileSystems."/".autoResize to true here.
  mobile.boot.stage-1.extraUtils = with pkgs; [
    { package = e2fsprogs; }
  ];
}
