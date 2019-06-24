ARG BASE_IMAGE=adoptopenjdk/openjdk11:jdk-11.0.3_7-slim
FROM ${BASE_IMAGE}

ENV CATALINA_HOME /opt/tomcat
#worker does not start when CATALINA_TMPDIR=$CATALINA_HOME/temp and use is not root
ENV CATALINA_TMPDIR $CATALINA_HOME/tmpdir

#directory with persistent data, visible to users (sandboxes, logs)
ENV CLOVER_HOME_DIR /var/clover
#directory with persistent data, invisible to users (tempspaces, cfg files)
ENV CLOVER_DATA_DIR /var/cloverdata
#shared libraries for both tomcat and worker
ENV CLOVER_LIB_DIR /var/cloverlib

#default configuration file
ARG CLOVER_CONF_DIR=$CATALINA_HOME/cloverconf
ENV CATALINA_CONF_DIR=$CATALINA_HOME/conf

ENV DEFAULT_CONF_FILE $CLOVER_CONF_DIR/default_clover.properties

#configuration files, which can be customized by user
ENV CLOVER_HOME_CONF_DIR $CLOVER_HOME_DIR/conf
ENV JNDI_CONF_FILE $CLOVER_HOME_CONF_DIR/jndi-conf.xml
ENV JMX_CONF_FILE $CLOVER_HOME_CONF_DIR/jmx-conf.properties
ENV HTTPS_CONF_FILE $CLOVER_HOME_CONF_DIR/https-conf.xml

ENV CUSTOM_CONF_FILE $CLOVER_HOME_CONF_DIR/clover.properties

ENV SERVER_KEY_STORE $CLOVER_HOME_CONF_DIR/serverKS.jks

ARG TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.20/bin/apache-tomcat-9.0.20.tar.gz"

WORKDIR $CATALINA_HOME

#change the default shell to Bash
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux && \
	ln -sfv /bin/bash /bin/sh && \
#install gosu, time zones, locale and fontconfig
	apt-get update && \
	apt-get install -y gosu tzdata fontconfig locales dumb-init && \
	locale-gen en_US.UTF-8 && \
	rm -rf /var/lib/apt/lists/* && \
#verify that the binary works
	gosu nobody true
	
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'	

#download and extract tomcat in one step; create directories (one layer),
#create directories,
#create symbolic link for custom configuration file,
#create (empty) custom configuration file
#change permisions for the writable directories - CLO-16457
#remove the unused directories
RUN curl "$TOMCAT_URL" | tar -xz --strip-components=1 && \
	mkdir -p $CLOVER_CONF_DIR $CLOVER_HOME_DIR $CLOVER_DATA_DIR $CATALINA_TMPDIR && \
	chmod -R o+x $CATALINA_HOME/work $CATALINA_HOME/webapps $CATALINA_HOME/logs $CATALINA_HOME/temp && \
	rm -rf $CATALINA_HOME/webapps/* 

#logging.properties depends on tomcat version
COPY tomcat $CATALINA_HOME
COPY ./var /var

RUN chmod u+x entrypoint.sh && \
	chmod u+x bin/setenv.sh

VOLUME $CLOVER_DATA_DIR

EXPOSE 8080 8686

ENTRYPOINT ["/usr/bin/dumb-init", "--", "./entrypoint.sh"]
