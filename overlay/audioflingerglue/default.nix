{ stdenv
, fetchFromGitHub
, lib
}:

stdenv.mkDerivation rec {
  pname = "audioflingerglue";
  version = "0.0.13";

  src = fetchFromGitHub {
    owner = "mer-hybris";
    repo = "audioflingerglue";
    rev = version;
    sha256 = "051255l6km3jr3phblzrgb65hyigs1qzi7dm8hgb922zapc27pvp";
  };

  DROIDLIB = "lib64";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/include/audioflingerglue
    cp -v *.h *.cpp $out/include/audioflingerglue/
    sed -e "s/@TARGET_LIB_ARCH@/$DROIDLIB/" hybris.c.in > $out/include/audioflingerglue/hybris.c

    runHook postInstall
  '';

}
