# linux-mint-setup

Linux Mint (Cinnamon) の開発環境を新規PCで再現するためのセットアップスクリプト集。
PHP/Laravel + Python + JavaScript/TypeScript 開発を主目的としています。

## クイックスタート

新PCで以下を実行するだけで全部入ります。

### SSH 鍵を持っている場合 (推奨)

```bash
sudo apt update && sudo apt install -y git
git clone git@github.com:YOUR_USERNAME/linux-mint-setup.git ~/linux-mint-setup
cd ~/linux-mint-setup
./bootstrap.sh
```

### SSH 鍵がまだない場合

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/YOUR_USERNAME/linux-mint-setup.git ~/linux-mint-setup
# プライベートリポジトリの場合、GitHub Personal Access Token (PAT) が必要です
# https://github.com/settings/tokens から作成して、ユーザー名とトークンを入力
cd ~/linux-mint-setup
./bootstrap.sh
```

## 含まれるもの

### 01-system.sh: システム基本
- 日本語入力 (fcitx5 + mozc, **Mac風キーバインド** = かなON / 英数OFF)
- NumLock 起動時 ON (LightDM + systemd の二重設定で確実)
- Google Chrome + デフォルトブラウザ設定

### 02-dev-runtime.sh: 開発ランタイム
- Git (日本語ファイル名対応, 規定設定)
- **fnm** (Node.js のバージョン管理, .nvmrc 自動切替)
- **pyenv** (Python のバージョン管理, .python-version)
- **phpenv + php-build** (PHP のバージョン管理, .php-version)
- Composer
- Claude Code (ネイティブインストーラ)
- PHPビルド依存関係 (libicu, libzip, libonig, libsodium ほか)

### 03-terminal.sh: ターミナル環境
- **WezTerm** (タブ + ペイン + cwd通知)
- **Starship** (PHP/Node/Python のバージョンを自動表示)
- **PlemolJP** フォント (全バリエーション)
- モダン CLI: ripgrep, fd, bat, eza, fzf, jq, yq, lazygit, direnv, mkcert
- bash エイリアス + OSC 7 (ペイン分割で同じ cwd で開く)

### 04-apps.sh: GUI アプリ
- Docker Engine + Compose
- VS Code (公式 APT)
- Google Antigravity (AI IDE)
- GitKraken
- Slack (Flatpak)
- Insync (Google Drive クライアント, $39.99 の有償ソフト)
- Mailpit (Laravel メールテスト)
- Flameshot (スクリーンショット)

### install-runtimes.sh: ランタイム本体
基本セットアップとは別に、必要なときに実行します。

```bash
# 各ランタイムの最新版を一括
./scripts/install-runtimes.sh latest

# Node.js のみ最新LTS
./scripts/install-runtimes.sh node latest

# Python の特定バージョン
./scripts/install-runtimes.sh python 3.12.7 3.11.9

# PHP 複数バージョン (Xdebug + Redis + Imagick も自動)
./scripts/install-runtimes.sh php 8.2 8.3 8.4
```

## ディレクトリ構造

```
linux-mint-setup/
├── bootstrap.sh              # メインエントリ
├── scripts/
│   ├── 01-system.sh          # システム基本
│   ├── 02-dev-runtime.sh     # 開発ランタイム
│   ├── 03-terminal.sh        # ターミナル
│   ├── 04-apps.sh            # GUIアプリ
│   ├── install-runtimes.sh   # ランタイム個別インストール
│   └── lib/
│       └── common.sh         # 共通関数
├── dotfiles/
│   ├── wezterm.lua           # WezTerm 設定 (シンボリックリンクされる)
│   └── starship.toml         # Starship 設定 (シンボリックリンクされる)
├── docs/
│   └── ...                   # 補足ドキュメント
└── README.md
```

## dotfiles のシンボリックリンク方式

`dotfiles/wezterm.lua` と `dotfiles/starship.toml` は、ホームディレクトリの設定ファイルパスへ
**シンボリックリンク** されます。

```
~/.config/wezterm/wezterm.lua  →  ~/linux-mint-setup/dotfiles/wezterm.lua
~/.config/starship.toml        →  ~/linux-mint-setup/dotfiles/starship.toml
```

これにより:
- リポジトリ側のファイルを編集すると **即座にターミナル動作に反映**
- `git commit` してプッシュすれば 別PC で `git pull` するだけで設定が同期
- 設定変更の履歴が `git log` で追える

## 個別実行

`bootstrap.sh` には引数で個別実行モードがあります:

```bash
./bootstrap.sh system      # 01-system.sh のみ
./bootstrap.sh dev         # 02-dev-runtime.sh のみ
./bootstrap.sh terminal    # 03-terminal.sh のみ
./bootstrap.sh apps        # 04-apps.sh のみ
```

各スクリプトは**冪等**(再実行しても壊れない)に作ってあるので、
追加で何か入れたいときに何度でも回せます。

## 設定変更のワークフロー (複数PC運用)

```bash
# PC A で WezTerm の設定を変更
cd ~/linux-mint-setup
vim dotfiles/wezterm.lua
# WezTerm が自動再読み込みするので動作確認

# 良ければコミット
git add dotfiles/wezterm.lua
git commit -m "Adjust WezTerm font size"
git push

# PC B で取り込み
cd ~/linux-mint-setup
git pull
# WezTerm は次の設定検出で自動再読み込み (再起動不要)
```

## トラブルシューティング

### デスクトップが真っ黒になる

Cinnamon または XFCE のデスクトップ背景が真っ黒で、ファイラーも開けない場合:

```bash
# 原因: Insync の ファイラー連携プラグイン (Python製) がクラッシュさせている
sudo apt remove -y insync-nemo insync-thunar insync-caja insync-nautilus

# 再起動
sudo reboot
```

Insync 本体 (同期機能) は残るので、Google Drive 同期は引き続き動きます。
失われるのは「右クリック → Insync で共有」のメニュー機能だけです。

### ファイラーや Cinnamon 系アプリが PyGObject エラーで落ちる

```
ImportError: ... undefined symbol: PyExc_NotImplementedError
```

このエラーが出る場合は pyenv が悪さしています:

```bash
pyenv global system          # システム Python に戻す
sudo reboot                   # または cinnamon --replace で復旧
```

### スクリプトが途中で失敗した

各スクリプトは冪等です。失敗箇所を直して再実行すれば、成功した部分はスキップされます。

### 日本語入力が効かない
一度ログアウト → ログインしてください。それでも効かない場合は再起動。

### Chromeが見つからない / Antigravity がインストールできない
ネットワーク接続を確認してください。Docker Hub や GitHub に接続できる必要があります。

### PHP のビルドが失敗する
ビルド依存パッケージが不足している可能性があります:

```bash
sudo apt install -y build-essential libssl-dev libicu-dev libzip-dev \
                    libonig-dev libxml2-dev libcurl4-openssl-dev libsodium-dev
```

### docker コマンドで permission denied
docker グループへの追加は **再ログインで反映** されます:

```bash
sudo reboot
```

## ⚠️ 重要: pyenv の使い方

Linux Mint は内部でシステムの Python (`/usr/bin/python3`) を使って Cinnamon
デスクトップや Nemo (ファイラー) を動かしています。

`pyenv global 3.x.x` で別バージョンに切り替えると、システムが期待する
PyGObject などの Python モジュールが見つからなくなり、**Cinnamon が起動
しなくなります** (デスクトップが真っ黒になる症状)。

### 正しい使い方

```bash
# ❌ NG: システムが壊れる
pyenv global 3.13.0

# ✅ OK: プロジェクト単位で切り替え
cd ~/projects/my-app
pyenv local 3.13.0          # .python-version が作られる
python3 --version           # → 3.13.0 (このフォルダだけ)

# システム全体は system のまま維持
pyenv global system
```

### もし真っ黒になったら

ターミナルから:
```bash
pyenv global system
cinnamon --replace > /tmp/cinnamon.log 2>&1 &
disown
```

`install-runtimes.sh` は最新版でこの問題を回避するよう修正されています
(`pyenv global` を変更しない設計)。

---

## ライセンス

個人用設定なので公開・配布は想定していませんが、参考になれば自由にお使いください。

## 謝辞

このセットアップは Claude (Anthropic) との対話を通じて作成されました。
