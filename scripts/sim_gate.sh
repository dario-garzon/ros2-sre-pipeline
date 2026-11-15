#!/usr/bin/env bash
set -e

source /opt/ros/jazzy/setup.bash

gz sim -s -r diff_drive.sdf &
SIM_PID=$!
trap 'kill $SIM_PID' EXIT

for i in $(seq 1 30); do
  gz topic -l | grep -q vehicle_blue/cmd_vel && break
  sleep 1
done

POS_BEFORE=$(gz topic -e -t /model/vehicle_blue/odometry -n 1 | grep 'x:' | head -n 1 | awk '{print $2}')
gz topic -t /model/vehicle_blue/cmd_vel -m gz.msgs.Twist -p "linear: {x: 0.5}"
sleep 5
POS_AFTER=$(gz topic -e -t /model/vehicle_blue/odometry -n 1 | grep 'x:' | head -n 1 | awk '{print $2}')

awk -v a="$POS_BEFORE" -v b="$POS_AFTER" 'BEGIN { exit (b - a > 100) ? 0 : 1 }'
