# py-sh-mac-test

macOS での動きを確かめるためのリポジトリ。public なので、GitHub の macOS のランナーを無料で使える。秘密の値や社内の情報は置かない。

いま確かめていること:

- `bin/py.sh`（動く Python 3 を探して実行するラッパー）が、macOS の標準の bash 3.2 で動くか
- `python` で直接呼ぶ形が、macOS の標準の PATH（`/usr/bin:/bin`）と Homebrew を足した PATH で失敗するか
- `bin/py.sh` を通したときに増える時間（キャッシュ無しの 1 回目と、キャッシュありのとき）

push すると `.github/workflows/mac.yml` が macOS 14 と 15 で `check.sh` を動かす。
