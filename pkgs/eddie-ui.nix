{
  stdenv,
  lib,
  fetchFromGitHub,
  mono,
  dotnet-sdk,
  msbuild,
  makeWrapper,
  findutils,
  pkg-config,
  gtk2,
  gtk3,
  libayatana-appindicator,
  xz,
  stunnel,
  openvpn,
  curl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "eddie-ui";
  version = "2.21.8";

  src = fetchFromGitHub {
    owner = "AirVPN";
    repo = "Eddie";
    rev = version;
    hash = "sha256-kn0Zyli1GaPs4x+alUS18cqnz4xtqFWaSK4+O7AuTgg=";
  };

  arch =
    if stdenv.system == "i686-linux"
    then "x86"
    else "x64";

  buildInputs = [
    stunnel
    libayatana-appindicator
    xz
  ];

  nativeBuildInputs = [
    dotnet-sdk
    msbuild
    findutils
    makeWrapper
    autoPatchelfHook
    pkg-config
    gtk3
  ];

  dontAutoPatchelf = true;

  postPatch = ''
    find . -type f -name "*.sh" -execdir chmod +x {} \;
    patchShebangs .
  '';

  buildPhase = ''
    runHook preBuild

    msbuild /verbosity:minimal /p:Configuration="Release" /p:Platform="$arch" src/eddie2.linux.ui.sln

    src/eddie.linux.postbuild.sh "src/App.Forms.Linux/bin/$arch/Release/" ui $arch Release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib $out/share/eddie-ui

    makeWrapper ${mono}/bin/mono $out/bin/eddie-ui \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [gtk2]} \
      --prefix PATH : ${lib.makeBinPath [openvpn curl]} \
      --add-flags $out/lib/eddie-ui/App.Forms.Linux.exe \
      --add-flags --path.resources=$out/share/eddie-ui \
      --add-flags --path.exec='"$@"'

    cp -r src/App.Forms.Linux/bin/$arch/Release $out/lib/eddie-ui

    cp common/manifest.json $out/share/eddie-ui/manifest.json
    cp common/libraries.txt $out/share/eddie-ui/libraries.txt
    cp common/gpl3.txt $out/share/eddie-ui/gpl3.txt
    cp common/cacert.pem $out/share/eddie-ui/cacert.pem
    cp common/icon.png $out/share/eddie-ui/icon.png
    cp common/icon_gray.png $out/share/eddie-ui/icon_gray.png
    cp common/icon.png $out/share/eddie-ui/tray.png
    cp common/icon_gray.png $out/share/eddie-ui/tray_gray.png
    cp common/iso-3166.json $out/share/eddie-ui/iso-3166.json
    cp -r common/lang $out/share/eddie-ui/lang
    cp -r common/providers $out/share/eddie-ui/providers

    cp -r repository/linux_arch/bundle/eddie-ui/usr/share/{applications,pixmaps} $out/share
    substituteInPlace $out/share/applications/eddie-ui.desktop \
      --replace /usr/ $out/

    runHook postInstall
  '';

  postFixup = ''
    autoPatchelf $out/lib/eddie-ui/eddie-tray
  '';
}
