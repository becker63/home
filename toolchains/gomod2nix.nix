{
  nixpkgs,
  gomod2nix,
}:

let
  lib = nixpkgs.lib;
  forAllSystems = lib.genAttrs lib.systems.flakeExposed;
in
{
  goPackages = forAllSystems (
    system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ gomod2nix.overlays.default ];
      };
    in
    {
      inherit (pkgs)
        go
        gopls
        delve
        gomod2nix
        ;
    }
  );

  buildGoBinary =
    {
      system,
      src,
      pname,
      version ? "0.1.0",
    }:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ gomod2nix.overlays.default ];
      };
    in
    pkgs.buildGoApplication {
      inherit pname version src;
      modules = ../src/codegen/go-schema-kcl/gomod2nix.toml;
    };
}
