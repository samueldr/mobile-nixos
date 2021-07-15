{ runCommandNoCC
, firmwareLinuxNonfree
, wireless-regdb
, vendor-firmware-files
}:

# The minimum set of firmware files required for the device.
runCommandNoCC "google-blueline-firmware" {
  src = firmwareLinuxNonfree;
} ''
  # Firmware from the vendor image
  mkdir -p $out/lib/firmware/qcom/sdm845/blueline

  find ${vendor-firmware-files}

  cp -vt $out/lib/firmware/qcom/sdm845/blueline ${vendor-firmware-files}/lib/firmware/*adsp*
  cp -vt $out/lib/firmware/qcom/sdm845/blueline ${vendor-firmware-files}/lib/firmware/*cdsp*

  # GPU (mainly)
  cp -vt $out/lib/firmware/qcom/sdm845/blueline ${vendor-firmware-files}/lib/firmware/*a630*

  # Modem stuff
  cp -vt $out/lib/firmware/qcom/sdm845/blueline ${vendor-firmware-files}/lib/firmware/*mba*
  cp -vt $out/lib/firmware/qcom/sdm845/blueline ${vendor-firmware-files}/lib/firmware/*modem*

  # Touch panel
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
