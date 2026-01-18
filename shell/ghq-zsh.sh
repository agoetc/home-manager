function ghq-fzf() {
    # ghq list -p でフルパスを取得し、basename で表示名を作る
    local src=$(ghq list -p | \
        awk -F/ '{print $NF "\t" $0}' | \
        fzf --with-nth 1 --delimiter '\t' \
            --preview "eza -1 --color=always {2}" | \
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
