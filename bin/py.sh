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
#
# Adding new candidate:
#   下記 CANDIDATES array に追加する。"py" だけは `-3` を付けて呼ぶ。
set -e

shopt -s nullglob

# Candidate python executables (priority order)
CANDIDATES=(
    "python3"                                                    # PATH-resolved (= Mac/Linux 大多数)
    "python"                                                     # PATH-resolved (= Windows python.org installer)
    "py"                                                         # Windows py launcher (= `-3` を付けて呼ぶ)
)
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

export PYTHONUTF8="${PYTHONUTF8:-1}"

CHECK='import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)'

for c in "${CANDIDATES[@]}"; do
    if [[ "$c" != */* ]]; then
        command -v "$c" >/dev/null 2>&1 || continue
    else
        [ -x "$c" ] || continue
    fi
    if [ "$c" = "py" ]; then
        if "$c" -3 -c "$CHECK" >/dev/null 2>&1; then
            exec "$c" -3 "$@"
        fi
    else
        if "$c" -c "$CHECK" >/dev/null 2>&1; then
            exec "$c" "$@"
        fi
    fi
done

echo "py.sh: Python 3 が見つからない（試したもの: ${CANDIDATES[*]}）" >&2
exit 127
