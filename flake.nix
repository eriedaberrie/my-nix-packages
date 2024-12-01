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
      lib.genAttrs (import systems) (system:
        f (import nixpkgs {
          inherit system;
          config.permittedInsecurePackages = [
            "dotnet-sdk-6.0.428"
            "dotnet-sdk-wrapped-6.0.428"
            "dotnet-runtime-6.0.36"
          ];
        }));
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
        lem-sdl2 = final.callPackage ./pkgs/lem {withSDL2 = true;};
        lem-ncurses = final.callPackage ./pkgs/lem {withSDL2 = false;};
        lem = final.lem-sdl2;
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
          syncyomi
          ;
      }
    );

    formatter = forSystems (pkgs: pkgs.alejandra);
  };
}
