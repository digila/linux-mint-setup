# 使い方早見

## WezTerm キーバインド

### コピー&ペースト (Windows風に設定済み)

| キー | 動作 |
|---|---|
| `Ctrl+C` | テキスト選択中はコピー、選択なしは SIGINT |
| `Ctrl+V` | ペースト |
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | 標準のコピー&ペースト (バックアップ) |

### ペイン

| キー | 動作 |
|---|---|
| `Ctrl+Shift+d` | ペインを **横** 分割 |
| `Ctrl+Shift+D` | ペインを **縦** 分割 |
| `Ctrl+Shift+矢印` | ペイン間を移動 |
| `Alt+Shift+矢印` | ペインをリサイズ |
| `Ctrl+Shift+w` | ペインを閉じる |
| `Ctrl+Shift+z` | ペインをズーム (一時最大化) |

### タブ

| キー | 動作 |
|---|---|
| `Ctrl+Shift+t` | 新しいタブ |
| `Ctrl+Tab` | 次のタブ |
| `Ctrl+Shift+Tab` | 前のタブ |

### その他

| キー | 動作 |
|---|---|
| `Ctrl + +/-` | フォントサイズ |
| `Ctrl + 0` | フォントサイズリセット |
| `F1` | コマンドパレット (機能を全検索可) |
| `Ctrl+Shift+r` | 設定を再読込 |

## 日本語入力 (Mac風)

| キー | 動作 |
|---|---|
| かな (Hiragana_Katakana) | 日本語 ON |
| 英数 (Eisu_toggle) | 日本語 OFF |
| 変換 | ON (保険) |
| 無変換 | OFF (保険) |
| 半角/全角 | トグル (保険) |
| Ctrl+Space | トグル (保険) |

## ランタイム切替

### Node.js (fnm)

```bash
fnm install --lts                   # 最新LTSをインストール
fnm install 22                      # メジャー指定
fnm list                            # インストール済み一覧
fnm use 22                          # このシェルだけ切替

# プロジェクトで:
echo "lts/*" > .nvmrc               # LTS追従
echo "22"    > .node-version        # メジャー固定
# cd で自動切替
```

### Python (pyenv)

```bash
pyenv install 3.13.0
pyenv versions                      # 一覧
pyenv global 3.13.0                 # 全体のデフォルト
pyenv shell 3.11.9                  # このシェルだけ

# プロジェクトで:
pyenv local 3.11.9                  # .python-version が作られる
```

### PHP (phpenv)

```bash
phpenv install 8.3.13                # ビルドに10〜20分
phpenv versions
phpenv global 8.3.13
phpenv shell 8.2.25

# プロジェクトで:
phpenv local 8.2.25                  # .php-version が作られる
```

## Claude Code

```bash
cd your-project/
claude                               # 対話モード
claude "Laravel migrate を作って"     # ワンショット

# プロジェクト方針を ./CLAUDE.md に書くと自動で読み込まれる
```

## Git エイリアス

```bash
g status                             # 設定済みエイリアス
lg                                   # lazygit (TUI)
```

## Docker

```bash
dc up -d                             # docker compose up -d
dc down
dps                                  # docker ps を整形表示
```

## Starship プロンプト表示

```
~/projects/my-app  main [!2+1]                        php 8.2.25
❯
```

- 左: ディレクトリ名 + Gitブランチ + 変更状況
- 右: そのプロジェクトのPHP/Node/Pythonバージョン (検出時のみ)
- `❯` の色: 緑=成功, 赤=直前のコマンドが失敗

## Xdebug の使い方 (trigger モード)

```bash
# 普段は OFF (オーバーヘッド最小)
php artisan tinker

# 一時的に ON
XDEBUG_TRIGGER=1 php artisan serve

# ブラウザから: Cookie XDEBUG_TRIGGER=1 をセット (Xdebug Helper 拡張が便利)
```
