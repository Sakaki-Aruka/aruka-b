#!/usr/bin/env bash
# ローカル開発用サーバ。
# hugo.toml の baseURL は本番 (https://b.aruka.online/) を指しているが、
# `hugo server` は配信時にホスト部を localhost:<port> へ自動で書き換えるため、
# 本番設定を変えずにローカルで確認できる。
#
# 使い方:
#   ./serve.sh           # ポート 5000 で起動
#   ./serve.sh 1313      # ポートを指定
#   PORT=8080 ./serve.sh # 環境変数でも指定可
set -euo pipefail

cd "$(dirname "$0")"

PORT="${1:-${PORT:-5000}}"

# テーマはサブモジュール。未取得なら取得しておく。
if [ ! -f "themes/GitHub Style/theme.toml" ]; then
  git submodule update --init --recursive
fi

# -D: ドラフトも表示 / --bind: 同一LANの端末からも確認可
exec hugo server -D --port "$PORT" --bind 0.0.0.0
