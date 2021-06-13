{ runCommandNoCC
, lib
, mruby
}:

let
  inherit (lib) concatMapStringsSep;

  # Select libs we need from the libs folder.
  libs = concatMapStringsSep " " (name: "${../../../boot/lib}/${name}") [
    "lvgui/args.rb"
    "lvgui/fiddlier.rb"
    "lvgui/lvgl/*.rb"
    "lvgui/lvgui/*.rb"
    "lvgui/mobile_nixos/*.rb"
    "lvgui/vtconsole.rb"
  ];
in

runCommandNoCC "tdm-gui.mrb" {
  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    mruby
  ];
} ''
  cp -prf $src src
  cd src

  mkdir -p $out/libexec/
  mrbc \
    -o $out/libexec/app.mrb \
    ${libs} \
    $(find ./windows -type f -name '*.rb' | sort) \
    main.rb

  # TODO: add ressources here?
  mkdir -p $out/share/tdm-gui
''
