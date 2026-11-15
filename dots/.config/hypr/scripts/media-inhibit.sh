#!/usr/bin/env bash
# Keep the screen awake while any media player is playing.
# Holds a systemd idle inhibitor (which hypridle honours) for as long as
# playerctl reports a player in the Playing state. Started from
# modules/autostart.lua.

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/media-inhibit.lock"
flock -n 9 || exit 0

inhibitor=""

playing() { playerctl -a status 2>/dev/null | grep -q '^Playing$'; }

update() {
    if playing; then
        [ -n "$inhibitor" ] && kill -0 "$inhibitor" 2>/dev/null && return
        systemd-inhibit --what=idle --who=media-inhibit --why="Media is playing" \
            sleep infinity &
        inhibitor=$!
    elif [ -n "$inhibitor" ]; then
        kill "$inhibitor" 2>/dev/null
        inhibitor=""
    fi
}

trap '[ -n "$inhibitor" ] && kill "$inhibitor" 2>/dev/null' EXIT

update
# Follow status changes of every player; players appearing/vanishing also
# print a line. Restart the follower if it exits (e.g. playerctld restart).
while true; do
    while read -r _; do update; done < <(playerctl -a -F status 2>/dev/null)
    update
    sleep 2
done
