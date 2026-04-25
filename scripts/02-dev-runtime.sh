#!/usr/bin/env bash
#
# scripts/02-dev-runtime.sh
#
# 開発ランタイム:
#   - Git (グローバル設定込み)
#   - Node.js (fnm)
#   - Python (pyenv)
#   - PHP (phpenv + php-build) + Composer
#   - Claude Code (ネイティブインストーラ)
#
# ランタイム本体は別途インストール:
#   ./scripts/install-runtimes.sh latest          # 各最新版
#   ./scripts/install-runtimes.sh php 8.2 8.3 8.4 # PHP複数バージョン
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_user
require_mint_or_ubuntu
require_sudo

section_start "02-dev-runtime.sh: 開発ランタイム"

BASHRC="$HOME/.bashrc"

# ============================================================
step "1/6  ビルド依存関係 (PHP/Python のビルドに必要)"
# ============================================================
sudo apt update
sudo apt install -y \
  build-essential curl wget git ca-certificates gnupg lsb-release \
  pkg-config autoconf bison re2c \
  unzip zip xz-utils \
  libssl-dev libreadline-dev zlib1g-dev libbz2-dev \
  libsqlite3-dev libncurses-dev libffi-dev liblzma-dev tk-dev \
  libxml2-dev libxslt1-dev libonig-dev libzip-dev \
  libcurl4-openssl-dev libicu-dev libsodium-dev libargon2-dev \
  libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev \
  libgd-dev libedit-dev libtidy-dev libpq-dev libmagickwand-dev

# ============================================================
step "2/6  Git の基本設定"
# ============================================================
log "Git バージョン: $(git --version)"

git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.autocrlf input
git config --global core.quotepath false   # 日本語ファイル名の文字化け防止

if [[ -z "$(git config --global user.name  || true)" ]] \
|| [[ -z "$(git config --global user.email || true)" ]]; then
  warn "Git の user.name / user.email が未設定です:"
  echo '      git config --global user.name  "あなたの名前"'
  echo '      git config --global user.email "you@example.com"'
fi

# ============================================================
step "3/6  Node.js: fnm"
# ============================================================
if ! command -v fnm &>/dev/null && [[ ! -x "$HOME/.local/share/fnm/fnm" ]]; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
else
  log "fnm は既にインストール済み"
fi

add_line_once "$BASHRC" "# --- fnm ---" '# --- fnm ---
export PATH="$HOME/.local/share/fnm:$PATH"
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell bash)"
fi'

# ============================================================
step "4/6  Python: pyenv"
# ============================================================
if [[ ! -d "$HOME/.pyenv" ]]; then
  curl -fsSL https://pyenv.run | bash
else
  log "pyenv は既にインストール済み (更新します)"
  git -C "$HOME/.pyenv" pull --ff-only 2>/dev/null || true
fi

add_line_once "$BASHRC" "# --- pyenv ---" '# --- pyenv ---
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - bash)"
  eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
fi'

# ============================================================
step "5/6  PHP: phpenv + php-build + Composer"
# ============================================================
if [[ ! -d "$HOME/.phpenv" ]]; then
  git clone --depth 1 https://github.com/phpenv/phpenv.git "$HOME/.phpenv"
else
  log "phpenv は既にインストール済み (更新します)"
  git -C "$HOME/.phpenv" pull --ff-only 2>/dev/null || true
fi

mkdir -p "$HOME/.phpenv/plugins"
if [[ ! -d "$HOME/.phpenv/plugins/php-build" ]]; then
  git clone --depth 1 https://github.com/php-build/php-build.git \
    "$HOME/.phpenv/plugins/php-build"
else
  log "php-build は既にインストール済み (更新します)"
  git -C "$HOME/.phpenv/plugins/php-build" pull --ff-only 2>/dev/null || true
fi

add_line_once "$BASHRC" "# --- phpenv ---" '# --- phpenv ---
export PHPENV_ROOT="$HOME/.phpenv"
[[ -d "$PHPENV_ROOT/bin" ]] && export PATH="$PHPENV_ROOT/bin:$PATH"
if command -v phpenv >/dev/null 2>&1; then
  eval "$(phpenv init - bash)"
fi'

# Composer
if ! command -v composer &>/dev/null; then
  log "Composer をインストール..."
  sudo apt install -y php-cli php-mbstring php-xml php-zip
  EXPECTED_SIG="$(wget -q -O - https://composer.github.io/installer.sig)"
  php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
  ACTUAL_SIG="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"
  if [[ "$EXPECTED_SIG" != "$ACTUAL_SIG" ]]; then
    err "Composer インストーラの署名が一致しません。中止"
    rm -f /tmp/composer-setup.php
    exit 1
  fi
  sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm -f /tmp/composer-setup.php
else
  log "Composer は既にインストール済み"
fi

# ============================================================
step "6/6  Claude Code (ネイティブインストーラ)"
# ============================================================
if ! command -v claude &>/dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
  curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code のインストールに失敗"
else
  log "Claude Code は既にインストール済み"
fi

add_line_once "$BASHRC" "# --- claude code ---" '# --- claude code ---
export PATH="$HOME/.local/bin:$PATH"'

section_end "02-dev-runtime.sh"

cat <<'EOS'

【次のステップ】
  source ~/.bashrc                      # PATHを反映
  ./scripts/install-runtimes.sh latest  # Node/Python/PHPの最新版を入れる
  ./scripts/03-terminal.sh              # ターミナル環境を構築

EOS
