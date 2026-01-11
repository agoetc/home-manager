function ghq-fzf() {
    # ghq list --full-path を使用して複数rootディレクトリに対応
    local src=$(ghq list --full-path | fzf --preview "ls -laTp {} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'")
    if [ -n "$src" ]; then
        BUFFER="cd $src"
        zle accept-line
    fi
    zle -R -c
}

zle -N ghq-fzf
bindkey '^g' ghq-fzf
bindkey '^G' ghq-fzf
