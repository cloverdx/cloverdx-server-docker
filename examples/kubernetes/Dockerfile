ARG DOCKER_REGISTRY
FROM ${DOCKER_REGISTRY}/cloverdx-server:latest

COPY conf $CLOVER_HOME_DIR/conf

COPY sandboxes $CLOVER_HOME_DIR/sandboxes

COPY license.dat $CLOVER_CONF_DIR

### Monitoring
# Copy JMX Exporter config file
COPY jmx-prometheus-config.yaml $CLOVER_CONF_DIR

# Copy JMX exporter jar
COPY jmx_prometheus_javaagent-0.12.0.jar $CLOVER_LIB_DIR

# Add exporter to Core Server
RUN echo "export JAVA_OPTS=\"$JAVA_OPTS -javaagent:/var/clover-lib/jmx_prometheus_javaagent-0.12.0.jar=8787:/var/clover/conf/jmx-prometheus-config.yaml\"" >> /opt/tomcat/bin/setenv.sh

# Add exporter to Worker
ENV WORKER_JAVA_OPTS=-javaagent:/var/clover-lib/jmx_prometheus_javaagent-0.12.0.jar=8788:/var/clover/conf/jmx-prometheus-config.yaml

# 8080: HTTP
# 8686 and 8687: JMX for Core server
# 8688 and 8689: JMX for Worker
# 8787: JMX exporter for Core
# 8788: JMX exporter for Worker
EXPOSE 8080 8686 8687 8688 8689 8787 8788
