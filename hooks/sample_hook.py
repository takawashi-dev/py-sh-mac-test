"""hook の代わり。標準入力の JSON を読み、動いたことと、使われた Python を出す。"""
import json
import sys

data = json.load(sys.stdin)
print(f"hook が動いた: {data.get('hook_event_name')} / {sys.executable} / {sys.version.split()[0]}")
