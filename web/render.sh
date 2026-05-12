#!/usr/bin/env bash

set -euo pipefail

OUTPUT=$(realpath "$1")
DEMO_VIDEO=$(realpath "$2")

SRC=$(realpath "${0%/*}")
README=$SRC/../README.md

mkdir -p "$OUTPUT"

cd "$SRC"
pandoc_args=(
    --standalone
    --css main.css
    --highlight-style breezeDark
    --syntax-definition viml-syntax.xml
    --lua-filter filter.lua
    --metadata title=
    --metadata pagetitle=Ceramicist
    --output "$OUTPUT/index.html"
)

set -x
sed '1,/<!-- website-start -->/d' "$README" |
    pandoc "${pandoc_args[@]}" \
        --include-before-body=<("$SRC/header" "$DEMO_VIDEO")


# Embed <link> style. Can't use `--embed-resources` because it
# will try to download @import resources.
sed --in-place --regexp-extended "
    /^\s*<link rel=\"stylesheet\" href=\"main.css\" \/>\s*$/ {
        i <style>
        r main.css
        a </style>
        d
    }
" "$OUTPUT/index.html"
