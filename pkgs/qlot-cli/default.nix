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
      rev = "refs/tags/${version}";
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

      ;; Use uiop:dump-image instead of sb-ext:save-lisp-and-die for the image restore hooks
      (setf uiop:*image-entry-point* #'qlot/cli:main)
      (uiop:dump-image "qlot"
                       :executable t
                       #+sb-core-compression :compression
                       #+sb-core-compression t)
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp qlot.asd $out
      rm *.asd
      cp -r * $out

      mv $out/qlot $out/bin
      wrapProgram $out/bin/qlot \
        --prefix LD_LIBRARY_PATH : $LD_LIBRARY_PATH

      runHook postInstall
    '';
  };
in
  qlot-cli
