{ lib
, runCommandNoCC
, fetchFromGitHub
, fetchurl
, firmwareLinuxNonfree
}:

let
  ipa_fws_b00 = muppets "/vendor/firmware/ipa_fws.b00" "sha256-3aYzjFozHLjbMcgGuTz7dwKKECkbW5rWFytrYhjX/cY=";
  ipa_fws_b01 = muppets "/vendor/firmware/ipa_fws.b01" "sha256-yQUnqSTQoabkeCpM1zpZtcuhCiBjzFNJvOkztIdnNk0=";
  ipa_fws_b02 = muppets "/vendor/firmware/ipa_fws.b02" "sha256-/ADnij5zkJ6zPgFZHLh1jGa7WNkSg8g5b8P/rJf9F6s=";
  ipa_fws_b03 = muppets "/vendor/firmware/ipa_fws.b03" "sha256-FAJAiPQ269JLCXyxE7IXfhLJOe/awCEdVgx8xJhhFQc=";
  ipa_fws_b04 = muppets "/vendor/firmware/ipa_fws.b04" "sha256-jVcsS03ulXLZCrkBN+wDAzGFa7/Yvy5u4xXaSlurM3M=";
  ipa_fws_mdt = muppets "/vendor/firmware/ipa_fws.mdt" "sha256-NsiJ2YRkms4oUbFy7UwagVPhxlSB5K/ja4eJjIUkqps=";

  venus_b00 = muppets "/vendor/firmware/venus.b00" "sha256-ltrumw72yELvLbV8xIrHvRYVSt7YEHQ6siwJOlarj1A=";
  venus_b01 = muppets "/vendor/firmware/venus.b01" "sha256-A0XUDlLJ8FQ+EZ0JbSTu/jgS4iVEc49K2IWzBHOJ3K4=";
  venus_b02 = muppets "/vendor/firmware/venus.b02" "sha256-0XEqmwVWmStmwwDOlG7ut1dl5GSK5tq4enOH6E4HNho=";
  venus_b03 = muppets "/vendor/firmware/venus.b03" "sha256-WKZQ3XiPxlh7IOtaa7s0FbblDZEV1h/1XpGoZXQHRLE=";
  venus_b04 = muppets "/vendor/firmware/venus.b04" "sha256-Q7CVluFJaAmqqWSzTBRlgPBWbIa8nXIYoSiP0V+5NCQ=";
  venus_mbn = muppets "/vendor/firmware/venus.mbn" "sha256-K97fe931iDMwvK3AJwM/dxxLa928fO5pApZSpgrJQXQ=";
  venus_mdt = muppets "/vendor/firmware/venus.mdt" "sha256-7hyZRMdaXyN8Sy2YpDtN4eHTFc4+MAhf+7BzHXk8LXw=";

  bdwlan-blueline-EVT1_0_bin = muppets "/vendor/firmware/bdwlan-blueline-EVT1.0.bin" "sha256-QfSE929va+aEVCDOZ2NsYA01ee1M5zYuZJuXUvuj6VI=";
  bdwlan-blueline-EVT1_1_bin = muppets "/vendor/firmware/bdwlan-blueline-EVT1.1.bin" "sha256-QfSE929va+aEVCDOZ2NsYA01ee1M5zYuZJuXUvuj6VI=";
  bdwlan-blueline_bin        = muppets "/vendor/firmware/bdwlan-blueline.bin"        "sha256-tqwPcPNaDERSPxn7QrXP9+pJ9TgigE5M5P49o05ktwM=";

  wil6210_brd                 = muppets "/vendor/firmware/wil6210.brd" "sha256-7a6QYxr6V8CSdZ5xyHBZKGgnd9Zh0qwiV1Cns51qMBc=";
  wil6210_fw                  = muppets "/vendor/firmware/wil6210.fw" "sha256-by5YZE3oW//gQmDy11T4/IKZ5JwEoKTdth9afCiZTEQ=";
  wil6210_sparrow_plus_ftm_fw = muppets "/vendor/firmware/wil6210_sparrow_plus_ftm.fw" "sha256-8sfZLTpA+GoQXFPfvoxmTLC2eyt9+9J/Gq94q46e7aM=";
  wlanmdsp_mbn                = muppets "/vendor/firmware/wlanmdsp.mbn" "sha256-BjSR8bcQZBsRqNoaMDAERbTXGFaQwkGVf6aBXAzUCZM=";

  # Helper to download the proprietary files.
  muppets = file: sha256: fetchurl {
    url = "https://github.com/TheMuppets/proprietary_vendor_google/raw/0ac1d82b3b5cf7e4e1b564456d0df57ec41ea22d/blueline/proprietary${file}";
    inherit sha256;
  };
in
runCommandNoCC "google-blueline-firmware" {
  meta.license = [ lib.licenses.unfree ];
} ''
  fwpath="$out/lib/firmware"
  mkdir -p $fwpath
  cp -v ${ipa_fws_b00}  $fwpath/ipa_fws.b00
  cp -v ${ipa_fws_b01}  $fwpath/ipa_fws.b01
  cp -v ${ipa_fws_b02}  $fwpath/ipa_fws.b02
  cp -v ${ipa_fws_b03}  $fwpath/ipa_fws.b03
  cp -v ${ipa_fws_b04}  $fwpath/ipa_fws.b04
  cp -v ${ipa_fws_mdt}  $fwpath/ipa_fws.mdt

  cp -v ${venus_b00}  $fwpath/venus.b00
  cp -v ${venus_b01}  $fwpath/venus.b01
  cp -v ${venus_b02}  $fwpath/venus.b02
  cp -v ${venus_b03}  $fwpath/venus.b03
  cp -v ${venus_b04}  $fwpath/venus.b04
  cp -v ${venus_mbn}  $fwpath/venus.mbn
  cp -v ${venus_mdt}  $fwpath/venus.mdt

  cp -v ${bdwlan-blueline-EVT1_0_bin} $fwpath/bdwlan-blueline-EVT1.0.bin
  cp -v ${bdwlan-blueline-EVT1_1_bin} $fwpath/bdwlan-blueline-EVT1.1.bin
  cp -v ${bdwlan-blueline_bin} $fwpath/bdwlan-blueline.bin

  cp -v ${wil6210_brd} $fwpath/wil6210.brd
  cp -v ${wil6210_fw} $fwpath/wil6210.fw
  cp -v ${wil6210_sparrow_plus_ftm_fw} $fwpath/wil6210_sparrow_plus_ftm.fw
  cp -v ${wlanmdsp_mbn} $fwpath/wlanmdsp.mbn
''