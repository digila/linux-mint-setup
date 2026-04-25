#!/usr/bin/env bash
#
# scripts/01-system.sh
#
# システム基本設定:
#   - 日本語入力 (fcitx5 + mozc, Mac風キーバインド)
#   - NumLock 起動時 ON
#   - Google Chrome (デフォルトブラウザに設定)
#
# 使い方:
#   ./scripts/01-system.sh
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_user
require_mint_or_ubuntu
require_sudo

section_start "01-system.sh: システム基本設定"

PROFILE="$HOME/.profile"

# ============================================================
step "1/4  システム更新"
# ============================================================
sudo apt update
sudo apt install -y curl wget gnupg ca-certificates lsb-release

# ============================================================
step "2/4  日本語入力 (fcitx5 + mozc, Mac風キーバインド)"
# ============================================================
# 既存のibus-mozcと競合する場合は削除
if dpkg -l 2>/dev/null | grep -qE '^ii\s+ibus-mozc'; then
  warn "ibus-mozc を削除します (fcitx5 と競合するため)"
  sudo apt remove -y ibus-mozc || true
fi

sudo apt install -y fcitx5 fcitx5-mozc fcitx5-configtool mozc-utils-gui

# 入力メソッドを fcitx5 に切替
if command -v im-config &>/dev/null; then
  im-config -n fcitx5 >/dev/null 2>&1 || true
fi

# 環境変数
add_line_once "$PROFILE" "# --- fcitx5 ---" '# --- fcitx5 ---
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx'

# 自動起動
mkdir -p "$HOME/.config/autostart"
if [[ ! -f "$HOME/.config/autostart/fcitx5.desktop" ]] \
   && [[ -f /usr/share/applications/org.fcitx.Fcitx5.desktop ]]; then
  cp /usr/share/applications/org.fcitx.Fcitx5.desktop "$HOME/.config/autostart/fcitx5.desktop"
  log "  fcitx5 を自動起動に登録しました"
fi

# Mac風キーバインド (かなでON / 英数でOFF)
FCITX_CONFIG_DIR="$HOME/.config/fcitx5"
FCITX_CONFIG="$FCITX_CONFIG_DIR/config"
mkdir -p "$FCITX_CONFIG_DIR"

if [[ -f "$FCITX_CONFIG" ]]; then
  cp "$FCITX_CONFIG" "$FCITX_CONFIG.bak.$(date +%Y%m%d-%H%M%S)"
fi

cat > "$FCITX_CONFIG" <<'INI'
[Hotkey]
EnumerateWithTriggerKeys=True
EnumerateSkipFirst=False

[Hotkey/ActivateKeys]
0=Hiragana_Katakana
1=Henkan

[Hotkey/DeactivateKeys]
0=Eisu_toggle
1=Muhenkan

[Hotkey/TriggerKeys]
0=Zenkaku_Hankaku
1=Control+space

[Hotkey/AltTriggerKeys]
0=

[Hotkey/EnumerateGroupForwardKeys]
0=Super+space

[Hotkey/EnumerateGroupBackwardKeys]
0=Shift+Super+space

[Hotkey/PrevPage]
0=Up

[Hotkey/NextPage]
0=Down

[Hotkey/PrevCandidate]
0=Shift+Tab

[Hotkey/NextCandidate]
0=Tab
INI
log "  Mac風キーバインドを設定 (かな=ON / 英数=OFF)"

# 即時反映
if pgrep -x fcitx5 >/dev/null && command -v fcitx5-remote &>/dev/null; then
  fcitx5-remote -r 2>/dev/null && log "  fcitx5 設定を再読み込み"
fi

# ============================================================
step "3/4  NumLock 起動時 ON"
# ============================================================
sudo apt install -y numlockx kbd

# LightDM 設定 (ログイン画面用)
sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/50-numlock.conf >/dev/null <<'EOF'
[Seat:*]
greeter-setup-script=/usr/bin/numlockx on
EOF

# systemd サービス (DM非依存の最終手段)
sudo tee /etc/systemd/system/numlock-on.service >/dev/null <<'EOF'
[Unit]
Description=Enable NumLock on all virtual consoles
DefaultDependencies=no
After=systemd-vconsole-setup.service
Before=display-manager.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'for tty in /dev/tty{1,2,3,4,5,6}; do /usr/bin/setleds -D +num < $tty 2>/dev/null || true; done'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable numlock-on.service
log "  systemd numlock-on.service を有効化"

# Cinnamon dconf
if command -v dconf &>/dev/null; then
  dconf write /org/cinnamon/desktop/peripherals/keyboard/numlock-state "true" 2>/dev/null || true
fi

# ~/.xprofile (X11セッション開始時の保険)
add_line_once "$HOME/.xprofile" "# Auto-enable NumLock" '# Auto-enable NumLock at X session start
[ -x /usr/bin/numlockx ] && /usr/bin/numlockx on'

# 現在のセッションでもON
[[ -n "${DISPLAY:-}" ]] && numlockx on 2>/dev/null || true

# ============================================================
step "4/4  Google Chrome のインストール + デフォルト設定"
# ============================================================
if ! command -v google-chrome &>/dev/null && ! command -v google-chrome-stable &>/dev/null; then
  TMP=$(mktemp -d)
  log "Chrome をダウンロード..."
  curl -fsSL -o "$TMP/chrome.deb" \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y "$TMP/chrome.deb"
  rm -rf "$TMP"
else
  log "Chrome は既にインストール済み"
fi

# デフォルトブラウザに設定
if [[ -f /usr/share/applications/google-chrome.desktop ]]; then
  xdg-settings set default-web-browser google-chrome.desktop
  xdg-mime default google-chrome.desktop x-scheme-handler/http
  xdg-mime default google-chrome.desktop x-scheme-handler/https
  xdg-mime default google-chrome.desktop text/html
  log "  Chrome をデフォルトブラウザに設定"
fi

section_end "01-system.sh"

cat <<'EOS'

【次のステップ】
  ./scripts/02-dev-runtime.sh   # 開発環境を構築

【注意】
  日本語入力と NumLock を完全反映するには 一度ログアウト/ログイン
  または再起動が必要です。後続スクリプトを先に実行してから最後に
  まとめて再起動するのが効率的です。

EOS
