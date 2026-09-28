#!/usr/bin/env bash

# ============================================================
# WAYBAR HARDWARE PANEL
#
# Menampilkan:
#   CPU
#   RAM
#   Temperature
#
# State disimpan di /tmp sehingga tidak perlu database
# atau konfigurasi permanen.
# ============================================================

STATE_FILE="/tmp/waybar-hardware-visible"


# ------------------------------------------------------------
# HIDDEN STATE
# ------------------------------------------------------------

if [[ ! -f "$STATE_FILE" ]]; then
    printf '{"text":"","tooltip":false}\n'
    exit 0
fi


# ------------------------------------------------------------
# CPU
# ------------------------------------------------------------

CPU_USAGE=$(awk '/^cpu / {
    idle=$5;
    total=$2+$3+$4+$5+$6+$7+$8;
    printf "%.0f", (1-idle/total)*100
}' /proc/stat)


# ------------------------------------------------------------
# MEMORY
# ------------------------------------------------------------

MEMORY_USAGE=$(free | awk '/Mem:/ {
    printf "%.0f", ($3/$2)*100
}')


# ------------------------------------------------------------
# TEMPERATURE
# ------------------------------------------------------------

TEMP="N/A"

# Cari sensor temperatur pertama yang tersedia.
for sensor in /sys/class/hwmon/hwmon*/temp*_input; do

    if [[ -r "$sensor" ]]; then

        value=$(cat "$sensor" 2>/dev/null)

        if [[ "$value" =~ ^[0-9]+$ ]]; then
            TEMP="$((value / 1000))°C"
            break
        fi

    fi

done


# ------------------------------------------------------------
# OUTPUT
# ------------------------------------------------------------

printf '{"text":" %s%%    %s%%    %s","tooltip":"CPU: %s%%\\nRAM: %s%%\\nTemperature: %s"}\n' \
    "$CPU_USAGE" \
    "$MEMORY_USAGE" \
    "$TEMP" \
    "$CPU_USAGE" \
    "$MEMORY_USAGE" \
    "$TEMP"
