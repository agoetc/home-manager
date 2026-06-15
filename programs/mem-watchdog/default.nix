{ pkgs, ... }:

# メモリ番犬: 暴走プロセスを SIGKILL して Mac 全体の道連れ(OOMハング)を防ぐ。
# macOS は cgroup も RLIMIT_AS(ulimit -v) も効かないため、launchd 常駐で代替する。
#
# 閾値の根拠(2026-06 時点、32GB機):
#   - 正規 zsh は <10MB。過去の OOM は zsh が 100〜186GB まで暴走していた(JetsamEvent物証)
#     → シェルが 8GB 超は確実に異常。誤検知ゼロでkill
#   - 正規の重量級アプリは Ableton Live ~26GB が観測最大
#     → 全プロセス共通の最終防衛は 60GB(Ableton等は安全圏、暴走 100GB+ は捕捉)
let
  watchdog = pkgs.writeShellScript "mem-watchdog" ''
    set -u
    LOG="$HOME/Library/Logs/mem-watchdog.log"
    SHELL_LIMIT_MB=8192     # シェルがこれ超え = 異常(正規は<10MB)
    GLOBAL_LIMIT_MB=61440   # どのプロセスでもこれ超え = マシン道連れ寸前(Ableton 26GB等は安全)

    note() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

    # top の MEM 列(例: 186G / 512M / 6641K)を MB(整数)へ
    to_mb() {
      local v="$1" n u
      n="''${v%[KMG+]}"; n="''${n%+}"; u="''${v: -1}"
      case "$u" in
        G) awk "BEGIN{printf \"%d\", $n*1024}" ;;
        M) awk "BEGIN{printf \"%d\", $n}" ;;
        K) awk "BEGIN{printf \"%d\", $n/1024}" ;;
        *) echo 0 ;;
      esac
    }

    /usr/bin/top -l 1 -stats pid,mem,command -o mem -n 30 2>/dev/null | \
    while read -r pid mem comm _rest; do
      [[ "$pid" =~ ^[0-9]+$ ]] || continue
      [[ "$mem" =~ ^[0-9] ]] || continue
      mb=$(to_mb "$mem")
      kill_it=0; reason=""
      case "$comm" in
        zsh|-zsh|bash|-bash|sh|dash|fish)
          if [ "$mb" -gt "$SHELL_LIMIT_MB" ]; then kill_it=1; reason="shell>''${SHELL_LIMIT_MB}MB"; fi ;;
      esac
      if [ "$mb" -gt "$GLOBAL_LIMIT_MB" ]; then kill_it=1; reason="proc>''${GLOBAL_LIMIT_MB}MB"; fi
      if [ "$kill_it" -eq 1 ]; then
        note "KILL pid=$pid comm=$comm mem=$mem (''${mb}MB) reason=$reason"
        /bin/kill -9 "$pid" 2>>"$LOG" && \
          /usr/bin/osascript -e "display notification \"killed $comm pid=$pid ($mem)\" with title \"mem-watchdog\"" >/dev/null 2>&1 || true
      fi
    done
  '';
in
{
  launchd.agents.mem-watchdog = {
    enable = true;
    config = {
      ProgramArguments = [ "${watchdog}" ];
      StartInterval = 30;          # 30秒ごとに監視
      RunAtLoad = true;
      ProcessType = "Background";
      StandardErrorPath = "/tmp/mem-watchdog.err";
      StandardOutPath = "/tmp/mem-watchdog.out";
    };
  };
}
