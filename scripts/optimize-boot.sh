#!/usr/bin/env bash
#
# scripts/optimize-boot.sh
#
# 起動時間の短縮 (安全な範囲のみ、機能は失わない)
#
# 期待効果: 約 8〜10 秒 短縮
#   1. NetworkManager-wait-online を無効化  (約6秒短縮)
#   2. GRUBタイムアウトを 1秒 に             (約3秒短縮)
#   3. Cinnamon設定デーモンの自動起動を抑制  (体感速度UP)
#   4. Mint Welcomeの自動起動を停止          (微小)
#
# 使い方:
#   ./scripts/optimize-boot.sh
#
# 元に戻す方法は最後のメッセージに記載
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_user
require_sudo

section_start "起動時間の最適化"

# ============================================================
step "1/4  NetworkManager-wait-online を無効化 (約6秒短縮)"
# ============================================================
if systemctl is-enabled NetworkManager-wait-online.service &>/dev/null; then
  sudo systemctl disable NetworkManager-wait-online.service
  log "  ✓ 無効化しました"
else
  log "  既に無効化済み"
fi

# ============================================================
step "2/4  GRUBタイムアウトを短縮 (5秒→1秒, 約3秒短縮)"
# ============================================================
if [[ -f /etc/default/grub ]]; then
  CURRENT_TIMEOUT=$(grep -E "^GRUB_TIMEOUT=" /etc/default/grub | head -1 | cut -d= -f2)

  if [[ "$CURRENT_TIMEOUT" == "1" ]]; then
    log "  既に 1 秒に設定済み"
  else
    sudo cp /etc/default/grub /etc/default/grub.bak.$(date +%Y%m%d-%H%M%S)
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
    sudo update-grub > /dev/null 2>&1
    log "  ✓ タイムアウトを 1 秒に変更"
    log "    (Shiftキー長押しでGRUBメニューは引き続き表示可能)"
  fi
fi

# ============================================================
step "3/4  Cinnamon設定デーモンの自動起動を抑制 (XFCE使用時)"
# ============================================================
# XFCEで使っているのにCinnamonの自動起動が17個動いている問題
# OnlyShowIn=Cinnamon; を NotShowIn=XFCE; に変更してXFCEで起動しないようにする
DISABLED_COUNT=0
for desktop_file in /etc/xdg/autostart/cinnamon-settings-daemon-*.desktop; do
  [[ ! -f "$desktop_file" ]] && continue

  filename=$(basename "$desktop_file")
  user_override="$HOME/.config/autostart/$filename"

  if [[ ! -f "$user_override" ]]; then
    mkdir -p "$HOME/.config/autostart"
    cp "$desktop_file" "$user_override"

    # NotShowIn にXFCEを追加 (既存があれば追加)
    if grep -q "^NotShowIn=" "$user_override"; then
      sed -i 's/^NotShowIn=\(.*\)/NotShowIn=\1XFCE;/' "$user_override"
    else
      echo "NotShowIn=XFCE;" >> "$user_override"
    fi

    DISABLED_COUNT=$((DISABLED_COUNT + 1))
  fi
done
log "  ✓ Cinnamon設定デーモン $DISABLED_COUNT 個をXFCEで起動しないように設定"

# ============================================================
step "4/4  Mint Welcome の自動起動を停止"
# ============================================================
WELCOME_FILE="$HOME/.config/autostart/mintwelcome.desktop"
if [[ ! -f "$WELCOME_FILE" ]] && [[ -f /etc/xdg/autostart/mintwelcome.desktop ]]; then
  mkdir -p "$HOME/.config/autostart"
  cp /etc/xdg/autostart/mintwelcome.desktop "$WELCOME_FILE"
  echo "Hidden=true" >> "$WELCOME_FILE"
  log "  ✓ Mint Welcome を非表示に設定"
elif [[ -f "$WELCOME_FILE" ]]; then
  log "  既に設定済み"
else
  log "  Mint Welcome は無効 (スキップ)"
fi

# ============================================================
section_end "最適化完了"

cat <<'EOS'

確認方法:
  sudo reboot
  systemd-analyze        # 再起動後に短くなったか確認

期待される改善:
  起動時間が 約8〜10秒 短縮されるはずです
  (現在 23秒 → 約 13〜15秒)

オプション(さらに短縮したい場合 - 機能とのトレードオフ):

  # Docker (使う時だけ手動起動でOKなら)
  sudo systemctl disable docker.service docker.socket
  # 使う時:  sudo systemctl start docker

  # Bluetooth (使わないなら)
  sudo systemctl disable bluetooth.service blueman-mechanism.service

  # プリンタ (使わないなら)
  sudo systemctl disable cups.service cups-browsed.service

  # Warpinator (LAN内ファイル共有 - 使わないなら)
  mkdir -p ~/.config/autostart
  cp /etc/xdg/autostart/warpinator-autostart.desktop ~/.config/autostart/
  echo "Hidden=true" >> ~/.config/autostart/warpinator-autostart.desktop

元に戻したい場合:

  # 1. NetworkManager-wait-online を有効化
  sudo systemctl enable NetworkManager-wait-online.service

  # 2. GRUBタイムアウトを戻す (バックアップから)
  sudo cp /etc/default/grub.bak.* /etc/default/grub
  sudo update-grub

  # 3. Cinnamon設定デーモンの設定を戻す
  rm ~/.config/autostart/cinnamon-settings-daemon-*.desktop

  # 4. Mint Welcomeの設定を戻す
  rm ~/.config/autostart/mintwelcome.desktop

EOS
