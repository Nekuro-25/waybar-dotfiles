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
CPU_STATE="/tmp/waybar-hardware-cpu"
HWMON_ROOT="${HWMON_ROOT:-/sys/class/hwmon}"


# ------------------------------------------------------------
# HIDDEN STATE
# ------------------------------------------------------------

if [[ ! -f "$STATE_FILE" ]]; then
    rm -f "$CPU_STATE"
    printf '{"text":"","tooltip":false}\n'
    exit 0
fi


# ------------------------------------------------------------
# CPU
# ------------------------------------------------------------

# Pemakaian CPU dihitung dari selisih dua sampel /proc/stat
# (bukan rata-rata sejak boot), jadi angkanya mengikuti beban saat ini.
read_cpu() {
    local _ user nice system idle iowait irq softirq steal
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    CPU_TOTAL=$((user + nice + system + idle + iowait + irq + softirq + steal))
    CPU_IDLE=$((idle + iowait))
}

read_cpu

if [[ -r "$CPU_STATE" ]]; then
    read -r PREV_TOTAL PREV_IDLE < "$CPU_STATE"
else
    # Belum ada sampel sebelumnya: ambil satu sampel pendek.
    PREV_TOTAL=$CPU_TOTAL
    PREV_IDLE=$CPU_IDLE
    sleep 0.25
    read_cpu
fi

echo "$CPU_TOTAL $CPU_IDLE" > "$CPU_STATE"

DELTA_TOTAL=$((CPU_TOTAL - PREV_TOTAL))
DELTA_IDLE=$((CPU_IDLE - PREV_IDLE))

CPU_USAGE=0
if (( DELTA_TOTAL > 0 )); then
    CPU_USAGE=$(( 100 * (DELTA_TOTAL - DELTA_IDLE) / DELTA_TOTAL ))
fi


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

# Pilih sensor suhu CPU berdasarkan NAMA, bukan nomor hwmon
# (nomor bisa berubah antar boot, dan hwmon pertama yang punya
# suhu biasanya NVMe, bukan CPU).
#   k10temp  = CPU AMD
#   coretemp = CPU Intel
for name_file in "$HWMON_ROOT"/hwmon*/name; do

    case "$(cat "$name_file" 2>/dev/null)" in
        k10temp|coretemp|zenpower)

            sensor="$(dirname "$name_file")/temp1_input"

            if [[ -r "$sensor" ]]; then

                value=$(cat "$sensor" 2>/dev/null)

                if [[ "$value" =~ ^[0-9]+$ ]]; then
                    TEMP="$((value / 1000))°C"
                    break
                fi

            fi
            ;;
    esac

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
