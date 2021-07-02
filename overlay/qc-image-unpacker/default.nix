{ stdenv, fetchFromGitHub, zlib }:

stdenv.mkDerivation {
  pname = "qc-image-unpacker";
  version = "unstable-2020-04-25";

  src = fetchFromGitHub {
    owner = "anestisb";
    repo = "qc_image_unpacker";
    rev = "dbaf73822205753c9a7722b330f74673cad183a5";
    sha256 = "0zfpphp1i2als3k595iv1gqqcgs5l69hw13y5rizc2j9rh0c56j0";
  };

  buildInputs = [
    zlib
  ];

  postPatch = ''
    substituteInPlace src/Makefile \
      --replace 'cp $(TARGET) ../bin/$(TARGET)' 'cp $(TARGET) $(out)/bin/$(TARGET)'
  '';

  buildPhase = ''
    mkdir -p $out/bin
    sh make.sh
  '';

  dontInstall = true;
}
