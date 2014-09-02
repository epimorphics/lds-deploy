#!/bin/bash
# Default script to create a dump file from a TDB image
#     makeDump.sh  DBlocation dumpLocation
set -o errexit

[[ $# = 2 ]] || { echo "Internal error calling makeDump" 1>&2 ; exit 99 ; }
[[ -d ${JENA_HOME:=/opt/jena}/bin ]] ||  { echo >&2 "Can't find jena scripts"; exit 1; }

DB=$1
DUMP=$2
readonly DS_NAME=DS-DB

if [[ $DB =~ (.*)\.tgz ]]; then
    DB_LOC=${BASH_REMATCH[1]}
    DB_COMPRESS=true
    mkdir -p $DB_LOC
    cd $DB_LOC
    tar xzf $DB
else
    DB_LOC=$DB
    DB_COMPRESS=false
fi

echo "Dumping database at: $DB_LOC"
mkdir -p $(dirname $DUMP)
$JENA_HOME/bin/tdbdump -loc $DB_LOC/$DS_NAME| gzip -c > $DUMP

if $DB_COMPRESS ; then
    rm -r $DB_LOC
fi
