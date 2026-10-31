#!/system/bin/sh
SCRIPT_DIR="$(CDPATH= cd -- "${0%/*}" 2>/dev/null && pwd)"
MODDIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
STATE="$MODDIR/state"
LOG="/data/local/tmp/mahirusleep-xos16-g200.log"
BACKLIGHT="/sys/class/leds/lcd-backlight/brightness"
POLL_INTERVAL=2

mkdir -p "$STATE"

log() {
    echo "[$(date '+%F %T' 2>/dev/null)] $*" >> "$LOG"
}

read_value() {
    [ -r "$1" ] && cat "$1" 2>/dev/null
}

write_value() {
    node="$1"
    value="$2"

    [ -e "$node" ] || {
        log "SKIP missing node: $node"
        return 1
    }

    if echo "$value" > "$node" 2>/dev/null; then
        actual="$(read_value "$node")"
        log "WRITE $node requested=$value actual=$actual"
        [ "$actual" = "$value" ]
    else
        log "FAIL write $node value=$value"
        return 1
    fi
}

save_once() {
    [ -f "$STATE/saved" ] && return 0
    : > "$STATE/values"

    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -d "$policy" ] || continue
        name="${policy##*/}"
        governor="$(read_value "$policy/scaling_governor")"
        max_freq="$(read_value "$policy/scaling_max_freq")"
        [ -n "$governor" ] && echo "$name governor $governor" >> "$STATE/values"
        [ -n "$max_freq" ] && echo "$name max_freq $max_freq" >> "$STATE/values"
    done

    : > "$STATE/cpu_online"
    for cpu in 3 4 5 7; do
        node="/sys/devices/system/cpu/cpu$cpu/online"
        value="$(read_value "$node")"
        [ -n "$value" ] && echo "$cpu $value" >> "$STATE/cpu_online"
    done

    touch "$STATE/saved"
    log "Saved original CPU policy and online states in $STATE."
}

restore_values() {
    [ -f "$STATE/saved" ] || return 0
    log "Restoring saved CPU settings."

    while read -r cpu online; do
        [ "$online" = "1" ] && write_value "/sys/devices/system/cpu/cpu$cpu/online" 1
    done < "$STATE/cpu_online"

    while read -r policy key value; do
        [ "$key" = "governor" ] || continue
        node="/sys/devices/system/cpu/cpufreq/$policy/scaling_governor"
        write_value "$node" "$value"
    done < "$STATE/values"

    # Match the original MahiruSleep screen-on frequency profile.
    # These are fixed caps, not the hardware maximum.
    write_value "/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq" 2000000
    write_value "/sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq" 2200000

    while read -r cpu online; do
        [ "$online" = "0" ] && write_value "/sys/devices/system/cpu/cpu$cpu/online" 0
    done < "$STATE/cpu_online"

    rm -f "$STATE/saved" "$STATE/values" "$STATE/cpu_online"
    log "Original CPU settings restored; state files removed."
}

apply_sleep_profile() {
    save_once
    log "Applying screen-off CPU profile."

    for cpu in 3 4 5 7; do
        node="/sys/devices/system/cpu/cpu$cpu/online"
        write_value "$node" 0
    done

    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -d "$policy" ] || continue
        write_value "$policy/scaling_governor" powersave
    done

    write_value "/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq" 500000
    write_value "/sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq" 725000

    log "Screen-off profile result: online=$(read_value /sys/devices/system/cpu/online)"
}

display_state() {
    dumpsys power 2>/dev/null | grep -m 1 -E 'mWakefulness=|Display Power: state='
}

is_screen_on() {
    state="$(display_state)"
    case "$state" in
        *Awake*|*"state=ON"*) return 0 ;;
        *) return 1 ;;
    esac
}

cleanup() {
    restore_values
    rm -f "$MODDIR/service.pid"
}
trap cleanup INT TERM EXIT

log "Starting as uid=$(id -u 2>/dev/null); module=$MODDIR; state=$STATE"
[ -r "$BACKLIGHT" ] || log "Warning: backlight node not readable: $BACKLIGHT"
log "Started display polling loop."

last_state="unknown"
while :; do
    if is_screen_on; then
        current_state="on"
    else
        current_state="off"
    fi

    if [ "$current_state" != "$last_state" ]; then
        if [ "$current_state" = "off" ]; then
            apply_sleep_profile
        else
            restore_values
        fi
        log "Display state: $current_state"
        last_state="$current_state"
    fi

    sleep "$POLL_INTERVAL"
done
