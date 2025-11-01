{
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [ inputs.haskell-flake.flakeModule ];

      perSystem = { config, pkgs, ... }: {
        haskellProjects.default = {
          packages = {
            miso.source = inputs.miso;
            servant-miso-client.source = inputs.servant-miso-client;
          };
          autoWire = [ "packages" "apps" ];
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ config.haskellProjects.default.outputs.devShell ];
          shellHook = "exec zsh";
          packages = with pkgs; [ ghcid ];
        };

        packages.default = config.packages.miso-fileupload;
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    miso.url = "github:dmjio/miso?rev=a26bc3f17bca95e72846ab5ce845272fcf0ad653";
    servant-miso-client.url = "github:haskell-miso/servant-miso-client";
  };
}
