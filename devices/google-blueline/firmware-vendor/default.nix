{ lib
, fetchurl
, runCommandNoCC
, unzip
, e2fsprogs
, simg2img
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
  nativeBuildInputs = [ unzip e2fsprogs simg2img ];
  meta.license = [
    # We make no claims that it can be redistributed.
    lib.licenses.unfree
  ];
} ''
  unzip ${upstreamImage} blueline-${buildID}/image-blueline-${buildID}.zip
  cd blueline-${buildID}
  unzip image-blueline-${buildID}.zip vendor.img
  simg2img vendor.img vendor-raw.img
  debugfs vendor-raw.img -R "rdump firmware ."

  mkdir -p $out/lib
  mv firmware $out/lib/firmware
''
