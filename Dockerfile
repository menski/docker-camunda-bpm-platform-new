FROM ubuntu:14.04

# install oracle java and xmlstarlet
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" > /etc/apt/sources.list.d/oracle-jdk.list && \
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com EEA14886 && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get update && \
    apt-get -y install --no-install-recommends oracle-java8-installer xmlstarlet ca-certificates && \
    apt-get clean && \
    rm -rf /var/cache/* /var/lib/apt/lists/*

# add start script
ADD start-camunda.sh /bin/

# expose http port
EXPOSE 8080

# start command
CMD ["/bin/start-camunda.sh"]

# nexus to download artifacts
ENV NEXUS=https://app.camunda.com/nexus/service/local/artifact/maven/content?r=public \
# camunda artifact
    GROUP=org.camunda.bpm.tomcat \
    ARTIFACT=camunda-bpm-tomcat \
    VERSION=7.4.0-SNAPSHOT \
# mysql artifact
    MYSQL_GROUP=mysql \
    MYSQL_ARTIFACT=mysql-connector-java \
    MYSQL_VERSION=5.1.21 \
# postgresql artifact
    POSTGRESQL_GROUP=org.postgresql \
    POSTGRESQL_ARTIFACT=postgresql \
    POSTGRESQL_VERSION=9.3-1102-jdbc4

# download camunda distro
ADD ${NEXUS}&g=${GROUP}&a=${ARTIFACT}&v=${VERSION}&p=tar.gz /tmp/camunda-bpm-platform.tar.gz

# unpack camunda distro
WORKDIR /camunda
RUN tar xzf /tmp/camunda-bpm-platform.tar.gz -C /camunda/ --wildcards --strip 2 server/*

# download mysql driver
ADD ${NEXUS}&g=${MYSQL_GROUP}&a=${MYSQL_ARTIFACT}&v=${MYSQL_VERSION}&p=jar /camunda/lib/

# download postgresl driver
ADD ${NEXUS}&g=${POSTGRESQL_GROUP}&a=${POSTGRESQL_ARTIFACT}&v=${POSTGRESQL_VERSION}&p=jar /camunda/lib/
