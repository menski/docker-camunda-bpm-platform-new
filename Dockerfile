FROM alpine:latest

# set berlin timezone
ENV TZ=Europe/Berlin

# expose http port
EXPOSE 8080

# add start script
ADD start-camunda.sh /bin/

# location of camunda distro
WORKDIR /camunda

# java environment
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=66 \
    JAVA_VERSION_BUILD=17 \
    JAVA_PACKAGE=server-jre \
    JAVA_HOME=/jre

ENV JDK_TARGZ="http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz" \
    PATH=${JAVA_HOME}/bin:${PATH} \
    LANG=C.UTF-8

# install tools
ENV GLIBC_APK="https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-2.21-r2.apk" \
    GLIBC_BIN_APK="https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-bin-2.21-r2.apk" \
    XMLSTARLET_APK="https://github.com/menski/alpine-pkg-xmlstarlet/releases/download/1.6.1-r1/xmlstarlet-1.6.1-r1.apk"

RUN apk add --update curl ca-certificates libxml2 libxslt && \
    cd /tmp && \
    curl -jSLo glibc.apk $GLIBC_APK && \
    curl -jSLo glibc-bin.apk $GLIBC_BIN_APK && \
    curl -jSLo xmlstarlet.apk $XMLSTARLET_APK && \
    apk add --allow-untrusted glibc.apk glibc-bin.apk xmlstarlet.apk && \
    /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib && \
    rm -rf /tmp/* /var/cache/apk/* && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# intall oracle jre
RUN cd /tmp && \
    mkdir -p $JAVA_HOME && \
    curl -jSLo jdk.tar.gz -H "Cookie: oraclelicense=accept-securebackup-cookie" $JDK_TARGZ && \
    tar xzf jdk.tar.gz && \
    mv jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR}/jre/* ${JAVA_HOME}/ && \
    rm -rf /tmp/*

# camunda and database driver artifacts
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

# download camunda distro and database drivers
RUN cd /tmp && \
    curl -jkSLo camunda.tar.gz "${NEXUS}&g=${GROUP}&a=${ARTIFACT}&v=${VERSION}&p=tar.gz" && \
    tar xzf camunda.tar.gz &&\
    mv server/apache-tomcat-*/* /camunda/ && \
    curl -jSL "${NEXUS}&g=${MYSQL_GROUP}&a=${MYSQL_ARTIFACT}&v=${MYSQL_VERSION}&p=jar" -o "/camunda/lib/${MYSQL_ARTIFACT}-${MYSQL_VERSION}.jar" && \
    curl -jSL "${NEXUS}&g=${POSTGRESQL_GROUP}&a=${POSTGRESQL_ARTIFACT}&v=${POSTGRESQL_VERSION}&p=jar" -o "/camunda/lib/${POSTGRESQL_ARTIFACT}-${POSTGRESQL_VERSION}.jar" && \
    rm -rf /tmp/*

# start command
CMD ["/bin/start-camunda.sh"]
