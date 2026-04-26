# claude-container

[findsummits](https://github.com/JJ1XGO/findsummits) プロジェクト向けの Claude Code コンテナ実行環境。
[sethjensen1/claude-container](https://github.com/sethjensen1/claude-container) をフォークし、findsummits の開発環境に合わせてカスタマイズしたもの。

Podman + Compose を使い、ホストの Claude 認証情報を共有しながら任意のディレクトリを `/workspace` にマウントして Claude Code を起動する。

## 前提

- [Podman](https://podman.io/) および `podman-compose`
- ホストに `~/.claude.json`（Claude 認証情報）が存在すること

## 使い方

```bash
# 任意のディレクトリで Claude Code を起動
./claude-container /path/to/project

# イメージを強制リビルドして起動
./claude-container -b /path/to/project

# イメージ・ネットワーク・dangling イメージを削除して終了
./claude-container --clean
```

スクリプトはシンボリックリンク経由でも動作する（`readlink` で自身のパスを解決する）。

## 環境変数

**利用側プロジェクト**のルートに `.claude-container` を置くと起動前に自動で読み込まれる。

| 変数 | デフォルト | 説明 |
|---|---|---|
| `CLAUDE_CONFIG_DIR` | `~` | `.claude.json` と `.claude/` が置かれているディレクトリ |
| `EXTRA_MOUNT` | （なし） | コンテナ内 `/data` に追加でマウントするホスト側パス |
| `TZ` | ホストから自動検出 | コンテナ内のタイムゾーン |

`TZ` は起動スクリプトがホストの `/etc/timezone`（なければ `/etc/localtime` シンボリックリンク）から自動検出する。`.claude-container` で明示した場合はそちらが優先される。

## 利用側プロジェクトの設定

bash history はターゲットプロジェクトの `.claude/bash_history` に保存される。誤ってコミットしないよう、ターゲットプロジェクトの `.gitignore` に以下を追加することを推奨する。

```
.claude/bash_history
```

## アーキテクチャ

5つのファイルが連携して動作する。

- **`claude-container`**（bash）— エントリーポイント。絶対パスを解決し、`.env` を読み込み、`TZ` を自動検出した上で `CONTEXT` / `CLAUDE_CONTAINER_DIR` を設定して `podman compose run` に委譲する。
- **`compose.yml`** — サービス `claude-auth-workspace` を定義。ホストの `~/.claude.json` と `~/.claude/`（認証・設定）、対象ワークスペース（`/workspace`）、`/etc/localtime`（タイムゾーン）をマウントする。`userns_mode: keep-id` でコンテナ内ファイルのオーナーをホストユーザーに合わせる。
- **`Dockerfile.claude`** — `node:24` をベースに Claude Code の依存パッケージと `@anthropic-ai/claude-code` をインストール。非 root ユーザー `node` で `claude --dangerously-skip-permissions` を起動する。`node:24-slim` ではなく `node:24` を使う理由: slim は `ca-certificates` を含まないため、大容量パッケージのダウンロードが失敗する環境がある。
- **`packages.txt`** — プロジェクト固有の apt パッケージ一覧。1行1パッケージ、`#` 始まりはコメント扱い。
- **`requirements.txt`** — プロジェクト固有の pip パッケージ一覧。`pip3 install -r` にそのまま渡される。

## イメージの変更

`Dockerfile.claude` を編集して `./claude-container -b /path/to/project` でリビルドする。`CLAUDE_CODE_VERSION` ビルド引数はデフォルト `latest`。再現性が必要な場合は `compose.yml` でバージョンを固定する。

## コンテナ間の永続化

コンテナは `--rm` で起動するため終了時に内部の状態は消えるが、以下はホストに bind mount されているため**コンテナを再起動しても保持される**。

| コンテナ内パス | ホスト側 | 内容 |
|---|---|---|
| `/home/node/.claude/` | `~/.claude/` | Claude のメモリ・設定・セッション履歴 |
| `/home/node/.claude.json` | `~/.claude.json` | Claude の認証情報 |
| `/workspace/` | 起動時に指定したディレクトリ | 作業対象プロジェクト |

## セキュリティモデル

Claude は `--dangerously-skip-permissions` で起動するため、ツール使用の確認プロンプトなしに動作する。ガードレールはコンテナ境界のみ — マウントされたワークスペースと `/data` への読み書きアクセスを持つ。意図したプロジェクトスコープ外の機密データを含むディレクトリはマウントしないこと。

## Podman 固有の注意

- `userns_mode: keep-id` はホストユーザーの UID/GID をコンテナ内にマップする Podman 固有の機能。Docker に移植する場合は削除する。
- `--in-pod false` は Podman Compose がデフォルトでサービスを Pod にラップする挙動を抑制する。Docker Compose はこのフラグを無視する。

## 変更後の確認

テストスイートはない。スクリプトや Compose / Dockerfile を編集した後は以下で確認する。

```bash
# シェルスクリプトの構文チェック
bash -n claude-container

# Compose ファイルの検証
podman compose -f compose.yml config
```

## 参考

- [Running Claude Code CLI in a Container (Endpoint Dev Blog)](https://www.endpointdev.com/blog/2026/03/claude-code-cli-in-container/) — フォーク元作者 Seth Jensen によるコンテナ化の解説記事

## ライセンス

GPL-3.0。フォーク元（sethjensen1/claude-container）は MIT ライセンス。詳細は [LICENSE](LICENSE) を参照。
