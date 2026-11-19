#!/usr/bin/env bash
# Spotlight-style launcher: one box that searches apps, open windows, system
# actions and files. Results stay hidden until you type. Typed text with no
# match runs on Enter: sums open the calculator, addresses open in the
# browser, anything else is a web search.
#   spotlight.sh        the launcher
#   spotlight.sh calc   just the calculator

pkill -x rofi && exit 0   # pressing the key again closes it

DIR="$HOME/.config/rofi"
MODES="$DIR/scripts/spotlight-modes.sh"

if [ "$1" = calc ]; then
    exec rofi -show calc -modi "calc:$MODES calc" -theme "$DIR/themes/spotlight.rasi" \
        -theme-str 'listview { require-input: false; lines: 1; }'
fi

exec rofi -show combi -theme "$DIR/themes/spotlight.rasi" \
    -modi "combi,calc:$MODES calc" \
    -combi-modes "web:$MODES fallback,drun,window,actions:$MODES actions,files:$MODES files" \
    -combi-display-format '{text}' -display-combi '' \
    -matching normal -sort -sorting-method fzf
