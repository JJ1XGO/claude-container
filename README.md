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

## 利用側プロジェクトの設定

bash history はターゲットプロジェクトの `.claude/bash_history` に保存される。誤ってコミットしないよう、ターゲットプロジェクトの `.gitignore` に以下を追加することを推奨する。

```
.claude/bash_history
```

## 環境変数

プロジェクトルートに `.env` を置くと起動前に自動で読み込まれる。

| 変数 | デフォルト | 説明 |
|---|---|---|
| `CLAUDE_CONFIG_DIR` | `~` | `.claude.json` と `.claude/` が置かれているディレクトリ |
| `EXTRA_MOUNT` | （なし） | コンテナ内 `/data` に追加でマウントするホスト側パス |

## 参考

- [Running Claude Code CLI in a Container (Endpoint Dev Blog)](https://www.endpointdev.com/blog/2026/03/claude-code-cli-in-container/) — フォーク元作者 Seth Jensen によるコンテナ化の解説記事

## ライセンス

GPL-3.0。フォーク元（sethjensen1/claude-container）は MIT ライセンス。詳細は [LICENSE](LICENSE) を参照。
