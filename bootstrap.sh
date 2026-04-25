#!/usr/bin/env bash
#
# bootstrap.sh
#
# 新PCでのセットアップエントリポイント。
#
# 使い方:
#   ./bootstrap.sh             # 全部(対話確認あり)
#   ./bootstrap.sh system      # 01のみ
#   ./bootstrap.sh dev         # 02のみ
#   ./bootstrap.sh terminal    # 03のみ
#   ./bootstrap.sh apps        # 04のみ
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

require_user

cat <<'EOS'

  ╭───────────────────────────────────────────╮
  │                                           │
  │   Linux Mint Development Environment      │
  │   Setup Bootstrap                         │
  │                                           │
  ╰───────────────────────────────────────────╯

EOS

TARGET="${1:-all}"

# ============================================================
# 最初に1回だけ sudo 認証 + keep-alive
# 子スクリプトでは LINUX_MINT_SETUP_SUDO_KEEPER_PID を見て二重起動しない
# ============================================================
require_mint_or_ubuntu
require_sudo

# ============================================================
# 子スクリプトを呼び出す関数
# ============================================================
run_script() {
  local script="$1"
  local name="$2"
  echo
  log "▶ $name を実行..."
  echo

  # bash で呼ぶ (環境変数を引き継ぐ)
  if ! bash "$SCRIPT_DIR/scripts/$script"; then
    err "$name が失敗しました"
    err "  個別に再実行する場合: ./scripts/$script"
    return 1
  fi

  log "✓ $name 完了"
}

# ============================================================
# 引数による分岐
# ============================================================
case "$TARGET" in
  all)
    log "全てのスクリプトを順に実行します:"
    log "  1. 01-system.sh    (日本語入力 / NumLock / Chrome)"
    log "  2. 02-dev-runtime.sh (Git / fnm / pyenv / phpenv / Composer / Claude Code)"
    log "  3. 03-terminal.sh    (WezTerm / Starship / フォント / CLI)"
    log "  4. 04-apps.sh        (Docker / VS Code / Antigravity / GitKraken / Slack / Insync)"
    echo
    log "推定所要時間: 30〜60分 (ネットワーク次第)"
    echo
    read -p "続行しますか? [y/N]: " ans
    [[ "$ans" != "y" && "$ans" != "Y" ]] && { log "中止しました"; exit 0; }

    run_script "01-system.sh"      "01: System"
    run_script "02-dev-runtime.sh" "02: Dev Runtime"
    run_script "03-terminal.sh"    "03: Terminal"
    run_script "04-apps.sh"        "04: Apps"

    cat <<'EOF'

  ╭──────────────────────────────────────────────────────╮
  │   ✨ 全スクリプト実行完了 ✨                           │
  ╰──────────────────────────────────────────────────────╯

  最終手順:

  1. 再起動 (sudo reboot)
     → docker のグループ反映 / NumLock / 日本語入力を完全有効化

  2. 言語ランタイムをインストール:
       ./scripts/install-runtimes.sh latest

     または PHP複数バージョン:
       ./scripts/install-runtimes.sh php 8.2 8.3 8.4

  3. Git ユーザー設定:
       git config --global user.name  "あなたの名前"
       git config --global user.email "you@example.com"

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
