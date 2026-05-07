set -euo pipefail

EXIT_CODE=0

run() {
    local success=$1
    local wait=$2
    local message=$3
    printf ' - %-20s ' "$message"
    sleep "$wait"
    if [ "$success" -eq 1 ]
    then
        printf '\e[32mOK\e[m\n'
    else
        printf '\e[31mFAIL\e[m\n'
        EXIT_CODE=1
    fi
}

run 1 0.4 "doing something"
run 1 0.3 "more stuff"
run 1 1.2 "something important"
run 1 0.4 "closing everything"

exit "$EXIT_CODE"



# vim: ft=bash
