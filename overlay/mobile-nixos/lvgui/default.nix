{ runCommandNoCC
, lib
, mruby
, mobile-nixos
}:

/**
 * Builds an LVGUI application.
 *
 * Tailor-made for Mobile NixOS; external uses not guaranteed.
 */
{ name
, src

/** Ruby files to include; note that by design this is not escaped when given to bash. */
, rubyFiles ? []

/** Derivation with all the assets to include */
, assets ? mobile-nixos.gui-assets
/** Path local to $out/share/ the assets are located at */
, assetsPath ? "lvgui/assets"
/** Path, local to $out, the executable will be written to */
, executablePath ? "libexec/app.mrb"
}:

let
  inherit (lib) concatMapStringsSep concatStringsSep;

  # Libraries assumed to be required by *all* LVGUI apps.
  libs = (concatMapStringsSep " " (name: "${../../../boot/lib}/${name}") [
    "lvgui/args.rb"
    "lvgui/fiddlier.rb"
    "lvgui/lvgl/*.rb"
    "lvgui/lvgui/*.rb"
    "lvgui/mobile_nixos/*.rb"
    "lvgui/vtconsole.rb"
    "xdg.rb"
  ]);

  app = runCommandNoCC name {
    inherit src;
    nativeBuildInputs = [
      mruby
    ];
    passthru = {
      inherit
        assets
        assetsPath
        executablePath
        simulator
      ;
    };
  } ''
    cp -prf $src src
    chmod -R +w src
    cd src

    mkdir -p $out/"$(dirname "${executablePath}")"
    (PS4=" $ "; set -x
    mrbc \
      -o $out/"${executablePath}" \
      ${libs} \
      ${concatStringsSep " " rubyFiles}
    )

    mkdir -p $(dirname $out/"share/${assetsPath}")
    ln -s ${assets} $out/"share/${assetsPath}"
  '';

  script-loader = mobile-nixos.stage-1.script-loader.override({
    withSimulator = true;
  });

  simulator = (script-loader.wrap {
    # This is the executable name
    name = "simulator";
    applet = "${app}/${app.executablePath}";
  }).overrideAttrs(old: rec {
    # Override the name for the derivation
    name = "simulator-for-${app.name}";
  })
  ;
in
  app
