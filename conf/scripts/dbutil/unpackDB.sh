#!/bin/bash
# Default script unpack an image of a database
#     packDB.sh  src test
set -o errexit

[[ $# = 2 ]] || { echo "Internal error calling unpackDB" 1>&2 ; exit 99 ; }

SRC=$1
DEST=$2

mkdir -p $DEST
cd $DEST
tar -zxf $SRC
