{
stdenvNoCC
, fetchFromGitHub
}:

let
  version = "23";
in
stdenvNoCC.mkDerivation {
  inherit version;
  name = "android-headers";

  src = fetchFromGitHub {
    owner = "ubports";
    repo = "android-headers";
    rev = "5baa625723a3ad77648012e4017f4de48374953a";
    sha256 = "115ayzdrv17rjh5c8816wm3h9sjw7syh43y6g35rf5zgnrmw2x0i";
  };

  installPhase = ''
    mkdir -p $out/include/
    cp -prf ${version} $out/include/android
    (
    cd $out/include
    ln -s android android-${version}
    )

    substituteInPlace debian/android-headers-${version}.pc \
      --replace "prefix=/usr" "prefix=$out"
    mkdir -p $out/lib/pkgconfig
    cp debian/android-headers-${version}.pc $out/lib/pkgconfig/android-headers.pc
  '';
}
