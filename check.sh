#!/bin/bash
# 渡された PATH のまま、いまの hook の形（python で直接呼ぶ）と bin/py.sh を通す形を比べる。
set +e
echo "PATH=$PATH / bash=$BASH_VERSION"
for c in python python3; do printf '%s: ' "$c"; command -v "$c" || echo "(無い)"; done

echo "--- 1. いまの hook の形: python hooks/sample_hook.py"
echo '{"hook_event_name":"Stop"}' | /bin/sh -c 'python hooks/sample_hook.py'
echo "exit=$?"

echo "--- 2. bin/py.sh を通す形: bash bin/py.sh hooks/sample_hook.py"
echo '{"hook_event_name":"Stop"}' | /bin/sh -c 'bash bin/py.sh hooks/sample_hook.py'
echo "exit=$?"

echo "--- 3. 終了コードがそのまま返るか（7 のはず）"
bash bin/py.sh -c 'import sys; sys.exit(7)'
echo "exit=$?"

echo "--- 4. 日本語の出力"
bash bin/py.sh -c 'print("".join(chr(c) for c in (0x65e5, 0x672c, 0x8a9e)))'

echo "--- 5. 10 回動かす時間（py.sh を通す / python3 を直接）"
time (for i in 1 2 3 4 5 6 7 8 9 10; do bash bin/py.sh -c pass; done)
time (for i in 1 2 3 4 5 6 7 8 9 10; do python3 -c pass; done)
