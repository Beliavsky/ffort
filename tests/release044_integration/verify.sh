#!/bin/sh
# Portable verifier hook; no builds and no implicit candidate/GNU discovery.
set -eu
if [ "$#" -ne 2 ]; then
  echo 'usage: verify.sh /absolute/fortfront-interpreter /absolute/gfortran' >&2
  exit 2
fi
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
python3 "$HERE/test_runner.py"
python3 "$HERE/run_tests.py" --candidate "$1" --gfortran "$2"
