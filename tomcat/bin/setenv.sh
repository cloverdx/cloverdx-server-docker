export CATALINA_OPTS="$CATALINA_OPTS -Xms${CLOVER_SERVER_HEAP_SIZE}m -Xmx${CLOVER_SERVER_HEAP_SIZE}m"
export CATALINA_OPTS="$CATALINA_OPTS -XX:ReservedCodeCacheSize=${ReservedCodeCacheSize}m"
export CATALINA_OPTS="$CATALINA_OPTS -Djdk.nio.maxCachedBufferSize=${maxCachedBufferSize}"

export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseG1GC"
export CATALINA_OPTS="$CATALINA_OPTS -XX:ParallelGCThreads=4"
export CATALINA_OPTS="$CATALINA_OPTS -XX:ConcGCThreads=4"
export CATALINA_OPTS="$CATALINA_OPTS -XX:InitiatingHeapOccupancyPercent=30"
export CATALINA_OPTS="$CATALINA_OPTS -XX:G1ReservePercent=10"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxGCPauseMillis=100"
 
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.config.file=$CLOVER_HOME_CONF_DIR/jmx-conf.properties"
export CATALINA_OPTS="$CATALINA_OPTS -Djava.rmi.server.hostname=${RMI_HOSTNAME}"

export CATALINA_OPTS="$CATALINA_OPTS -Dclover.default.config.file=$DEFAULT_CFG_FILE"
export CATALINA_OPTS="$CATALINA_OPTS -Dclover.config.file=$CUSTOM_CFG_FILE"
export CATALINA_OPTS="$CATALINA_OPTS -Dclover.clover.home=$CLOVER_HOME_DIR"
export CATALINA_OPTS="$CATALINA_OPTS -Dclover.lib=$CLOVER_LIB_DIR"
export CATALINA_OPTS="$CATALINA_OPTS -Dclover.log4j2.appender.stdout.level=info"

export CATALINA_OPTS="$CATALINA_OPTS ${SERVER_JAVA_OPTS}"
