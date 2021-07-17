{
	mobile-nixos
,	fetchFromGitHub
,	kernelPatches ? [] # FIXME
,	buildPackages
,	dtbTool
}:

let
	inherit (buildPackages) dtc;
in
		   
	(mobile-nixos.kernel-builder {
		configfile = ./config.aarch64;
		file = "Image.gz-dtb";
		hasDTB = true;
				
		version = "5.6-rc6";
		src = fetchFromGitHub {
			owner = "JamiKettunen";
			repo = "linux-mainline-oneplus5";
			rev = "23fbecc56ba4f3828f7adf59f81e891a3a7e6764";
			sha256 = "0kxg1fj8y7r8fpzj86y2v7kkwxcmr0wx282lhrmpkjwyj9cs6wh9";
		};

	patches = [
	];

	
	postPatch = ''
    # Remove -Werror from all makefiles
    local i
    local makefiles="$(find . -type f -name Makefile)
    $(find . -type f -name Kbuild)"
    for i in $makefiles; do
      sed -i 's/-Werror-/-W/g' "$i"
      sed -i 's/-Werror//g' "$i"
    done
    echo "Patched out -Werror"
  '';

  makeFlags = [ "DTC_EXT=${dtc}/bin/dtc"];

  isModular = false;

}).overrideAttrs ({ postInstall ? "", postPatch ? "", ... }: {
  installTargets = [ "Image.gz" "zinstall" "Image.gz-dtb" "install" ];
  postInstall = postInstall + ''
    cp $buildRoot/arch/arm64/boot/Image.gz-dtb $out/
  '';
})
