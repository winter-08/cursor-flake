{
  lib,
  stdenv,
  buildVscode,
  fetchurl,
  appimageTools,
  undmg,
  commandLineArgs ? "",
  useVSCodeRipgrep ? stdenv.hostPlatform.isDarwin,
}:

let
  inherit (stdenv) hostPlatform;
  finalCommandLineArgs = "--update=false " + commandLineArgs;
  iconName = "cursor";

  sourcesJson = lib.importJSON ./sources.json;
  inherit (sourcesJson) version;
  vscodeVersion = sourcesJson.vscodeVersion or version;

  sources = lib.mapAttrs (
    _: info:
    fetchurl {
      inherit (info) url hash;
    }
  ) sourcesJson.sources;

  source = sources.${hostPlatform.system};

  # Upstream ships a 1024x1024 app icon; buildVscode only installs that one size under
  # hicolor/. Many desktops treat non-standard sizes as missing, so the menu shows no icon.
  cursor-unwrapped = buildVscode rec {
    inherit useVSCodeRipgrep version vscodeVersion;
    commandLineArgs = finalCommandLineArgs;

    pname = "cursor";

    executableName = "cursor";
    longName = "Cursor";
    shortName = "cursor";
    libraryName = "cursor";
    inherit iconName;

    src =
      if hostPlatform.isLinux then
        appimageTools.extract {
          inherit pname version;
          src = source;
        }
      else
        source;

    extraNativeBuildInputs = lib.optionals hostPlatform.isDarwin [ undmg ];

    sourceRoot =
      if hostPlatform.isLinux then "${pname}-${version}-extracted/usr/share/cursor" else "Cursor.app";

    tests = { };

    updateScript = ./update.sh;

    # Editing the binary within the app bundle invalidates the notarized signature on macOS.
    dontFixup = stdenv.hostPlatform.isDarwin;

    # Cursor ships its own launcher layout, so the generic VSCode path patch is not applicable.
    patchVSCodePath = false;

    meta = {
      description = "AI-powered code editor built on VS Code";
      homepage = "https://cursor.com";
      changelog = "https://cursor.com/changelog";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = [
        "aarch64-linux"
        "x86_64-linux"
      ]
      ++ lib.platforms.darwin;
      mainProgram = "cursor";
    };
  };
in
if hostPlatform.isLinux then
  cursor-unwrapped.overrideAttrs (oldAttrs: {
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        icon_src="$out/share/pixmaps/${iconName}.png"
        for size in 16 24 32 48 64 128 256 512; do
          mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
          magick "$icon_src" -resize "''${size}x''${size}" \
            "$out/share/icons/hicolor/''${size}x''${size}/apps/${iconName}.png"
        done
      '';
  })
else
  cursor-unwrapped
