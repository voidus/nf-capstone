{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    nix-npm-buildpackage = {
      url = "github:serokell/nix-npm-buildpackage";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-npm-buildpackage }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          nix-npm-buildpackage.overlays.default
        ];
      };

      inherit (pkgs) buildNpmPackage writeShellScriptBin;
      inherit (nixpkgs.lib) cleanSource;
    in {
      inherit inputs;

      packages.${system} = rec {
        nf-capstone-data = (buildNpmPackage {
          src = cleanSource ./.;
          npmBuild = "npm run build";
        }).overrideAttrs (old: {
          installPhase = ''
            ${old.installPhase}
            cp -R .next $out/.next
          '';
        });
        nf-capstone = writeShellScriptBin "nf-capstone" ''
            set -x
            exec ${nf-capstone-data}/node_modules/.bin/next start ${nf-capstone-data}
        '';
        default = nf-capstone;
      };

      apps.${system}.default = {
          type = "app";
          program = "${self.packages.${system}.nf-capstone}/bin/nf-capstone";
      };
  };
}
