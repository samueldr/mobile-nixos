{ lib, mobile-nixos }:

mobile-nixos.mkLVGUIApp {
  name = "tdm-gui.mrb";
  src = lib.cleanSource ./.;
  rubyFiles = [
    "$(find ./windows -type f -name '*.rb' | sort)"
    "main.rb"
  ];
}
