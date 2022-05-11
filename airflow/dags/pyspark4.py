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
        dag_id='pyspark4',
        schedule_interval=None,
        start_date=datetime(2021, 1, 1),
        tags=['example', "spark", "python", "pyspark4"],
) as dag:
    kpo = KubernetesPodOperator(
        namespace='spark-sapp-work',
        task_id="ctemp-py4",
        name="ctemp-airflow-py4",
        config_file=configuration_file_path,
        in_cluster=False,
        service_account_name="spark",
        image="ghcr.io/opendataplatform/spark-odp:3.2.1",
        image_pull_policy="Always",
        env_vars={
            "SRC": "s3a://spark-sapp/data/city_temperature.csv",
            "SPARK_BUCKET": "spark-sapp",
            "DATABASE": "sapp",
            "TABLE": "ctmp_airflow_py4",
            "DATAMART_FOLDER": "/warehouse/sapp.db",
            "SELECT": "SELECT * FROM _src_",
        },
        configmaps=["sapp-default"],
        secrets = [secret_access_key, secret_secret_key],
        cmds=["/bin/sh", "-c", """
cat >/tmp/work.py <<EOF
# -------------------------------------
from pyspark.sql import SparkSession
import sys
spark = SparkSession.builder.enableHiveSupport().getOrCreate()
df = spark.read.options(header='True', inferSchema='True', delimiter=",").csv("${SRC}")
df.createOrReplaceTempView("_src_")
df.show()
spark.sql("CREATE DATABASE IF NOT EXISTS ${DATABASE}")
spark.sql("DROP TABLE IF EXISTS ${DATABASE}.${TABLE}")
spark.sql("CREATE TABLE IF NOT EXISTS ${DATABASE}.${TABLE} USING PARQUET LOCATION 's3a://${SPARK_BUCKET}/${DATAMART_FOLDER}/${TABLE}' AS ${SELECT}")
spark.sql("SHOW TABLES FROM ${DATABASE}").show()
spark.sql("DESCRIBE TABLE ${DATABASE}.${TABLE}").show()
spark.sql("SELECT COUNT(*) FROM ${DATABASE}.${TABLE}").show()
spark.stop()
sys.exit(0)
EOF
# -------------------------------------
PY_CODE="/tmp/work.py"
. /opt/confBuilder.sh
set -x
set -f
/opt/spark/bin/spark-submit --master k8s://https://kubernetes.default.svc --deploy-mode client --name ctemp-airflow-py4 $CONF $PY_CODE
"""],
)

    kpo
