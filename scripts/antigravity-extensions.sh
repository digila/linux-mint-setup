#!/usr/bin/env bash
#
# scripts/antigravity-extensions.sh
#
# Antigravity (VS Codeベース AI IDE) の拡張機能を管理
#
# 使い方:
#   ./scripts/antigravity-extensions.sh export
#       現在インストールされている拡張機能を
#       dotfiles/antigravity-extensions.txt に書き出す
#
#   ./scripts/antigravity-extensions.sh install
#       dotfiles/antigravity-extensions.txt の拡張機能を一括インストール
#       既にインストール済みのものはスキップ
#
#   ./scripts/antigravity-extensions.sh sync
#       export → git add → コミット用の差分表示
#
#   ./scripts/antigravity-extensions.sh list
#       現在インストール済みの拡張機能を一覧表示 (ID + バージョン)
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

EXTENSIONS_FILE="$REPO_ROOT/dotfiles/antigravity-extensions.txt"
COMMAND="${1:-help}"

# Antigravity が入っているか確認
if ! command -v antigravity &>/dev/null; then
  err "antigravity コマンドが見つかりません"
  err "  04-apps.sh を実行して Antigravity をインストールしてください"
  exit 1
fi

# ============================================================
# export: 現在の拡張機能を ファイル化
# ============================================================
cmd_export() {
  step "現在インストールされている拡張機能をエクスポート"

  mkdir -p "$(dirname "$EXTENSIONS_FILE")"

  # ヘッダ + 拡張機能ID一覧
  cat > "$EXTENSIONS_FILE" <<EOF
# Antigravity 拡張機能リスト
# このファイルは antigravity-extensions.sh export で自動生成されます
# 一括インストール: ./scripts/antigravity-extensions.sh install
# 最終更新: $(date '+%Y-%m-%d %H:%M:%S')

EOF

  # 拡張機能ID形式 (publisher.name) の行だけ抽出
  # ([createInstance]等の警告メッセージを除外)
  antigravity --list-extensions 2>/dev/null \
    | grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_.-]+$' \
    >> "$EXTENSIONS_FILE"

  local count
  count=$(grep -cv '^#\|^$' "$EXTENSIONS_FILE")

  log "  ✓ $count 個の拡張機能を $EXTENSIONS_FILE に書き出しました"
  echo
  log "  内容プレビュー:"
  grep -v '^#\|^$' "$EXTENSIONS_FILE" | sed 's/^/      /'
}

# ============================================================
# install: ファイルから一括インストール
# ============================================================
cmd_install() {
  step "拡張機能を一括インストール"

  if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    err "$EXTENSIONS_FILE が見つかりません"
    err "  まず別PCで以下を実行してファイルを作ってください:"
    err "    ./scripts/antigravity-extensions.sh export"
    err "    git add dotfiles/antigravity-extensions.txt"
    err "    git commit -m 'Add Antigravity extensions list'"
    err "    git push"
    exit 1
  fi

  # 現在インストール済みの拡張機能 (重複防止用)
  local installed_extensions
  installed_extensions=$(antigravity --list-extensions 2>/dev/null \
                            | grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_.-]+$' \
                            | tr '[:upper:]' '[:lower:]')

  local total=0 installed=0 skipped=0 failed=0
  local failed_list=()

  while IFS= read -r ext; do
    # コメント・空行をスキップ
    [[ -z "$ext" ]] && continue
    [[ "$ext" =~ ^[[:space:]]*# ]] && continue

    total=$((total + 1))
    local ext_lower
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    if echo "$installed_extensions" | grep -qx "$ext_lower"; then
      log "  ⊙ $ext (既にインストール済み)"
      skipped=$((skipped + 1))
    else
      echo -n "  → $ext をインストール中..."
      if antigravity --install-extension "$ext" --force >/dev/null 2>&1; then
        echo " ✓"
        installed=$((installed + 1))
      else
        echo " ✗ 失敗"
        failed=$((failed + 1))
        failed_list+=("$ext")
      fi
    fi
  done < "$EXTENSIONS_FILE"

  echo
  echo "=============================================="
  log "結果サマリ:"
  echo "  対象:         $total"
  echo "  新規インストール: $installed"
  echo "  既にあり:     $skipped"
  echo "  失敗:         $failed"

  if [[ ${#failed_list[@]} -gt 0 ]]; then
    echo
    warn "失敗した拡張機能:"
    for ext in "${failed_list[@]}"; do
      echo "  - $ext"
    done
    warn "Open VSX で配布されていない可能性があります"
    warn "  Antigravity のマーケットプレイスから手動インストールしてください"
  fi
}

# ============================================================
# sync: export してから差分を表示
# ============================================================
cmd_sync() {
  cmd_export
  echo
  step "Git 差分を確認"

  if [[ ! -d "$REPO_ROOT/.git" ]]; then
    warn "$REPO_ROOT は Git リポジトリではありません"
    return
  fi

  cd "$REPO_ROOT"
  if git diff --quiet "dotfiles/antigravity-extensions.txt" 2>/dev/null; then
    log "  変更なし"
  else
    log "  以下の差分があります:"
    git diff "dotfiles/antigravity-extensions.txt"
    echo
    log "  コミットするには:"
    log "    git add dotfiles/antigravity-extensions.txt"
    log "    git commit -m 'Update Antigravity extensions'"
    log "    git push"
  fi
}

# ============================================================
# list: 現在の拡張機能を表示
# ============================================================
cmd_list() {
  step "インストール済みの拡張機能"
  antigravity --list-extensions --show-versions
}

# ============================================================
# help
# ============================================================
cmd_help() {
  cat <<EOS
Antigravity 拡張機能管理

使い方:
  $0 export      現在の拡張機能を dotfiles/antigravity-extensions.txt に書き出し
  $0 install     ファイルから一括インストール (既にあるものはスキップ)
  $0 sync        export + Git差分表示
  $0 list        現在インストール済みを一覧表示

典型的なフロー:

  ◆ 初回のセットアップ (このPCで作業)
    ./scripts/antigravity-extensions.sh export
    git add dotfiles/antigravity-extensions.txt
    git commit -m "Add Antigravity extensions list"
    git push

  ◆ 別PCにセットアップする時
    git clone ...
    cd linux-mint-setup
    ./bootstrap.sh                                       # まず本体を入れる
    ./scripts/antigravity-extensions.sh install          # 拡張機能を流し込む

  ◆ 拡張機能を追加した後の同期
    ./scripts/antigravity-extensions.sh sync             # 差分確認
    git add -A && git commit -m "..." && git push        # コミット
EOS
}

# ============================================================
# メイン
# ============================================================
case "$COMMAND" in
  export)  cmd_export ;;
  install) cmd_install ;;
  sync)    cmd_sync ;;
  list)    cmd_list ;;
  help|--help|-h) cmd_help ;;
  *)
    err "不明なコマンド: $COMMAND"
    echo
    cmd_help
    exit 1
    ;;
esac
