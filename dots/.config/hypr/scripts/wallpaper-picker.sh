#!/usr/bin/env bash
# Wallpaper picker (SUPER + W): rofi grid of thumbnails. Picking one sets it
# through scripts/wallpaper.sh, which re-themes everything (waybar/theme.sh).

DIR="$HOME/Pictures/Wallpapers"
THUMBS="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
mkdir -p "$THUMBS"

pkill -x rofi && exit 0   # pressing the key again closes it

mapfile -t walls < <(find "$DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
[ "${#walls[@]}" -gt 0 ] || { notify-send "Wallpaper picker" "No images in $DIR"; exit 1; }

# Small cached thumbnails keep rofi fast; regenerated when the image changes.
for w in "${walls[@]}"; do
    t="$THUMBS/$(basename "${w%.*}").jpg"
    [ "$t" -nt "$w" ] || magick "$w[0]" -thumbnail 400x225^ -gravity center -extent 400x225 "$t"
done

current=$(grep '^wallpaper' ~/.config/waypaper/config.ini | cut -d'=' -f2 | xargs | sed "s|~|$HOME|")

choice=$(for w in "${walls[@]}"; do
    printf '%s\0icon\x1f%s\n' "$(basename "$w")" "$THUMBS/$(basename "${w%.*}").jpg"
done | rofi -dmenu -i -p "Wallpaper" -show-icons -no-custom \
    -select "$(basename "$current")" \
    -theme-str '
        window   { width: 900px; }
        mainbox  { children: [ listview ]; }
        listview { columns: 4; lines: 3; flow: horizontal; spacing: 10px; }
        element  { children: [ element-icon ]; padding: 6px; border-radius: 8px; }
        element-icon { size: 190px; }')

[ -n "$choice" ] && ~/.config/hypr/scripts/wallpaper.sh "$DIR/$choice"
