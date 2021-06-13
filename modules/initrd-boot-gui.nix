{ config, lib, pkgs, ... }:

let
  minimalX11Config = pkgs.runCommandNoCC "minimalX11Config" {
    allowedReferences = [ "out" ];
  } ''
    (PS4=" $ "; set -x
    mkdir -p $out
    cp -r ${pkgs.xlibs.xkeyboardconfig}/share/X11/xkb $out/xkb
    cp -r ${pkgs.xlibs.libX11.out}/share/X11/locale $out/locale
    )

    for f in $(grep -lIiR '${pkgs.xlibs.libX11.out}' $out); do
      printf ':: substituting original path for $out in "%s".\n' "$f"
      substituteInPlace $f \
        --replace "${pkgs.xlibs.libX11.out}/share/X11/locale/en_US.UTF-8/Compose" "$out/locale/en_US.UTF-8/Compose"
    done
  '';
in
{
  mobile.boot.stage-1.contents = with pkgs; [
    {
      object = "${pkgs.mobile-nixos.stage-1.boot-error}/libexec/boot-error.mrb";
      symlink = "/applets/boot-error.mrb";
    }
    {
      object = "${pkgs.mobile-nixos.stage-1.boot-splash}/libexec/boot-splash.mrb";
      symlink = "/applets/boot-splash.mrb";
    }
    {
      object = "${pkgs.mobile-nixos.stage-1.boot-recovery-menu}/libexec/boot-recovery-menu.mrb";
      symlink = "/applets/boot-selection.mrb";
    }
    {
      object = "${minimalX11Config}";
      symlink = "/etc/X11";
    }
  ];

  mobile.boot.stage-1.environment = {
    XKB_CONFIG_ROOT = "/etc/X11/xkb";
    XLOCALEDIR = "/etc/X11/locale";
  };
}
