{
  description = "Buck2 + uv2nix project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    buck2-nix = {
      url = "github:tweag/buck2.nix";
      flake = false;
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      buck2-nix,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      gomod2nix,
      ...
    }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      uv = import ./uv2nix.nix {
        inherit
          nixpkgs
          pyproject-nix
          uv2nix
          pyproject-build-systems
          ;
      };

      go = import ./gomod2nix.nix {
        inherit nixpkgs gomod2nix;
      };
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonSet = uv.pythonSets.${system}.overrideScope uv.editableOverlay;
          virtualenv = pythonSet.mkVirtualEnv "home" uv.workspace.deps.all;
        in
        {
          default = pkgs.mkShell {
            packages = [
              virtualenv
              pkgs.uv
              pkgs.buck2

              # Go toolchain
              pkgs.go
              go.goPackages.${system}.gomod2nix
              self.packages.${system}.go-schema-kcl

              pkgs.kpt
              pkgs.kcl
            ];

            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = pythonSet.python.interpreter;
              UV_PYTHON_DOWNLOADS = "never";
            };

            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel)

              mkdir -p .buckconfig.d
              cat > .buckconfig.d/buck2-nix.config <<'EOS'
              [external_cell_nix]
                git_origin = https://github.com/tweag/buck2.nix.git
                commit_hash = ${buck2-nix.rev}
              EOS

              buck2 build root//schemas/crds:generated_srcs --out tests/generated
            '';
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = uv.pythonSets.${system}.mkVirtualEnv "env" uv.workspace.deps.default;

          go-schema-kcl = go.buildGoBinary {
            inherit system;
            pname = "go-schema-kcl";
            src = ../src/codegen/go-schema-kcl;
          };

          # cloudcoil generation implicitly relies on this
          ruff = pkgs.ruff;
        }
      );
    };
}
