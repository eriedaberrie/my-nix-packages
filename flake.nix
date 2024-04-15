{
  description = "Some custom nix packages (mostly) by eriedaberrie";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    inherit (nixpkgs) lib;
    forSystems = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];
    pkgsFor = system:
      import nixpkgs {
        inherit system;
      };
  in {
    packages = forSystems (system: let
      pkgs = pkgsFor system;
    in {
      fastfetch = pkgs.fastfetch.overrideAttrs (new: (old: {
        patches = lib.singleton ./pkgs/flashfetch.patch;
        postPatch = old.postPatch or "" + ''
          substituteAllInPlace src/flashfetch.c
        '';
        flashfetchOptions = "";
        flashfetchModules = [];
        flashfetchModulesRaw = lib.concatMapStrings (m: "&options->${m},") new.flashfetchModules;
      }));

      eddie-ui = pkgs.callPackage ./pkgs/eddie-ui.nix { };
      syncyomi = pkgs.callPackage ./pkgs/syncyomi.nix { };
      geticons = pkgs.callPackage ./pkgs/geticons.nix { };
    });

    formatter = forSystems (system: (pkgsFor system).alejandra);
  };
}
