#!/bin/bash
# コンテナイメージのビルド・動作確認スクリプト
# 結果は .claude/test-results/YYYY-MM-DD_HHMMSS.log に保存される

IMAGE="localhost/claude-test"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/.claude/test-results"
LOG_FILE="${LOG_DIR}/$(date +%Y-%m-%d_%H%M%S).log"
PASS=0
FAIL=0

mkdir -p "$LOG_DIR"

log() {
  echo "$@" | tee -a "$LOG_FILE"
}

check() {
  local desc="$1"; shift
  local output status
  output=$("$@" 2>&1) && status=0 || status=$?
  if [ "$status" -eq 0 ]; then
    printf "  %-52s[PASS]\n" "$desc" | tee -a "$LOG_FILE"
    PASS=$((PASS + 1))
  else
    printf "  %-52s[FAIL]\n" "$desc" | tee -a "$LOG_FILE"
    FAIL=$((FAIL + 1))
  fi
  printf "%s\n" "$output" >> "$LOG_FILE"
}

log "========================================"
log "  Build & Smoke Test  $(date)"
log "  Log: $LOG_FILE"
log "========================================"
log ""

log "## 静的チェック"
check "bash -n claude-container" bash -n "${SCRIPT_DIR}/claude-container"
check "podman compose config" podman compose -f "${SCRIPT_DIR}/compose.yml" config
log ""

log "## ビルド"
check "podman build --no-cache" podman build --no-cache \
  -f "${SCRIPT_DIR}/Dockerfile.claude" -t "$IMAGE" "$SCRIPT_DIR"
log ""

log "## イメージサイズ"
podman images "$IMAGE" --format \
  "  Repository: {{.Repository}}\n  Tag:        {{.Tag}}\n  Size:       {{.Size}}" \
  | tee -a "$LOG_FILE"
log ""

log "## Claude Code ツール"
check "claude --version" podman run --rm "$IMAGE" claude --version
check "gh --version"     podman run --rm "$IMAGE" gh --version
check "jq --version"     podman run --rm "$IMAGE" jq --version
log ""

log "## findsummits 依存"
check "gcc --version"    podman run --rm "$IMAGE" gcc --version
check "make --version"   podman run --rm "$IMAGE" make --version
check "python3 + numpy"  podman run --rm "$IMAGE" \
  python3 -c "import numpy; print(numpy.__version__)"
log ""

log "## TZ"
check "date (UTC確認)"   podman run --rm "$IMAGE" date
log ""

log "========================================"
log "  結果: PASS=${PASS}  FAIL=${FAIL}"
log "========================================"
log ""
log "## bash history 永続化確認（手動）"
log "  以下を順番に実行してください："
log "  1. mkdir -p /tmp/test-claude-history"
log "  2. podman run --rm -it --userns=keep-id -v /tmp/test-claude-history:/workspace/.claude ${IMAGE} bash"
log "  3. コンテナ内で任意のコマンドを実行（例: ls, echo hello）"
log "  4. exit でコンテナを終了"
log "  5. cat /tmp/test-claude-history/bash_history で履歴を確認"
