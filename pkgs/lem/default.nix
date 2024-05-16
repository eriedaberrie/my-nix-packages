{
  lib,
  sbcl,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  which,
  git,
  cacert,
  pkg-config,
  libtool,
  autoconf,
  automake,
  libffi,
  ncurses,
  openssl,
  SDL2,
  SDL2_image,
  SDL2_ttf,
  writeText,
  makeWrapper,
  withSDL2 ? true,
}: let
  lem = sbcl.buildASDFSystem rec {
    pname = "lem";
    version = "2.2.0";

    src = fetchFromGitHub {
      owner = "lem-project";
      repo = "lem";
      rev = "refs/tags/v${version}";
      hash = "sha256-aMPyeOXyFSxhh75eiAwMStLc2fO1Dwi2lQsuH0IYMd0=";
    };

    bundleLibs = stdenvNoCC.mkDerivation {
      pname = "${pname}-bundle-libs";
      inherit src version;

      nativeBuildInputs = [
        sbcl.pkgs.qlot-cli
        which
        git
        cacert
      ];

      installPhase = ''
        runHook preInstall

        export HOME=$(mktemp -d)
        qlot install --jobs $NIX_BUILD_CORES --no-deps
        qlot bundle

        cp -r .bundle-libs $out

        # Unnecessary and also platform-dependent file
        rm $out/bundle-info.sexp

        # Remove vendored .so files
        find $out -type f '(' -name '*.so' -o -name '*.dll' ')' -exec rm '{}' ';'

        runHook postInstall
      '';

      dontBuild = true;
      dontFixup = true;
      outputHashMode = "recursive";
      outputHash = "sha256-DDFUP/lEkxoCNil23KlSqJb0mWCriAgNzpq8RAF4mFc=";
    };

    nativeLibs =
      [
        libffi
        openssl
      ]
      ++ lib.optionals (!withSDL2) [
        ncurses
      ]
      ++ lib.optionals withSDL2 [
        SDL2
        SDL2_image
        (SDL2_ttf.overrideAttrs (old: {
          configureFlags = old.configureFlags or [] ++ ["--disable-freetype-builtin"];
        }))
      ];

    nativeBuildInputs = [
      pkg-config
      libtool
      autoconf
      automake
      makeWrapper
    ];

    configurePhase = ''
      runHook preConfigure

      cp -r $bundleLibs bundleLibs
      chmod -R +w bundleLibs

      pushd bundleLibs/software

      # Patch out things that would cause compiler warnings and then a compile-file-error
      # These fixes should probably be upstreamed at some point
      sed -i 's/nreverse/reverse/' cl-sdl2-ttf-*/src/helpers.lisp
      sed -i 's/(code-char #xFFFD)/#xFFFD/' micros-*/backend/backend.lisp

      # async-process normally vendors its own .so files but we manually build them here instead
      pushd async-process-*
      chmod +x bootstrap
      ./bootstrap
      popd

      popd

      # Move over the generated .so file(s) to a central location
      mkdir _lib
      find bundleLibs/software -type f -name '*.so' -exec mv '{}' _lib ';'

      # Retain the current LD_LIBRARY_PATH for the final wrapProgram, but temporarily prepend ./_lib to allow the lisp builder access to the libraries before writing them to $out/lib
      _LD_LIBRARY_PATH=$LD_LIBRARY_PATH
      export LD_LIBRARY_PATH=$PWD/_lib:$LD_LIBRARY_PATH

      # Loading swank tries to write to ~/.slime
      export HOME=$(mktemp -d)

      runHook postConfigure
    '';

    buildScript = let
      lemSystem =
        if withSDL2
        then "lem-sdl2"
        else "lem-ncurses";
    in
      writeText "build-lem.lisp" ''
        (load "${lem.asdfFasl}/asdf.${lem.faslExt}")

        ;; Avoid writing to the global fasl cache
        (asdf:initialize-output-translations '(:output-translations :disable-cache
                                                                    :inherit-configuration))

        ;; Create dummy ql:quickload for micros to load properly
        (defpackage :ql (:export #:quickload))
        (setf (fdefinition 'ql:quickload) #'asdf:load-system)

        (let ((asdf:*system-definition-search-functions*
               (copy-list asdf:*system-definition-search-functions*)))
          (load "bundleLibs/bundle.lisp")
          (asdf:load-system :${lemSystem}))

        ;; async-process sets this to its vendored .so files, which we don't use
        (setf cffi:*foreign-library-directories* ())

        (let ((out-path (uiop:getenv "out")))
          (uiop:register-image-restore-hook
           (lambda ()
             (load (concatenate 'string
                                out-path
                                "/share/lem/bundleLibs/bundle.lisp")))
           nil))

        (setf uiop:*image-entry-point* #'lem:main)
        (uiop:dump-image "lem"
                         :executable t
                         #+sb-core-compression :compression
                         #+sb-core-compression t)
      '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/lem
      mv lem $out/bin
      mv _lib $out/lib
      cp -r * $out/share/lem

      echo $out

      wrapProgram $out/bin/lem \
        ${lib.optionalString withSDL2 "--set-default SDL_VIDEODRIVER wayland,x11"} \
        --prefix LD_LIBRARY_PATH : $out/lib:$_LD_LIBRARY_PATH

      runHook postInstall
    '';

    meta = {
      description = "Common Lisp editor/IDE with high expansibility";
      homepage = "https://lem-project.github.io";
      changelog = "https://github.com/lem-project/lem/releases/tag/v${version}";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [eriedaberrie];
      mainProgram = "lem";
      platforms = lib.platforms.linux;
    };
  };
in
  lem
