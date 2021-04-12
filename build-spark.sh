#!/bin/bash

set -ex

SPARK_VERSION=3.0.2
HADOOP_VERSION=3.2.0
HIVE_VERSION=2.3.5
AWS_SDK_VERSION=1.11.682
BIGQUERY_CONNECTOR_VERSION=0.19.1
#
MYCWD=$(pwd)
rm -rf /tmp/opt
# BUILD HIVE FOR HIVE v1 - needed for spark client
git clone --depth 1 --branch rel/release-$HIVE_VERSION https://github.com/apache/hive.git /tmp/opt/hive
cd /tmp/opt/hive
# wget https://issues.apache.org/jira/secure/attachment/12958417/HIVE-12679.branch-1.2.patch
# patch -p0 <HIVE-12679.branch-1.2.patch
wget https://issues.apache.org/jira/secure/attachment/12958418/HIVE-12679.branch-2.3.patch
patch -p0 <HIVE-12679.branch-2.3.patch
mvn clean install -DskipTests -Phadoop-2 # -Dspark.version=$SPARK_VERSION -Dhadoop.version=$HADOOP_VERSION
# Related to this issue https://github.com/awslabs/aws-glue-data-catalog-client-for-apache-hive-metastore/pull/14
mkdir -p ~/.m2/repository/org/spark-project
cp -r ~/.m2/repository/org/apache/hive ~/.m2/repository/org/spark-project

# BUILD AWS GLUE DATA CATALOG CLIENT
git clone https://github.com/ismailsimsek/aws-glue-data-catalog-client-for-apache-hive-metastore.git /tmp/opt/glue
cd /tmp/opt/glue
#sed -i '/<packaging>pom<\/packaging>/a <dependencies><dependency><groupId>org.apache.hadoop<\/groupId><artifactId>hadoop-common<\/artifactId><version>${hadoop.version}<\/version><scope>provided<\/scope><\/dependency><\/dependencies>' shims/pom.xml
mvn clean package -DskipTests -pl -aws-glue-datacatalog-hive2-client -Dhadoop.version=$HADOOP_VERSION -Dhive2.version=$HIVE_VERSION -Daws.sdk.version=$AWS_SDK_VERSION

# BUILD SPARK
git clone --depth 1 --branch v$SPARK_VERSION https://github.com/apache/spark.git /tmp/opt/spark
cd /tmp/opt/spark
./dev/make-distribution.sh --name my-custom-spark --pip -Phadoop-${HADOOP_VERSION%.*} -Phive -Dhadoop.version=$HADOOP_VERSION -Dhive.version=$HIVE_VERSION

# ADD MISSING & BUILT JARS TO SPARK CLASSPATHS + CONFIG
cd /tmp/opt/spark/dist
# Copy missing deps
mvn dependency:get -Dartifact=asm:asm:3.2
mvn dependency:get -Dartifact=net.minidev:json-smart:1.3.1
mvn dependency:get -Dartifact=org.apache.httpcomponents:httpcore:4.4.9
mvn dependency:get -Dartifact=org.apache.httpcomponents:httpcore:4.4.11
find /tmp/opt/glue -name "*.jar" -exec cp {} jars \;
# Copy configuration
cp ${MYCWD}/conf/* conf
# Copy AWS and Bigquery connector jars
echo :quit | ./bin/spark-shell --conf spark.jars.packages=com.amazonaws:aws-java-sdk:$AWS_SDK_VERSION,org.apache.hadoop:hadoop-aws:$HADOOP_VERSION,com.google.cloud.spark:spark-bigquery-with-dependencies_2.12:$BIGQUERY_CONNECTOR_VERSION
cp ~/.ivy2/jars/*.jar jars
# Download GCS connector jar
wget https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop2-latest.jar -P jars/
# Create archive
DIRNAME=spark-bin-hadoop-glue
mv /tmp/opt/spark/dist /tmp/opt/spark/$DIRNAME
cd /tmp/opt/spark && tar -cvzf $DIRNAME.tgz $DIRNAME
