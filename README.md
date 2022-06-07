# HowTo launch a spark job with OpenDataPlatform

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Index

  - [Introduction](#introduction)
    - [Prerequisites](#prerequisites)
    - [Spark job launching](#spark-job-launching)
    - [The sample (and simple) CreateTable application](#the-sample-and-simple-createtable-application)
  - [Preparation](#preparation)
  - [Launching from a local Spark deployment](#launching-from-a-local-spark-deployment)
  - [Launch as a Kubernetes Job](#launch-as-a-kubernetes-job)
  - [Launch from Jupyter notebook](#launch-from-jupyter-notebook)
  - [Launch as a Spark Operator SparkApplication](#launch-as-a-spark-operator-sparkapplication)
  - [Launch as an Argo Workflow task](#launch-as-an-argo-workflow-task)
  - [Launch as an Apache Airflow task](#launch-as-an-apache-airflow-task)
  - [The `confBuilder.sh` script](#the-confbuildersh-script)
    - [confBuilder.sh variables](#confbuildersh-variables)
  - [Embed application code in image](#embed-application-code-in-image)
  - [Embed application code to launcher (python)](#embed-application-code-to-launcher-python)
- [The OpenDataPlatform provided images](#the-opendataplatform-provided-images)
  - [Standard Spark base image (spark:3.2.1 and spark-py:3.2.1)](#standard-spark-base-image-spark321-and-spark-py321)
  - [Spark-odp image](#spark-odp-image)
  - [Spark operator image](#spark-operator-image)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Introduction

This HowTo is aimed to help you getting started with the OpenDataPlatform service offer. As such, it focus on the specificity of this environment.

It is assumed the reader has a basic understanding of Spark concepts and is familiar to Kubernetes basic usage and associated tools (kubectl, ....) and concepts (Namespace, Pods, ConfigMap, Secrets, ServiceAccount...)

### Prerequisites

Following your inscription to the OpenDataPlatform service offer, the following resources should have been provided:

- A dedicated namespace `spark-<clientId>-work`
- A dedicated S3 bucket `spark-<clientId>` and its access information (endpoint/access key/secret key).
- A dedicated Hive Metastore URI access
- A dedicated Jupyter Hub URL access
- A dedicated Spark History Server URL access

These informations will be used for configuring your application(s).

Beside this, your account should belong to a group which have been granted with appropriate permissions.

### Spark job launching

There are several way to launch a Spark job on Kubernetes with ODP, depending on the context and user's preference. You can:

- Issue a `spark-submit` from your desktop
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

This *HowTo* is built around a sample application, which must be as simple as possible, to keep focus on launching method.

This application will:
- Read a `.csv` file
- Store data in `parquet` format, as a external Hive table, to validate usage of the Hive Metastore. This is achieved by using a Create Table As Select (CTAS) request.
- Perform a `COUNT(*)` to check table good health.

The beauty of Spark is that all this can be expressed in a couple lines of code.

This application is higly configurable, using a set of input parameters on the command line.

The schema of the target table is defined by the SELECT part of the CTAS. This is configurable. For 
this sample, we will use `SELECT * FROM _src_`, thus building the table with all fields of the `.csv` source file (By convention, `_src_` is the name of the view on the source dataset).

As data source, we will use a `city_temperature.csv` file, providing dayly temperature on several cities, worlwide. But note the code does not depends on input schema and could be used as is for other data set.. 

There is a [java version](../java/src/main/java/simpleapp/CreateTable.java) and [pyspark version](../py/create_table.py) of this application. Both use the same set of input parameters

## Preparation

Depending of the use cases described below, a small set of dependencies may be required

- The sample data set must be loaded on S3, in a well known location.
- A kubernetes `Secret` must be created in target namespave to host accessKey/secretKey for S3 access. There is a [script](../tools/s3secret.sh) to help for this.
- Application code should be uploaded to S3. 

## Launching from a local Spark deployment

This launch method is mainly used in primary development stages. It assume a Spark client environment has been deployed on you local computer.

As matter of starting point, a [Java](../launchers/desktop/java.sh) and [PySpark](../launchers/desktop/pyspark.sh) version of launching script are provided.

First you may ensure your current account is granted with enough rights to perform Spark deployment. 
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

> Note the `set -f` to prevent shell expansion of the '*' in the SELECT

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
- The `--master` option is specific for a Kubernetes deployment.
- The `spark-submit` command will upload the application jar file onto the S3 storage. This means your workstation must 
  recognize the server certificate as valid (Issued by a registered certificate authority). If this is not the case, a 
  workaround is to disable the certificate check on S3 API by setting the appropriate variable: `export JAVA_TOOL_OPTIONS="-Dcom.amazonaws.sdk.disableCertChecking=true"`

The PySpark version is almost the same, excepted the `--class` parameter is removed and $JAR is replaced by $PY_FILE.

After adapting the script, you should be able to launch your first Spark job on Kubernetes. On success, you should be able to log on the Spark history server to view Spark stagging.

## Launch as a Kubernetes Job

Kubernetes `Jobs` and `CronJobs` are appropriate tools to launch Spark task, either on one shot or on schedule.

A good point is launching a Spark application this way does not require any local Spark deployment. Just access to the Kubernetes cluster with appropriate permissions.

Two sample jobs are provided here. One for [Java](../launchers/job/java1.yaml) and one for [PySpark](../launchers/job/pyspark1.yaml).

Most of the context related value are defined as environment variables. You will need to modify them:

```
    env:
      - name: SPARK_BUCKET
        value: "spark-sapp"
      - name: S3_ENDPOINT
        value: "https://n0.minio1:9000/"
      - name: NAMESPACE
        value: "spark-sapp-work"
      - name: HIVE_METASTORE_URI
        value: thrift://hive-metastore.spark-sapp-sys.svc:9083
```

Also, note the way the secret values are set in environment variables:

```
    env:
      ....
      - name: S3_ACCESS_KEY
        valueFrom:
          secretKeyRef:
            key: accessKey
            name: s3access
      - name: S3_SECRET_KEY
        valueFrom:
          secretKeyRef:
            key: secretKey
            name: s3access
```

And note this yaml syntax trick to include a multiline script:

```
      command:
        - "/bin/sh"
        - -c
        - |
          CONF="--conf spark.kubernetes.container.image=ghcr.io/opendataplatform/spark-odp:3.2.1"
          CONF="${CONF} --conf spark.kubernetes.namespace=${NAMESPACE}"
          CONF="${CONF} --conf spark.kubernetes.container.image.pullPolicy=Always"
          ....
```

We will see later how to remove these cumbersome `CONF="$CONF ..."` lines.

The application code will be fetched using http(s):

```
     JAR="https://n0.minio1:9000/spark-sapp/jars/simpleapp-0.1.0-uber.jar"
```
```
     PY_CODE="https://n0.minio1:9000/spark-sapp/py/create_table.py"
```

Of course, this should be adjusted to the location where you stored your code.

An alternate solution would be to embed application code in the Docker image. More on this later.

And the spark-submit at the end:

```
     /opt/spark/bin/spark-submit --master k8s://https://kubernetes.default.svc --deploy-mode client --name  ......
```

As the submit will occur inside the kubernetes, we can refer to the API Server (`--master` option) using a generic address.

We use the `client` mode. This means the job is in fact the driver. The 'cluster' mode may work, but will have no advantage and the following drawback:

- 1 more intermediate pod. More moving part. More logs to scan, more used resources.
- The kubernetes Job subsystem provide a cleanup mechanism for completed jobs (`ttlSecondsAfterFinished: 200` in our sample). 
Unfortunately, Spark does not set `ownerReference` relationship, between the job's pod and the driver. So, the driver pod will remain indefinitely in `Completed` stage, and will need some manual cleanup.

## Launch from Jupyter notebook

A sample PySpark notebook is provided [here](../launchers/jupyter/pyspark.ipynb)

All context related value are defined as Python variables, at the top of the file. You will need to modify them, according to your configuration:

```jupyter
# To adjust to our context
NAMESPACE = "spark-sapp-work"
HIVE_METASTORE_URI = "thrift://hive-metastore.spark-sapp-sys.svc:9083"
SPARK_BUCKET = "spark-sapp"
S3_ENDPOINT = "https://n0.minio1:9000/"
S3_ACCESS_KEY = "spark-sapp"
S3_SECRET_KEY = "xxxxxxxxxxxxxxxxxxxxxx"
S3_SSL="true"
OAUTH_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6Ik92a2tYVFhwbVNndUR0QnZDLTVsSkFIRk1sR0VuWWdJbE5qVXZNTUZlQkkifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJzcGFyay1zYXBwLXdvcmsiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoic3BhcmstdG9rZW4tbWN2NHMiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoic3BhcmsiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJhNzIwZDUwZC04MTk2LTQwZTEtOGZiYi0zNTJmYmRkODkyYTUiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6c3Bhcmstc2FwcC13b3JrOnNwYXJrIn0.pwkhBXy7hOILG-KYG2ImER5-kJDlmwRkw0a04ACszWSYjBnOXoToTLdBo8v2GZYETzw1-2t1ja62qW1YvxEgOwSwnHQTeh87qi3mYhl1e37-OFj0X4YCrt41cMfBQUJaxo8uX-xV-98INB4GtdkgE2aSP1roNZj1ft-SwVC_tXx3GvWm4lhDGxQ7uuxtVzc2xEXZBffSsXUpm-fKzqatT3x3hQVRD4TNLF0DoU84LnbPyPz8ZcAt9zF4apJWBaHQJnVcoK-OnW4nnhQng6ffI-qKqKvwi89-Irfc5FrW5cl9nj3CWtos_W889VPk8UN_6M2DLHRtFec6L5SlU2fWQQ"
```

The must trickest part is to provide an authentication token for the 'spark' ServiceAccount. The following command will do the job;
 
```
kubectl -n spark-sapp-work describe secret $(kubectl -n spark-sapp-work get secret | (grep spark || echo "$_") | awk '{print $1}') | grep token: | awk '{print $2}'
```
You will have to cute/paste the (long) result as the `S3_SECRET_KEY` value

After the two first steps, which initialise the Spark Session (Thus launching spark executors), the remaining of the notebook will act as the sample application described above.

## Launch as a Spark Operator SparkApplication

An alternate way to launch a spark job is to use a ad-hoc operator, such as google [spark-on-k8s-operator](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator).

It will allow to launch a Spark job by applying a Kubernetes manifest. Two Custom Resource Definitions are provided: `SparkApplication` and `ScheduledSparkApplication`.

Two sample manifests are provided here. One for [Java](../launchers/sparkoperator/java.yaml) and one for [PySpark](../launchers/sparkoperator/pyspark.yaml).

You will need to adjust some parameters in the `arguments` ans `sparkConf` properties. 

Also, adjust the `mainApplicationFile` property to target where you stored your code.

Note than this approach is quite redundant with launching a Spark job using the Kubernetes `Jobs` (and `Cronjobs`) facility, as decribed previously. 
So, we suggest to use this simplest solution (Kubernetes Jobs and CronJobs) and use only the Spark Operator if required. 

## Launch as an Argo Workflow task 

Argo Workflow is a workflow engine dedicated fo Kubernetes. It is perfectly well suited to orchestrate Spark Jobs in such context.

You will find a simple workflow with a single step [here for its Java version](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/argoworkflow/java1.yaml) 
and [here for its PySpark version](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/argoworkflow/pyspark1.yaml). 

In ArgoWorkflow jargon, a `template` is a single job description. A good analogy would be to consider a template is a function, with input and output parameters. 
Then, a workflow is an orchestration of templates, like a program is an orchestration of functions.

Let's have a look in our sample (Some detail may be omited) :

```
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: ctemp-awf-java1-
  namespace: spark-sapp-work
  ....
spec:
  entrypoint: create-table
  arguments:
    parameters:
      - { name: src, value: "s3a://spark-sapp/data/city_temperature.csv" }
      - { name: bucket, value: "spark-sapp" }
      - { name: database, value: "sapp" }
      - { name: table, value: "ctemp_awf_java1" }
      - { name: datamartFolder, value: "/warehouse/sapp.db" }
      - { name: select, value: "SELECT * FROM _src_" }
```

A Workflow is a specific Kubernetes resource. Its `spec` must contains an entrypoint, which define the first template to launch. Optionnaly, it may provide arguments for this initial call.

Then, there is a list of all templates. Only one in our case:

```
apiVersion: argoproj.io/v1alpha1
kind: Workflow
....
spec:
  ....
  templates:
    - name: create-table
      inputs:
        parameters:
          - name: src
          - name: bucket
          - name: database
          - name: table
          - name: datamartFolder
          - name: select
      serviceAccountName: spark
      .....
```

A template, as a function, got a name and must declare all its input parameters. It must also define the Kubernetes ServiceAccount it will use to run.

Argo Workflow provide several types of templates. Some such as `dag` or `steps` are aimed to orchestrate others template. 
Some such as `container` or `script` are intended to perform a task and will instanciate a pod.

Here, we will use a `script` template:

```
apiVersion: argoproj.io/v1alpha1
kind: Workflow
....
spec:
  ....
  templates:
    - name: create-table
      ....
      script:
        image: ghcr.io/opendataplatform/spark-odp:3.2.1
        imagePullPolicy: Always
        env:
          - name: SPARK_BUCKET
            value: "spark-sapp"
          - name: S3_ENDPOINT
            value: "https://n0.minio1:9000/"
          - name: S3_ACCESS_KEY
            valueFrom:
              secretKeyRef:
                key: accessKey
                name: s3access
          - name: S3_SECRET_KEY
            valueFrom:
              secretKeyRef:
                key: secretKey
                name: s3access
          - name: NAMESPACE
            value: "spark-sapp-work"
          - name: HIVE_METASTORE_NAMESPACE
            value: spark-sapp-sys
        command: [bash]
        source: |
          CONF="--conf spark.kubernetes.container.image=ghcr.io/opendataplatform/spark-odp:3.2.1"
          CONF="${CONF} --conf spark.kubernetes.namespace=${NAMESPACE}"
          CONF="${CONF} --conf spark.kubernetes.container.image.pullPolicy=Always"
          ....
          CONF="${CONF} --conf spark.hadoop.fs.s3a.fast.upload=true"
          CONF="${CONF} --conf spark.driver.host=$(hostname -I)"  # For --deploy-mode client
          JAR="https://n0.minio1:9000/spark-sapp/jars/simpleapp-0.1.0-uber.jar"
          set -x
          set -f
          /opt/spark/bin/spark-submit --master k8s://https://kubernetes.default.svc --deploy-mode client --name ctemp-awf-java1 --class simpleapp.CreateTable $CONF  $JAR \
            --src "{{ inputs.parameters.src }}"  --bucket {{ inputs.parameters.bucket }} --datamartFolder "{{ inputs.parameters.datamartFolder }}" \
            --database {{ inputs.parameters.database }} --table {{ inputs.parameters.table }} \
            --select "{{ inputs.parameters.select }}"

```

Templates of this type may accept most of the Pod attributes.

In our case, the structure of this part for a Spark Job is quite similar to the one of a Kubernetes Jobs. 
The main difference is, aside environement variables, we have another level of configuration by using the Argo Workflow specific parameters system.

A last note: If you dig in Argo Workflow documentation, you will find a feature called 'artifact', which allow moving data between jobs. 
In our case, as data are located on an S3 storage, which is shared between jobs, passing data between jobs is just matter of passing S3 reference as parameters. 
So, the Artifact system is useless and not configured in our implementation.     

## Launch as an Apache Airflow task

Apache Airflow is a generic workflow orchestrator. As such, it is not included in the OpenDataPlatform service offer. 
But, if you have access to an existing Airflow deployment, this chapter will describe how to launch Spark Jobs using a [KubernetesPodOperator](https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/operators.html).

You will find a simple dag [here for its Java version](https://github.com/OpenDataPlatform/simpleapp/blob/main/airflow/dags/java1.py)
and [here for its PySpark version](https://github.com/OpenDataPlatform/simpleapp/blob/main/airflow/dags/pyspark1.py).

The structure of the dag is quite similar to the one of the Kubernetes Job described in a previous chapter. Except the Pod is defined as a Python object. 

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
- A set of variable value, provided as environment variables.

With this script, the last part of the manifests will be simplified, like the following:

```
      command:
        - "/bin/sh"
        - -c
        - |
          JAR="https://n0.minio1:9000/spark-sapp/jars/simpleapp-0.1.0-uber.jar"
          . /opt/confBuilder.sh
          set -x
          set -f
          /opt/spark/bin/spark-submit --master k8s://https://kubernetes.default.svc --deploy-mode client --name ctemp-job-java2 --class simpleapp.CreateTable $CONF  $JAR \
            --src "s3a://${SPARK_BUCKET}/data/city_temperature.csv"  --bucket ${SPARK_BUCKET} --database sapp --table ctemp_job_java2 --datamartFolder /warehouse/sapp.db \
            --select "SELECT * FROM _src_"
```

In a Kubernetes context, the practice will be to define a set of default parameters for an application in a ConfigMap,
which will be used by all pods using a `envFrom.[]configMapRef` directive, like the following:

```
          envFrom:
            - configMapRef:
                name: sapp-default
          env:
            - name: EXECUTOR_LIMIT_CORES    # Default value overriding
              value: "1800m"
```

As the variables defined in `env` take precedence over the ones defined in `envFrom`, we can override the defaut values, as `EXECUTOR_LIMIT_CORES` in the previous sample.

To define such ConfigMap, [here is a good starting point](https://github.com/OpenDataPlatform/simpleapp/blob/main/tools/sapp-default.sh)

Below are links for examples of `confBuilder.sh`:

- Example for Kubernetes Jobs: [Java](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/job/java2.yaml) and [PySpark](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/job/pyspark2.yaml)
- Example for Argo Workflow: [Java](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/argoworkflow/java2.yaml) and [PySpark](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/argoworkflow/pyspark2.yaml)
- Example for Apache Airflow: [Java](https://github.com/OpenDataPlatform/simpleapp/blob/main/airflow/dags/java2.py) and [PySpark](https://github.com/OpenDataPlatform/simpleapp/blob/main/airflow/dags/pyspark2.py)

### confBuilder.sh variables

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

The source code of this script can be found [here](https://github.com/OpenDataPlatform/kdc01/blob/master/addons/spark/docker/odp/confBuilder.sh)

## Embed application code in image

In most of previous samples, the application code is made available for drivers and executors as an https link.

Another approach coud be to include this application code in a specifc image.

The Dockerfile may look like this:

```
ARG img_base

FROM ${img_base}

# For this HowTo, embed both Java and Python version of the application
COPY py/create_table.py /opt/
ARG sapp_version
COPY java/build/libs/simpleapp-${sapp_version}-uber.jar /opt/
```

And the build command may look like this: 

```
docker build --push  --build-arg img_base=${DOCKER_REPO}/spark-odp:${ODP_TAG} --build-arg sapp_version=${SAPP_TAG} -t $(DOCKER_REPO)/sapp:${SAPP_TAG} -f Dockerfile .
```

Then, in your manifest, you can refer to you code:

```
    JAR="local:///opt/simpleapp-0.1.0-uber.jar"
    # or
    PY_CODE="local:///opt/create_table.py"
```

And, of course, don't forget to change the image in your manifest.

This approach could be appropriate if you have a smooth CI/CD chain.

Below are links for examples:

- Example for Kubernetes Jobs: [Java](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/job/java3.yaml) and [PySpark](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/job/pyspark3.yaml)
- Example for Argo Workflow: [Java](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/argoworkflow/java3.yaml) and [PySpark](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/argoworkflow/pyspark3.yaml)
- Example for Apache Airflow: [Java](https://github.com/OpenDataPlatform/simpleapp/blob/main/airflow/dags/java3.py) and [PySpark](https://github.com/OpenDataPlatform/simpleapp/blob/main/airflow/dags/pyspark3.py)

## Embed application code to launcher (python)

Here is another pattern, if you use pyspark and if your application code is made of few lines. Your code can be embded your code directly in the manifest, like the following:

```
      command:
        - "/bin/sh"
        - -c
        - |
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
          /opt/spark/bin/spark-submit --master k8s://https://kubernetes.default.svc --deploy-mode client --name ctemp-job-py4 $CONF $PY_CODE
```

Below are links for full examples:

- Example for [Kubernetes Jobs](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/job/pyspark4.yaml)
- Example for [Argo Workflow](https://github.com/OpenDataPlatform/simpleapp/blob/main/launchers/argoworkflow/pyspark4.yaml)
- Example for [Apache Airflow](https://github.com/OpenDataPlatform/simpleapp/blob/main/airflow/dags/pyspark4.py)

# The OpenDataPlatform provided images

Here is a short description of docker images you may use for Spark application in OpenDataPlatform

Note all these image include support for both amd64 and arm64 platforms

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

- `confBuilder.sh` script

  When used as Spark client, an helper script may be used to ease configuration. See below for a full description

## Spark operator image

This is a rebuild of the spark-operator image, based on spark-odp. Aim is to provide:

- Coherency of the spark version on all images
- Support run as non root.
- multiplatform support
