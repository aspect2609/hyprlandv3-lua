#!/usr/bin/env bash
# Text for the hyprlock labels (hyprlock.conf runs these via cmd[update:...]).
#   lockinfo.sh greeting | battery | music

case "$1" in
greeting)
    h=$(date +%H)
    if   [ "$h" -lt 5 ];  then part="night"
    elif [ "$h" -lt 12 ]; then part="morning"
    elif [ "$h" -lt 18 ]; then part="afternoon"
    else                       part="evening"
    fi
    echo "Good $part, ${USER^}"
    ;;
battery)
    bat=/sys/class/power_supply/BAT0
    [ -d "$bat" ] || exit 0
    cap=$(cat "$bat/capacity")
    if [ "$(cat "$bat/status")" = Charging ]; then
        icon="󰂄"
    else
        icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
        icon=${icons[$(( cap >= 100 ? 9 : cap / 10 ))]}
    fi
    echo "$icon  $cap%"
    ;;
music)
    playerctl metadata --format '󰎆  {{ artist }} — {{ title }}' 2>/dev/null | cut -c1-60
    ;;
esac
