# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

[findsummits](https://github.com/JJ1XGO/findsummits) プロジェクト向けの Claude Code サンドボックス環境。
[sethjensen1/claude-container](https://github.com/sethjensen1/claude-container)（MIT）をフォークし、findsummits の開発環境に合わせてカスタマイズしたもの。

## Usage

```bash
# Run Claude in a target directory
./claude-container /path/to/project

# Force image rebuild
./claude-container -b /path/to/project
```

The script can be symlinked anywhere; it resolves its own location via `readlink` to find `compose.yml` and `Dockerfile.claude`.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CLAUDE_CONFIG_DIR` | `~` | Directory containing `.claude.json` and `.claude/` |
| `EXTRA_MOUNT` | `/dev/null` | Additional host path mounted at `/data` inside the container |

These can be set in a `.env` file at the target project root — it is sourced automatically before launch.

## Architecture

Three files work together:

- **`claude-container`** (bash) — entry point. Resolves absolute paths, loads `.env`, then sets `CONTEXT` and `CLAUDE_CONTAINER_DIR` and delegates to `podman compose run`.
- **`compose.yml`** — defines the single service `claude-auth-workspace`. Mounts the host's `~/.claude.json` and `~/.claude/` (auth + config) plus the target workspace at `/workspace`. Uses `userns_mode: keep-id` so files inside the container have the same UID as the host user.
- **`Dockerfile.claude`** — builds on `node:20`, installs CLI tools (`gh`, `fzf`, `jq`, `zsh`, etc.) and Python with numpy, then installs `@anthropic-ai/claude-code` globally. Runs as the non-root `node` user with `CMD ["claude", "--dangerously-skip-permissions"]`.

The image name is fixed as `localhost/claude-container_claude-auth-workspace` (Compose-derived). When `-b` is not passed and the image already exists, Compose skips the build step entirely.

## Modifying the Image

Edit `Dockerfile.claude` and rebuild with `./claude-container -b /path/to/project`. The `CLAUDE_CODE_VERSION` build arg defaults to `latest`; pin it in `compose.yml` if reproducibility matters.
