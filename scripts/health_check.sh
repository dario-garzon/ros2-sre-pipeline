#!/usr/bin/env bash
NAME=ros2-sre-node

for i in $(seq 1 60); do
  RUNNING=$(docker inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null || echo false)
  if [ "$RUNNING" = "true" ] && docker logs --since 10s "$NAME" 2>&1 | grep -q "Hello world"; then
    exit 0
  fi
  sleep 1
done
exit 1