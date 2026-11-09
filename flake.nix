{
  description = "Some custom nix packages (mostly) by eriedaberrie";

  outputs = {self, ...} @ args: let
    inputs = (import ./.tack) {overrides = args.tackOverrides or {};};
    inherit (inputs) nixpkgs systems;
    inherit (nixpkgs) lib;
    forSystems = f: lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
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

        interception-k2k = final.callPackage ./pkgs/interception-k2k {inherit (pins) interception-k2k;};

        lem-sdl2 = final.callPackage ./pkgs/lem {withSDL2 = true;};
        lem-ncurses = final.callPackage ./pkgs/lem {withSDL2 = false;};
        lem = final.lem-sdl2;
      };
    };

    packages = forSystems (
      pkgs: {
        inherit
          (self.overlays.default pkgs pkgs)
          fastfetch
          interception-k2k
          lem-sdl2
          lem-ncurses
          lem
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
