FROM python:3.6-slim-stretch

# ADD REPO FOR JDK
RUN echo "deb http://ftp.us.debian.org/debian sid main" >> /etc/apt/sources.list \
&&  apt-get update \
&&  mkdir -p /usr/share/man/man1

# INSTALL PACKAGES
RUN apt-get install -y git wget openjdk-8-jdk

# INSTALL MAVEN
ENV MAVEN_VERSION=3.6.3
RUN cd /opt \
&&  wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
&&  tar zxvf /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
&&  rm apache-maven-${MAVEN_VERSION}-bin.tar.gz
ENV PATH=/opt/apache-maven-$MAVEN_VERSION/bin:$PATH
ENV MAVEN_HOME /opt/apache-maven-${MAVEN_VERSION}

# configure the pentaho nexus repo to prevent build errors
# similar to the following: https://github.com/apache/hudi/issues/2479
COPY ./maven-settings.xml ${MAVEN_HOME}/conf/settings.xml

