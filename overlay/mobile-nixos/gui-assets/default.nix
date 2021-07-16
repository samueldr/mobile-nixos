{ runCommandNoCC
, overpass
, roboto
, font-awesome_4
, nodePackages
}:

let
  artwork = ../../../artwork;
in
runCommandNoCC "gui-assets" {
  nativeBuildInputs = [
    nodePackages.svgo
  ];
} ''
mkdir -p $out
cp --no-preserve=mode ${artwork + "/app-background.svg"} $out/app-background.svg
cp --no-preserve=mode ${artwork + "/logo/logo.white.svg"} $out/logo.svg
(
  cd $out
  for f in *.svg; do svgo $f; done
)
mkdir -p $out/fonts
cp -t $out/fonts \
  ${roboto}/share/fonts/truetype/Roboto-Regular.ttf \
  ${overpass}/share/fonts/opentype/overpass-bold.otf \
  ${overpass}/share/fonts/opentype/overpass-extrabold.otf \
  ${font-awesome_4}/share/fonts/opentype/FontAwesome.otf

(
  cd $out/fonts
  ln -s FontAwesome.otf fallback.ttf
)
''
