{
  description = "Development shell for en-croissant";

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
      in
      {
        devShells.default = pkgs.mkShell {
          packages =
            commonPackages
            ++ lib.optionals pkgs.stdenv.isLinux linuxPackages
            ++ lib.optionals pkgs.stdenv.isDarwin darwinPackages;

          shellHook = lib.concatStringsSep "\n" (
            [
              "export PNPM_HOME=\"$PWD/.pnpm-home\""
              "export PATH=\"$PNPM_HOME:$PATH\""
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
