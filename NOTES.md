# links


[Argocd](https://argocd.shared1)

[Argo workflow](https://argoqs.shared1)

[minio-console-minio1](https://n0.minio1:9443/)

[sapp-History Server](https://sapp-history-server.shared1)

[sapp-jhub](https://sapp-jhub.shared1)



# Initial setup

To create kubconfig for spark account
```
./tools/generate_kubeconfig.sh spark-sapp-work spark ./kubeconfigs/spark-sapp-work.spark
```


To upload sample data set: 
```
./tools/upload-data.sh minio1/spark-sapp/data
```

To upload java code (For spark operator)

```
./tools/upload-java-simpleapp.sh minio1/spark-sapp/jars
```

To upload python code (For spark operator)

```
./tools/upload-py-simpleapp.sh minio1/spark-sapp/py
```

To generate the secrets

```
./tools/s3secret.sh spark-sapp-work spark-sapp "pd2t3yiizB0hTRjQOiIMihNNwMGeBM9P1vd1We2cUK1_MrAkRzY4qg=="
```

# Intellij setup

```
git clone https://github.com/OpenDataPlatform/simpleapp.git
cd simpleapp/
cd java
./gradlew
cd ../py/
./setup/install.sh
```

## Projet init:

- Start intellij
- New project
- Empty project
- Don't care about 'not empty' warning

## Python module

- Project Structure/Platform Setting/SDK/+/Add Python SDK
- Existing environment, navigate to our venv
- Project structure / Modules
- `+`
- Import module
- Navigate to py folder
- Create module from existing source
- Select python SDK
- Uncheck django
- Set module SDK to our python env

## Java module

- Project structure / Modules
- `+`
- Import module
- Navigate to java folder
- Import module from external model / Gradle



# AIRFLOW

mkdir airflow
cd airflow
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.3.0/docker-compose.yaml'

mkdir -p ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)" > .env

docker-compose up airflow-init

docker-compose up
or
docker-compose up

docker-compose run airflow-worker airflow info

curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.3.0/airflow.sh'
chmod +x airflow.sh


./airflow.sh dags list

./airflow.sh info

or 
./airflow.sh bash
Creating airflow_airflow-cli_run ... done
default@8a64e06828eb:/opt/airflow$ airflow dags list


In docker-compose:
AIRFLOW__CORE__LOAD_EXAMPLES: 'false'

# To update stuff (DagBag) after modification in dags folder:
airflow dags reserialize
