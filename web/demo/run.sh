#!/usr/bin/env bash

set -euo pipefail

VIDEO_OUTPUT=$1

SRC="${0%/*}"

WORKDIR=$(mktemp -d)
export WORKDIR

PIDS=()
X11_DISPLAY=99

cleanup() {
    if [ "${#PIDS}" -gt 0 ]
    then
        set -x
        kill "${PIDS[@]}"
    fi

    wait
}

waitfile() {
    local path=$1
    local start=$SECONDS
    while ! [ -e "$path" ]
    do
        if [ $((SECONDS - start)) -gt 10 ]
        then
            echo "Timeout waiting for $path"
            exit 1
        fi

        sleep 0.1
    done
}

trap cleanup EXIT

# Launch Xvfb and wait for it to be available.
"$SRC/start-x11" $X11_DISPLAY &
PIDS+=($!)
waitfile /tmp/.X11-unix/X99

# Launch Neovim and wait for the signal that its init
# is completed.
export NVIM_SIGNAL="$WORKDIR/nvim-signal"
"$SRC/start-nvim" $X11_DISPLAY &
PIDS+=($!)

waitfile "$NVIM_SIGNAL"

record="$WORKDIR/record.nut"
"$SRC/record-x11" $X11_DISPLAY "$record" 60

"$SRC/captions" "$record" "$VIDEO_OUTPUT"
