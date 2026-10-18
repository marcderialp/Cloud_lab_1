#!/bin/sh
primary() {
    for h in pg-1 pg-2 pg-3; do
        wget -qO /dev/null -T 2 "http://$h:8008/primary" 2>/dev/null && return 0
    done
    return 1
}
routed() {
    [ "$(printf '\000\000\000\010\004\322\026\057' | nc -w 2 db 5432 2>/dev/null | head -c1)" != "" ]
}
echo "waiting for a PostgreSQL primary behind haproxy"
i=0
until primary && routed; do
    i=$((i+1))
    [ $i -lt 120 ] || { echo "no primary after 4 min, starting anyway"; break; }
    sleep 2
done
exec /run.sh "$@"
