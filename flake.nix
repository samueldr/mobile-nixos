{
  description = "mobile-nixos";

  outputs = inputs@{ self }:
    let
      all-devices =
        builtins.filter
        (d: builtins.pathExists (./. + "/devices/${d}/default.nix"))
        (builtins.attrNames (builtins.readDir ./devices))
      ;
    in {
      nixosModules = builtins.listToAttrs (map (device:
        {
          name = device;
          value = (import ./lib/configuration.nix { inherit device; });
        }
      ) all-devices);
    };
}
