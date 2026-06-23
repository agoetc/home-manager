#!/usr/bin/env bash
# Stop hook: ツール呼び出しがアシスタントの「テキスト」に化けて出力され、
# 実行されないまま終了した事故を検知し、stop を block して呼び直させる。
#
# 守備範囲はこの「実行されなかった取りこぼし」の回収だけ。トークン漏れの予防や、
# ツールが発火済みのノイズ（例: 先頭に紛れる無関係トークン）は対象外。
#
# 安全側設計: 検知以外のあらゆる経路・エラーは exit 0（クリーンなターンを誤って
# 止めない）。検知時のみ block JSON を出力する。

input="$(cat)"

get() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

# 無限ループ防止: 直前の stop が既にこの hook 由来の継続なら、もう block しない。
[ "$(get '.stop_hook_active // false')" = "true" ] && exit 0

transcript="$(get '.transcript_path // empty')"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

# 最終アシスタントメッセージの text を取り出す。
last_text="$(jq -rs '
  [ .[] | select(.type == "assistant" and (.message.content? != null)) ] as $a
  | ($a | length) as $n
  | if $n == 0 then empty
    else ($a[$n - 1].message.content[]? | select(.type == "text") | .text)
    end
' "$transcript" 2>/dev/null)"
[ -n "$last_text" ] || exit 0

# コードフェンス(```...```)とインラインコード(`...`)を除去。
# ツールXMLを「正当に議論・引用」する場合はバッククォートで囲う運用なので、
# それらは誤検知させない。裸で落ちている呼び出しだけを残す。
stripped="$(printf '%s' "$last_text" | perl -0777 -pe 's/```.*?```//gs; s/`[^`]*`//g' 2>/dev/null)"
[ -n "$stripped" ] || exit 0

# 未実行のツール呼び出しは、プレーンテキスト中に裸の <invoke name=...> として現れる。
if printf '%s' "$stripped" | grep -Eq '<[[:space:]]*(antml:)?invoke[[:space:]]+name='; then
  printf '%s\n' '{"decision":"block","reason":"直前のメッセージにツール呼び出しXML(<invoke ...>)がテキストとして出力され、実行されませんでした。その出力は無効です。意図したツールを今すぐ正規のツール呼び出しとして実行し直してください(説明テキストは不要、ツール呼び出しのみ)。"}'
fi
exit 0
