#!/usr/bin/env bash
#
# scripts/lib/common.sh
# 全スクリプトで読み込まれる共通関数
#

# ---------- ログ出力 ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }
step() { echo -e "\n${BLUE}==>${NC} ${BLUE}$*${NC}"; }

# ---------- 設定ファイルへの追記 (重複防止) ----------
add_line_once() {
  local file="$1" marker="$2" content="$3"
  touch "$file"
  if ! grep -Fq "$marker" "$file"; then
    printf '\n%s\n' "$content" >> "$file"
    log "  $file に追記しました ($marker)"
  else
    log "  $file は設定済み (スキップ): $marker"
  fi
}

# ---------- 確認: rootで実行されていないか ----------
require_user() {
  if [[ $EUID -eq 0 ]]; then
    err "このスクリプトは root では実行しないでください"
    exit 1
  fi
}

# ---------- sudo認証 + keep-alive ----------
# 環境変数 LINUX_MINT_SETUP_SUDO_KEEPER_PID が既にあればスキップ
# (bootstrap.sh から子スクリプトを呼ぶときの二重起動を防ぐ)
require_sudo() {
  # 既に親プロセス (bootstrap.sh等) で keep-alive が動いていればスキップ
  if [[ -n "${LINUX_MINT_SETUP_SUDO_KEEPER_PID:-}" ]]; then
    if kill -0 "$LINUX_MINT_SETUP_SUDO_KEEPER_PID" 2>/dev/null; then
      log "sudo keep-alive は既に親プロセスで動作中 (PID: $LINUX_MINT_SETUP_SUDO_KEEPER_PID)"
      return 0
    fi
  fi

  # sudo 認証
  if ! sudo -v 2>/dev/null; then
    err "sudo の認証に失敗しました"
    exit 1
  fi

  # keep-alive を起動 (1回だけ)
  ( while true; do
      sudo -n true 2>/dev/null || exit
      sleep 60
      kill -0 "$$" 2>/dev/null || exit
    done ) &
  local keeper_pid=$!

  # 環境変数で子プロセスに通知
  export LINUX_MINT_SETUP_SUDO_KEEPER_PID=$keeper_pid

  # このシェル終了時に keeper を停止
  trap "kill $keeper_pid 2>/dev/null || true" EXIT

  log "sudo keep-alive を開始 (PID: $keeper_pid)"
}

# ---------- 環境チェック: Linux Mint / Ubuntuベースか ----------
require_mint_or_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    err "/etc/os-release が見つかりません"
    exit 1
  fi

  source /etc/os-release
  case "${ID:-}:${ID_LIKE:-}" in
    *ubuntu*|*debian*|*linuxmint*)
      log "OS: ${PRETTY_NAME:-不明}"
      ;;
    *)
      warn "Linux Mint / Ubuntu / Debian 系以外: ${ID}"
      read -p "  続行しますか? [y/N]: " ans
      [[ "$ans" != "y" && "$ans" != "Y" ]] && exit 1
      ;;
  esac
}

# ---------- Ubuntu の codename を返す ----------
get_ubuntu_codename() {
  local cn
  cn=$(grep -oP '(?<=^UBUNTU_CODENAME=).*' /etc/os-release 2>/dev/null || true)
  if [[ -z "$cn" ]]; then
    cn=$(lsb_release -cs 2>/dev/null || echo "")
  fi
  echo "$cn"
}

# ---------- セクション開始/終了の見出し ----------
section_start() {
  echo
  echo "=============================================="
  echo "  $1"
  echo "=============================================="
}

section_end() {
  echo
  echo "=============================================="
  log "$1 完了"
  echo "=============================================="
}
