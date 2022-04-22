

# ---------------------- Version related configuration

SPARK_VERSION := 3.2.1
HADOOP_VERSION := 3.2
# See ../NOTES.md
AWS_SDK_BUNDLE_VERSION := 1.11.901
HADOOP_VERSION2 := 3.3.1

SPARK_ARCHIVE := spark-$(SPARK_VERSION)-bin-hadoop$(HADOOP_VERSION).tgz
SPARK_BASE := spark-$(SPARK_VERSION)-bin-hadoop$(HADOOP_VERSION)
AWS_JAVA_JAR := aws-java-sdk-bundle-$(AWS_SDK_BUNDLE_VERSION).jar
HADOOP_AWS_JAR := hadoop-aws-$(HADOOP_VERSION2).jar

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# ----------------------------------------------------------------- common download
archives/$(SPARK_ARCHIVE):
	wget https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/$(SPARK_ARCHIVE) --directory-prefix=archives

.PHONY: patch-jars
patch-jars: patches/jars/$(AWS_JAVA_JAR) patches/jars/$(HADOOP_AWS_JAR)

patches/jars/$(AWS_JAVA_JAR):
	wget "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_BUNDLE_VERSION}/$(AWS_JAVA_JAR)" --directory-prefix=patches/jars

patches/jars/$(HADOOP_AWS_JAR):
	wget "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION2}/$(HADOOP_AWS_JAR)" --directory-prefix=patches/jars

# -------------------------------------------------------------------- local setup

.PHONY: spark
spark: $(SPARK_BASE) patch-jars patches ## Setup a local dev env in local/spark-....

$(SPARK_BASE): archives/$(SPARK_ARCHIVE)
	tar xvzf ./archives/$(SPARK_ARCHIVE) && touch $(SPARK_BASE)

patches: $(SPARK_BASE)/jars/$(AWS_JAVA_JAR) $(SPARK_BASE)/jars/$(HADOOP_AWS_JAR) $(SPARK_BASE)/conf/log4j.properties $(SPARK_BASE)/conf/spark-defaults.conf

$(SPARK_BASE)/jars/$(AWS_JAVA_JAR):
	cp patches/jars/$(AWS_JAVA_JAR) $@

$(SPARK_BASE)/jars/$(HADOOP_AWS_JAR):
	cp patches/jars/$(HADOOP_AWS_JAR) $@

$(SPARK_BASE)/conf/log4j.properties:
	cp patches/conf/log4j.properties $@

$(SPARK_BASE)/conf/spark-defaults.conf:
	cp patches/conf/spark-defaults.conf $@
