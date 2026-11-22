#!/usr/bin/env bash
set -e

STATE_FILE="$HOME/.ros2-sre-last-good"
FAILED_FILE="$HOME/.ros2-sre-last-failed"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE="${1:-$(curl -fsSL https://raw.githubusercontent.com/dario-garzon/ros2-sre-pipeline/deploy/desired-image)}"

RUNNING_IMAGE=$(docker inspect -f '{{.Config.Image}}' ros2-sre-node 2>/dev/null || echo "")

if [ -f "$FAILED_FILE" ] && [ "$(cat "$FAILED_FILE")" = "$IMAGE" ]; then
  echo "Skipping $IMAGE: it already failed the health check"
  exit 0
fi

IS_UP=$(docker inspect -f '{{.State.Running}}' ros2-sre-node 2>/dev/null || echo false)

if [ "$RUNNING_IMAGE" = "$IMAGE" ] && [ "$IS_UP" = "true" ]; then
  echo "Already running $IMAGE, nothing to do"
  exit 0
fi

docker pull --platform linux/arm64 "$IMAGE"
docker rm -f ros2-sre-node 2>/dev/null || true
docker run -d --name ros2-sre-node --platform linux/arm64 "$IMAGE"

if "$SCRIPT_DIR/health_check.sh"; then
  echo "$IMAGE" > "$STATE_FILE"
  echo "Deploy OK"
else
  echo "Health check failed"
  echo "$IMAGE" > "$FAILED_FILE"
  if [ -f "$STATE_FILE" ]; then
    LAST_GOOD=$(cat "$STATE_FILE")
    docker rm -f ros2-sre-node
    docker run -d --name ros2-sre-node --platform linux/arm64 "$LAST_GOOD"
    if "$SCRIPT_DIR/health_check.sh"; then
      echo "Rolled back and recovered"
      exit 1
    else
      echo "Rollback FAILED: node is down"
      exit 2
    fi
  else
    echo "No previous good version to roll back to: node is down"
    exit 2
  fi
fi