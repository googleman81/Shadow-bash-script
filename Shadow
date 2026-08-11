#!/bin/bash

# ================================================================
# 🌑 Shadow — Unified macOS / GeForce NOW Optimizer
#
# Runs once with elevated privileges, then leaves three lightweight
# background workers active: Shinobi 2.1, Shinobi 2.4, and Airtouch.
#
# Usage:
#   chmod +x Shadow.sh
#   sudo ./Shadow.sh
#
# Rebooting restores runtime sysctl values and stops all workers.
# ================================================================

set -u

SCRIPT_PATH="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)/$(basename "$0")"

# ----------------------------------------------------------------
# Internal workers — launched by the elevated parent below.
# ----------------------------------------------------------------

shinobi2_1() {
    local port lsof_output pid
    local me
    me="$(/usr/bin/id -un)"

    local ports=(
        # 🌐 Universal ports
        80 443 3478 4379 4380 322 8282 5228

        # 🎮 GeForce NOW ports
        49003 49004 49005 49006

        # 📺 Chromium MediaRouter / Chromecast
        8008 8009

        # 🎮 Steam ports
        27000 27001 27002 27003 27004 27005 27006 27007 27008 27009
        27010 27011 27012 27013 27014 27015 27016 27017 27018 27019
        27020 27021 27022 27023 27024 27025 27026 27027 27028 27029
        27030 27031 27032 27033 27034 27035 27036 27037 27038 27039
        27040 27041 27042 27043 27044 27045 27046 27047 27048 27049
        27050
    )

    while true; do
        for port in "${ports[@]}"; do
            lsof_output="$(
                /usr/sbin/lsof -nP \
                    -iUDP:"$port" -iTCP:"$port" \
                    -i6UDP:"$port" -i6TCP:"$port" 2>/dev/null |
                /usr/bin/grep -v "$me" |
                /usr/bin/awk 'NR>1'
            )"

            if [[ -n "$lsof_output" ]]; then
                while IFS= read -r pid; do
                    [[ "$pid" =~ ^[0-9]+$ ]] && /bin/kill -9 "$pid" 2>/dev/null || true
                done < <(
                    printf '%s\n' "$lsof_output" |
                    /usr/bin/awk '{print $2}' |
                    /usr/bin/sort -u
                )
            fi
        done
        /bin/sleep 2
    done
}

shinobi2_4() {
    local process_name="GeForceNOW"
    local gfn_was_running=false
    local gfn_running path

    local clean_paths=(
        "$HOME/Library/Caches/GeForceNOW"
        "$HOME/Library/Logs/GeForceNOW"
        "$HOME/Library/Caches/NVIDIA"
        "$HOME/Library/Logs/NVIDIA"
        "$HOME/Library/Application Support/GeForceNOW/cef"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/streaming-telemetry"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/temp"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/Cache"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/Code Cache"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/Session Storage"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/Network Persistent State"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/Service Worker/CacheStorage"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/Service Worker/ScriptCache"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/IndexedDB"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/Local Storage"
        "$HOME/Library/Application Support/NVIDIA/GeForceNOW/TransportSecurity"
    )

    while true; do
        if /usr/bin/pgrep -x "$process_name" >/dev/null 2>&1; then
            gfn_running=true
        else
            gfn_running=false
        fi

        if [[ "$gfn_running" == true ]]; then
            gfn_was_running=true
            /bin/sleep 15
        else
            if [[ "$gfn_was_running" == true ]]; then
                for path in "${clean_paths[@]}"; do
                    if [[ -d "$path" ]]; then
                        /bin/rm -rf \
                            "$path"/* \
                            "$path"/.[!.]* \
                            "$path"/..?* 2>/dev/null
                    elif [[ -e "$path" ]]; then
                        /bin/rm -f "$path" 2>/dev/null
                    fi
                done
            fi
            gfn_was_running=false
            /bin/sleep 60
        fi
    done
}

airtouch() {
    while true; do
        if /sbin/ifconfig awdl0 2>/dev/null | /usr/bin/grep -q 'status: active'; then
            /sbin/ifconfig awdl0 down >/dev/null 2>&1 || true
        fi
        /bin/sleep 60
    done
}

case "${1:-}" in
    --shadow-worker-shinobi21)
        shinobi2_1
        exit 0
        ;;
    --shadow-worker-shinobi24)
        shinobi2_4
        exit 0
        ;;
    --shadow-worker-airtouch)
        airtouch
        exit 0
        ;;
esac

# ----------------------------------------------------------------
# 🚦 Elevated entry point
# ----------------------------------------------------------------

if [[ "$(/usr/bin/id -u)" -ne 0 ]]; then
    echo "Shadow must be started with elevated privileges:"
    echo "  sudo ./Shadow.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(/usr/bin/stat -f '%Su' /dev/console)}"

if [[ -z "$REAL_USER" || "$REAL_USER" == "root" || "$REAL_USER" == "loginwindow" ]]; then
    echo "Shadow could not identify the logged-in user."
    exit 1
fi

REAL_HOME="$(
    /usr/bin/dscl . -read "/Users/$REAL_USER" NFSHomeDirectory 2>/dev/null |
    /usr/bin/sed 's/^NFSHomeDirectory: //'
)"

if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
    echo "Shadow could not identify the home folder for $REAL_USER."
    exit 1
fi

# ----------------------------------------------------------------
# 🌐 Initial sysctl tweaks (runtime only; reset after reboot)
# ----------------------------------------------------------------

apply_sysctl() {
    local setting="$1"
    if ! /usr/sbin/sysctl -w "$setting"; then
        echo "[Shadow] Warning: macOS rejected $setting" >&2
    fi
}

apply_sysctl net.inet.udp.recvspace=131072
apply_sysctl net.inet.tcp.delayed_ack=0
apply_sysctl net.inet.tcp.bg_target_qdelay=20
apply_sysctl net.inet.tcp.rtt_min=1
apply_sysctl net.inet.tcp.randomize_ports=1
apply_sysctl net.inet.tcp.recvspace=262144
apply_sysctl net.inet.tcp.sendspace=262144
apply_sysctl net.inet6.icmp6.rediraccept=0
apply_sysctl net.inet.tcp.l4s=1
apply_sysctl net.inet.tcp.accurate_ecn=1
apply_sysctl net.qos.policy.wifi_enabled=1

# ----------------------------------------------------------------
# 🚀 Launch background workers once
# ----------------------------------------------------------------

worker_running() {
    /usr/bin/pgrep -f "$SCRIPT_PATH $1" >/dev/null 2>&1
}

launch_user_worker() {
    local worker="$1"
    local label="$2"

    if worker_running "$worker"; then
        echo "[Shadow] $label is already running."
        return
    fi

    /usr/bin/sudo -u "$REAL_USER" \
        /usr/bin/env HOME="$REAL_HOME" USER="$REAL_USER" LOGNAME="$REAL_USER" \
        /usr/bin/nohup "$SCRIPT_PATH" "$worker" >/dev/null 2>&1 &
    echo "[Shadow] Started $label for $REAL_USER."
}

launch_root_worker() {
    local worker="$1"
    local label="$2"

    if worker_running "$worker"; then
        echo "[Shadow] $label is already running."
        return
    fi

    /usr/bin/nohup "$SCRIPT_PATH" "$worker" >/dev/null 2>&1 &
    echo "[Shadow] Started $label."
}

launch_user_worker --shadow-worker-shinobi21 "Shinobi 2.1"
launch_user_worker --shadow-worker-shinobi24 "Shinobi 2.4"
launch_root_worker --shadow-worker-airtouch "Airtouch"

echo
echo "🌑 Shadow is active. Runtime settings and workers reset after reboot."
exit 0
