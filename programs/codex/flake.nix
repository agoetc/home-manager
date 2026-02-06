{
  description = "Codex CLI - always latest version";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      versionInfo = builtins.fromJSON (builtins.readFile ./version.json);

      platformKeyMap = {
        "aarch64-darwin" = "aarch64-darwin";
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          platformKey = platformKeyMap.${system};
          platformInfo = versionInfo.platforms.${platformKey};
        in
        {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "codex";
            version = versionInfo.version;

            src = pkgs.fetchurl {
              url = "https://github.com/openai/codex/releases/download/rust-v${versionInfo.version}/${platformInfo.asset}";
              hash = platformInfo.hash;
            };

            nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

            dontBuild = true;
            __noChroot = true;

            unpackPhase = ''
              tar xzf $src
            '';

            installPhase = ''
              runHook preInstall
              install -D -m755 ${platformInfo.binary} $out/bin/codex
              wrapProgram $out/bin/codex --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ripgrep ]}
              runHook postInstall
            '';

            meta = {
              description = "Lightweight coding agent that runs in your terminal";
              homepage = "https://github.com/openai/codex";
              license = pkgs.lib.licenses.asl20;
              mainProgram = "codex";
            };
          };
        }
      );
    };
}
