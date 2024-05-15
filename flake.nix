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
      default = final: prev: {
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

        eddie-ui = final.callPackage ./pkgs/eddie-ui {};
        geticons = final.callPackage ./pkgs/geticons {};
        lem-sdl2 = final.callPackage ./pkgs/lem {buildSDL2 = true;};
        lem-ncurses = final.callPackage ./pkgs/lem {buildSDL2 = false;};
        lem = final.lem-sdl2;
        qlot-cli = final.callPackage ./pkgs/qlot-cli {};
        syncyomi = final.callPackage ./pkgs/syncyomi {};
      };
    };

    packages = forSystems (
      pkgs: {
        inherit
          (pkgs.extend self.overlays.default)
          fastfetch
          eddie-ui
          geticons
          lem-sdl2
          lem-ncurses
          lem
          qlot-cli
          syncyomi
          ;
      }
    );

    formatter = forSystems (pkgs: pkgs.alejandra);
  };
}
