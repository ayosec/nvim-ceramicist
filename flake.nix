{
  description = "Development environment for nvim-ceramicist";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils/1ef2e671c3b0c19053962c07dbda38332dcebf26";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        watch = pkgs.writeShellScriptBin "watch" ''
          exec ${pkgs.watchexec}/bin/watchexec --restart -n \
            -- make "$@"
        '';
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gnumake
            lua-language-server
            luajitPackages.luacheck
            watch
            watchexec
          ];
        };

        formatter = pkgs.writeShellScriptBin "fmt" ''
          exec ${pkgs.alejandra}/bin/alejandra -q "$@";
        '';
      }
    );
}
