#!/bin/bash
# Default script to count the quads in a dump file
#     countDump.sh  dumpLocation
set -o errexit
set -o pipefail

[[ $# = 1 ]] || { echo "Internal error calling countDump" 1>&2 ; exit 1 ; }

readonly DUMP=$1
gunzip -c $DUMP | wc -l
