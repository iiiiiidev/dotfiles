#!/usr/bin/env bash

DIR="${WALLPAPER_DIR:-$HOME/wallpapers}"
INTERVAL=3600

if ! awww query >/dev/null 2>&1; then
    awww-daemon &
    until awww query >/dev/null 2>&1; do
        sleep 0.2
    done
fi

while true; do
    mapfile -t outputs < <(awww query | awk -F': ' '{ print ($1 == "" ? $2 : $1) }')
    mapfile -t walls < <(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \) | shuf)
    if [ "${#walls[@]}" -eq 0 ] || [ "${#outputs[@]}" -eq 0 ]; then
        exit 1
    fi
    i=0
    for output in "${outputs[@]}"; do
        awww img "${walls[i % ${#walls[@]}]}" -o "$output" --resize crop --transition-type grow --transition-pos center --transition-fps 144 --transition-duration 1.5
        i=$((i + 1))
    done
    sleep "$INTERVAL"
done
