{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gwq";
  version = "0.0.11";

  src = fetchFromGitHub {
    owner = "d-kuro";
    repo = "gwq";
    rev = "v${version}";
    hash = "sha256-T9G/sbI7P2I2yXNdX95SIr7Mzx87Z5oaqZmb6Y3Fooc=";
  };

  vendorHash = "sha256-c1vq9yETUYfY2BoXSEmRZj/Ceetu0NkIoVCM3wYy5iY=";

  subPackages = [ "cmd/gwq" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "Git worktree manager with fuzzy finder";
    homepage = "https://github.com/d-kuro/gwq";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "gwq";
  };
}
