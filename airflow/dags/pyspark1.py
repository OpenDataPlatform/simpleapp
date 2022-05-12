import os
from datetime import datetime

from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from airflow.kubernetes.secret import Secret
# Reference: https://airflow.readthedocs.io/en/1.10.6/_api/airflow/contrib/operators/kubernetes_pod_operator/index.html

my_dir = os.path.dirname(os.path.abspath(__file__))
configuration_file_path = os.path.join(my_dir, "spark-sapp-work.spark")

secret_access_key=Secret("env", "S3_ACCESS_KEY", "s3access", "accessKey" )
secret_secret_key=Secret("env", "S3_SECRET_KEY", "s3access", "secretKey" )

with DAG(
        dag_id='pyspark1',
        schedule_interval=None,
        start_date=datetime(2021, 1, 1),
        tags=['example', "spark", "python", "pyspark1"],
) as dag:
    kpo = KubernetesPodOperator(
        namespace='spark-sapp-work',
        task_id="ctemp-py1",
        name="ctemp-airflow-py1",
        config_file=configuration_file_path,
        in_cluster=False,
        service_account_name="spark",
        image="ghcr.io/opendataplatform/spark-odp:3.2.1",
        image_pull_policy="Always",
        env_vars={
            "SPARK_BUCKET": "spark-sapp",
            "S3_ENDPOINT": "https://n0.minio1:9000/",
            "NAMESPACE": "spark-sapp-work",
            "HIVE_METASTORE_URI": "thrift://hive-metastore.spark-sapp-sys.svc:9083",
        },
        secrets = [secret_access_key, secret_secret_key],
        cmds=["/bin/sh", "-c", """
              CONF="--conf spark.kubernetes.container.image=ghcr.io/opendataplatform/spark-odp:3.2.1"
              CONF="${CONF} --conf spark.kubernetes.namespace=${NAMESPACE}"
              CONF="${CONF} --conf spark.kubernetes.container.image.pullPolicy=Always"
              CONF="${CONF} --conf spark.executor.instances=2"
              CONF="${CONF} --conf spark.kubernetes.executor.limit.cores=1500m"
              CONF="${CONF} --conf spark.kubernetes.executor.request.cores=500m"
              CONF="${CONF} --conf spark.executor.memory=4G"
              CONF="${CONF} --conf spark.kubernetes.authenticate.executor.serviceAccountName=spark"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.endpoint=${S3_ENDPOINT}"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.access.key=${S3_ACCESS_KEY}"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.secret.key=${S3_SECRET_KEY}"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.connection.ssl.enabled=true"
              CONF="${CONF} --conf spark.eventLog.enabled=true"
              CONF="${CONF} --conf spark.eventLog.dir=s3a://${SPARK_BUCKET}/eventlogs"
              CONF="${CONF} --conf spark.kubernetes.file.upload.path=s3a://${SPARK_BUCKET}/shared"
              CONF="${CONF} --conf spark.hive.metastore.uris=${HIVE_METASTORE_URI}"
              CONF="${CONF} --conf spark.sql.warehouse.dir=s3a://${SPARK_BUCKET}/warehouse"
              CONF="${CONF} --conf hive.metastore.warehouse.dir=s3a://${SPARK_BUCKET}/warehouse"
              # These are default values. Need to be redefined here as default file is overrided, by mounting /opt/spark/conf folder
              CONF="${CONF} --conf spark.hadoop.mapreduce.outputcommitter.factory.scheme.s3a=org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.committer.name=directory"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.committer.staging.tmp.path=/tmp/spark_staging"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.buffer.dir=/tmp/spark_local_buf"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.committer.staging.conflict-mode=fail"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.path.style.access=true"
              CONF="${CONF} --conf spark.hadoop.fs.s3a.fast.upload=true"
              CONF="${CONF} --conf spark.driver.host=$(hostname -I)"  # For --deploy-mode client
              PY_CODE="https://n0.minio1:9000/spark-sapp/py/create_table.py"
              set -x
              set -f
              /opt/spark/bin/spark-submit --master k8s://https://kubernetes.default.svc --deploy-mode client --name ctemp-airflow-py1 $CONF $PY_CODE \
              --src "s3a://spark-sapp/data/city_temperature.csv"  --bucket spark-sapp --database sapp --table ctemp_airflow_py1 --datamartFolder /warehouse/sapp.db \
              --select "SELECT * FROM _src_"
        """],
    )

    kpo
