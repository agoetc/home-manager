{
  description = "Claude Code - always latest version";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
      manifest = builtins.fromJSON (builtins.readFile ./manifest.json);

      platformKeyMap = {
        "aarch64-darwin" = "darwin-arm64";
        "x86_64-darwin" = "darwin-x64";
        "aarch64-linux" = "linux-arm64";
        "x86_64-linux" = "linux-x64";
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          platformKey = platformKeyMap.${system};
          platformManifest = manifest.platforms.${platformKey};
        in
        {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "claude-code";
            version = manifest.version;

            src = pkgs.fetchurl {
              url = "${baseUrl}/${manifest.version}/${platformKey}/claude";
              sha256 = platformManifest.checksum;
            };

            dontUnpack = true;
            dontBuild = true;
            __noChroot = pkgs.stdenv.hostPlatform.isDarwin;
            dontStrip = true;

            nativeBuildInputs = [
              pkgs.installShellFiles
              pkgs.makeBinaryWrapper
            ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isElf [ pkgs.autoPatchelfHook ];

            strictDeps = true;

            installPhase = ''
              runHook preInstall

              install -D -m755 $src $out/bin/claude

              wrapProgram $out/bin/claude \
                --set DISABLE_AUTOUPDATER 1 \
                --set USE_BUILTIN_RIPGREP 0 \
                --prefix PATH : ${
                  pkgs.lib.makeBinPath ([
                    pkgs.procps
                    pkgs.ripgrep
                  ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                    pkgs.bubblewrap
                    pkgs.socat
                  ])
                }

              runHook postInstall
            '';

            meta = {
              description = "Agentic coding tool that lives in your terminal";
              homepage = "https://github.com/anthropics/claude-code";
              license = pkgs.lib.licenses.unfree;
              platforms = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
              mainProgram = "claude";
            };
          };
        }
      );
    };
}
