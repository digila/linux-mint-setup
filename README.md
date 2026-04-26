# linux-mint-setup

Linux Mint (Cinnamon / XFCE) 上で **PHP/Laravel + Python + JavaScript/TypeScript**
の開発環境をワンコマンドで構築するスクリプト集です。

新しい PC に Linux Mint を入れた直後の真っ新な状態から、`bootstrap.sh` 1 つで
**日本語入力・開発ランタイム・モダンなターミナル・主要 IDE** まで揃います。

---

## 動作確認環境

- **OS**: Linux Mint 22.x (Cinnamon / XFCE)、ベースは Ubuntu 24.04 (Noble)
- **CPU**: Intel x86_64 (ARM 未対応)
- **RAM**: 推奨 8GB 以上 (4GB でも動作はします)
- **キーボード**: 日本語 (JIS) 配列推奨

Ubuntu 24.04 系であれば Linux Mint 以外の派生でもおおむね動くはずですが、
`xdg-open` の挙動や Cinnamon 固有の設定 (NumLock 等) は Mint を前提にしています。

## インストールされるもの一覧

### 開発ランタイム

| カテゴリ | ツール | 用途 |
|---|---|---|
| バージョン管理 | **fnm** | Node.js のバージョン切替 (`.nvmrc` 自動切替) |
| バージョン管理 | **pyenv** | Python のバージョン切替 (`.python-version`) |
| バージョン管理 | **phpenv + php-build** | PHP のバージョン切替 (`.php-version`) |
| パッケージ管理 | **Composer** | PHP のパッケージ管理 |
| AI コーディング | **Claude Code** | ターミナル AI アシスタント |
| Git | **Git** | バージョン管理 (日本語ファイル名対応) |

PHP には Xdebug / Redis / Imagick の各拡張も自動でインストールされます
(`install-runtimes.sh php` 実行時)。

### ターミナル環境

| カテゴリ | ツール | 用途 |
|---|---|---|
| ターミナル | **WezTerm** | タブ + ペイン分割 + cwd 通知 |
| プロンプト | **Starship** | PHP/Node/Python のバージョン自動表示 |
| フォント | **PlemolJP** | 日本語等幅プログラミングフォント (全バリエーション) |
| 検索 | **ripgrep** (`rg`) | 高速 grep |
| ファイル探索 | **fd** | 高速 find |
| ファイル表示 | **bat** | シンタックスハイライト付き cat |
| ls 代替 | **eza** | アイコン・色・Git ステータス対応 |
| あいまい検索 | **fzf** | コマンド履歴・ファイル選択 |
| JSON | **jq** | JSON 整形・抽出 |
| YAML | **yq** | YAML 整形・抽出 |
| Git TUI | **lazygit** | ターミナル UI の Git クライアント |
| 環境変数 | **direnv** | プロジェクト別の自動環境変数読み込み |
| HTTPS | **mkcert** | ローカル開発用の信頼済み証明書発行 |

### GUI アプリケーション

| カテゴリ | アプリ | 用途 |
|---|---|---|
| エディタ / IDE | **Google Antigravity** | AI 統合 IDE (VS Code ベース) |
| エディタ / IDE | **VS Code** | Microsoft 公式エディタ |
| ブラウザ | **Google Chrome** | デフォルトブラウザに設定済み |
| Git GUI | **GitKraken** | グラフィカル Git クライアント |
| コミュニケーション | **Slack** (Flatpak) | チャット |
| コンテナ | **Docker Engine + Compose** | コンテナ実行環境 |
| Google Drive | **Insync** ($39.99) | Google Drive 同期 (有償) |
| メールテスト | **Mailpit** | Laravel 等のメール送信確認用 SMTP サーバ |
| スクリーンショット | **Flameshot** | 矩形選択・注釈付きスクショ |

### システム設定

| 項目 | 内容 |
|---|---|
| 日本語入力 | fcitx5 + mozc (**Mac 風キーバインド**: かな で ON / 英数 で OFF) |
| キーボード | NumLock 起動時 ON (LightDM + systemd の二重設定) |
| ターミナル統合 | OSC 7 によるカレントディレクトリ通知 (ペイン分割で同じ cwd で開く) |
| 設定ファイル管理 | dotfiles をシンボリックリンクで配置 (Git 管理可能) |

### 含まれない / 別途必要なもの

- **Node.js / Python / PHP の本体**: `install-runtimes.sh` で別途インストール
- **JetBrains 系 IDE** (PhpStorm 等): 必要なら手動で
- **MySQL / PostgreSQL / Redis 等の DB**: Docker での運用を推奨
- **Adobe 系・MS Office 系**: Linux 版を別途インストールするか Web 版を使用

## クイックスタート

### Step 0: 前提パッケージのインストール

Linux Mint をインストールした直後の状態を想定しています。
**Git すら入っていない状態**から始めるので、まず Git と curl をインストールします。

```bash
sudo apt update && sudo apt install -y git curl
```

### Step 1: クローン

```bash
# このリポジトリをそのまま使う場合
git clone https://github.com/digila/linux-mint-setup.git ~/linux-mint-setup

# 自分用にカスタマイズしたい場合は GitHub で Fork してから
git clone https://github.com/YOUR_USERNAME/linux-mint-setup.git ~/linux-mint-setup

cd ~/linux-mint-setup
```

(自分でフォークして使う場合は `YOUR_USERNAME` を自分のユーザー名に置き換えてください)

### Step 2: bootstrap 実行

```bash
./bootstrap.sh
```

確認プロンプトに `y` で答えると、4 つのスクリプトが順に実行されます (約 30〜60 分):

1. システム基本 (日本語入力・NumLock・Chrome)
2. 開発ランタイム (Git・fnm・pyenv・phpenv・Composer・Claude Code)
3. ターミナル環境 (WezTerm・Starship・PlemolJP・モダン CLI)
4. GUI アプリ (Docker・VS Code・Antigravity・GitKraken・Slack・Insync)

完了後、必要に応じて以下の補助スクリプトを実行します:

```bash
./scripts/install-runtimes.sh latest          # Node.js / Python / PHP の最新版
./scripts/antigravity-extensions.sh install   # Antigravity 拡張機能を一括導入
./scripts/fix-intel-gpu-electron-apps.sh      # Intel HD Graphics 環境のフリーズ対策 (該当機のみ)
./scripts/optimize-boot.sh                    # 起動時間の短縮 (任意)
```

### Step 3: 仕上げ

```bash
# Git のユーザー設定 (まだなら)
git config --global user.name  "あなたの名前"
git config --global user.email "you@example.com"

# 再起動 (Docker / NumLock / 日本語入力を完全有効化)
sudo reboot
```

再起動後、各アプリの初回ログイン:

- **Insync**: メニューから起動 → Google アカウントでログイン
- **Antigravity**: メニューから起動 → 個人 Gmail でログイン
- **GitKraken**: メニューから起動 → GitHub と連携
- **Slack**: メニューから起動 → ワークスペースに参加
- **Claude Code**: ターミナルで `cd プロジェクト && claude`

## 含まれるもの

### コアセットアップ (`bootstrap.sh` で順次実行)

#### 01-system.sh: システム基本

- 日本語入力 (fcitx5 + mozc, **Mac 風キーバインド** = かな ON / 英数 OFF)
- NumLock 起動時 ON (LightDM + systemd の二重設定で確実)
- Google Chrome + デフォルトブラウザ設定

#### 02-dev-runtime.sh: 開発ランタイム

- Git (日本語ファイル名対応, 既定設定)
- **fnm** (Node.js のバージョン管理, `.nvmrc` 自動切替)
- **pyenv** (Python のバージョン管理, `.python-version`)
- **phpenv + php-build** (PHP のバージョン管理, `.php-version`)
- Composer
- Claude Code (ネイティブインストーラ)
- PHP ビルド依存関係 (libicu, libzip, libonig, libsodium ほか)

#### 03-terminal.sh: ターミナル環境

- **WezTerm** (タブ + ペイン + cwd 通知)
- **Starship** (PHP/Node/Python のバージョンを自動表示)
- **PlemolJP** フォント (全バリエーション)
- モダン CLI: ripgrep, fd, bat, eza, fzf, jq, yq, lazygit, direnv, mkcert
- bash エイリアス + OSC 7 (ペイン分割で同じ cwd で開く)

#### 04-apps.sh: GUI アプリ

- Docker Engine + Compose
- VS Code (公式 APT)
- Google Antigravity (AI IDE)
- GitKraken
- Slack (Flatpak)
- Insync (Google Drive クライアント, $39.99 の有償ソフト)
- Mailpit (Laravel メールテスト)
- Flameshot (スクリーンショット)

> Insync のファイラー連携プラグイン (`insync-nemo` / `insync-thunar` 等) は
> 意図的にインストールしません。Python の PyGObject に依存して
> ファイラー全般をクラッシュさせる既知の問題があるためです。

### 補助スクリプト

#### install-runtimes.sh: ランタイム本体のインストール

`02-dev-runtime.sh` で各ツール (fnm/pyenv/phpenv) は入れていますが、
Node.js/Python/PHP 本体は別途インストールします。

```bash
# 各ランタイムの最新版を一括
./scripts/install-runtimes.sh latest

# 個別:
./scripts/install-runtimes.sh node latest
./scripts/install-runtimes.sh node 22 20
./scripts/install-runtimes.sh python latest
./scripts/install-runtimes.sh python 3.13.0
./scripts/install-runtimes.sh php latest
./scripts/install-runtimes.sh php 8.2 8.3 8.4   # 複数バージョン (Xdebug+Redis+Imagick 自動)
```

> ⚠️ Python は `pyenv global` を変更しません。
> 詳細は下の [pyenv の使い方](#-重要-pyenv-の使い方) を参照。

#### antigravity-extensions.sh: Antigravity 拡張機能の同期

```bash
# 現在の拡張機能をファイル化
./scripts/antigravity-extensions.sh export

# ファイルから一括インストール (別 PC で使う)
./scripts/antigravity-extensions.sh install

# 現在の拡張機能を変更後、Git 差分を表示
./scripts/antigravity-extensions.sh sync

# インストール済み一覧 (バージョン付き)
./scripts/antigravity-extensions.sh list
```

拡張機能リストは `dotfiles/antigravity-extensions.txt` に保存され、Git 管理対象です。

#### fix-intel-gpu-electron-apps.sh: Intel GPU 環境のフリーズ対策

Intel HD Graphics 530/520/620 等の Skylake/Kaby Lake 世代の Intel GPU で、
Electron 系アプリ (Antigravity, VS Code, Chrome, Slack) が拡張機能インストール
時等に PC 全体をフリーズさせる既知の問題対策。

```bash
# 各 Electron アプリの GPU 加速を一括無効化
./scripts/fix-intel-gpu-electron-apps.sh

# それでもフリーズが続く場合は カーネルパラメータも修正
./scripts/fix-intel-gpu-electron-apps.sh full
sudo reboot
```

新しい GPU を搭載した PC (NVIDIA / AMD / 第 8 世代以降の Intel) では不要です。

#### optimize-boot.sh: 起動時間の短縮 (任意)

```bash
./scripts/optimize-boot.sh
```

`NetworkManager-wait-online` の無効化、GRUB タイムアウト短縮、Cinnamon 設定
デーモンの無駄起動抑制などで **約 8〜10 秒短縮** できます。

## ディレクトリ構造

```
linux-mint-setup/
├── bootstrap.sh                          # メインエントリ
├── README.md                             # このファイル
├── .gitignore
├── docs/
│   └── USAGE.md                          # WezTerm/Starship 等の使い方早見
├── dotfiles/                             # シンボリックリンクされる設定ファイル
│   ├── wezterm.lua                       # WezTerm 設定
│   ├── starship.toml                     # Starship 設定
│   └── antigravity-extensions.txt        # Antigravity 拡張機能リスト
└── scripts/
    ├── 01-system.sh                      # システム基本
    ├── 02-dev-runtime.sh                 # 開発ランタイム
    ├── 03-terminal.sh                    # ターミナル
    ├── 04-apps.sh                        # GUI アプリ
    ├── install-runtimes.sh               # ランタイム個別インストール
    ├── antigravity-extensions.sh         # Antigravity 拡張機能管理
    ├── fix-intel-gpu-electron-apps.sh    # Intel GPU 対策
    ├── optimize-boot.sh                  # 起動時間最適化
    └── lib/
        └── common.sh                     # 共通ヘルパー関数
```

## dotfiles のシンボリックリンク方式

`dotfiles/` 配下のファイルは、ホームディレクトリの設定ファイルパスへ
**シンボリックリンク** されます。

```
~/.config/wezterm/wezterm.lua  →  ~/linux-mint-setup/dotfiles/wezterm.lua
~/.config/starship.toml        →  ~/linux-mint-setup/dotfiles/starship.toml
```

これにより:

- リポジトリ側のファイルを編集すると **即座にターミナル動作に反映**
- 自分でフォークして使えば、`git commit` & `git push` で別 PC に設定を同期できる
- 設定変更の履歴が `git log` で追える

`antigravity-extensions.txt` は通常ファイル(リンクではなく)で管理しています。
更新は `./scripts/antigravity-extensions.sh export` で行います。

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

## 自分用にカスタマイズして使う

このリポジトリは「動く参考実装」です。自分用に変えたい場合は **フォーク** して使ってください:

```bash
# 1. GitHub でこのリポジトリを Fork
# 2. 自分のフォーク先からクローン
git clone https://github.com/YOUR_USERNAME/linux-mint-setup.git ~/linux-mint-setup
cd ~/linux-mint-setup

# 3. dotfiles を編集して push
vim dotfiles/wezterm.lua
git add -A
git commit -m "Customize WezTerm"
git push

# 4. 別 PC では git pull するだけで反映
```

複数 PC を運用する人は、自分用フォークを 1 つ作っておくと開発環境を完全に同期できます。

## トラブルシューティング

### Antigravity / VS Code / Chrome がフリーズする (Intel HD Graphics)

Intel HD Graphics 530/520/620 等の Skylake/Kaby Lake 世代の Intel GPU で、
Electron 系アプリが拡張機能インストール時等に PC 全体をフリーズさせる場合:

```bash
./scripts/fix-intel-gpu-electron-apps.sh
# それでも続くなら
./scripts/fix-intel-gpu-electron-apps.sh full
sudo reboot
```

### デスクトップが真っ黒になる

Cinnamon または XFCE のデスクトップ背景が真っ黒で、ファイラーも開けない場合:

```bash
# 原因: Insync の ファイラー連携プラグイン (Python 製) がクラッシュさせている
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

```bash
# apt が中途半端な状態の場合 (前回のフリーズ後など)
sudo dpkg --configure -a
sudo apt install -f

# 再実行
./bootstrap.sh
```

### 日本語入力が効かない

一度ログアウト → ログインしてください。それでも効かない場合は再起動。

### Chrome が見つからない / Antigravity がインストールできない

ネットワーク接続を確認してください。Docker Hub や GitHub に接続できる必要があります。

### PHP のビルドが失敗する

ビルド依存パッケージが不足している可能性があります:

```bash
sudo apt install -y build-essential libssl-dev libicu-dev libzip-dev \
                    libonig-dev libxml2-dev libcurl4-openssl-dev libsodium-dev \
                    libmagickwand-dev
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

`install-runtimes.sh` は `pyenv global` を変更しない設計なので、
このスクリプト経由でインストールすればこの問題は起きません。

## 既知の地雷ポイント (このリポジトリで対策済み)

このスクリプト集を作る過程で発見した、**Linux Mint × pyenv × Insync × Electron**
の組み合わせで起こる地雷とその対策を共有します:

| # | 問題 | 対策箇所 |
|---|---|---|
| 1 | `bootstrap.sh` から呼んだ子スクリプトが sudo keep-alive を二重起動 → 完全フリーズ | `lib/common.sh` の `require_sudo` で環境変数チェック |
| 2 | `pyenv global` でシステム Python を上書きすると Cinnamon/Nemo が壊れる | `install-runtimes.sh` で `pyenv global` を変更しない |
| 3 | Insync のファイラー連携プラグインが PyGObject 経由でファイラーを巻き込みクラッシュ | `04-apps.sh` でプラグインをインストールしない |
| 4 | Intel HD Graphics 530 等で Electron アプリが拡張機能インストール時に PC 全体をフリーズ | `fix-intel-gpu-electron-apps.sh` で GPU 加速を無効化 |

同じ環境で困っている人の参考になれば幸いです。

## ライセンス

[MIT License](LICENSE)

## 謝辞

このセットアップは Claude (Anthropic) との対話を通じて作成されました。
何度もシステムを破壊しながら、最終的に Linux Mint 開発環境構築の知見が
詰まったスクリプト集になりました。
