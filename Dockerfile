FROM ubuntu:14.04

# set berlin timezone
ENV TZ=Europe/Berlin

# install tools
RUN apt-get update && \
    apt-get -y install --no-install-recommends curl xmlstarlet ca-certificates && \
    apt-get clean && \
    rm -rf /var/cache/* /var/lib/apt/lists/*

# intall oracle jre
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=66 \
    JAVA_VERSION_BUILD=17 \
    JAVA_PACKAGE=server-jre \
    JAVA_HOME=/jre

ENV PATH ${JAVA_HOME}/bin:${PATH}

RUN cd /tmp && \
    curl -jkSLH "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz | tar xzf - && \
    mkdir -p $JAVA_HOME && \
    mv jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR}/jre/* ${JAVA_HOME}/ && \
    rm -rf /tmp/*

# add start script
ADD start-camunda.sh /bin/

# expose http port
EXPOSE 8080

# start command
CMD ["/bin/start-camunda.sh"]

# nexus to download artifacts
ENV NEXUS=https://app.camunda.com/nexus/service/local/artifact/maven/content?r=public \
# camunda artifact
    GROUP=org.camunda.bpm.wildfly \
    ARTIFACT=camunda-bpm-wildfly \
    VERSION=7.4.0-SNAPSHOT \
# mysql artifact
    MYSQL_GROUP=mysql \
    MYSQL_ARTIFACT=mysql-connector-java \
    MYSQL_VERSION=5.1.21 \
# postgresql artifact
    POSTGRESQL_GROUP=org.postgresql \
    POSTGRESQL_ARTIFACT=postgresql \
    POSTGRESQL_VERSION=9.3-1102-jdbc4

# wildfly modules
ENV MYSQL_MODULE=/camunda/modules/mysql/${MYSQL_ARTIFACT}/main \
    POSTGRESQL_MODULE=/camunda/modules/org/postgresql/${POSTGRESQL_ARTIFACT}/main

# wildfly settings
ENV PREPEND_JAVA_OPTS="-Djboss.bind.address=0.0.0.0 -Djboss.bind.address.management=0.0.0.0" \
    LAUNCH_JBOSS_IN_BACKGROUND=TRUE

# download camunda distro
ADD ${NEXUS}&g=${GROUP}&a=${ARTIFACT}&v=${VERSION}&p=tar.gz /tmp/camunda-bpm-platform.tar.gz

# unpack camunda distro
WORKDIR /camunda
RUN tar xzf /tmp/camunda-bpm-platform.tar.gz -C /camunda/ --wildcards --strip 2 server/*

# prepare mysqsl and postgresql modules
ADD database-module.xml /tmp/database-module.xml
RUN mkdir -p ${MYSQL_MODULE} ${POSTGRESQL_MODULE} && \
    cp -v /tmp/database-module.xml ${MYSQL_MODULE}/module.xml && \
    mv -v /tmp/database-module.xml ${POSTGRESQL_MODULE}/module.xml && \
    sed -i "s/%GROUP%/${MYSQL_GROUP}/g; s/%ARTIFACT%/${MYSQL_ARTIFACT}/g; s/%VERSION%/${MYSQL_VERSION}/g" ${MYSQL_MODULE}/module.xml && \
    sed -i "s/%GROUP%/${POSTGRESQL_GROUP}/g; s/%ARTIFACT%/${POSTGRESQL_ARTIFACT}/g; s/%VERSION%/${POSTGRESQL_VERSION}/g" ${POSTGRESQL_MODULE}/module.xml

# download mysql driver
ADD ${NEXUS}&g=${MYSQL_GROUP}&a=${MYSQL_ARTIFACT}&v=${MYSQL_VERSION}&p=jar ${MYSQL_MODULE}/${MYSQL_ARTIFACT}-${MYSQL_VERSION}.jar

# download postgresl driver
ADD ${NEXUS}&g=${POSTGRESQL_GROUP}&a=${POSTGRESQL_ARTIFACT}&v=${POSTGRESQL_VERSION}&p=jar ${POSTGRESQL_MODULE}/${POSTGRESQL_ARTIFACT}-${POSTGRESQL_VERSION}.jar
