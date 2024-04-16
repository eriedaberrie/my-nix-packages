{
  description = "Some custom nix packages (mostly) by eriedaberrie";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    inherit (nixpkgs) lib;
    forSystems = f:
      lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system: f nixpkgs.legacyPackages.${system});
  in {
    packages = forSystems (
      pkgs: {
        fastfetch = pkgs.fastfetch.overrideAttrs (new: (old: {
          patches = lib.singleton ./pkgs/fastfetch/flashfetch.patch;
          postPatch =
            old.postPatch
            or ""
            + ''
              substituteAllInPlace src/flashfetch.c
            '';
          flashfetchOptions = "";
          flashfetchModules = [];
          flashfetchModulesRaw = lib.concatMapStrings (m: "&options->${m},") new.flashfetchModules;
        }));

        eddie-ui = pkgs.callPackage ./pkgs/eddie-ui {};
        geticons = pkgs.callPackage ./pkgs/geticons {};
        syncyomi = pkgs.callPackage ./pkgs/syncyomi {};
      }
    );

    formatter = forSystems (pkgs: pkgs.alejandra);
  };
}
