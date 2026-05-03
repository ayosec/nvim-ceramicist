#!/usr/bin/env bash

set -euo pipefail

cd "${0%/*}"

set -x
sed 's/#16080d;/#c2ada3;/' < logo.svg > dark-logo.svg
