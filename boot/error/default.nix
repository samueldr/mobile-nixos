{ lib, runCommandNoCC, mobile-nixos }:

let
  assets = runCommandNoCC "boot-error-assets" {} ''
    mkdir -p $out
    cp ${../../artwork/sad.svg} $out/sad.svg
  '';
in
mobile-nixos.mkLVGUIApp {
  name = "boot-error.mrb";
  executablePath = "libexec/boot-error.mrb";
  src = lib.cleanSource ./.;
  rubyFiles = [
    "${../lib}/hal/reboot_modes.rb"
    "${../lib}/init/configuration.rb"
    "$(find ./lib -type f -name '*.rb' | sort)"
    "main.rb"
  ];
  inherit assets;
  assetsPath = "boot-error/assets";
}
