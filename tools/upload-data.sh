#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

S3_TARGET=$1; shift
if [ -z "${S3_TARGET}" ]; then echo "Usage: $0 <mc_alias>/<bucket>/<path>";  exit 1; fi

mc cp $MYDIR/../data/city_temperature.csv $S3_TARGET

echo ""
mc tree  -f $S3_TARGET

