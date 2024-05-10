{
  description = "Some custom nix packages (mostly) by eriedaberrie";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    systems.url = "github:nix-systems/default-linux";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    ...
  }: let
    inherit (nixpkgs) lib;
    forSystems = f:
      lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
  in {
    overlays = {
      default = _: prev: {
        fastfetch = prev.fastfetch.overrideAttrs (new: (old: {
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

        eddie-ui = prev.callPackage ./pkgs/eddie-ui {};
        geticons = prev.callPackage ./pkgs/geticons {};
        syncyomi = prev.callPackage ./pkgs/syncyomi {};
      };
    };

    packages = forSystems (
      pkgs: {
        inherit
          (self.overlays.default pkgs pkgs)
          fastfetch
          eddie-ui
          geticons
          syncyomi
          ;
      }
    );

    formatter = forSystems (pkgs: pkgs.alejandra);
  };
}
