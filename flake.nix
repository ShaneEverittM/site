{
  description = "shanemurphy.space — Zola static site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # `nix build` → renders the site into ./result (the contents of public/).
      # Config lives in zola.toml (non-default name), so pass it explicitly.
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "shanemurphy-space";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.zola ];
          buildPhase = ''
            zola --config zola.toml build --output-dir $out
          '';
          # mkDerivation's default installPhase would clobber $out; we wrote there directly.
          dontInstall = true;
        };
      });

      # `nix develop` → shell with the same zola the build uses.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.zola ];
          # `nix develop` drops into a bash subshell. When launched from Warp,
          # emit Warp's bootstrap escape sequence so the subshell gets blocks,
          # completions, etc.
          #
          # Two guards:
          #   - $- contains `i` only for an interactive shell. Under direnv the
          #     hook runs non-interactively inside the already-warpified host
          #     shell, so there's no subshell to bootstrap — skip it there.
          #   - $TERM_PROGRAM makes it a no-op outside Warp.
          shellHook = ''
            case $- in
              *i*)
                if [ "$TERM_PROGRAM" = "WarpTerminal" ]; then
                  printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "bash" }}\x9c'
                fi
                ;;
            esac
          '';
        };
      });

      # `nix run` / `nix run .#serve` → live-reloading dev server.
      apps = forAllSystems (pkgs:
        let
          serve = pkgs.writeShellScriptBin "serve" ''
            exec ${pkgs.zola}/bin/zola --config zola.toml serve "$@"
          '';
        in
        {
          default = self.apps.${pkgs.stdenv.hostPlatform.system}.serve;
          serve = {
            type = "app";
            program = "${serve}/bin/serve";
          };
        });
    };
}
