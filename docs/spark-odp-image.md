# The OpenDataPlatform provided images

Here is a short description of docker images you may use for Spark application in OpenDataPlatform

Note all these image include support for both amd64 and arm64 platforms 


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Index

- [Standard Spark base image (spark:3.2.1 and spark-py:3.2.1)](#standard-spark-base-image-spark321-and-spark-py321)
- [Spark-odp image](#spark-odp-image)
- [Spark operator image](#spark-operator-image)
- [The `confBuilder.sh` script](#the-confbuildersh-script)
  - [Variables](#variables)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Standard Spark base image (spark:3.2.1 and spark-py:3.2.1)

There are images build from the [documented spark procedure](https://spark.apache.org/docs/latest/running-on-kubernetes.html#docker-images), with no modification.

The image including the Python langage binding will be used as a base for the spark-odp image. Note it also support all JVM based application.

This image is just an intermediate step and should not be used as is in OpenDataPlatform context.

## Spark-odp image

This image is one of the key pieces of the OpenDataPlatform service offer.

It is built from the standard Spark-py base image and may be used in many context, both as Spark Driver or Spark Executor

It include a set of modifications allowing smooth integration in OpenDataPlatfom context.

- Run as non root

  The standard Spark image run with a user ID of 185. A `spark` user is created with this ID.

- s3 access 

  Access to s3 storage require some extra jar to be included in the spark classpath. 

- Certificate(s)

  Certificate(s) required to access external resources are copied in the image and stored in the java keystore. 
    
- log4j configuration

  A basic log4j configuration is provided.

- confBuilder.sh script

  When used as Spark client, an helper script may be used to ease configuration. See below for a full description

## Spark operator image

This is a rebuild of the spark-operator image, based on spark-odp. Aim is to provide:

- Coherency of the spark version on all images
- Support run as non root.
- multiplatform support

## The `confBuilder.sh` script

When submitting a Spark application, a bunch of options must be provided, typically using the `--conf` parameter. A typical submit operation may look like this: 

```
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

${SPARK_HOME}/bin/spark-submit --master k8s://${K8S_API_SERVER} --deploy-mode cluster --name ctemp-desktop-java  ${CONF} \
 --class myapp.mymainclass .../myapp.jar [application parameter]
```

When several jobs are to be submitted, it is a good practice to mutualise such code in a single batch, which will be included in launcher scripts.

Also, when defining a Spark job as a Kubernetes Job or CronJob, or as an Argo Workflow template, defining such configuration on each job is a real pain. 
Also, for most of the jobs part of an application, most of the parameters are the same. 

To make life more easy, the `confBuilder.sh` script has been included in `spark-odp image`. It will build the $CONF variable with:

- A set of constant value, specific to the OpenDataPlatform usage (Most of them being related to S3 access)
- A set of variable value, provided as environment variable.

In a Kubernetes context, the practice will be to define a set of default parameters for an application in a ConfigMap, 
which will be used by all pods using a `envFrom.[]configMapRef` directive.

See the [HowTo](./howto.md) for example of usage.

### Variables

Here is a description of all environment variable which can be set:

| Name                          | req | Corresponding Spark configuration value                                                    | Comment                                             |
|-------------------------------|-----|--------------------------------------------------------------------------------------------|-----------------------------------------------------|
| SPARK_CONTAINER_IMAGE         | No  | spark.kubernetes.executor.container.image and<br>spark.kubernetes.executor.container.image | Defaut to `ghcr.io/opendataplatform/spark-odp:3.2.1` |
| IMAGE_PULL_POLICY             | No  | spark.kubernetes.container.image.pullPolicy                                                | Default: `IfNotPresent`                             |
| EXECUTOR_SERVICE_ACCOUNT_NAME | No  | spark.kubernetes.authenticate.executor.serviceAccountName                                  | Default: `spark`                                    |
| S3_CONNECTION_SSL_ENABLED     | No  | spark.hadoop.fs.s3a.connection.ssl.enabled                                                 | Default: `true`                                     |
| S3_ENDPOINT                   | Yes | spark.hadoop.fs.s3a.endpoint                                                               |                                                     |
| S3_ACCESS_KEY                 | Yes | spark.hadoop.fs.s3a.access.key                                                             |                                                     |
| S3_SECRET_KEY                 | Yes | spark.hadoop.fs.s3a.secret.key                                                             |                                                     |
| NAMESPACE                     | Yes | spark.kubernetes.namespace                                                                 |                                                     |
| EXECUTOR_INSTANCES            | Yes | spark.executor.instances                                                                   |                                                     |
| EXECUTOR_LIMIT_CORES          | Yes | spark.kubernetes.executor.limit.cores                                                      |                                                     |
| EXECUTOR_REQUEST_CORES        | Yes | spark.kubernetes.executor.request.cores                                                    |                                                     |
| EXECUTOR_MEMORY               | Yes | spark.executor.memory                                                                      |                                                     |
| EVENT_LOG_DIR                 | No  | spark.eventLog.dir                                                                         | Is set, then `spark.eventLog.enabled=true` is added |
| FILE_UPLOAD_PATH              | No  | spark.kubernetes.file.upload.path                                                          |                                                     |
| HIVE_METASTORE_URI            | No  | spark.hive.metastore.uris                                                                  |                                                     |
| SQL_WAREHOUSE_DIR             | No  | spark.sql.warehouse.dir and<br>hive.metastore.warehouse.dir                                |                                                     |

Also, this script add `spark.driver.host=$(hostname -I)`. This is required in client deployment mode in a Kubernetes context.

