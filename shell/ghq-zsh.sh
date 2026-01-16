function ghq-fzf() {
    # 表示: ghq list (プロジェクト名), 値: ghq list --full-path (フルパス)
    local src=$(paste <(ghq list) <(ghq list --full-path) | \
        fzf --with-nth 1 --delimiter '\t' \
            --preview "ls -laTp {2} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'" | \
        cut -f2)
    if [ -n "$src" ]; then
        BUFFER="cd $src"
        zle accept-line
    fi
    zle -R -c
}

zle -N ghq-fzf
bindkey '^g' ghq-fzf
bindkey '^G' ghq-fzf
