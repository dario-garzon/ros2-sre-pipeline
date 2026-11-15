#!/usr/bin/env bash
set -e

IMAGE=$(curl -fsSL https://raw.githubusercontent.com/dario-garzon/ros2-sre-pipeline/deploy/desired-image)

docker pull --platform linux/arm64 "$IMAGE"
docker rm -f ros2-sre-node 2>/dev/null || true
docker run -d --name ros2-sre-node --platform linux/arm64 "$IMAGE"