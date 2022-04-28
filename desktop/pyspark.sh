#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export KUBECONFIG=${MYDIR}/../kubeconfigs/spark-sapp-work.spark

# Theses variable must be adjusted to match environment:
NAMESPACE="spark-sapp-work"
HIVE_METASTORE_NAMESPACE=spark-sapp-sys
SPARK_BUCKET="spark-sapp"
S3_ENDPOINT="https://n0.minio1:9000/"
S3_ACCESS_KEY=spark-sapp
S3_SECRET_KEY=pd2t3yiizB0hTRjQOiIMihNNwMGeBM9P1vd1We2cUK1_MrAkRzY4qg==
K8S_API_SERVER=https://192.168.56.14:6443   # n0.kspray2
SPARK_HOME=${MYDIR}/spark/spark-3.2.1-bin-hadoop3.2


# This will define the schema of the resulting table
set -f
SELECT='SELECT * FROM _src_'

CONF="--conf spark.kubernetes.container.image=ghcr.io/opendataplatform/spark-odp:3.2.1"
CONF="${CONF} --conf spark.kubernetes.container.image.pullPolicy=Always"
CONF="${CONF} --conf spark.executor.instances=2"
CONF="${CONF} --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark"
CONF="${CONF} --conf spark.kubernetes.driver.limit.cores=1500m"
CONF="${CONF} --conf spark.kubernetes.executor.limit.cores=1500m"
CONF="${CONF} --conf spark.kubernetes.driver.request.cores=500m"
CONF="${CONF} --conf spark.kubernetes.executor.request.cores=500m"
CONF="${CONF} --conf spark.driver.memory=4G"
CONF="${CONF} --conf spark.executor.memory=4G"
CONF="${CONF} --conf spark.hadoop.fs.s3a.connection.ssl.enabled=true"
CONF="${CONF} --conf spark.eventLog.enabled=true"
CONF="${CONF} --conf spark.kubernetes.file.upload.path=s3a://${SPARK_BUCKET}/shared"
CONF="${CONF} --conf spark.kubernetes.namespace=${NAMESPACE}"
CONF="${CONF} --conf spark.eventLog.dir=s3a://${SPARK_BUCKET}/eventlogs"
CONF="${CONF} --conf spark.hadoop.fs.s3a.endpoint=${S3_ENDPOINT}"
CONF="${CONF} --conf spark.hadoop.fs.s3a.access.key=${S3_ACCESS_KEY}"
CONF="${CONF} --conf spark.hadoop.fs.s3a.secret.key=${S3_SECRET_KEY}"
CONF="${CONF} --conf spark.hive.metastore.uris=thrift://hive-metastore.${HIVE_METASTORE_NAMESPACE}.svc:9083"
CONF="${CONF} --conf spark.sql.warehouse.dir=s3a://${SPARK_BUCKET}/warehouse"
CONF="${CONF} --conf hive.metastore.warehouse.dir=s3a://${SPARK_BUCKET}/warehouse"

PY_FILE= ${MYDIR}/../py/create_table.py

export JAVA_TOOL_OPTIONS="-Dcom.amazonaws.sdk.disableCertChecking=true"

set +x
${SPARK_HOME}/bin/spark-submit --master k8s://${K8S_API_SERVER} --deploy-mode cluster ${CONF} \
--name ctemp-desktop-py $PY_FILE --src s3a://spark-sapp/data/city_temperature.csv  --bucket spark-sapp --database sapp --table ctemp_desktop_py --datamartFolder /warehouse/sapp.db \
--select "$SELECT"

