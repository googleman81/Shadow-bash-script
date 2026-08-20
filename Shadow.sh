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
    local me="${1:-}"

    if [[ -z "$me" || "$me" == "root" || "$me" == "loginwindow" ]]; then
        echo "[Shadow] Shinobi 2.1 received an invalid protected user." >&2
        exit 1
    fi

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
    /usr/bin/awk -v protected_user="$me" \
        'NR > 1 && $3 != protected_user'
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
    local streamer_name="GeForceNOWStreamer"
    local container_name="GeForceNOWContainer"
    local gfn_was_running=false
    local gfn_running path

    local gfn_root="$HOME/Library/Application Support/NVIDIA/GeForceNOW"
    local cef_default="$gfn_root/CefCache/Default"
    local darwin_cache="$(/usr/bin/getconf DARWIN_USER_CACHE_DIR)"
    local darwin_temp="$(/usr/bin/getconf DARWIN_USER_TEMP_DIR)"

    local clean_paths=(
        # Existing 2.4 targets
        "$HOME/Library/Caches/GeForceNOW"
        "$HOME/Library/Logs/GeForceNOW"
        "$HOME/Library/Caches/NVIDIA"
        "$HOME/Library/Logs/NVIDIA"
        "$gfn_root/logs"
        "$gfn_root/telemetry"
        "$gfn_root/temp"
        "$gfn_root/tempFreestylePreview"
        "$cef_default/Session Storage"
        "$cef_default/Service Worker/CacheStorage"
        "$cef_default/Service Worker/ScriptCache"

        # Complete observed GFN root, excluding sharedstorage.json
        "$gfn_root/CefCache"
        "$gfn_root/ReliabilityMonitor"
        "$gfn_root/Share"
        "$gfn_root/CxNative_GeForceNOW*.log"
        "$gfn_root/geronimo.log"
        "$gfn_root/console.log"
        "$gfn_root/debug.log"
        "$gfn_root/MessageBus_GFN_session*.conf
        "$gfn_root/NvCrimson.gfnupdate.json"
        "$gfn_root/NvCrimson.sharedstorage.json"
        "$gfn_root/NvCrimson.storage.json"
        "$gfn_root/storage.json"
        "$gfn_root/updatestatus.json"

        # Current and legacy Application Support
        "$HOME/Library/Application Support/NVIDIA Corporation"
        "$HOME/Library/Application Support/GeForceNOW"
        "$HOME/Library/Application Support/com.nvidia.GeForceNOW"
        "$HOME/Library/Application Support/com.nvidia.gfnpc.mall"

        # Current and legacy caches
        "$HOME/Library/Caches/com.nvidia.gfnpc.mall"
        "$HOME/Library/Caches/com.nvidia.GeForceNOW"
        "$HOME/Library/Caches/com.nvidia.nvcontainer"
        "$HOME/Library/Caches/com.apple.nsurlsessiond/Downloads/com.nvidia.gfnpc.mall"

        # HTTP, WebKit and cookie state
        "$HOME/Library/HTTPStorages/com.nvidia.gfnpc.mall"
        "$HOME/Library/HTTPStorages/com.nvidia.GeForceNOW"
        "$HOME/Library/HTTPStorages/com.nvidia.nvcontainer"
        "$HOME/Library/WebKit/com.nvidia.gfnpc.mall"
        "$HOME/Library/WebKit/com.nvidia.GeForceNOW"
        "$HOME/Library/Cookies/com.nvidia.gfnpc.mall.binarycookies"
        "$HOME/Library/Cookies/com.nvidia.GeForceNOW.binarycookies"

        # Saved state, scripts and shared containers
        "$HOME/Library/Saved Application State/com.nvidia.gfnpc.mall.savedState"
        "$HOME/Library/Saved Application State/com.nvidia.GeForceNOW.savedState"
        "$HOME/Library/Application Scripts/com.nvidia.gfnpc.mall"
        "$HOME/Library/Application Scripts/com.nvidia.GeForceNOW"
        "$HOME/Library/Application Scripts/com.nvidia.nvcontainer"
        "$HOME/Library/Group Containers/group.com.nvidia.gfnpc.mall"
        "$HOME/Library/Group Containers/group.com.nvidia.GeForceNOW"

        # Current and legacy preference plists
        "$HOME/Library/Preferences"/com.nvidia.gfnpc.mall*.plist
        "$HOME/Library/Preferences"/com.nvidia.GeForceNOW*.plist
        "$HOME/Library/Preferences"/com.nvidia.nvcontainer*.plist

        # Exact current-user Darwin caches
        "$darwin_cache/com.nvidia.gfnpc.mall"
        "$darwin_cache/com.nvidia.gfnpc.mall.helper.gpu"

        # Randomly suffixed current-user temporary directories
        "$darwin_temp"/.com.nvidia.gfnpc.mall.*
        "$darwin_temp"/com.nvidia.gfnpc.mall*
        "$darwin_temp"/.com.nvidia.GeForceNOW.*
        "$darwin_temp"/com.nvidia.GeForceNOW*

        # User crash-report bookkeeping and reports
        "$HOME/Library/Application Support/CrashReporter"/GeForceNOW*
        "$HOME/Library/Application Support/CrashReporter"/com.nvidia.gfnpc.mall*
        "$HOME/Library/Logs/DiagnosticReports"/GeForceNOW*
        "$HOME/Library/Logs/DiagnosticReports"/com.nvidia.gfnpc.mall*

        # System diagnostic reports observed during inventory
        "/Library/Logs/DiagnosticReports"/GeForceNOW*
        "/Library/Logs/DiagnosticReports"/com.nvidia.gfnpc.mall*
    )

    while true; do
        if /usr/bin/pgrep -x "$process_name" >/dev/null 2>&1 ||
           /usr/bin/pgrep -x "$streamer_name" >/dev/null 2>&1; then
            gfn_running=true
        else
            gfn_running=false
        fi

        if [[ "$gfn_running" == true ]]; then
            gfn_was_running=true
            /bin/sleep 15
        else
            if [[ "$gfn_was_running" == true ]]; then
                if /usr/bin/pgrep -x "$container_name" >/dev/null 2>&1; then
                    /usr/bin/pkill -TERM -x "$container_name" 2>/dev/null
                    /bin/sleep 5

                    if /usr/bin/pgrep -x "$container_name" >/dev/null 2>&1; then
                        /usr/bin/pkill -KILL -x "$container_name" 2>/dev/null
                    fi
                fi

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
        shinobi2_1 "${2:-}"
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
# 🚀 Launch background workers
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
    local worker_arg="${3:-}"

    if worker_running "$worker"; then
        echo "[Shadow] $label is already running."
        return
    fi

    if [[ -n "$worker_arg" ]]; then
        /usr/bin/nohup "$SCRIPT_PATH" "$worker" "$worker_arg" >/dev/null 2>&1 &
    else
        /usr/bin/nohup "$SCRIPT_PATH" "$worker" >/dev/null 2>&1 &
    fi

    echo "[Shadow] Started $label."
}

# launch_root_worker --shadow-worker-shinobi21 "Shinobi 2.1" "$REAL_USER"
launch_user_worker --shadow-worker-shinobi24 "Shinobi 2.4"
launch_root_worker --shadow-worker-airtouch "Airtouch"

echo
echo "🌑 Shadow is active. Runtime settings and workers reset after reboot."
exit 0
