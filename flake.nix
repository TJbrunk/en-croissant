{
  description = "Development shell and package outputs for en-croissant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        linuxLibraries = with pkgs; [
          webkitgtk_4_1
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl
          libsoup_3
          librsvg
        ];

        commonPackages = with pkgs; [
          nodejs_22
          pnpm
          pkg-config
          rustc
          cargo
          rustfmt
          clippy
          cargo-tauri
          git
          curl
          cacert
        ];

        linuxPackages = with pkgs; [
          gcc
          gobject-introspection
          wrapGAppsHook4
          webkitgtk_4_1
          gtk3
          glib
          dbus
          openssl
          libsoup_3
          librsvg
        ];

        darwinPackages = with pkgs; [
          darwin.apple_sdk.frameworks.AppKit
          darwin.apple_sdk.frameworks.CoreFoundation
          darwin.apple_sdk.frameworks.CoreServices
          darwin.apple_sdk.frameworks.Foundation
          darwin.apple_sdk.frameworks.Security
          darwin.apple_sdk.frameworks.WebKit
        ];

        enCroissant = pkgs.stdenv.mkDerivation rec {
          pname = "en-croissant";
          version = "0.15.0";
          src = self;
          cargoRoot = "src-tauri";

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit pname version src;
            fetcherVersion = 1;
            hash = "sha256-78zo2RUBNMW7Q3aHHJypGLZjFi7S621gZq9iEvH8SFo=";
          };

          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            sourceRoot = "source/${cargoRoot}";
            hash = "sha256-/L3URUdUIVrWHlXgRJfmDfFfOKGz9slDe49iE5nPw5k=";
          };

          nativeBuildInputs =
            [
              pkgs.nodejs_22
              pkgs.pnpm
              pkgs.pnpmConfigHook
              pkgs.pkg-config
              pkgs.rustc
              pkgs.cargo
              pkgs.cargo-tauri
              pkgs.rustPlatform.cargoSetupHook
              pkgs.makeWrapper
            ]
            ++ lib.optionals pkgs.stdenv.isLinux linuxPackages
            ++ lib.optionals pkgs.stdenv.isDarwin darwinPackages;

          buildPhase = ''
            runHook preBuild
            pnpm run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 src-tauri/target/release/en-croissant $out/bin/en-croissant
            runHook postInstall
          '';

          postFixup = lib.optionalString pkgs.stdenv.isLinux ''
            wrapProgram $out/bin/en-croissant \
              --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath linuxLibraries} \
              --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}
          '';
        };
      in
      {
        packages = {
          en-croissant = enCroissant;
          default = enCroissant;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = enCroissant;
        };

        devShells.default = pkgs.mkShell {
          packages =
            commonPackages
            ++ lib.optionals pkgs.stdenv.isLinux linuxPackages
            ++ lib.optionals pkgs.stdenv.isDarwin darwinPackages;

          shellHook = lib.concatStringsSep "\n" (
            [
              "export PNPM_HOME=\"$PWD/.pnpm-home\""
              "export PATH=\"$PNPM_HOME:$PATH\""
              "if [ -d \"$PWD/result/bin\" ]; then export PATH=\"$PWD/result/bin:$PATH\"; fi"
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              "export LD_LIBRARY_PATH=\"${lib.makeLibraryPath linuxLibraries}:$LD_LIBRARY_PATH\""
              "export XDG_DATA_DIRS=\"${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS\""
            ]
          );
        };
      }
    );
}
