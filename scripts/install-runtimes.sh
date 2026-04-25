#!/usr/bin/env bash
#
# scripts/install-runtimes.sh
#
# 各ランタイムを最新版または指定バージョンでインストール
#
# 使い方:
#   ./scripts/install-runtimes.sh latest
#       Node.js 最新LTS / Python 最新安定 / PHP 最新安定 を一括インストール
#
#   ./scripts/install-runtimes.sh node latest
#   ./scripts/install-runtimes.sh node 22 20
#       Node.js のみ
#
#   ./scripts/install-runtimes.sh python latest
#   ./scripts/install-runtimes.sh python 3.12.7 3.11.9
#       Python のみ
#
#   ./scripts/install-runtimes.sh php latest
#   ./scripts/install-runtimes.sh php 8.2 8.3 8.4
#   ./scripts/install-runtimes.sh php 8.2.25 8.3.13
#       PHP のみ (拡張: Xdebug + Redis + Imagick も自動インストール)
#

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ---- バージョン管理ツールを有効化 ----
export PATH="$HOME/.local/share/fnm:$HOME/.pyenv/bin:$HOME/.phpenv/bin:$PATH"
command -v fnm    >/dev/null 2>&1 && eval "$(fnm env --shell bash)"
command -v pyenv  >/dev/null 2>&1 && eval "$(pyenv init - bash)"
command -v phpenv >/dev/null 2>&1 && eval "$(phpenv init - bash)"

JOBS=$(nproc)

# ============================================================
# 引数処理
# ============================================================
TARGET="${1:-}"
shift || true

if [[ -z "$TARGET" ]]; then
  cat <<EOS
使い方:
  $0 latest                  # Node + Python + PHP の最新を一括
  $0 node latest             # Node の最新LTS
  $0 node 22 20              # Node の特定バージョン (複数指定可)
  $0 python latest
  $0 python 3.12.7
  $0 php latest
  $0 php 8.2 8.3 8.4         # PHPは複数指定推奨 (Xdebug+Redis+Imagick自動)
EOS
  exit 1
fi

# ============================================================
# Node.js インストール (fnm)
# ============================================================
install_node() {
  local versions=("$@")
  step "Node.js (fnm)"

  if ! command -v fnm &>/dev/null; then
    err "fnm が見つかりません。02-dev-runtime.sh を先に実行してください"
    return 1
  fi

  if [[ "${versions[0]:-}" == "latest" ]] || [[ ${#versions[@]} -eq 0 ]]; then
    log "Node.js 最新 LTS をインストール..."
    fnm install --lts
    fnm default lts-latest
    log "  Node $(fnm exec --using=lts-latest node --version) を default に設定"
  else
    for v in "${versions[@]}"; do
      log "Node.js $v をインストール..."
      fnm install "$v"
    done
    fnm default "${versions[-1]}"
  fi
}

# ============================================================
# Python インストール (pyenv)
# ============================================================
install_python() {
  local versions=("$@")
  step "Python (pyenv)"

  if ! command -v pyenv &>/dev/null; then
    err "pyenv が見つかりません。02-dev-runtime.sh を先に実行してください"
    return 1
  fi

  log "pyenv を最新化..."
  git -C "$HOME/.pyenv" pull --ff-only 2>/dev/null || true

  if [[ "${versions[0]:-}" == "latest" ]] || [[ ${#versions[@]} -eq 0 ]]; then
    local latest
    latest=$(pyenv install --list \
      | grep -E '^[[:space:]]+3\.[0-9]+\.[0-9]+$' \
      | sort -V | tail -1 | xargs)
    versions=("$latest")
    log "最新安定版を検出: Python $latest"
  fi

  for v in "${versions[@]}"; do
    if pyenv versions --bare | grep -qx "$v"; then
      log "  Python $v: 既にインストール済み"
    else
      log "  Python $v をインストール (数分)..."
      pyenv install "$v"
    fi
  done

  pyenv global "${versions[-1]}"
  pyenv rehash
  log "  global: Python $(python --version 2>&1 | awk '{print $2}')"

  python -m pip install --upgrade pip --quiet 2>/dev/null && \
    log "  pip 更新: $(pip --version | awk '{print $2}')"
}

# ============================================================
# PHP インストール + 拡張 (phpenv + php-build)
# ============================================================
install_php_extensions() {
  local version="$1"
  local php_dir="$HOME/.phpenv/versions/$version"
  local php_bin="$php_dir/bin/php"
  local pecl_bin="$php_dir/bin/pecl"
  local conf_d="$php_dir/etc/conf.d"

  mkdir -p "$conf_d"

  # Xdebug
  if "$php_bin" -m 2>/dev/null | grep -qi '^xdebug$'; then
    log "    Xdebug: 既に有効"
  else
    log "    Xdebug をインストール..."
    if "$pecl_bin" install --force xdebug >/dev/null 2>&1; then
      cat > "$conf_d/xdebug.ini" <<'INI'
zend_extension=xdebug.so
xdebug.mode=debug,develop
xdebug.start_with_request=trigger
xdebug.client_host=127.0.0.1
xdebug.client_port=9003
xdebug.discover_client_host=false
xdebug.log_level=0
INI
      log "      ✓ Xdebug (port 9003, trigger モード)"
    else
      warn "    Xdebug インストール失敗"
    fi
  fi

  # Redis
  if "$php_bin" -m 2>/dev/null | grep -qi '^redis$'; then
    log "    Redis: 既に有効"
  else
    log "    Redis をインストール..."
    if printf '\n\n\n\n\n\n\n\n' | "$pecl_bin" install --force redis >/dev/null 2>&1; then
      echo "extension=redis.so" > "$conf_d/redis.ini"
      log "      ✓ Redis"
    else
      warn "    Redis インストール失敗"
    fi
  fi

  # Imagick
  if "$php_bin" -m 2>/dev/null | grep -qi '^imagick$'; then
    log "    Imagick: 既に有効"
  else
    log "    Imagick をインストール..."
    if printf '\n' | "$pecl_bin" install --force imagick >/dev/null 2>&1; then
      echo "extension=imagick.so" > "$conf_d/imagick.ini"
      log "      ✓ Imagick"
    else
      warn "    Imagick インストール失敗 (PHP $version との互換性問題の可能性)"
    fi
  fi

  phpenv rehash >/dev/null 2>&1 || true
}

resolve_php_version() {
  local input="$1"
  if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$input"
    return
  fi
  phpenv install --list 2>&1 \
    | grep -E "^[[:space:]]*${input}\.[0-9]+$" \
    | sort -V | tail -1 | xargs
}

install_php() {
  local versions=("$@")
  step "PHP (phpenv + php-build)"

  if ! command -v phpenv &>/dev/null; then
    err "phpenv が見つかりません。02-dev-runtime.sh を先に実行してください"
    return 1
  fi

  log "php-build プラグインを最新化..."
  git -C "$HOME/.phpenv/plugins/php-build" pull --ff-only 2>/dev/null || true

  # libmagickwand-dev (Imagick用)
  sudo apt install -y libmagickwand-dev 2>/dev/null || true

  if [[ "${versions[0]:-}" == "latest" ]] || [[ ${#versions[@]} -eq 0 ]]; then
    local latest
    latest=$(phpenv install --list 2>&1 \
      | grep -E '^[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+$' \
      | sort -V | tail -1 | xargs)
    versions=("$latest")
    log "最新安定版を検出: PHP $latest"
  fi

  local installed=()
  local failed=()

  for input in "${versions[@]}"; do
    local v
    v=$(resolve_php_version "$input")
    if [[ -z "$v" ]]; then
      err "PHP '$input' に対応するバージョンが見つかりません"
      failed+=("$input")
      continue
    fi

    log "PHP $v (指定: $input)"

    if phpenv versions --bare | grep -qx "$v"; then
      log "  ビルド: 既にインストール済み"
    else
      warn "  ビルド開始 (約10〜20分 / -j${JOBS})..."
      if MAKE_JOBS=$JOBS phpenv install "$v"; then
        log "  ビルド完了"
      else
        err "  PHP $v ビルド失敗"
        failed+=("$v")
        continue
      fi
    fi

    phpenv rehash >/dev/null 2>&1 || true
    install_php_extensions "$v"
    installed+=("$v")
  done

  if [[ ${#installed[@]} -gt 0 ]]; then
    local latest
    latest=$(printf '%s\n' "${installed[@]}" | sort -V | tail -1)
    phpenv global "$latest"
    log "global: PHP $latest"
  fi

  if [[ ${#failed[@]} -gt 0 ]]; then
    warn "失敗: ${failed[*]}"
  fi
}

# ============================================================
# 引数の処理
# ============================================================
case "$TARGET" in
  latest)
    install_node latest
    install_python latest
    install_php latest
    ;;
  node)
    install_node "$@"
    ;;
  python)
    install_python "$@"
    ;;
  php)
    install_php "$@"
    ;;
  *)
    err "不明なターゲット: $TARGET"
    err "  使えるターゲット: latest, node, python, php"
    exit 1
    ;;
esac

# ============================================================
# サマリ
# ============================================================
echo
echo "=============================================="
log "完了 🎉"
echo "=============================================="
echo
command -v node   >/dev/null && printf "  %-10s %s\n" "Node:"   "$(node --version)"
command -v python >/dev/null && printf "  %-10s %s\n" "Python:" "$(python --version 2>&1 | awk '{print $2}')"
command -v php    >/dev/null && printf "  %-10s %s\n" "PHP:"    "$(php --version | head -1 | awk '{print $2}')"
command -v composer >/dev/null && printf "  %-10s %s\n" "Composer:" "$(composer --version 2>&1 | awk '{print $3}')"
echo

cat <<'EOS'
プロジェクトごとのバージョン切替:
    echo "lts/*" > .nvmrc          # Node.js
    pyenv local 3.12.7              # Python
    phpenv local 8.3.13             # PHP
EOS
