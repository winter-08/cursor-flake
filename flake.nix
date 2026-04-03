{
  description = "Cursor flake with package, overlay, and NixOS/nix-darwin modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems =
        f:
        lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [ self.overlays.default ];
            }
          )
        );
    in
    {
      overlays.default = final: prev: {
        cursor = final.callPackage ./package.nix { };
      };

      packages = forAllSystems (pkgs: {
        default = pkgs.cursor;
        cursor = pkgs.cursor;
      });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = lib.getExe pkgs.cursor;
        };
        cursor = {
          type = "app";
          program = lib.getExe pkgs.cursor;
        };
      });

      nixosModules.default =
        { config, lib, pkgs, ... }:
        let
          cfg = config.programs.cursor;
        in
        {
          options.programs.cursor = {
            enable = lib.mkEnableOption "Cursor";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              defaultText = lib.literalExpression "inputs.cursor.packages.${pkgs.system}.default";
              description = "Cursor package to install.";
            };
          };

          config = lib.mkIf cfg.enable {
            nixpkgs.config.allowUnfree = lib.mkDefault true;
            nixpkgs.overlays = [ self.overlays.default ];
            environment.systemPackages = [ cfg.package ];
          };
        };

      darwinModules.default =
        { config, lib, pkgs, ... }:
        let
          cfg = config.programs.cursor;
        in
        {
          options.programs.cursor = {
            enable = lib.mkEnableOption "Cursor";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              defaultText = lib.literalExpression "inputs.cursor.packages.${pkgs.system}.default";
              description = "Cursor package to install.";
            };
          };

          config = lib.mkIf cfg.enable {
            nixpkgs.config.allowUnfree = lib.mkDefault true;
            nixpkgs.overlays = [ self.overlays.default ];
            environment.systemPackages = [ cfg.package ];
          };
        };
    };
}
