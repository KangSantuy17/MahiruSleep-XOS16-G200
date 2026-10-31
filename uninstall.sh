#!/system/bin/sh
MODDIR="${0%/*}"
STATE="$MODDIR/state"

# Best-effort restore if state data is still present.
if [ -f "$STATE/saved" ]; then
    while read -r cpu online; do
        [ "$online" = "1" ] && echo 1 > "/sys/devices/system/cpu/cpu$cpu/online" 2>/dev/null
    done < "$STATE/cpu_online"

    while read -r policy key value; do
        if [ "$key" = "governor" ]; then
            echo "$value" > "/sys/devices/system/cpu/cpufreq/$policy/scaling_governor" 2>/dev/null
        elif [ "$key" = "max_freq" ]; then
            echo "$value" > "/sys/devices/system/cpu/cpufreq/$policy/scaling_max_freq" 2>/dev/null
        fi
    done < "$STATE/values"

    while read -r cpu online; do
        [ "$online" = "0" ] && echo 0 > "/sys/devices/system/cpu/cpu$cpu/online" 2>/dev/null
    done < "$STATE/cpu_online"
fi

rm -f "$MODDIR/service.pid"
