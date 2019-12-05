{
stdenv
, lib
, fetchFromGitHub
, fetchpatch
, autoreconfHook
, pkgconfig

, android-headers
, file
, wayland
, xorg
}:

let
  inherit (stdenv) targetPlatform;

  fetchpmospatch = {name, sha256}: fetchpatch {
    inherit name;
    url = "https://gitlab.com/postmarketOS/pmaports/raw/c2cb2a17d47458083f4e62714a46b1875d73cebb/hybris/libhybris/${name}";
    inherit sha256;
    stripLen = 1;
  };

in
stdenv.mkDerivation {
  name = "libhybris";
  version = "0";

  src = fetchFromGitHub {
    owner = "libhybris";
    repo = "libhybris";
    # Use same rev as postmarketOS so patches applies
    rev = "8ddb15b53d6a63b1545bbf97d00ea93827bd68eb";
    sha256 = "1xv714f8xz9j83y4snchz0m6flgvf82nhr75hdjwcjn3rlkwq2vb";
  };

  patches = [
    (fetchpmospatch {
      name = "0002-tests-Regression-test-for-EGL-glibc-TLS-conflict.patch";
      sha256 = "0nzw51hd8z1xz7vjlr1hsban4aikapq71g3r2wsil0jjk745b24z";
    })
    (fetchpmospatch {
      name = "0003-PATCH-v2-Implement-X11-EGL-platform-based-on-wayland.patch";
      sha256 = "0ijfygxw6hlgam74cjbygr6agy60b24nwjg14q1a0xnrbs5g828x";
    })
    (fetchpmospatch {
      name = "0004-Build-test-hwcomposer-7-caf.patch";
      sha256 = "0zdphi1ypw3l2z10nrr60xx2ymcnff1h03sc228q57kl46cd9nhm";
    })
    (fetchpmospatch {
      name = "0005-eglplatform_wayland-link-libEGL-at-runtime.patch";
      sha256 = "1fgydb2i6awska47ajylahfw7azndqqc31nazvicai10b47b151b";
    })
  ];

  postAutoreconf = ''
    substituteInPlace configure \
      --replace "/usr/bin/file" "${file}/bin/file"
  '';

  configureFlags = [
    "--enable-wayland"
    "--enable-trace"
    "--enable-experimental"
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

  buildInputs = [
    wayland
    xorg.libX11
    xorg.libXext
  ];
}
