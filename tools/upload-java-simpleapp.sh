#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASEDIR="$(cd $MYDIR/.. && pwd)"


S3_TARGET=$1; shift
if [ -z "${S3_TARGET}" ]; then echo "Usage: $0 <mc_alias>/<bucket>/<path>";  exit 1; fi


cd $BASEDIR/java && ./gradlew
if [ $? -ne 0 ]
then
  exit 1
fi

mc cp $BASEDIR/java/build/libs/simpleapp-0.1.0-uber.jar $S3_TARGET/simpleapp-0.1.0-uber.jar
mc policy set download $S3_TARGET/simpleapp-0.1.0-uber.jar

echo ""
mc tree  -f $S3_TARGET

