#!/usr/bin/env bash
#
# bootstrap.sh
#
# 新PCでのセットアップエントリポイント。
# クローン後にこれ1つ実行すれば全部入ります。
#
# 使い方:
#   git clone git@github.com:YOUR_USERNAME/linux-mint-setup.git ~/linux-mint-setup
#   cd ~/linux-mint-setup
#   ./bootstrap.sh
#
# 個別実行:
#   ./bootstrap.sh system     # 01のみ
#   ./bootstrap.sh dev        # 02のみ
#   ./bootstrap.sh terminal   # 03のみ
#   ./bootstrap.sh apps       # 04のみ
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

require_user

# ============================================================
# Banner
# ============================================================
cat <<'EOS'

  ╭───────────────────────────────────────────╮
  │                                           │
  │   Linux Mint Development Environment      │
  │   Setup Bootstrap                         │
  │                                           │
  ╰───────────────────────────────────────────╯

EOS

# ============================================================
# 引数による分岐
# ============================================================
TARGET="${1:-all}"

run_script() {
  local script="$1"
  local name="$2"
  echo
  log "▶ $name を実行..."
  echo
  bash "$SCRIPT_DIR/scripts/$script"
}

case "$TARGET" in
  all)
    log "全てのスクリプトを順に実行します"
    log "  1. 01-system.sh    (日本語入力 / NumLock / Chrome)"
    log "  2. 02-dev-runtime.sh (Git / fnm / pyenv / phpenv / Composer / Claude Code)"
    log "  3. 03-terminal.sh    (WezTerm / Starship / フォント / CLI)"
    log "  4. 04-apps.sh        (Docker / VS Code / Antigravity / GitKraken / Slack / Insync)"
    echo
    read -p "続行しますか? [y/N]: " ans
    [[ "$ans" != "y" && "$ans" != "Y" ]] && { log "中止しました"; exit 0; }

    run_script "01-system.sh"      "01: System"
    run_script "02-dev-runtime.sh" "02: Dev Runtime"
    run_script "03-terminal.sh"    "03: Terminal"
    run_script "04-apps.sh"        "04: Apps"

    cat <<'EOF'

  ╭──────────────────────────────────────────────────────╮
  │                                                      │
  │   ✨ 全スクリプト実行完了 ✨                           │
  │                                                      │
  ╰──────────────────────────────────────────────────────╯

  最終手順:

  1. 再起動 (sudo reboot)
     → docker のグループ反映 / NumLock / 日本語入力を完全有効化

  2. ターミナルで言語ランタイムをインストール:
       ./scripts/install-runtimes.sh latest

     または PHP複数バージョン:
       ./scripts/install-runtimes.sh php 8.2 8.3 8.4

  3. Git ユーザー設定 (まだなら):
       git config --global user.name  "あなたの名前"
       git config --global user.email "you@example.com"

  4. アプリの初期セットアップ:
     - Insync:      Google アカウントでログイン
     - Antigravity: 個人 Gmail でログイン
     - GitKraken:   GitHub と連携
     - Slack:       ワークスペースに参加
     - Claude Code: cd プロジェクト/ && claude

EOF
    ;;

  system)   run_script "01-system.sh"      "01: System" ;;
  dev)      run_script "02-dev-runtime.sh" "02: Dev Runtime" ;;
  terminal) run_script "03-terminal.sh"    "03: Terminal" ;;
  apps)     run_script "04-apps.sh"        "04: Apps" ;;

  *)
    err "不明なターゲット: $TARGET"
    err "  使えるターゲット: all (デフォルト), system, dev, terminal, apps"
    exit 1
    ;;
esac
