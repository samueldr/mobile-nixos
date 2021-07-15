{ lib
, fetchurl
, runCommandNoCC
, unzip
, e2fsprogs
, mtools
, simg2img
, qc-image-unpacker
}:

let
  # https://dl.google.com/dl/android/aosp/blueline-rq3a.210605.005-factory-53820251.zip
  buildID = "rq3a.210605.005";
  upstreamImage = fetchurl {
    url = "https://dl.google.com/dl/android/aosp/blueline-${buildID}-factory-53820251.zip";
    sha256 = "17l4b5gs8g182czl3zyvs8kydb6w23hbwkd2m9ngy7wfym8h50jk";
  };
in
runCommandNoCC "google-blueline-firmware" {
  nativeBuildInputs = [ unzip e2fsprogs mtools simg2img qc-image-unpacker ];
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  unzip ${upstreamImage}

  cd blueline-${buildID}

  # Extract vendor files
  unzip image-blueline-${buildID}.zip vendor.img
  simg2img vendor.img vendor-raw.img
  debugfs vendor-raw.img -R "rdump firmware ."

  # Extract radio files
  qc_image_unpacker -i radio-blueline-*.img
  mcopy -i radio-blueline-*/modem ::/image ./
  mv -vt firmware image/*

  mkdir -p $out/lib
  mv -v firmware $out/lib/firmware
''
