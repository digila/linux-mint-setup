#!/usr/bin/env bash
#
# scripts/03-terminal.sh
#
# ターミナル環境:
#   - WezTerm (公式APTリポジトリ)
#   - Starship (公式インストーラ)
#   - PlemolJP (フォント全バリエーション)
#   - モダンCLIツール (ripgrep/fd/bat/eza/fzf/jq/yq/lazygit/direnv/mkcert)
#   - bashエイリアス (ls=eza, cat=bat 等)
#
# 設定ファイルは dotfiles/ から シンボリックリンク で配置するため
# リポジトリ側の編集が即座にターミナル動作に反映されます
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_user
require_mint_or_ubuntu
require_sudo

section_start "03-terminal.sh: ターミナル環境"

BASHRC="$HOME/.bashrc"
DOTFILES_DIR="$REPO_ROOT/dotfiles"

# ============================================================
step "1/6  WezTerm のインストール"
# ============================================================
if ! command -v wezterm &>/dev/null; then
  sudo install -m 0755 -d /usr/share/keyrings
  curl -fsSL https://apt.fury.io/wez/gpg.key \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg

  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
    | sudo tee /etc/apt/sources.list.d/wezterm.list > /dev/null
  sudo chmod 644 /etc/apt/sources.list.d/wezterm.list

  sudo apt update
  sudo apt install -y wezterm
else
  log "WezTerm は既にインストール済み: $(wezterm --version | head -1)"
fi

# ============================================================
step "2/6  PlemolJP フォント (全バリエーション)"
# ============================================================
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if fc-list 2>/dev/null | grep -qi "PlemolJP Console NF"; then
  log "PlemolJP Console NF は既にインストール済み"
else
  log "PlemolJP の最新リリース情報を取得..."
  RELEASE_JSON=$(curl -fsSL https://api.github.com/repos/yuru7/PlemolJP/releases/latest)
  ALL_URLS=$(echo "$RELEASE_JSON" \
    | grep -oP '"browser_download_url":\s*"\K[^"]+\.zip' | sort -u)

  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' RETURN

  i=0
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    fname=$(basename "$url")
    log "  ダウンロード: $fname"
    if curl -fsSL "$url" -o "$TMP/$fname"; then
      mkdir -p "$TMP/extract_$i"
      unzip -q -o "$TMP/$fname" -d "$TMP/extract_$i" 2>/dev/null || true
      i=$((i + 1))
    fi
  done <<< "$ALL_URLS"

  find "$TMP" -type f \( -name "*.ttf" -o -name "*.otf" \) \
    -exec cp {} "$FONT_DIR/" \;
  fc-cache -f "$FONT_DIR"
  log "  PlemolJP インストール完了"
  trap - RETURN
fi

# ============================================================
step "3/6  Starship のインストール"
# ============================================================
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
else
  log "Starship は既にインストール済み: $(starship --version | head -1)"
fi

add_line_once "$BASHRC" "# --- starship ---" '# --- starship ---
eval "$(starship init bash)"'

# ============================================================
step "4/6  モダン CLI ツール"
# ============================================================
sudo apt install -y \
  ripgrep fd-find bat fzf jq \
  direnv shellcheck tmux htop tree \
  unzip zip xclip

mkdir -p "$HOME/.local/bin"
[[ -x /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
[[ -x /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"

# eza
if ! command -v eza &>/dev/null; then
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update && sudo apt install -y eza
else
  log "eza は既にインストール済み"
fi

# yq
if ! command -v yq &>/dev/null; then
  YQ_VER=$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest \
            | grep -oP '"tag_name":\s*"\K[^"]+' || echo "v4.44.3")
  sudo wget -qO /usr/local/bin/yq \
    "https://github.com/mikefarah/yq/releases/download/${YQ_VER}/yq_linux_amd64"
  sudo chmod +x /usr/local/bin/yq
fi

# lazygit
if ! command -v lazygit &>/dev/null; then
  LG_VER=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
            | grep -oP '"tag_name":\s*"v\K[^"]+' || echo "0.44.1")
  TMP=$(mktemp -d)
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz" \
    -o "$TMP/lg.tar.gz"
  tar -C "$TMP" -xzf "$TMP/lg.tar.gz" lazygit
  sudo install -m 755 "$TMP/lazygit" /usr/local/bin/lazygit
  rm -rf "$TMP"
fi

# mkcert (ローカルHTTPS用)
sudo apt install -y libnss3-tools
if ! command -v mkcert &>/dev/null; then
  MK_VER=$(curl -fsSL https://api.github.com/repos/FiloSottile/mkcert/releases/latest \
            | grep -oP '"tag_name":\s*"v\K[^"]+' || echo "1.4.4")
  sudo wget -qO /usr/local/bin/mkcert \
    "https://github.com/FiloSottile/mkcert/releases/download/v${MK_VER}/mkcert-v${MK_VER}-linux-amd64"
  sudo chmod +x /usr/local/bin/mkcert
fi

# direnv フック
add_line_once "$BASHRC" "# --- direnv ---" '# --- direnv ---
eval "$(direnv hook bash)"'

# ============================================================
step "5/6  bash エイリアス + OSC 7 (cwd通知)"
# ============================================================
add_line_once "$BASHRC" "# --- aliases ---" '# --- aliases ---
alias ls="eza --group-directories-first"
alias ll="eza -lah --group-directories-first --git"
alias la="eza -a"
alias lt="eza --tree --level=2"
alias cat="bat --paging=never"
alias g="git"
alias lg="lazygit"
alias dc="docker compose"
alias dps="docker ps --format '"'"'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"'"'"
[[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]] && source /usr/share/doc/fzf/examples/key-bindings.bash
[[ -f /usr/share/bash-completion/completions/fzf     ]] && source /usr/share/bash-completion/completions/fzf
export PATH="$HOME/.local/bin:$PATH"'

# OSC 7 (WezTermにcwdを通知 → タブタイトル表示 + ペイン分割で同じcwd)
add_line_once "$BASHRC" "# --- OSC 7 ---" '# --- OSC 7 (wezterm cwd) ---
__osc7_cwd() {
  local strlen=${#PWD}
  local encoded="" pos c o
  for (( pos=0; pos<strlen; pos++ )); do
    c=${PWD:$pos:1}
    case "$c" in
      [-/.:_~A-Za-z0-9]) o="$c" ;;
      *) printf -v o '"'"'%%%02X'"'"' "'"'"'$c"
    esac
    encoded+="$o"
  done
  printf "\e]7;file://%s%s\e\\" "$HOSTNAME" "$encoded"
}
case "$PROMPT_COMMAND" in
  *__osc7_cwd*) ;;
  "") PROMPT_COMMAND="__osc7_cwd" ;;
  *) PROMPT_COMMAND="__osc7_cwd;${PROMPT_COMMAND}" ;;
esac'

# ============================================================
step "6/6  dotfiles をシンボリックリンクで配置"
# ============================================================
link_dotfile() {
  local src="$1" dest="$2"
  local dest_dir
  dest_dir=$(dirname "$dest")
  mkdir -p "$dest_dir"

  if [[ -L "$dest" ]]; then
    if [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
      log "  $dest はリンク済み"
      return
    fi
  fi

  if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
    local backup="$dest.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$backup"
    warn "  既存ファイルを $backup にバックアップ"
  fi

  ln -sfn "$src" "$dest"
  log "  シンボリックリンク作成: $dest -> $src"
}

link_dotfile "$DOTFILES_DIR/wezterm.lua"   "$HOME/.config/wezterm/wezterm.lua"
link_dotfile "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

section_end "03-terminal.sh"

cat <<'EOS'

【次のステップ】
  source ~/.bashrc       # PATH と エイリアス を反映
  wezterm                # WezTerm 起動
  ./scripts/04-apps.sh   # GUIアプリをインストール

【便利な使い方】
  - dotfiles/wezterm.lua を編集すると、保存と同時にWezTermが自動で
    設定を再読込します (リンクなので即時反映)。
  - 設定変更後は git commit して、別PCでは git pull するだけ。

EOS
