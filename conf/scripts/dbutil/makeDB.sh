#!/bin/bash
# Default script to load a dumped nq image into a TDB
#     makeDB.sh  srcDump  DBlocation
set -o errexit

[[ $# = 2 ]] || { echo "Internal error calling makeDB" 1>&2 ; exit 99 ; }

[[ -d ${JENA_HOME:=/opt/jena}/bin ]] ||  { echo >&2 "Can't find jena scripts"; exit 1; }

SRC_DUMP=$1
DEST=$2
readonly DS_NAME=DS-DB

if [[ $DEST =~ (.*)\.tgz ]]; then
    DB_LOC=${BASH_REMATCH[1]}
    DB_COMPRESS=true
else
    DB_LOC=$DEST
    DB_COMPRESS=false
fi

echo "Building database at: $DB_LOC"
mkdir -p $DB_LOC/$DS_NAME
$JENA_HOME/bin/tdbloader2 -loc $DB_LOC/$DS_NAME $SRC_DUMP

if $DB_COMPRESS ; then
    cd $DB_LOC
    tar -zcf $DEST *
    rm -r $DB_LOC
fi
