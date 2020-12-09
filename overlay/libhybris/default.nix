{
stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, pkgconfig

, android-headers
, file
, useLegacyProperties ? false
}:

let
  inherit (stdenv) targetPlatform buildPlatform;
  libPrefix = if targetPlatform == buildPlatform then ""
    else stdenv.targetPlatform.config;
in
stdenv.mkDerivation {
  pname = "libhybris";
  version = "2020-09-17";

  src = fetchFromGitHub {
    owner = "libhybris";
    repo = "libhybris";
    rev = "30a137c54d4bc8f39612b55f66dee12209ca80b6";
    sha256 = "0apw0q21bxajzambvfr0prahlanri1ij2zkhpf4kc6sqh7fc2vnk";
  };

  patches = [
    ./0001-Removes-failing-test-for-wayland-less-builds.patch
  ]
    ++ lib.optional useLegacyProperties ./0001-HACK-Rely-on-legacy-properties-rather-than-native-pr.patch
  ;

  postAutoreconf = ''
    substituteInPlace configure \
      --replace "/usr/bin/file" "${file}/bin/file"
  '';

  NIX_LDFLAGS = [
    # For libsupc++.a
    "-L${stdenv.cc.cc.out}/${libPrefix}/lib/"
  ];

  configureFlags = [
    "--with-android-headers=${android-headers}/include/android/"
  ]
  ++ lib.optional targetPlatform.isAarch64 "--enable-arch=arm64"
  ++ lib.optional targetPlatform.isAarch32 "--enable-arch=arm"
  ;

  sourceRoot = "source/hybris";

  nativeBuildInputs = [
    autoreconfHook
    pkgconfig
  ];
}
