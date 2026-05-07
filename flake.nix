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

        watch = pkgs.writeShellScriptBin "W" ''
          exec ${pkgs.watchexec}/bin/watchexec -n \
            -- make "$@"
        '';
      in
        with pkgs; {
          devShells.default = mkShell {
            buildInputs = [
              gnumake
              lua-language-server
              luajitPackages.luacheck
              panvimdoc
              watch
              watchexec
            ];
          };

          devShells.web = mkShell {
            FONTCONFIG_FILE = makeFontsConf {
              fontDirectories = [
                quicksand
                dejavu_fonts
              ];
            };

            buildInputs = [
              bash
              ffmpeg-full
              libfaketime
              neovim
              pandoc
              pango
              xdotool
              xterm
              xvfb
            ];
          };

          formatter = writeShellScriptBin "fmt" ''
            exec ${alejandra}/bin/alejandra -q "$@";
          '';
        }
    );
}
