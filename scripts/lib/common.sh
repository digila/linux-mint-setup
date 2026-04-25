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
# 使い方: add_line_once "$HOME/.bashrc" "# --- fnm ---" 'export PATH=...'
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
    err "通常ユーザーで実行してください"
    exit 1
  fi
}

# ---------- 確認: sudoが使えるか ----------
require_sudo() {
  if ! sudo -v 2>/dev/null; then
    err "sudo の認証に失敗しました"
    exit 1
  fi
  # 実行中はsudoをキープ
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPER=$!
  trap 'kill $SUDO_KEEPER 2>/dev/null || true' EXIT
}

# ---------- 環境チェック: Linux Mint / Ubuntuベースか ----------
require_mint_or_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    err "/etc/os-release が見つかりません。対応OSではありません"
    exit 1
  fi

  source /etc/os-release
  case "${ID:-}:${ID_LIKE:-}" in
    *ubuntu*|*debian*|*linuxmint*)
      log "OS: ${PRETTY_NAME:-不明}"
      ;;
    *)
      warn "Linux Mint / Ubuntu / Debian 系以外の環境です: ${ID}"
      warn "問題が発生する可能性があります"
      read -p "  続行しますか? [y/N]: " ans
      [[ "$ans" != "y" && "$ans" != "Y" ]] && exit 1
      ;;
  esac
}

# ---------- Ubuntu の codename を返す (LightDM/Docker等で使用) ----------
get_ubuntu_codename() {
  local cn
  cn=$(grep -oP '(?<=^UBUNTU_CODENAME=).*' /etc/os-release 2>/dev/null || true)
  if [[ -z "$cn" ]]; then
    cn=$(lsb_release -cs 2>/dev/null || echo "")
  fi
  echo "$cn"
}

# ---------- このリポジトリのルートを返す ----------
# scripts/01-system.sh から呼ばれた場合 → ../  に解決
repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  # scripts/lib から呼ばれている可能性も考慮
  if [[ -d "$script_dir/../scripts" ]]; then
    echo "$(cd "$script_dir/.." && pwd)"
  elif [[ -d "$script_dir/scripts" ]]; then
    echo "$script_dir"
  else
    echo "$script_dir"
  fi
}

# ---------- セクション開始の見出し (装飾) ----------
section_start() {
  local title="$1"
  echo
  echo "=============================================="
  echo "  $title"
  echo "=============================================="
}

# ---------- セクション終了の見出し ----------
section_end() {
  local title="$1"
  echo
  echo "=============================================="
  log "$title 完了"
  echo "=============================================="
}
