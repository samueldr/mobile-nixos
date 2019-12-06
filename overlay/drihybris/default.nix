{ stdenv
, fetchFromGitHub
, autoreconfHook
, pkgconfig
, utilmacros
, xorgserver
, android-headers
, libhybris
, drihybrisproto
, file
}:

stdenv.mkDerivation {
  pname = "drihybris";

  inherit (drihybrisproto) src version;

  nativeBuildInputs = [
    autoreconfHook
    pkgconfig
  ];

  configureFlags = [
    "--enable-drihybris"
  ];

  installFlags = [
    "DESTDIR=$(out)"
  ];

  # TODO: Fix upstream
  postInstall = ''
    mv $out/${xorgserver.dev}/include $out/
    rm -r $out/${xorgserver.dev}
    mv $out/$out/lib $out/lib
    rm -r $out/$out
  '';

  preConfigure = ''
    substituteInPlace configure \
      --replace "/usr/bin/file" "${file}/bin/file"
  '';

  buildInputs = [
    drihybrisproto
    utilmacros
    xorgserver
  ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/NotKit/drihybris";
    description = "Custom DRI3-based Xorg extension for use with libhybris";
    maintainers = with maintainers; [ adisbladis ];
    platforms = stdenv.lib.platforms.linux;
  };
}
