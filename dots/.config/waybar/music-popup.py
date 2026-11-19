#!/usr/bin/env python3
"""Music popup for the waybar mpris module.

Album art, track info, seek bar, previous / play-pause / next / stop, system
volume and a player switcher when more than one player is open. Opens under
the cursor; run again (click the module) to close. Also closes on Escape or a
click anywhere outside it. Colours come from the current pywal palette.
"""
import hashlib
import json
import os
import signal
import subprocess
import sys
import threading
import time
import urllib.request

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, GtkLayerShell  # noqa: E402

WIDTH = 360
ART = 72
PIDFILE = "/tmp/music-popup.pid"
CLOSEDFILE = "/tmp/music-popup.closed"
ART_CACHE = os.path.expanduser("~/.cache/music-popup")
SEP = "\x1f"
FIELDS = ("playerName", "status", "artist", "title", "album", "mpris:artUrl", "mpris:length", "position")


def run(*cmd, timeout=5):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout.strip()
    except Exception:
        return ""


def bg(*cmd):
    threading.Thread(target=run, args=cmd, daemon=True).start()


def palette():
    """Current pywal colours, or Tokyo Night if pywal hasn't run."""
    c = {"bg": "#1a1b26", "surface": "#24283b", "accent": "#bb9af7", "fg": "#c0caf5", "sub": "#565f89"}
    try:
        wal = json.load(open(os.path.expanduser("~/.cache/wal/colors.json")))
        col = wal["colors"]
        c.update(bg=wal["special"]["background"], fg=wal["special"]["foreground"],
                 surface=col["color1"], accent=col["color5"], sub=col["color8"])
    except (OSError, KeyError, ValueError):
        pass
    return c


def css(c):
    return f"""
window.popup, window.clickaway {{ background-color: transparent; }}
.card {{ background-color: {c['bg']}; border: 2px solid {c['surface']};
        border-radius: 14px; color: {c['fg']}; }}
* {{ font-family: "JetBrainsMono Nerd Font", sans-serif; font-size: 13px; }}
.title {{ font-weight: bold; font-size: 14px; }}
.sub, .time {{ color: alpha({c['fg']}, 0.6); }}
.time {{ font-size: 11px; }}
.seek {{ margin-bottom: -6px; }}
.art {{ background-color: {c['surface']}; border-radius: 10px; font-size: 30px; }}
button {{ background: {c['surface']}; border: none; border-radius: 10px; color: {c['fg']};
         box-shadow: none; padding: 4px 12px; min-height: 0; }}
button:hover {{ background: alpha({c['accent']}, 0.6); }}
.ctl {{ font-size: 18px; padding: 4px 16px; }}
.play {{ background: {c['accent']}; color: {c['bg']}; }}
.play:hover {{ background: alpha({c['accent']}, 0.8); }}
.flat {{ background: transparent; padding: 2px 6px; font-size: 16px; }}
scale trough {{ background: {c['surface']}; border-radius: 4px; min-height: 6px; }}
scale highlight {{ background: {c['accent']}; border-radius: 4px; }}
scale slider {{ background: {c['fg']}; border: none; border-radius: 50%; min-width: 12px;
               min-height: 12px; margin: -4px; box-shadow: none; }}
combobox button {{ padding: 2px 8px; }}
""".encode()


def fmt(secs):
    secs = max(0, int(secs))
    return f"{secs // 60}:{secs % 60:02d}"


def toggle_or_exit():
    """If a popup is already open, close it and exit; else claim the pidfile."""
    try:
        pid = int(open(PIDFILE).read())
        if "music-popup" in open(f"/proc/{pid}/cmdline").read():
            os.kill(pid, signal.SIGTERM)
            sys.exit(0)
    except (OSError, ValueError):
        pass
    # The click on the module that closed us via the click-away layer also
    # launches us again; don't reopen straight away.
    try:
        if time.time() - float(open(CLOSEDFILE).read()) < 0.4:
            sys.exit(0)
    except (OSError, ValueError):
        pass
    open(PIDFILE, "w").write(str(os.getpid()))


def cursor_x():
    """Cursor x relative to the focused monitor, so the popup opens under the click."""
    try:
        pos = json.loads(run("hyprctl", "cursorpos", "-j"))
        mon = next(m for m in json.loads(run("hyprctl", "monitors", "-j")) if m["focused"])
        return pos["x"] - mon["x"], mon["width"] / mon["scale"]
    except (ValueError, KeyError, StopIteration):
        return None, None


class ClickAway(Gtk.Window):
    """Invisible full-screen layer under the popup; any click on it closes the popup."""

    def __init__(self, on_click):
        super().__init__()
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "music-popup-clickaway")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM,
                     GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
            GtkLayerShell.set_anchor(self, edge, True)
        GtkLayerShell.set_exclusive_zone(self, -1)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)
        self.set_visual(Gdk.Screen.get_default().get_rgba_visual())
        self.get_style_context().add_class("clickaway")
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
        self.connect("button-press-event", lambda *_: on_click())


class Popup(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.get_style_context().add_class("popup")
        self.set_size_request(WIDTH, -1)
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "music-popup")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 4)
        x, mon_w = cursor_x()
        left = 8 if x is None else min(max(8, int(x - WIDTH / 2)), int(mon_w - WIDTH - 8))
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.LEFT, left)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        screen = Gdk.Screen.get_default()
        self.set_visual(screen.get_rgba_visual())
        prov = Gtk.CssProvider()
        prov.load_from_data(css(palette()))
        Gtk.StyleContext.add_provider_for_screen(screen, prov, Gtk.STYLE_PROVIDER_PRIORITY_USER)

        # The window itself stays transparent so the card's rounded corners show.
        card = Gtk.Box()
        card.get_style_context().add_class("card")
        self.add(card)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        for side in ("top", "bottom", "start", "end"):
            getattr(box, f"set_margin_{side}")(14)
        card.pack_start(box, True, True, 0)

        # ── Player switcher (only shown with more than one player) ──
        self.players = []
        self.player = None
        self.switcher = Gtk.ComboBoxText()
        self.switcher_handler = self.switcher.connect("changed", self.on_switch)
        box.pack_start(self.switcher, False, False, 0)

        # ── Art + track info ──
        top = Gtk.Box(spacing=12)
        self.art = Gtk.Image()
        self.art_frame = Gtk.EventBox()
        self.art_frame.set_size_request(ART, ART)
        self.art_frame.get_style_context().add_class("art")
        self.art_placeholder = Gtk.Label(label="󰎈")
        self.art_frame.add(self.art_placeholder)
        self.art_url = None
        top.pack_start(self.art_frame, False, False, 0)
        info = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2, valign=Gtk.Align.CENTER)
        self.l_title = self.label("Nothing playing", "title")
        self.l_artist = self.label("", "sub")
        self.l_album = self.label("", "sub")
        for lbl in (self.l_title, self.l_artist, self.l_album):
            lbl.set_ellipsize(3)
            lbl.set_max_width_chars(26)
            info.pack_start(lbl, False, False, 0)
        top.pack_start(info, True, True, 0)
        box.pack_start(top, False, False, 0)

        # ── Seek bar ──
        self.length = 0
        self.seek = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 1, 1)
        self.seek.set_draw_value(False)
        self.seek.get_style_context().add_class("seek")
        self.seek.connect("change-value", self.on_seek)
        seek_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        seek_box.pack_start(self.seek, False, False, 0)
        times = Gtk.Box()
        self.l_pos = self.label("0:00", "time")
        self.l_len = self.label("0:00", "time")
        times.pack_start(self.l_pos, False, False, 0)
        times.pack_end(self.l_len, False, False, 0)
        seek_box.pack_start(times, False, False, 0)
        box.pack_start(seek_box, False, False, 0)

        # ── Controls ──
        ctl = Gtk.Box(spacing=8, halign=Gtk.Align.CENTER)
        self.b_play = None
        for icon, cmd in (("󰓛", "stop"), ("󰒮", "previous"), ("󰐊", "play-pause"), ("󰒭", "next")):
            b = Gtk.Button(label=icon)
            b.get_style_context().add_class("ctl")
            b.connect("clicked", lambda _b, c=cmd: self.control(c))
            ctl.pack_start(b, False, False, 0)
            if cmd == "play-pause":
                b.get_style_context().add_class("play")
                self.b_play = b
        box.pack_start(ctl, False, False, 2)

        # ── Volume (system output) ──
        vol = Gtk.Box(spacing=8)
        self.b_mute = Gtk.Button(label="󰕾")
        self.b_mute.get_style_context().add_class("flat")
        self.b_mute.connect("clicked", lambda _b: (bg("swayosd-client", "--output-volume", "mute-toggle"), GLib.timeout_add(150, self.refresh_once)))
        self.vol = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.vol.set_draw_value(False)
        self.vol.connect("change-value", self.on_volume)
        self.l_vol = self.label("", "time")
        self.l_vol.set_width_chars(4)
        vol.pack_start(self.b_mute, False, False, 0)
        vol.pack_start(self.vol, True, True, 0)
        vol.pack_start(self.l_vol, False, False, 0)
        box.pack_start(vol, False, False, 0)

        self.dragging_until = 0
        self.vol_dragging_until = 0
        self.vol_lock = threading.Lock()
        self.vol_target = None
        self.vol_worker = False
        self.connect("key-press-event", lambda _w, e: e.keyval == Gdk.KEY_Escape and self.close_popup())
        self.connect("destroy", lambda *_: Gtk.main_quit())
        # Backdrop must be mapped first so the popup stacks above it.
        self.clickaway = ClickAway(self.close_popup)
        self.clickaway.show_all()
        self.show_all()
        self.switcher.hide()
        self.refresh_once()
        GLib.timeout_add(1000, self.refresh)

    @staticmethod
    def label(text, cls):
        lbl = Gtk.Label(label=text, xalign=0)
        lbl.get_style_context().add_class(cls)
        return lbl

    def pctl(self, *args):
        return ("playerctl", "-p", self.player, *args) if self.player else ("playerctl", *args)

    def control(self, cmd):
        bg(*self.pctl(cmd))
        GLib.timeout_add(200, self.refresh_once)

    def on_seek(self, _scale, _scroll, value):
        self.dragging_until = time.time() + 1.5
        self.l_pos.set_text(fmt(value))
        bg(*self.pctl("position", str(max(0, value))))
        return False

    def on_volume(self, _scale, _scroll, value):
        value = int(min(100, max(0, value)))
        self.l_vol.set_text(f"{value}%")
        self.vol_dragging_until = time.time() + 1.5
        with self.vol_lock:
            self.vol_target = value
            if self.vol_worker:
                return False
            self.vol_worker = True
        threading.Thread(target=self.apply_volume, daemon=True).start()
        return False

    def apply_volume(self):
        """Set the latest slider value, then show swayosd's popup like the volume keys do.

        Dragging fires many events; this applies only the newest one at a time.
        swayosd-client's numbers are relative, so pamixer sets the level and
        "+0" just displays it.
        """
        while True:
            with self.vol_lock:
                target = self.vol_target
            run("pamixer", "--set-volume", str(target))
            run("swayosd-client", "--output-volume", "+0")
            with self.vol_lock:
                if self.vol_target == target:
                    self.vol_worker = False
                    return

    def on_switch(self, combo):
        name = combo.get_active_text()
        if name and name != self.player:
            self.player = name
            self.art_url = None
            self.refresh_once()

    def close_popup(self):
        try:
            open(CLOSEDFILE, "w").write(str(time.time()))
        except OSError:
            pass
        self.clickaway.destroy()
        self.destroy()

    # ── Polling ──
    def refresh(self):
        self.refresh_once()
        return True

    def refresh_once(self):
        threading.Thread(target=self.collect, daemon=True).start()
        return False

    def collect(self):
        players = [p for p in run("playerctl", "-l").splitlines() if p]
        player = self.player if self.player in players else None
        if player is None and players:
            # Prefer whatever is playing, like waybar's module does.
            playing = [p for p in players if run("playerctl", "-p", p, "status") == "Playing"]
            player = (playing or players)[0]
        meta = []
        if player:
            fmt_str = SEP.join("{{" + f + "}}" for f in FIELDS)
            meta = run("playerctl", "-p", player, "metadata", "--format", fmt_str).split(SEP)
        volume = run("pamixer", "--get-volume")
        muted = run("pamixer", "--get-mute") == "true"
        GLib.idle_add(self.apply, players, player, meta, volume, muted)

    def apply(self, players, player, meta, volume, muted):
        if players != self.players:
            self.players = players
            self.switcher.handler_block(self.switcher_handler)
            self.switcher.remove_all()
            for p in players:
                self.switcher.append_text(p)
            self.switcher.handler_unblock(self.switcher_handler)
            self.switcher.set_visible(len(players) > 1)
        self.player = player
        if player in players:
            self.switcher.handler_block(self.switcher_handler)
            self.switcher.set_active(players.index(player))
            self.switcher.handler_unblock(self.switcher_handler)

        if len(meta) == len(FIELDS):
            info = dict(zip(FIELDS, meta))
            self.l_title.set_text(info["title"] or "Unknown")
            self.l_artist.set_text(info["artist"])
            self.l_album.set_text(info["album"])
            self.b_play.set_label("󰏤" if info["status"] == "Playing" else "󰐊")
            length = int(info["mpris:length"] or 0) / 1e6
            pos = int(info["position"] or 0) / 1e6
            if length != self.length:
                self.length = length
                self.seek.set_range(0, max(length, 1))
                self.l_len.set_text(fmt(length))
            self.seek.set_sensitive(length > 0)
            if time.time() > self.dragging_until:
                self.seek.set_value(pos)
                self.l_pos.set_text(fmt(pos))
            self.set_art(info["mpris:artUrl"])
        else:
            self.l_title.set_text("Nothing playing")
            self.l_artist.set_text("")
            self.l_album.set_text("")
            self.b_play.set_label("󰐊")
            self.seek.set_sensitive(False)
            self.set_art("")

        if volume.isdigit() and time.time() > self.vol_dragging_until:
            self.vol.set_value(int(volume))
            self.l_vol.set_text(f"{volume}%")
        self.b_mute.set_label("󰖁" if muted else "󰕾")
        return False

    # ── Album art ──
    def set_art(self, url):
        if url == self.art_url:
            return
        self.art_url = url
        if not url:
            return self.show_art(None)
        threading.Thread(target=self.load_art, args=(url,), daemon=True).start()

    def load_art(self, url):
        path = None
        if url.startswith("file://"):
            path = urllib.request.url2pathname(url[7:])
        elif url.startswith(("http://", "https://")):
            os.makedirs(ART_CACHE, exist_ok=True)
            path = os.path.join(ART_CACHE, hashlib.sha1(url.encode()).hexdigest())
            if not os.path.exists(path):
                try:
                    urllib.request.urlretrieve(url, path + ".tmp")
                    os.replace(path + ".tmp", path)
                except OSError:
                    path = None
        GLib.idle_add(self.show_art, path, url)

    def show_art(self, path, url=None):
        if url is not None and url != self.art_url:
            return False  # a newer track's art is already on its way
        child = self.art_frame.get_child()
        pixbuf = None
        if path:
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, ART, ART, True)
            except GLib.Error:
                pass
        new = self.art_placeholder
        if pixbuf:
            self.art.set_from_pixbuf(pixbuf)
            new = self.art
        if child is not new:
            self.art_frame.remove(child)
            self.art_frame.add(new)
            new.show()
        return False


if __name__ == "__main__":
    toggle_or_exit()
    signal.signal(signal.SIGTERM, lambda *_: Gtk.main_quit())
    Popup()
    Gtk.main()
