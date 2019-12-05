{ stdenv
, fetchFromGitHub
, autoreconfHook
, pkgconfig
, utilmacros
, xorgserver
, android-headers
, libhybris
, glamor-hybris
, drihybris
, drihybrisproto
}:

stdenv.mkDerivation {
  pname = "xf86-video-hwcomposer";
  version = "unstable-2019-02-07";

  src = fetchFromGitHub {
    owner = "gemian";
    repo = "xf86-video-hwcomposer";
    rev = "0440e52d31ebe4565d0f92dfb45a8c52aab18b03";
    sha256 = "0yz02jgr12g8gln01qh1rpbixkc6bdcg6rf6h6g04na3gw4f3xr7";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkgconfig
  ];

  configureFlags = [
    "--enable-drihybris"
    "--enable-glamor-hybris"
  ];

  buildInputs = [
    drihybrisproto
    android-headers
    libhybris
    utilmacros
    xorgserver
    glamor-hybris
    drihybris
  ];

  NIX_CFLAGS_COMPILE = stdenv.lib.concatStringsSep " " [
    "-I${android-headers}/include/android"
    # For glamor-hybris.h
    "-I${glamor-hybris}/include/xorg"
    # For drihybris.h
    "-I${drihybris}/include/xorg"
  ];

  meta = with stdenv.lib; {
    homepage = https://github.com/gemian/xf86-video-hwcomposer;
    description = "Xorg DDX driver to renderer through HWComposer API on Android devices via libhybris";
    maintainers = with maintainers; [ adisbladis ];
    platforms = stdenv.lib.platforms.linux;
  };
}
