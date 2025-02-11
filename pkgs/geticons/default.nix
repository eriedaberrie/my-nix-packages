{
  lib,
  rustPlatform,
  fetchFromSourcehut,
  installShellFiles,
  scdoc,
}:
rustPlatform.buildRustPackage rec {
  pname = "geticons";
  version = "1.2.2";

  src = fetchFromSourcehut {
    owner = "~zethra";
    repo = pname;
    rev = version;
    sha256 = "09m4irxbyshyycv03xwdy6ilfmf1slrqqshlfnv3hifyw9yd8j8w";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-V3e3boIzn76irAfn9fF9MycPRAWorUUSD/CUZhgKv0E=";

  nativeBuildInputs = [
    installShellFiles
    scdoc
  ];

  outputs = ["out" "man"];

  postInstall = ''
    make geticons.1
    installManPage geticons.1
  '';

  meta = {
    description = "A cli utility to get icons for apps on your system or other generic icons by name";
    homepage = "https://git.sr.ht/~zethra/geticons";
    licenses = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
}
