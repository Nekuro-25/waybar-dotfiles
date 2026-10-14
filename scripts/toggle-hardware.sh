#!/usr/bin/env bash

# ============================================================
# TOGGLE WAYBAR HARDWARE PANEL
#
# SUPER + I
#
#   hidden → visible
#   visible → hidden
# ============================================================

STATE_FILE="/tmp/waybar-hardware-visible"

if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
else
    touch "$STATE_FILE"
fi

# SIGRTMIN + 8
# digunakan oleh custom/hardware
pkill -RTMIN+8 waybar
