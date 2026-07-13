#!/usr/bin/env bash

DIR="$HOME/wallpapers"
INTERVAL=3600

if ! awww query >/dev/null 2>&1; then
    awww-daemon &
    until awww query >/dev/null 2>&1; do
        sleep 0.2
    done
fi

while true; do
    mapfile -t walls < <(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) | shuf)
    if [ "${#walls[@]}" -eq 0 ]; then
        exit 1
    fi
    awww img "${walls[0]}" -o DP-2 --resize crop --transition-type grow --transition-pos center --transition-fps 240 --transition-duration 1.5
    awww img "${walls[1]:-${walls[0]}}" -o HDMI-A-1 --resize crop --transition-type grow --transition-pos center --transition-fps 144 --transition-duration 1.5
    sleep "$INTERVAL"
done
