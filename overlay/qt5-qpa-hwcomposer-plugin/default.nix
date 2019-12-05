{ stdenv
, fetchFromGitHub
, mkDerivation
, pkgconfig
, qmake
, android-headers
, libhybris
, mtdev
, fetchpatch
, qtsensors
, mesa
, qtbase
, qtwayland
}:

let
  version = "5.6.2.12";
in mkDerivation {
  pname = "qt5-qpa-hwcomposer-plugin";
  inherit version;

  src = fetchFromGitHub {
    owner = "mer-hybris";
    repo = "qt5-qpa-hwcomposer-plugin";
    rev = version;
    sha256 = "150lk7pm59c9wklvybm103n9fz3w38kp2xajs7cb3cj9izgg8h2n";
  };

  patches = [
    (fetchpatch {
      # PR includes changes from LuneOS (including Qt 5.12 build fix)
      name = "luneos-improvements.patch";
      url = "https://patch-diff.githubusercontent.com/raw/mer-hybris/qt5-qpa-hwcomposer-plugin/pull/80.patch";
      sha256 = "03q20d6v9jc1vvnb17b2ax7xprrsfshlgrcndc13vd0hbby9y2al";
    })
    ./opengl-include.patch
  ];

  qmakeFlags = [ "DEFINES+=QT_NO_OPENGL_ES_3" ];

  preConfigure = ''
    cd hwcomposer
  '';

  nativeBuildInputs = [
    pkgconfig
    qmake
  ];

  buildInputs = [
    android-headers
    libhybris
    mtdev
    qtsensors  # Remove qtsensors once luneos patches are dropped
    mesa
    qtbase
    qtwayland
  ];

}
