#!/bin/sh
set -e
label() {
    docker node update --label-add role="$2" ${3:+--label-add slot="$3"} "$1" >/dev/null
    echo "$1 -> role=$2${3:+ slot=$3}"
}
if [ $# -gt 0 ]; then
    for a in "$@"; do
        node=${a%%=*}; v=${a#*=}; label "$node" "${v%%:*}" "$( [ "$v" != "${v#*:}" ] && echo "${v#*:}")"
    done
    atenea=$(echo "$@" | tr ' ' '\n' | grep '=atenea' | head -n1 | cut -d= -f1)
    [ -n "$atenea" ] && echo "export NFS_SERVER=$(docker node inspect "$atenea" --format '{{.Status.Addr}}')"
    exit 0
fi
for n in $(docker node ls --format '{{.Hostname}}'); do
    case $n in
        *front*)  label "$n" front ;;
        *app*)    label "$n" app "$(echo "$n" | grep -o '[0-9]*' | tail -n1)" ;;
        *stats*)  label "$n" stats ;;
        *atenea*) label "$n" atenea ;;
        *backup*) label "$n" backup ;;
        *) echo "$n: name does not match, label it by hand" >&2 ;;
    esac
done

a=$(docker node ls --format '{{.Hostname}}' | grep atenea | head -n1)
[ -n "$a" ] && echo "export NFS_SERVER=$(docker node inspect "$a" --format '{{.Status.Addr}}')"
