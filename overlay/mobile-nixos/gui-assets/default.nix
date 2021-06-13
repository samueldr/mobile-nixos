{ runCommandNoCC
, overpass
, roboto
, font-awesome_4
}:

let
  artwork = ../../../artwork;
in
runCommandNoCC "gui-assets" { } ''
mkdir -p $out
cp ${artwork + "/app-background.svg"} $out/app-background.svg
cp ${artwork + "/logo/logo.white.svg"} $out/logo.svg
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
