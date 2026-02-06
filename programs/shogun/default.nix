{ config, pkgs, lib, ... }:

let
  shogunDir = "${config.home.homeDirectory}/.local/share/multi-agent-shogun";

  settingsYaml = ''
    # multi-agent-shogun 設定ファイル
    language: ja
    shell: zsh
    skill:
      save_path: "~/.claude/skills/"
      local_path: "${shogunDir}/skills/"
    logging:
      level: info
      path: "${shogunDir}/logs/"
  '';

  projectsYaml = ''
    projects:
      - id: sample_project
        name: "Sample Project"
        path: "/path/to/your/project"
        priority: high
        status: active
    current_project: sample_project
  '';

  globalContextMd = ''
    # グローバルコンテキスト
    最終更新: (未設定)

    ## システム方針
    - (殿の好み・方針をここに記載)

    ## プロジェクト横断の決定事項
    - (複数プロジェクトに影響する決定をここに記載)

    ## 注意事項
    - (全エージェントが知るべき注意点をここに記載)
  '';
in
{
  home.activation.shogunSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # STEP 1: リポジトリ取得・更新
    if [ ! -d "${shogunDir}" ]; then
      ${pkgs.git}/bin/git clone https://github.com/yohey-w/multi-agent-shogun.git "${shogunDir}"
    else
      ${pkgs.git}/bin/git -C "${shogunDir}" fetch origin
      ${pkgs.git}/bin/git -C "${shogunDir}" reset --hard origin/main
    fi

    # STEP 2: 実行権限付与
    chmod +x "${shogunDir}/shutsujin_departure.sh" 2>/dev/null || true
    chmod +x "${shogunDir}/first_setup.sh" 2>/dev/null || true
    chmod +x "${shogunDir}/setup.sh" 2>/dev/null || true

    # STEP 3: ディレクトリ構造作成
    for dir in queue/tasks queue/reports config status instructions logs demo_output skills memory; do
      mkdir -p "${shogunDir}/$dir"
    done

    # STEP 4: 設定ファイル初期化（存在しない場合のみ）
    if [ ! -f "${shogunDir}/config/settings.yaml" ]; then
      cat > "${shogunDir}/config/settings.yaml" << 'SETTINGS'
    ${settingsYaml}
    SETTINGS
    fi

    if [ ! -f "${shogunDir}/config/projects.yaml" ]; then
      cat > "${shogunDir}/config/projects.yaml" << 'PROJECTS'
    ${projectsYaml}
    PROJECTS
    fi

    if [ ! -f "${shogunDir}/memory/global_context.md" ]; then
      cat > "${shogunDir}/memory/global_context.md" << 'GLOBALCTX'
    ${globalContextMd}
    GLOBALCTX
    fi

    # STEP 5: 足軽用タスク・レポートファイル初期化
    for i in 1 2 3 4 5 6 7 8; do
      TASK_FILE="${shogunDir}/queue/tasks/ashigaru''${i}.yaml"
      if [ ! -f "$TASK_FILE" ]; then
        cat > "$TASK_FILE" << TASK
    # 足軽''${i}専用タスクファイル
    task:
      task_id: null
      parent_cmd: null
      description: null
      target_path: null
      status: idle
      timestamp: ""
    TASK
      fi

      REPORT_FILE="${shogunDir}/queue/reports/ashigaru''${i}_report.yaml"
      if [ ! -f "$REPORT_FILE" ]; then
        cat > "$REPORT_FILE" << REPORT
    worker_id: ashigaru''${i}
    task_id: null
    timestamp: ""
    status: idle
    result: null
    REPORT
      fi
    done
  '';

  programs.zsh.shellAliases = {
    shogun = "${shogunDir}/shutsujin_departure.sh";
    css = "tmux attach-session -t shogun";
    csm = "tmux attach-session -t multiagent";
  };
}
