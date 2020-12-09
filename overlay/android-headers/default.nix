{
stdenvNoCC
, fetchFromGitHub
, version ? "24"
}:

stdenvNoCC.mkDerivation {
  pname = "android-headers";
  inherit version;

  src = fetchFromGitHub {
    owner = "ubports";
    repo = "android-headers";
    rev = "5b241ecec5508b373beb9b1caf795a5b16ae077f";
    sha256 = "148gbn49dl4bipbpmfvl5470cnnsf1n4qaw9ndpib9rv9632vycd";
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
