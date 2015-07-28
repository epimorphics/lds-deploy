#!/bin/bash
# Build a new epr database image from an IR upload
# usage: dbrebuild.sh  ir-file

set -o errexit
[[ $# = 1 ]] || { echo "Usage: dbrebuild.sh ir_file" 1>&2 ; exit 1 ; }

readonly JENA_BASE=/opt/jena/bin
readonly FUSEKI_BASE=/opt/fuseki
readonly WORK_DIR=/tmp/dms-work

readonly IR_FILE="$1"

# Convert a ttl file to nquads ready for loading
# prepareGraph file name graphName
prepareGraph() {
    [[ $# = 3 ]] || { echo "Internal error calling prepareGraph" 1>&2 ; exit 1 ; }
    local file="$1"
    local name="$2"
    local graphname="$3"
    $JENA_BASE/riot -q -nocheck $file | sed -e "s|\.$|<$graphname> .|" > ${name}.nq
}

mkdir -p $WORK_DIR
tmpdir=$( mktemp -d --tmpdir=$WORK_DIR )

cd $tmpdir
cp /opt/dms/conf/scripts/epr/asm.ttl .

echo "*** Prepare IR graph"
prepareGraph $IR_FILE ir http://localhost/dms/metadata/epr/wcb_ir/graph

echo "*** Prepare vocabularies"
for vocab in /var/opt/dms/services/epr/components/vocabularies/uploads/*
do
    if [[ $vocab =~ .*/(.*)-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9\-]*_[0-9\-]*\.ttl ]] ; 
    then 
        stub=${BASH_REMATCH[1]}
        prepareGraph $vocab $stub http://localhost/dms/metadata/epr/vocabularies/graph/$stub
    fi
done

echo "*** Loading merge graph"
cat *.nq > merge.nq
$JENA_BASE/tdbloader2 --loc=DS-DB merge.nq

echo "*** Text index"
java -cp $FUSEKI_BASE/fuseki-server.jar jena.textindexer --desc=asm.ttl

echo "*** Prepare upload"
tar czf baseline_image.tgz DS-DB DS-DB-lucene

S3_IMAGE="s3://dms-deploy/images/epr/images/$( date +%F/%H-%M-%S-0000 )/baseline_image.tgz"
aws s3 cp baseline_image.tgz $S3_IMAGE

echo "*** Clean up work area"
cd /tmp
rm -r $tmpdir

echo $S3_IMAGE
