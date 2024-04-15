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
    });

    formatter = forSystems (system: (pkgsFor system).alejandra);
  };
}
