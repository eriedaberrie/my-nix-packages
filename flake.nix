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
            "dotnet-runtime-wrapped-6.0.36"
          ];
        }));
    pins = import ./npins;
  in {
    overlays = {
      default = final: prev: {
        fastfetch =
          (prev.fastfetch.override {
            flashfetchSupport = true;
          })
          .overrideAttrs (new: (old: {
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

        eddie-ui = final.callPackage ./pkgs/eddie-ui {inherit pins;};
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

    devShells = forSystems (
      pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [
            pkgs.npins
          ];
        };
      }
    );

    formatter = forSystems (pkgs: pkgs.alejandra);
  };
}
