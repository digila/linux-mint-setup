#!/usr/bin/env bash
#
# scripts/fix-intel-gpu-electron-apps.sh
#
# Intel HD Graphics (Skylake/Kaby Lake) 世代のGPUドライバ不安定問題対策
#
# 症状: Antigravity / VS Code / Chrome / Slack で拡張機能インストール時等に
#      システム全体が完全フリーズする (マウスもキーボードも反応しない)
#
# 原因: Intel HD Graphics 530 等の Skylake世代GPU と新しい Mesa ドライバの
#      組み合わせで、Electronアプリの GPU加速 が使われた瞬間にカーネルごと
#      ハングする既知の問題
#
# 対策:
#   1. Electron系アプリの起動コマンドに --disable-gpu を追加
#   2. (オプション) i915ドライバのカーネルパラメータを安定化
#
# 使い方:
#   chmod +x scripts/fix-intel-gpu-electron-apps.sh
#   ./scripts/fix-intel-gpu-electron-apps.sh         # 1のみ (アプリ別対策)
#   ./scripts/fix-intel-gpu-electron-apps.sh full    # 1+2 (カーネルも対策)
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_user
MODE="${1:-app-only}"

section_start "Intel GPU 対策 (Electronアプリのフリーズ防止)"

# ============================================================
# 対策1: 各 Electron アプリのデスクトップエントリを修正
# ============================================================
USER_APPS_DIR="$HOME/.local/share/applications"
mkdir -p "$USER_APPS_DIR"

patch_desktop_file() {
  local app_name="$1"        # 表示名 (Antigravity 等)
  local desktop_file="$2"    # 元の .desktop ファイル名
  local exec_pattern="$3"    # 既存の Exec= の正規表現
  local replacement="$4"     # 置換後のExecコマンド

  step "$app_name の GPU加速を無効化"

  local src="/usr/share/applications/$desktop_file"
  local dest="$USER_APPS_DIR/$desktop_file"

  if [[ ! -f "$src" ]]; then
    warn "  $src が見つかりません (アプリ未インストール、スキップ)"
    return
  fi

  # 既にユーザー側に存在する場合はバックアップ
  if [[ -f "$dest" ]]; then
    cp "$dest" "$dest.bak.$(date +%Y%m%d-%H%M%S)"
    log "  既存のユーザー設定をバックアップ"
  fi

  # システムから user 設定にコピー
  cp "$src" "$dest"

  # Exec= 行を書き換え
  if grep -q "^Exec=$exec_pattern" "$dest"; then
    sed -i "s|^Exec=$exec_pattern|Exec=$replacement|" "$dest"
    log "  ✓ $dest を修正しました"
    log "    新しいExec: $(grep '^Exec=' "$dest" | head -1)"
  else
    warn "  Exec= の置換パターン '$exec_pattern' が見つかりませんでした"
    warn "  $dest を手動で確認してください"
  fi
}

# ---- Antigravity ----
patch_desktop_file "Antigravity" "antigravity.desktop" \
  "antigravity\(.*\)" \
  "antigravity --disable-gpu --disable-software-rasterizer\1"

# ---- Google Chrome ----
patch_desktop_file "Google Chrome" "google-chrome.desktop" \
  "/usr/bin/google-chrome-stable\(.*\)" \
  "/usr/bin/google-chrome-stable --disable-gpu\1"

# ---- VS Code ----
patch_desktop_file "VS Code" "code.desktop" \
  "/usr/share/code/code\(.*\)" \
  "/usr/share/code/code --disable-gpu\1"

# ---- VS Code URL Handler ----
patch_desktop_file "VS Code (URL Handler)" "code-url-handler.desktop" \
  "/usr/share/code/code\(.*\)" \
  "/usr/share/code/code --disable-gpu\1"

# ---- GitKraken ----
patch_desktop_file "GitKraken" "gitkraken.desktop" \
  "/usr/share/gitkraken/gitkraken\(.*\)" \
  "/usr/share/gitkraken/gitkraken --disable-gpu\1"

# Slack は Flatpak 経由なので別途対応
if flatpak list 2>/dev/null | grep -q 'com\.slack\.Slack'; then
  step "Slack (Flatpak) の GPU加速を無効化"
  flatpak override --user com.slack.Slack --command='sh' \
    --env=ELECTRON_DISABLE_GPU=1 2>/dev/null || true
  log "  ✓ Slack に環境変数 ELECTRON_DISABLE_GPU=1 を設定"
fi

# ============================================================
# 対策2: カーネルパラメータ (オプション、ハードクラッシュが続く場合)
# ============================================================
if [[ "$MODE" == "full" ]]; then
  step "カーネルパラメータ修正 (i915ドライバ安定化)"

  if grep -q "i915.enable_psr=0" /etc/default/grub 2>/dev/null; then
    log "  既に設定済み"
  else
    sudo cp /etc/default/grub /etc/default/grub.bak.$(date +%Y%m%d-%H%M%S)
    log "  /etc/default/grub をバックアップ"

    # GRUB_CMDLINE_LINUX_DEFAULT に i915 オプション追加
    sudo sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"|GRUB_CMDLINE_LINUX_DEFAULT="\1 i915.enable_psr=0 i915.enable_fbc=0"|' \
      /etc/default/grub

    log "  GRUB設定を更新:"
    grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | sed 's/^/    /'

    sudo update-grub
    warn "  カーネルパラメータの変更を反映するには再起動が必要です"
  fi
else
  log "(カーネルパラメータの修正は ./fix-intel-gpu-electron-apps.sh full でのみ実行)"
fi

# ============================================================
# 確認
# ============================================================
section_end "Intel GPU 対策"

cat <<'EOS'

修正された .desktop ファイル:
EOS
ls -la "$USER_APPS_DIR"/*.desktop 2>/dev/null | grep -v '\.bak' | awk '{print "  "$9}'

cat <<'EOS'

確認方法:

  1. メニューから (またはタスクバーから) 各アプリを起動
  2. 拡張機能インストール、長時間使用 等で フリーズが発生しないか確認

それでもフリーズする場合:

  ./scripts/fix-intel-gpu-electron-apps.sh full
  → カーネルパラメータも追加で修正 (再起動必須)

ユーザー設定の優先度:

  ~/.local/share/applications/  (このスクリプトが書き込む場所)
  > /usr/share/applications/    (システムのデフォルト)

  なので、システム側のアプリ更新で設定が上書きされることはありません。

元に戻したい場合:

  rm ~/.local/share/applications/antigravity.desktop
  rm ~/.local/share/applications/google-chrome.desktop
  # 等
EOS
