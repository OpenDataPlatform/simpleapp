# HowTo launch a spark job with OpenDataPlatform


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Index

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

There is several way to launch a spark job on ODP, depending on the context and user's preference

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
