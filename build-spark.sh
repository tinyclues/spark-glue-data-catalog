#!/bin/bash

set -ex

SPARK_VERSION=3.1.2
HADOOP_VERSION=3.2.0
HIVE_VERSION=2.3.7
AWS_SDK_VERSION=1.11.797

# BUILD HIVE FOR HIVE v1 - needed for spark client
cd /opt/
wget https://github.com/apache/hive/archive/rel/release-${HIVE_VERSION}.tar.gz -O hive.tar.gz
mkdir hive && tar xzf hive.tar.gz --strip-components=1 -C hive
cd /opt/hive
wget https://issues.apache.org/jira/secure/attachment/12958418/HIVE-12679.branch-2.3.patch

patch -p0 <HIVE-12679.branch-2.3.patch
mvn clean install -DskipTests
# Related to this issue https://github.com/awslabs/aws-glue-data-catalog-client-for-apache-hive-metastore/pull/14
mkdir -p ~/.m2/repository/org/spark-project
cp -r ~/.m2/repository/org/apache/hive ~/.m2/repository/org/spark-project

# BUILD AWS GLUE DATA CATALOG CLIENT
git clone https://github.com/viaduct-ai/aws-glue-data-catalog-client-for-apache-hive-metastore /opt/glue

cd /opt/glue
mvn clean package \
    -DskipTests \
    -Dhive2.version=${HIVE_VERSION} \
    -Dhadoop.version=${HADOOP_VERSION} \
    -Daws.sdk.version=${AWS_SDK_VERSION} \
    -pl -aws-glue-datacatalog-hive2-client


# BUILD SPARK
git clone https://github.com/apache/spark.git /opt/spark
cd /opt/spark
git checkout tags/v$SPARK_VERSION -b v$SPARK_VERSION
./dev/make-distribution.sh --name my-custom-spark --pip -Phadoop-${HADOOP_VERSION%.*} -Phive -Dhadoop.version=$HADOOP_VERSION -Dhive.version=$HIVE_VERSION

# ADD MISSING & BUILT JARS TO SPARK CLASSPATHS + CONFIG
cd /opt/spark/dist
# Copy missing deps
mvn dependency:get -Dartifact=asm:asm:3.2
mvn dependency:get -Dartifact=net.minidev:json-smart:1.3.1
mvn dependency:get -Dartifact=org.apache.httpcomponents:httpcore:4.4.11
find /opt/glue -name "*.jar" -exec cp {} jars \;
# Copy configuration
cp /conf/* conf
# Copy AWS and Bigquery connector jars
echo :quit | ./bin/spark-shell --conf spark.jars.packages=com.amazonaws:aws-java-sdk:$AWS_SDK_VERSION,org.apache.hadoop:hadoop-aws:$HADOOP_VERSION
cp /root/.ivy2/jars/*.jar jars
# Create archive
DIRNAME=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION%.*}-glue
mv /opt/spark/dist /opt/spark/$DIRNAME
cd /opt/spark && tar -cvzf $DIRNAME.tgz $DIRNAME
mv $DIRNAME.tgz /dist
