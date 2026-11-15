#!/usr/bin/env bash
set -e

STATE_FILE="$HOME/.ros2-sre-last-good"

IMAGE=$(curl -fsSL https://raw.githubusercontent.com/dario-garzon/ros2-sre-pipeline/deploy/desired-image)

docker pull --platform linux/arm64 "$IMAGE"
docker rm -f ros2-sre-node 2>/dev/null || true
docker run -d --name ros2-sre-node --platform linux/arm64 "$IMAGE"

if ./scripts/health_check.sh; then
  echo "$IMAGE" > "$STATE_FILE"
  echo "Deploy OK"
else
  echo "Health check failed"
  if [ -f "$STATE_FILE" ]; then
    LAST_GOOD=$(cat "$STATE_FILE")
    docker rm -f ros2-sre-node
    docker run -d --name ros2-sre-node --platform linux/arm64 "$LAST_GOOD"
    echo "Rolled back"
  else
    echo "No previous good version to roll back to"
  fi
  exit 1
fi