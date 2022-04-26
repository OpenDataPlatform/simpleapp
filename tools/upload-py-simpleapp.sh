#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASEDIR="$(cd $MYDIR/.. && pwd)"


S3_TARGET=$1; shift
if [ -z "${S3_TARGET}" ]; then echo "Usage: $0 <mc_alias>/<bucket>/<path>";  exit 1; fi

mc cp $BASEDIR/py/create_table.py $S3_TARGET/create_table.py
mc policy set download $S3_TARGET/create_table.py

echo ""
mc tree  -f $S3_TARGET

