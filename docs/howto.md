# HowTo launch a spark job with OpenDataPlatform

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Index

- [Introduction](#introduction)
  - [The sample (and simple) application](#the-sample-and-simple-application)
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

There are several way to launch a Spark job on Kubernetes with ODP, depending on the context and user's preference. You can:

- Issue a spark-submit from your desktop
- Launch the Spark job using the [Spark Operator](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator) (One shot, or scheduled)
- Launch the Spark job as a Kubernetes Job or CronJob
- Launch the Spark job as a task from a generic workflow manager, such as [Argo Workflow](https://argoproj.github.io/argo-workflows/) or [Airflow](https://airflow.apache.org/)
- Launch the Spark jobs from a Notebook, such as Jupyter.
- ...

Also, all this can be achieved for a job wrote in Java/Scala or PySpark/Python 

On top of that, there are other variations:

- Is the application code embedded in the container image or stored on an external repository ?
- In the (frequent) case where several jobs share a set of common configuration parameters, do we try to mutualise their definition in a single place ? 

### The sample (and simple) application

This HowTo is built around a sample application, which must be as simple as possible, to keep focus on launching method.

This application will:
- Read a `.csv` file
- Store data in `parquet` format, as a external Hive table, to validate usage of the Hive Metastore.
- Perform a count(*) to check table good health.

The beauty of Spark is that all this can be expressed in a couple of line of code.

There is a [java version](../java/src/main/java/simpleapp/CreateTable.java) and [pyspark version](../py/create_table.py) of this application

## Launch from a local Spark deployment

### Java

See [java.sh](../desktop/java.sh)

### Python 

See [pyspark.sh](../desktop/pyspark.sh)

## Launch from Jupiter notebook

### Python

## Launch as a Spark Operator SparkApplication

### Java

See [java.yaml](../sparkoperator/java.yaml)

### Python

See [pyspark.yaml](../sparkoperator/pyspark.yaml)

## Launch as a Kubernetes Job 

- When using cluster mode, there will be to pod (The job and the driver), which are independant.
  When the job is deleted

### Java

### Python

## Launch as an Argo Workflow task 

### Java

### Python

## Launch as an Apache Airflow task

### Java

### Python 

## Variations

- Use wrapper mode
- Add application code to launcher (python)
- Embed application code in image
- Inject secret using code



