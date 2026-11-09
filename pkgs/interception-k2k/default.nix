{
  lib,
  interception-k2k,
  stdenv,
  writeTextDir,
  symlinkJoin,
  map-rules-h ? "",
  tap-rules-h ? "",
  multi-rules-h ? "",
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "interception-k2k";
  version = interception-k2k.revision;

  src = interception-k2k;

  makeFlags = let
    rulesHeaders = symlinkJoin {
      name = "joined-rules-headers";
      paths =
        lib.zipListsWith writeTextDir
        ["cfg/map-rules.h.in" "cfg/tap-rules.h.in" "cfg/multi-rules.h.in"]
        [map-rules-h tap-rules-h multi-rules-h];
    };
  in ["CONFIG_DIR=${rulesHeaders}"];

  installPhase = ''
    runHook preInstall
    install -Dm755 out/cfg $out/bin/interception-k2k
    runHook postInstall
  '';
})
