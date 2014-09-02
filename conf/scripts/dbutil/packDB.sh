#!/bin/bash
# Default script create a zipped image of a database
#     packDB.sh  src test
set -o errexit

[[ $# = 2 ]] || { echo "Internal error calling packDB" 1>&2 ; exit 99 ; }

SRC=$1
DEST=$2
readonly DS_NAME=DS-DB

cd $SRC
tar -zcf $DEST *
cd ..
rm -r $SRC
