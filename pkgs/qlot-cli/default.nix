{
  sbcl,
  fetchFromGitHub,
  openssl,
  makeWrapper,
  writeText,
}: let
  qlot-cli = sbcl.buildASDFSystem rec {
    pname = "qlot";
    version = "1.5.2";
    src = fetchFromGitHub {
      owner = "fukamachi";
      repo = "qlot";
      rev = version;
      hash = "sha256-j9iT25Yz9Z6llCKwwiHlVNKLqwuKvY194LrAzXuljsE=";
    };
    lispLibs = with sbcl.pkgs; [
      archive
      deflate
      dexador
      fuzzy-match
      ironclad
      lparallel
      yason
    ];
    nativeLibs = [
      openssl
    ];
    nativeBuildInputs = [
      makeWrapper
    ];
    buildScript = writeText "build-qlot-cli" ''
      (load "${qlot-cli.asdfFasl}/asdf.${qlot-cli.faslExt}")
      (asdf:load-system :qlot/command)
      (asdf:load-system :qlot/subcommands)

      ;; Use uiop:dump-image instead of sb-ext:dump-image for the image restore hooks
      (setf uiop:*image-entry-point* #'qlot/cli:main)
      (uiop:dump-image "qlot"
                       :executable t
                       #+sb-core-compression :compression
                       #+sb-core-compression t)
    '';
    installPhase = ''
      mkdir -p $out/bin
      mv qlot $out/bin
      wrapProgram $out/bin/qlot \
        --prefix LD_LIBRARY_PATH : $LD_LIBRARY_PATH
    '';
  };
in
  qlot-cli
