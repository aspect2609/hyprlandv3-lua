#!/usr/bin/env bash
# Rofi script modes behind the Spotlight launcher (see ../spotlight.sh).
#   fallback  typed text with no match: maths -> calc, address -> open, else web search
#   actions   lock / sleep / restart / ... plus a couple of desktop helpers
#   files     files and folders under the usual home directories
#   calc      little calculator: Enter evaluates, picking a result copies it
#
# Rofi calls each mode with no argument to list entries, then again with the
# chosen entry (ROFI_INFO holds its id) or the typed text (ROFI_RETV=2).

SEARCH_URL="https://duckduckgo.com/?q="
SPOTLIGHT="$HOME/.config/rofi/spotlight.sh"
HYPR_SCRIPTS="$HOME/.config/hypr/scripts"

mode=$1; shift
arg=$*

# Run something after rofi has closed: detached, with rofi's pipes released,
# so scripts that start with `pkill -x rofi` don't kill themselves.
later() { setsid -f sh -c 'sleep 0.15; exec "$@"' sh "$@" >/dev/null 2>&1 </dev/null; }

is_math() {
    local s=$1
    [[ $s == =* ]] && return 0
    [[ $s =~ [0-9] ]] || return 1
    [[ $s =~ [-+*/^%×÷]|\ (to|in)\ |sqrt|sin|cos|tan|log|! ]]
}

# "to -unit" asks qalc for 3.1 mi rather than 3 mi + 188 yd + ...
calc() { local e=${1#=}; qalc -t -- "${e/ to / to -}" 2>/dev/null; }

case $mode in
fallback)
    [ -z "$arg" ] && exit 0                     # lists nothing of its own
    if is_math "$arg"; then
        SPOTLIGHT_CALC=$arg later "$SPOTLIGHT" calc
    elif [[ $arg =~ ^(https?://)?[[:alnum:]-]+(\.[[:alnum:]-]+)+(/[^[:space:]]*)?$ ]]; then
        [[ $arg == http* ]] || arg="https://$arg"
        later xdg-open "$arg"
    else
        later xdg-open "$SEARCH_URL$(jq -rn --arg q "$arg" '$q|@uri')"
    fi
    ;;

actions)
    if [ -n "$ROFI_INFO" ]; then
        case $ROFI_INFO in
            lock)      later hyprlock ;;
            sleep)     later systemctl suspend ;;
            restart)   later systemctl reboot ;;
            shutdown)  later systemctl poweroff ;;
            logout)    later hyprctl dispatch exit ;;
            wallpaper) later "$HYPR_SCRIPTS/wallpaper-picker.sh" ;;
            keybinds)  later "$HYPR_SCRIPTS/keybinds.sh" ;;
        esac
        exit 0
    fi
    # name | icon | id | extra search words
    while IFS='|' read -r name icon id meta; do
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\x1fmeta\x1f%s\n' "$name" "$icon" "$id" "$meta"
    done << 'EOF'
Lock Screen|system-lock-screen|lock|lock hyprlock
Sleep|system-suspend|sleep|suspend
Restart|system-reboot|restart|reboot
Shut Down|system-shutdown|shutdown|power off poweroff
Log Out|system-log-out|logout|exit quit hyprland
Change Wallpaper|preferences-desktop-wallpaper|wallpaper|background theme
Keyboard Shortcuts|preferences-desktop-keyboard-shortcuts|keybinds|keybinds hotkeys cheatsheet
EOF
    ;;

files)
    if [ -n "$ROFI_INFO" ]; then
        later xdg-open "$ROFI_INFO"
        exit 0
    fi
    printf '\0markup-rows\x1ftrue\n'
    cd ~ || exit
    fd --max-depth 5 --type f --type d --exclude node_modules . \
        Desktop Documents Downloads Music Pictures Videos Projects "Obsidian Vault" 2>/dev/null |
    awk -v home="$HOME" '
        function esc(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); return s }
        {
            path = $0; isdir = sub(/\/$/, "", path)
            n = split(path, parts, "/"); name = parts[n]
            dir = substr(path, 1, length(path) - length(name) - 1)
            ext = tolower(name); if (!sub(/.*\./, "", ext)) ext = ""
            if (isdir)                                              icon = "folder"
            else if (ext == "pdf")                                  icon = "application-pdf"
            else if (ext ~ /^(png|jpe?g|gif|webp|svg|bmp|heic)$/)    icon = "image-x-generic"
            else if (ext ~ /^(mp3|flac|wav|ogg|m4a|opus)$/)          icon = "audio-x-generic"
            else if (ext ~ /^(mp4|mkv|webm|mov|avi)$/)               icon = "video-x-generic"
            else if (ext ~ /^(docx?|odt|rtf)$/)                      icon = "x-office-document"
            else if (ext ~ /^(xlsx?|ods|csv)$/)                      icon = "x-office-spreadsheet"
            else if (ext ~ /^(pptx?|odp)$/)                          icon = "x-office-presentation"
            else if (ext ~ /^(html?)$/)                              icon = "text-html"
            else if (ext ~ /^(sh|py|lua|js|ts|go|rs|c|cpp|h|java)$/) icon = "text-x-script"
            else if (ext ~ /^(zip|tar|gz|xz|zst|7z|rar)$/)           icon = "package-x-generic"
            else                                                    icon = "text-x-generic"
            # Search text is "name  ~/folder"; shown as name with a dimmed folder.
            printf "%s  ~/%s\0display\x1f%s  <span alpha=\"45%%\" size=\"small\">~/%s</span>\x1ficon\x1f%s\x1finfo\x1f%s/%s\n",
                name, dir, esc(name), esc(dir), icon, home, path
        }'
    ;;

calc)
    if [ -n "$ROFI_INFO" ]; then                # picked a result: copy it
        printf '%s' "$ROFI_INFO" | wl-copy
        notify-send -a Calculator -i accessories-calculator "Copied" "$ROFI_INFO"
        exit 0
    fi
    expr=${arg:-$SPOTLIGHT_CALC}
    printf '\0prompt\x1fCalculator\n'
    if [ -n "$expr" ]; then
        result=$(calc "$expr")
        printf '\0message\x1f%s\n' "${expr#=}"
        printf '= %s\0icon\x1faccessories-calculator\x1finfo\x1f%s\n' "$result" "$result"
    else
        printf '\0message\x1fType a sum and press Enter\n'
    fi
    ;;
esac
