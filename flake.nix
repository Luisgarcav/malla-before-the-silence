{
  description = "MALLA: BEFORE THE SILENCE — web game prototype";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pnpm = pkgs.pnpm_11;

      source = pkgs.lib.cleanSourceWith {
        src = ./.;
        filter =
          path: type:
          let
            name = baseNameOf (toString path);
          in
          !builtins.elem name [
            "result"
            "node_modules"
            ".svelte-kit"
            "build"
            "game.wasm"
          ];
      };

      site = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "malla-before-the-silence-web";
        version = "0.1.0-prototype";
        src = source;

        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (finalAttrs) pname version src;
          inherit pnpm;
          sourceRoot = "${finalAttrs.src.name}/web";
          fetcherVersion = 4;
          hash = "sha256-jd3/a/HFru49u+VoNYSYQfHj4H1vnuoJc5xuJ+h64jA=";
        };

        pnpmRoot = "web";
        nativeBuildInputs = [
          pkgs.odin
          pkgs.nodejs_24
          pnpm
          pkgs.pnpmConfigHook
        ];

        buildPhase = ''
          runHook preBuild
          cd web
          pnpm run validate
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/share/malla-before-the-silence-web"
          cp -r build/. "$out/share/malla-before-the-silence-web/"
          runHook postInstall
        '';

        meta = {
          description = "Static SvelteKit game powered by an Odin WebAssembly engine";
          platforms = [ "x86_64-linux" ];
        };
      });

      server = pkgs.writeShellApplication {
        name = "malla-before-the-silence";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          port="''${PORT:-4173}"
          echo "MALLA: BEFORE THE SILENCE // http://127.0.0.1:$port"
          python3 -m http.server "$port" \
            --bind 127.0.0.1 \
            --directory "${site}/share/malla-before-the-silence-web"
        '';
      };
    in
    {
      packages.${system}.default = site;

      apps.${system}.default = {
        type = "app";
        program = "${server}/bin/malla-before-the-silence";
        meta.description = "Serve MALLA: BEFORE THE SILENCE locally";
      };

      checks.${system}.default = site;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.odin
          pkgs.nodejs_24
          pnpm
        ];
      };
    };
}
