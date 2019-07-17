FROM adoptopenjdk/openjdk11:jdk-11.0.3_7-slim

ARG TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.20/bin/apache-tomcat-9.0.20.tar.gz"

# Tomcat home directory
ENV CATALINA_HOME /opt/tomcat

# Directory with persistent data, visible to users (sandboxes, logs, configuration files)
ENV CLOVER_HOME_DIR /var/clover
# Directory with persistent data, invisible to users (tempspaces)
ENV CLOVER_DATA_DIR /var/cloverdata
# Shared libraries for both Tomcat and worker
ENV CLOVER_LIB_DIR /var/clover-lib

# Default directories for configuration files
ENV CLOVER_CONF_DIR $CLOVER_HOME_DIR/conf
ENV CATALINA_CONF_DIR $CATALINA_HOME/conf

# Configuration files
ENV CLOVER_CONF_FILE $CLOVER_CONF_DIR/clover.properties
ENV JNDI_CONF_FILE $CLOVER_CONF_DIR/jndi-conf.xml
ENV JMX_CONF_FILE $CLOVER_CONF_DIR/jmx-conf.properties
ENV HTTPS_CONF_FILE $CLOVER_CONF_DIR/https-conf.xml

# Set default locale to en_US; see also 'locale-gen' command below
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

WORKDIR $CATALINA_HOME

# Change the default shell to Bash
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux && \
	# The default answers be used for all questions
	export DEBIAN_FRONTEND=noninteractive && \
	# Change the default shell from dash to bash
	ln -sfv /bin/bash /bin/sh && \
	# Install required packages
	apt-get update && \
	apt-get install --no-install-recommends -y gosu tzdata fontconfig locales dumb-init && \
	apt-get -y autoremove && \
	apt-get -y clean && \
	rm -rf /var/lib/apt/lists/* && \
	# Install en_US locale
	locale-gen $LANG && \
	# Verify that gosu works
	gosu nobody true && \
	# Download and extract Tomcat
	curl "$TOMCAT_URL" | tar -xz --strip-components=1 && \
	# Create directories
	mkdir -p $CLOVER_CONF_DIR $CLOVER_HOME_DIR $CLOVER_DATA_DIR && \
	# Change permisions for the writable directories - CLO-16457
	chmod -R o+x $CATALINA_HOME/work $CATALINA_HOME/webapps $CATALINA_HOME/logs $CATALINA_HOME/temp && \
	# Remove unused directories
	rm -rf $CATALINA_HOME/webapps/*

# Customize downloaded Tomcat
COPY tomcat $CATALINA_HOME
# Copy additional libraries
COPY var /var

# Change permissions for startup scripts
RUN chmod u+x entrypoint.sh && \
	chmod u+x bin/setenv.sh

# Create volumes for Clover home dir and internal data dir
VOLUME $CLOVER_HOME_DIR $CLOVER_DATA_DIR

# 8080: HTTP, 8686 and 8687: JMX for Core server, 8688 and 8689: JMX for worker
EXPOSE 8080 8686 8687 8688 8689

ENTRYPOINT ["/usr/bin/dumb-init", "--", "./entrypoint.sh"]
