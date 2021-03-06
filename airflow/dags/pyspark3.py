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
        dag_id='pyspark3',
        schedule_interval=None,
        start_date=datetime(2021, 1, 1),
        tags=['example', "spark", "python", "pyspark3"],
) as dag:
    kpo = KubernetesPodOperator(
        namespace='spark-sapp-work',
        task_id="ctemp-py3",
        name="ctemp-airflow-py3",
        config_file=configuration_file_path,
        in_cluster=False,
        service_account_name="spark",
        image="ghcr.io/opendataplatform/sapp:0.1.0",
        image_pull_policy="Always",
        env_vars={},
        configmaps=["sapp-default"],
        secrets = [secret_access_key, secret_secret_key],
        cmds=["/bin/sh", "-c", """
            . /opt/confBuilder.sh
              PY_CODE="local:///opt/create_table.py"
              set -x
              set -f
              /opt/spark/bin/spark-submit --master k8s://https://kubernetes.default.svc --deploy-mode client --name ctemp-airflow-py3 $CONF $PY_CODE \
              --src "s3a://spark-sapp/data/city_temperature.csv"  --bucket spark-sapp --database sapp --table ctemp_airflow_py3 --datamartFolder /warehouse/sapp.db \
              --select "SELECT * FROM _src_"
        """],
    )

    kpo
