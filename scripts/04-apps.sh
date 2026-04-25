#!/usr/bin/env bash
#
# scripts/04-apps.sh
#
# GUI アプリ + Docker:
#   - Docker Engine + Compose plugin
#   - VS Code (公式APT)
#   - Google Antigravity (AI IDE)
#   - GitKraken
#   - Slack (Flatpak)
#   - Insync (Google Drive クライアント)
#   - Mailpit (Laravel メールテスト)
#   - Flameshot (スクリーンショット)
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_user
require_mint_or_ubuntu
require_sudo

section_start "04-apps.sh: GUIアプリ + Docker"

UBU_CODENAME=$(get_ubuntu_codename)
log "Ubuntu codename: $UBU_CODENAME"

# ============================================================
step "1/8  Docker Engine + Compose"
# ============================================================
if ! command -v docker &>/dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $UBU_CODENAME stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io \
                      docker-buildx-plugin docker-compose-plugin

  sudo usermod -aG docker "$USER"
  warn "  docker グループに追加。反映には ログアウト/ログイン が必要"
else
  log "Docker は既にインストール済み: $(docker --version)"
fi

# ============================================================
step "2/8  VS Code"
# ============================================================
if ! command -v code &>/dev/null; then
  wget -qO /tmp/ms.gpg https://packages.microsoft.com/keys/microsoft.asc
  gpg --dearmor /tmp/ms.gpg
  sudo install -D -o root -g root -m 644 /tmp/ms.gpg.gpg \
    /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
  rm -f /tmp/ms.gpg /tmp/ms.gpg.gpg
  sudo apt update
  sudo apt install -y code
else
  log "VS Code は既にインストール済み"
fi

# ============================================================
step "3/8  Google Antigravity (AI IDE)"
# ============================================================
if ! command -v antigravity &>/dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
  sudo chmod a+r /etc/apt/keyrings/antigravity-repo-key.gpg

  echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
    | sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

  sudo apt update
  sudo apt install -y antigravity
else
  log "Antigravity は既にインストール済み"
fi

# ============================================================
step "4/8  GitKraken"
# ============================================================
if ! command -v gitkraken &>/dev/null; then
  TMP=$(mktemp -d)
  curl -fsSL -o "$TMP/gitkraken.deb" \
    https://release.gitkraken.com/linux/gitkraken-amd64.deb
  sudo apt install -y "$TMP/gitkraken.deb"
  rm -rf "$TMP"
else
  log "GitKraken は既にインストール済み"
fi

# ============================================================
step "5/8  Slack (Flatpak)"
# ============================================================
sudo apt install -y flatpak

if ! flatpak remotes | grep -qi '^flathub\b'; then
  sudo flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
fi

if ! flatpak list 2>/dev/null | grep -q 'com\.slack\.Slack'; then
  log "Slack をインストール (200MB程度)..."
  flatpak install -y flathub com.slack.Slack
else
  log "Slack は既にインストール済み"
fi

# ============================================================
step "6/8  Insync (Google Drive クライアント)"
# ============================================================
if ! command -v insync &>/dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xACCAF35C" \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/insync.gpg
  sudo chmod 644 /etc/apt/keyrings/insync.gpg

  echo "deb [signed-by=/etc/apt/keyrings/insync.gpg] http://apt.insync.io/ubuntu $UBU_CODENAME non-free contrib" \
    | sudo tee /etc/apt/sources.list.d/insync.list > /dev/null
  sudo chmod 644 /etc/apt/sources.list.d/insync.list

  sudo apt update
  sudo apt install -y insync

  # ⚠️ ファイラー連携プラグイン (insync-nemo / insync-thunar 等) は
  # 意図的にインストールしません。これらは Python ベースで動作し、
  # システムの PyGObject に依存するため、pyenv 等と相性が悪く
  # ファイラーやデスクトップ環境を巻き込んでクラッシュさせる
  # 既知の問題があります。
  #
  # 同期機能は本体だけで完全に動作します。右クリックメニューの
  # 「Insync で共有」等が必要な場合のみ、手動でインストールしてください:
  #   sudo apt install insync-nemo    # Cinnamon
  #   sudo apt install insync-thunar  # XFCE  (※ファイラー全般の不安定化リスクあり)
  log "  ファイラー連携プラグインはスキップしました (詳細はコメント参照)"
else
  log "Insync は既にインストール済み"
fi

# ============================================================
step "7/8  Mailpit (Laravel メールテスト)"
# ============================================================
if ! command -v mailpit &>/dev/null; then
  curl -sL https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh \
    | sudo bash
else
  log "Mailpit は既にインストール済み"
fi

# ============================================================
step "8/8  Flameshot (スクリーンショット)"
# ============================================================
sudo apt install -y flameshot

section_end "04-apps.sh"

cat <<'EOS'

【全スクリプト実行完了】 🎉

最終ステップ:
  1. 一度ログアウト → ログイン (または再起動 sudo reboot)
     → docker を sudo無しで使えるようになる
     → 日本語入力 (fcitx5) が完全に有効化
     → NumLock がログイン画面から ON

  2. ターミナルで:
       fnm install --lts          # Node.js LTS
       pyenv install 3.13.0       # Python (例)
       phpenv install 8.3.13      # PHP (例、10〜20分かかります)

  3. Insync を起動して Google アカウントでログイン
  4. Antigravity を起動して 個人 Gmail でログイン

【ヒント】各ランタイムを最新版で一括導入したい場合:
  ./scripts/install-runtimes.sh latest

EOS
