{ lib, mobile-nixos }:

mobile-nixos.mkLVGUIApp {
  name = "hello-gui.mrb";
  src = lib.cleanSource ./.;
  rubyFiles = [
    "$(find ./windows -type f -name '*.rb' | sort)"
    "main.rb"
  ];
}
