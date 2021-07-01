{ lib
, fetchurl
, runCommandNoCC
, firmwareLinuxNonfree
, wireless-regdb
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

  vendor-firmware-files = runCommandNoCC "google-blueline-firmware" {
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
  '';
in
# The minimum set of firmware files required for the device.
runCommandNoCC "google-blueline-firmware" {
  src = firmwareLinuxNonfree;
} ''
  # Firmware from the vendor image
  mkdir -p $out/lib/firmware/qcom/sdm845
  cp -vt $out/lib/firmware/qcom ${vendor-firmware-files}/lib/firmware/*a630*
  cp -vt $out/lib/firmware/qcom/sdm845 ${vendor-firmware-files}/lib/firmware/*adsp*
  cp -vt $out/lib/firmware/qcom/sdm845 ${vendor-firmware-files}/lib/firmware/*cdsp*
  cp -vt $out/lib/firmware/ ${vendor-firmware-files}/lib/firmware/ftm5*.ftb

  # Firmware we can get from upstream
  for firmware in \
    qca/crbtfw21.tlv \
    qca/crnv21.bin \
  ; do
    mkdir -p "$(dirname $out/lib/firmware/$firmware)"
    cp -vrf "$src/lib/firmware/$firmware" $out/lib/firmware/$firmware
  done
  cp -vt $out/lib/firmware ${wireless-regdb}/lib/firmware/regulatory.db*
''
