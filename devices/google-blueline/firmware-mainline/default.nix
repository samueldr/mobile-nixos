{ lib
, runCommandNoCC
, firmwareLinuxNonfree
, wireless-regdb
}:

# The minimum set of firmware files required for the device.
runCommandNoCC "google-blueline-firmware" {
  src = firmwareLinuxNonfree;
} ''
  for firmware in \
    qca/crbtfw21.tlv \
    qca/crnv21.bin \
    qcom/a630_gmu.bin \
    qcom/a630_sqe.fw \
  ; do
    mkdir -p "$(dirname $out/lib/firmware/$firmware)"
    cp -vrf "$src/lib/firmware/$firmware" $out/lib/firmware/$firmware
  done
  cp -vt $out/lib/firmware ${wireless-regdb}/lib/firmware/regulatory.db*
''
