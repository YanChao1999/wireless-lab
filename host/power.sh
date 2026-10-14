#!/bin/sh
# Host-side control of the programmable power module.
# Usage: power.sh on|off|cycle
# Backend selected with POWER_BACKEND:
#   cmd      POWER_ON_CMD / POWER_OFF_CMD run via sh -c (any relay/PDU/GPIO tool)
#   uhubctl  POWER_HUB (-l) and POWER_PORT (-p) of a switchable USB hub
#   http     POWER_URL base; calls $POWER_URL/on and $POWER_URL/off (curl)
#   manual   prompts the operator (default)
set -eu
act=${1:?usage: power.sh on|off|cycle}
backend=${POWER_BACKEND:-manual}
delay=${POWER_CYCLE_DELAY:-3}

do_set() {
    case "$backend" in
    cmd)
        if [ "$1" = on ]; then c=${POWER_ON_CMD:?POWER_ON_CMD}; else c=${POWER_OFF_CMD:?POWER_OFF_CMD}; fi
        sh -c "$c" ;;
    uhubctl)
        uhubctl -l "${POWER_HUB:?POWER_HUB}" -p "${POWER_PORT:?POWER_PORT}" -a "$1" ;;
    http)
        curl -fsS "${POWER_URL:?POWER_URL}/$1" >/dev/null ;;
    manual)
        printf 'Switch board power %s, then press Enter: ' "$1"; read -r _ ;;
    *) echo "unknown POWER_BACKEND=$backend" >&2; exit 1 ;;
    esac
}

case "$act" in
on|off) do_set "$act" ;;
cycle) do_set off; sleep "$delay"; do_set on ;;
*) echo "usage: power.sh on|off|cycle" >&2; exit 1 ;;
esac
