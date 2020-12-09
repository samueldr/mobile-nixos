{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, pkgconfig
, runtimeShell
, pulseaudio
, libpulseaudio
, libtool
, runCommand
, android-headers
, libhybris
, dbus
, pulseaudio-modules-droid
, audioflingerglue
}:

let
  version = "12.2.4";

  # Export private header files
  pulsecore = runCommand "pulsecore-headers" {} ''
    mkdir -p $out/include/pulsecore/filter
    tar -xf ${pulseaudio.src}
    cp -a pulseaudio-${pulseaudio.version}/src/pulsecore/*.h $out/include/pulsecore/
    cp -a pulseaudio-${pulseaudio.version}/src/pulsecore/filter/*.h $out/include/pulsecore/filter/
    mkdir -p $out/lib/pkgconfig/
    sed s/'Name: libpulse'/'Name: pulsecore'/ ${lib.getDev pulseaudio}/lib/pkgconfig/libpulse.pc > $out/lib/pkgconfig/pulsecore.pc
  '';

in stdenv.mkDerivation rec {
  pname = "pulseaudio-modules-droid-glue";
  inherit version;

  src = fetchFromGitHub {
    owner = "mer-hybris";
    repo = "pulseaudio-modules-droid-glue";
    rev = version;
    sha256 = "0895iibh8x7jhwwdf0ax8a8lz6x0kjd2gylwcvjfjrwvxkd0r6qj";
  };

  postPatch = ''
    # Patch git usage
    cat > git-version-gen << EOF
    #!${runtimeShell}
    echo -n ${version}
    EOF
  '';

  NIX_CFLAGS_COMPILE = "-I${audioflingerglue}/include/audioflingerglue";
  NIX_CFLAGS_LINK = "-L${pulseaudio}/lib/pulseaudio -lpulsecommon-${pulseaudio.version} -lpulsecore-${pulseaudio.version}";
  # NIX_LDFLAGS = "-L${pulseaudio}/lib/pulseaudio";
  # NIX_LDFLAGS = "-pulsecommon";

  preAutoreconf = ''
    sed -i s/'\/usr\/share\/audioflingerglue\/'/'${lib.escape [ "/" ] "${audioflingerglue}/include/audioflingerglue/"}'/ src/glue/Makefile.am
  '';

  nativeBuildInputs = [
    autoreconfHook
    pkgconfig
    libtool
  ];

  buildInputs = [
    android-headers
    pulsecore
    pulseaudio
    pulseaudio-modules-droid
    libhybris
    dbus
    audioflingerglue
  ];

  meta = with stdenv.lib; {
    homepage = https://github.com/mer-hybris/pulseaudio-modules-droid-glue;
    description = "PulseAudio Droid glue module";
    platforms = platforms.linux;
    license = licenses.lgpl21;
    maintainers = with maintainers; [ adisbladis ];
  };
}
