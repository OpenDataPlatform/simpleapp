# HowTo launch a spark job with OpenDataPlatform

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Index

- [Introduction](#introduction)
  - [The sample (and simple) CreateTable application](#the-sample-and-simple-createtable-application)
- [Launch from a local Spark deployment](#launch-from-a-local-spark-deployment)
  - [Java](#java)
  - [Python](#python)
- [Launch from Jupiter notebook](#launch-from-jupiter-notebook)
  - [Python](#python-1)
- [Launch as a Spark Operator SparkApplication](#launch-as-a-spark-operator-sparkapplication)
  - [Java](#java-1)
  - [Python](#python-2)
- [Launch as a Kubernetes Job](#launch-as-a-kubernetes-job)
  - [Java](#java-2)
  - [Python](#python-3)
- [Launch as an Argo Workflow task](#launch-as-an-argo-workflow-task)
  - [Java](#java-3)
  - [Python](#python-4)
- [Launch as an Apache Airflow task](#launch-as-an-apache-airflow-task)
  - [Java](#java-4)
  - [Python](#python-5)
- [Variations](#variations)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Introduction

### Prerequisites

Following your inscription to the OpenDataPlatform service offer, the following information should have been provided:

- A dedicated namespace spark-<clientId>-work
- A dedicated S3 bucket spark-<clientId> and its access information (endpoint/access key/secret key) stored in a secret
- Your dedicated Hive Metastore URI access
- A dedicated Jupyter Hub URL access
- A dedicated Spark History server URL access

These informations will be used for configuring your application(s).

Beside this, your account should belong to a group which have been granted with appropriate permissions.

### Spark job launching

There are several way to launch a Spark job on Kubernetes with ODP, depending on the context and user's preference. You can:

- Issue a spark-submit from your desktop
- Launch the Spark job as a Kubernetes Job or CronJob
- Launch the Spark job using the [Spark Operator](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator) (One shot, or scheduled)
- Launch the Spark job as a task from a generic workflow manager, such as [Argo Workflow](https://argoproj.github.io/argo-workflows/) or [Airflow](https://airflow.apache.org/)
- Launch the Spark jobs from a Notebook, such as Jupyter.
- ...

Also, all this can be achieved for a job wrote in Java/Scala or PySpark/Python 

On top of that, there are other variations:

- Is the application code embedded in the container image or stored on an external repository ?
- In the (frequent) case where several jobs share a set of common configuration parameters, do we try to mutualise their definition in a single place ? 

### The sample (and simple) CreateTable application

This HowTo is built around a sample application, which must be as simple as possible, to keep focus on launching method.

This application will:
- Read a `.csv` file
- Store data in `parquet` format, as a external Hive table, to validate usage of the Hive Metastore. This is achieved by using a Create Table As Select (CTAS) request.
- Perform a count(*) to check table good health.

The beauty of Spark is that all this can be expressed in a couple of line of code.

The schema of the target table is defined by the SELECT part of the CTAS. This is configurable. For 
this sample, we will use `SELECT * FROM _src`, thus building the table with all fields of the `.csv` source file.

As data source, we will use a `city_temperature.csv` file, providing dayly temperature on several cities, worlwide. But note this sample does not depend of the input schema. 

There is a [java version](../java/src/main/java/simpleapp/CreateTable.java) and [pyspark version](../py/create_table.py) of this application. Both use the same set of input parameters

## Launching from a local Spark deployment

This launch method is mainly used in primary development stages. It assume a Spark client environment has been deployed on you local computer.

As matter of starting point, a [Java](../launchers/desktop/java.sh) and [Pyspark](../launchers/desktop/pyspark.sh) version of launching script are provided.

First you may ensure your current account is granted with enough rights to peform Spark deployment. 
If not you may have been provided with a config file, which must be defined by a `KUBECONFIG` environment variable.

Then you will need to define your current application context in some environment variables:

```
NAMESPACE="spark-sapp-work"
HIVE_METASTORE_URI="thrift://hive-metastore.spark-sapp-sys.svc:9083"
SPARK_BUCKET="spark-sapp"
S3_ENDPOINT="https://n0.mys3server/"
S3_ACCESS_KEY=spark-sapp
S3_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx==
K8S_API_SERVER=https://XXX.XXX.XXX.XXX:6443
SPARK_HOME=...../spark/spark-3.2.1-bin-hadoop3.2
# This will define the schema of the resulting table
set -f
SELECT='SELECT * FROM _src_'
```

(Note the `set -f` to prevent shell expansion of the '*' in the SELECT )

Then you will find a bunch on configuration settings, required for correct spark execution:

```
CONF="--conf spark.kubernetes.container.image=ghcr.io/opendataplatform/spark-odp:3.2.1"
CONF="${CONF} --conf spark.kubernetes.container.image.pullPolicy=Always"
CONF="${CONF} --conf spark.executor.instances=2"
CONF="${CONF} --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark"
.... Some parts removed ...
CONF="${CONF} --conf spark.sql.warehouse.dir=s3a://${SPARK_BUCKET}/warehouse"
CONF="${CONF} --conf hive.metastore.warehouse.dir=s3a://${SPARK_BUCKET}/warehouse"
```

Then, for the java application, we find the `spark-submit` command. 
```
JAR=<Your JAR file location on your system>
${SPARK_HOME}/bin/spark-submit --master k8s://${K8S_API_SERVER} --deploy-mode cluster ${CONF} --name <myAppName> --class simpleapp.CreateTable $JAR <application Parameters....>
```

Note the following:

- The deployment is in `cluster mode`. This means both drivers and executor will be launched inside the Kubernetes cluster. 
- The --master option is specific a a Kubernetes deployment.
- The `spark-submit` command will upload the application jar file onto the S3 storage. This means your workstation must 
  recognize the server certificate as valid (Issued by a registered certificate authority). If this is not the case, a 
  workaround is to disable the certificate check on S3 API by setting the appropriate variable: `export JAVA_TOOL_OPTIONS="-Dcom.amazonaws.sdk.disableCertChecking=true"`

The pyspark version is almost the same, excepted the `--class` parameter is removed and $JAR is replaced by $PY_FILE.

## Launch as a Kubernetes Job

- When using cluster mode, there will be to pod (The job and the driver), which are independant.
  When the job is deleted


## Launch from Jupiter notebook

## Launch as a Spark Operator SparkApplication

## Launch as an Argo Workflow task 

## Launch as an Apache Airflow task

## Variations

- Use confBuilder script mode
- Add application code to launcher (python)
- Embed application code in image



