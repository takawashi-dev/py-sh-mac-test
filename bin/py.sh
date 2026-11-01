#!/usr/bin/env bash
# bin/py.sh — Python 3 finder + invoker (= "python3" / "python" の有無が OS で違うことへの wrapper)
#
# Purpose:
#   Windows (python.org installer) には `python` と `py` はあるが `python3` が無く、
#   `python3` は Microsoft Store を開くだけの入口 (= 実行すると失敗する) になっている。
#   Mac は `python3` はあるが `python` はふつう無い。
#   スキルが `python` / `python3` を直書きすると どちらかの OS で止まるため、
#   本 wrapper が 動く Python 3 を探し、見つけたもので残り argv を exec する。
#
#   各 candidate は 実際に動いて Python 3 であることを確かめてから使う
#   (= Store の入口と Python 2 を飛ばす)。
#
# Usage:
#   bash bin/py.sh bin/memory-search.py 語
#   bash bin/py.sh -m pytest tests/x.py -q
#
# Exit codes:
#   - python 自身の exit code (= Python 3 found + invoked された場合)
#   - 127 (= Python 3 not found in any candidate)
#
# Environment:
#   PYTHONUTF8 が未設定なら 1 にする (= Windows Git Bash で日本語出力が cp932 になり文字化けするのを防ぐ)。
#   PD_FORGE_PY_CACHE: 見つけた Python を覚えるファイル (既定 ~/.cache/pd-forge/py-sh.tsv)。
#
# Cache:
#   見つけた Python の実行ファイルの場所を、そのときの PATH と組にして覚える。次から同じ PATH なら
#   確かめずにそのまま使う (= Windows では確かめるだけで 1 回 0.1 秒以上かかる。hook から呼ぶため)。
#   PATH が変わったら (= venv など) 探し直す。覚えるのは新しい 10 組まで。
#
# Adding new candidate:
#   下記 CANDIDATES に追加する。"py" だけは `-3` を付けて呼ぶ。
set -e

shopt -s nullglob

export PYTHONUTF8="${PYTHONUTF8:-1}"
CACHE="${PD_FORGE_PY_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/pd-forge/py-sh.tsv}"

# 前回、同じ PATH で見つけた Python があれば、それを使う。
# exec はループの外で行う (= ループの中だと標準入力がキャッシュのファイルになり、hook が JSON を読めない)
found=""
if [ -r "$CACHE" ]; then
    while IFS=$'\t' read -r exe path; do
        if [ "$path" = "$PATH" ] && [ -x "$exe" ]; then found="$exe"; break; fi
    done < "$CACHE"
fi
[ -n "$found" ] && exec "$found" "$@"

# 試す順。Windows (= Git Bash) は python.org の Python に python3 が無く、python3 が Store の入口なので python を先にする
case "${OSTYPE:-}" in
    msys*|cygwin*|win32*) CANDIDATES=("python" "py" "python3") ;;
    *)                    CANDIDATES=("python3" "python" "py") ;;
esac
# Windows python.org installer (= 新しい版を先に)
_win=()
for p in "${LOCALAPPDATA:-}"/Programs/Python/Python3*/python.exe "/c/Program Files/Python3"*/python.exe; do
    _win+=("$p")
done
if [ "${#_win[@]}" -gt 0 ]; then
    # 版番号の降順 (= sort -V -r)
    while IFS= read -r p; do CANDIDATES+=("$p"); done < <(printf '%s\n' "${_win[@]}" | sort -V -r)
fi
CANDIDATES+=(
    "/opt/homebrew/bin/python3"                                  # Mac homebrew (Apple Silicon)
    "/usr/local/bin/python3"                                     # Mac/Linux 一般
    "/usr/bin/python3"                                           # Linux apt / Mac system
)

# 動いて Python 3 なら、実行ファイルの場所を出す (= Store の入口と Python 2 は失敗する)
PROBE='import sys; print(sys.executable) if sys.version_info[0] == 3 else sys.exit(1)'

for c in "${CANDIDATES[@]}"; do
    if [[ "$c" != */* ]]; then
        command -v "$c" >/dev/null 2>&1 || continue
    else
        [ -x "$c" ] || continue
    fi
    flag=()
    [ "$c" = "py" ] && flag=(-3)
    if exe="$("$c" "${flag[@]}" -c "$PROBE" 2>/dev/null)"; then
        exe="${exe%$'\r'}"
        case "${OSTYPE:-}" in
            msys*|cygwin*|win32*) command -v cygpath >/dev/null 2>&1 && exe="$(cygpath -u "$exe")" ;;
        esac
        if [ -n "$exe" ] && [ -x "$exe" ]; then
            # 覚える (= 新しい組を先頭に、古い組は 9 つまで。書けなくても止めない)
            { mkdir -p "${CACHE%/*}" \
                && { printf '%s\t%s\n' "$exe" "$PATH"; if [ -r "$CACHE" ]; then head -n 9 "$CACHE"; fi; } > "$CACHE.$$" \
                && mv -f "$CACHE.$$" "$CACHE"; } 2>/dev/null || rm -f "$CACHE.$$" 2>/dev/null || true
            exec "$exe" "$@"
        fi
        exec "$c" "${flag[@]}" "$@"
    fi
done

echo "py.sh: Python 3 が見つからない（試したもの: ${CANDIDATES[*]}）" >&2
exit 127
