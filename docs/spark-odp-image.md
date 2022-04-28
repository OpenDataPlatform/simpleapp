# The OpenDataPlatform provided images

Here is a short description of docker images you may use for Spark application in OpenDataPlatform

Note all these image include support for both amd64 and arm64 platforms 


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Index

- [Standard Spark base image](#standard-spark-base-image)
- [Spark-odp image](#spark-odp-image)
- [Spark operator image](#spark-operator-image)
- [The 'wrapper' mode](#the-wrapper-mode)
  - [Variables](#variables)
- [Some application example](#some-application-example)
  - [Kubernetes Job](#kubernetes-job)
  - [Argo workflow template](#argo-workflow-template)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Standard Spark base image

This is the image build from the [documented spark procedure](https://spark.apache.org/docs/latest/running-on-kubernetes.html#docker-images), with no modification.

The image including the Python langage binding will be used as a base for the spark-odp image. Note it also support all JVM based application. 

## Spark-odp image

This image is one of the key pieces of the OpenDataPlatform application.

It is built from the standard Spark base image and may be used in many context, both as Spark Driver or Spark Executor

It include a set of modifications allowing smooth integration in OpenDataPlatfom context.

- Run as non root

  The standard Spark image run with a user ID of 185. A `spark` user is created with this ID.

- s3 access 

  Access to s3 storage require some extra jar to be included in the spark classpath. 

- Certificate(s)

  Certificate(s) required to access external resources are copied in the image and stored in the java keystore. 
    
- log4j configuration

  A basic log4j configuration is provided.

- wrapper mode

  When used as Spark client, an helper script may be used to ease configuration. See below for a full description

## Spark operator image

This is a rebuild of the spark-operator image, based on spark-odp. Aim is to provide:

- Coherency of the spark version on all images
- Support run as non root.
- multiplatform support

## The 'wrapper' mode

When submitting a Spark application, a bnch of options must be provided, typically using the `--conf` parameter. A typical submit operation may look like this: 

```
 .../bin/spark-submit --master k8s://https://192.168.56.14:6443 --deploy-mode cluster
...
--conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
--conf spark.hadoop.fs.s3a.fast.upload=true \
--conf spark.hadoop.fs.s3a.path.style.access=true \ 
--conf spark.executor.instances=1 \
--conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \ 
--conf spark.kubernetes.namespace=spark-gha1-work \
--conf spark.kubernetes.container.image=ghcr.io/opendataplatform/spark-odp:3.2.1 \ 
--conf spark.kubernetes.container.image.pullPolicy=Always \
--conf spark.kubernetes.driver.limit.cores=4 \
--conf spark.kubernetes.executor.limit.cores=4 \ 
--conf spark.kubernetes.driver.request.cores=2 \ 
--conf spark.kubernetes.executor.request.cores=2 \ 
--conf spark.driver.memory=4G \
--conf spark.executor.memory=8G \ 
--conf spark.hadoop.fs.s3a.connection.ssl.enabled=true \ 
--conf spark.kubernetes.file.upload.path=s3a://spark-gha1/shared \ 
--conf spark.eventLog.enabled=true \
--conf spark.eventLog.dir=s3a://spark-gha1/eventlogs \ 
--conf spark.hadoop.fs.s3a.endpoint=https://n0.minio1:9000/ \ 
--conf spark.hadoop.fs.s3a.access.key=spark-gha1  \
--conf spark.hadoop.fs.s3a.secret.key=XXXXXXXXXXXXXXXXXXXXXXXX \
... 
```

When defining a Spark job as a Kubernetes Job or CronJob, or as an Argo Workflow template, defining such configuration on each job is a real pain. 
Also, for most of the jobs part of an application, most of the parameters are the same. 

The wrapper mode will allow to define such parameters in a more easy way and to share them between jobs. 
To achieve this, a script is included in client mode to fetch configuration from Environment variables. 
Then, a set of variable can be defined in a ConfigMap, which will be used by all pods using a `envFrom.[]configMapRef` directive.

### Variables

Here is a description of all environment variable which can be set:

| Name                   | req. | Corresponding Spark configuration value     | Comment                                                     |
|------------------------|------|---------------------------------------------|-------------------------------------------------------------|
| PY_CODE                | No   | N/A                                         | The Python code to execute (`local:///...` or `s3a://...`)  |
| CLASS_NAME             | No   | N/A                                         | The Java class to execute                                   |
| JAR                    | No   | N/A                                         | The application jar (`local:///...` or `s3a://...`)         |
| APP_NAME               | Yes  | N/A                                         | The application name (Will be set with `--name` option)     |
| NBR_EXECUTORS          | Yes  | spark.executor.instances                    |                                                             |
| SPARK_EXECUTOR_IMAGE   | Yes  | spark.kubernetes.executor.container.image   |                                                             |
| IMAGE_PULL_POLICY      | No   | spark.kubernetes.container.image.pullPolicy | Default: `IfNotPresent`                                     |
| EXECUTOR_MEMORY        | Yes  | spark.executor.memory                       |                                                             |
| EXECUTOR_LIMIT_CORES   | Yes  | spark.kubernetes.executor.limit.cores       |                                                             |
| EXECUTOR_REQUEST_CORES | Yes  | spark.kubernetes.executor.request.cores     |                                                             |
| S3_ENDPOINT            | Yes  | spark.hadoop.fs.s3a.endpoint                |                                                             |
| S3_ACCESS_KEY          | Yes  | spark.hadoop.fs.s3a.access.key              |                                                             |
| S3_SECRET_KEY          | Yes  | spark.hadoop.fs.s3a.secret.key              |                                                             |
| S3_SSL                 | No   | spark.hadoop.fs.s3a.connection.ssl.enabled  | Default: True                                               |
| EVENT_LOG_BUCKET       | No   | spark.eventLog.dir                          | If not set, no event logs will be generated                 |
| EVENT_LOG_DIR          | No   | spark.eventLog.dir                          | Default: `/eventlogs`                                       |
| HIVE_METASTORE_URI     | No   | spark.hive.metastore.uris                   | If not set, no mtastore will be configured                  |
| SQL_WAREHOUSE_DIR      | No   | spark.sql.warehouse.dir                     | Default: `/warehouse`                                       |
| SQL_WAREHOUSE_BUCKET   | No   | spark.sql.warehouse.dir                     | If not set, no warehouse will be configured                 |


## Some application example

### Kubernetes Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: json2parquet
  namespace: spark-tawf-work
spec:
  ttlSecondsAfterFinished: 200
  backoffLimit: 1
  template:
    spec:
      serviceAccountName: spark
      containers:
        - name: json2parquet
          image: ghcr.io/opendataplatform/spark-odp:3.2.1
          imagePullPolicy: Always
          env:
          - name: APP_NAME
            value: json2parquet
          - name: CLASS_NAME
            value: gha2spark.Json2Parquet
          - name: JAR
            value: "s3a://spark-tawf/jars/gha2spark-0.1.2-uber.jar"
          - name: EXECUTOR_MEMORY
            value: "6G"
          envFrom:
          - configMapRef:
              name: jobs-config
          args:
            - wrapper
            - --backDays
            - "1"
            - --maxFiles
            - "1"
            - --waitSeconds
            - "0"
            - --srcBucketFormat
            - "spark-tawf"
            - --srcObjectFormat
            - "/data/primary/gha-{{year}}-{{month}}-{{day}}-{{hour}}.json.gz"
            - --dstBucketFormat
            - "spark-tawf"
            - --dstObjectFormat
            - "/data/secondary/raw/year={{year}}/month={{month}}/day={{day}}/hour={{hour}}"
      restartPolicy: Never
```

### Argo workflow template

