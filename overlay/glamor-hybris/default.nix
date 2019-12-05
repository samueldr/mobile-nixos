{ stdenv
, fetchFromGitHub
, autoreconfHook
, pkgconfig
, utilmacros
, xorgserver
, drihybrisproto
, drihybris
, file
, xorg
, libdrm
, libhybris
}:

stdenv.mkDerivation {
  pname = "glamor-hybris";
  version = "unstable-2018-12-16";

  src = fetchFromGitHub {
    owner = "NotKit";
    repo = "glamor-hybris";
    rev = "347463bcd688b75067d0dda2a920fb74fc976f51";
    sha256 = "1b6nihxlfavvry9v7wfwddd7wllyr9bhgqsc66n421yydg8imay5";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkgconfig
  ];

  buildInputs = [
    xorgserver
    xorg.libXi
    xorg.libX11
    xorg.xorgproto
    drihybrisproto
    drihybris
    utilmacros
    libdrm
    libhybris
  ];

  NIX_CFLAGS_COMPILE = stdenv.lib.concatStringsSep " " [
    # For drihybris.h
    "-I${drihybris}/include/xorg"
    # For drm.h
    "-I${libdrm.dev}/include/libdrm"
  ];

  configureScript = "./autogen.sh --enable-glamor-gles2";

  installFlags = [
    "DESTDIR=$(out)"
  ];

  preConfigure = ''
    substituteInPlace configure \
      --replace "/usr/bin/file" "${file}/bin/file"
  '';


  postInstall = ''
    # TODO: Fix upstream
    mv $out/${xorgserver.dev}/include $out/
    rm -r $out/${xorgserver.dev}
    mv $out/$out/lib $out/lib
    rm -r $out/$out

    mv $out/include/xorg/glamor.h $out/include/xorg/glamor-hybris.h
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/gemian/xf86-video-hwcomposer;
    description = "Glamor Xserver 2D acceleration, modified to work with libhybris drivers";
    maintainers = with maintainers; [ adisbladis ];
    platforms = stdenv.lib.platforms.linux;
  };
}
