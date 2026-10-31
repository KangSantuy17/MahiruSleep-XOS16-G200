#!/system/bin/sh
MODDIR="${0%/*}"
LOG="/data/local/tmp/mahirusleep-xos16-g200.log"

# Avoid running duplicate instances.
if [ -f "$MODDIR/service.pid" ]; then
    OLD_PID="$(cat "$MODDIR/service.pid" 2>/dev/null)"
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        exit 0
    fi
fi

mkdir -p /data/local/tmp
: > "$LOG"
echo $$ > "$MODDIR/service.pid"

# Give Android time to finish booting.
sleep 20

"$MODDIR/scripts/sleep.sh" >> "$LOG" 2>&1
