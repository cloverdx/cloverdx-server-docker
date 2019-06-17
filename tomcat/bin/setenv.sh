export CATALINA_OPTS="$CATALINA_OPTS -Xms${CLOVER_SERVER_HEAP_SIZE}m -Xmx${CLOVER_SERVER_HEAP_SIZE}m"
export CATALINA_OPTS="$CATALINA_OPTS -XX:ReservedCodeCacheSize=${ReservedCodeCacheSize}m"
export CATALINA_OPTS="$CATALINA_OPTS -Djdk.nio.maxCachedBufferSize=${maxCachedBufferSize}"

export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseG1GC"
export CATALINA_OPTS="$CATALINA_OPTS -XX:ParallelGCThreads=4"
export CATALINA_OPTS="$CATALINA_OPTS -XX:ConcGCThreads=4"
export CATALINA_OPTS="$CATALINA_OPTS -XX:InitiatingHeapOccupancyPercent=30"
export CATALINA_OPTS="$CATALINA_OPTS -XX:G1ReservePercent=10"
export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxGCPauseMillis=100"
 
#echo "RMI_HOSTNAME - ${RMI_HOSTNAME}"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.config.file=$CLOVER_HOME_CONF_DIR/jmx-conf.properties"

#JMX settings
#export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
#export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote=true"
#export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=8686"

#Settings JMX without SSL
#export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
#export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
#export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.rmi.port=8686"
#export CATALINA_OPTS="$CATALINA_OPTS -Djava.rmi.server.hostname=${RMI_HOSTNAME}"
		
#Settings JMX with SSL
#export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=true"
#export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl.need.client.auth=false"
#export CATALINA_OPTS="$CATALINA_OPTS -Djavax.net.ssl.keyStore=/var/clover/conf/serverKS.jks"
#export CATALINA_OPTS="$CATALINA_OPTS -Djavax.net.ssl.keyStorePassword=semafor"



export CATALINA_OPTS="$CATALINA_OPTS -Dclover.default.config.file=$DEFAULT_CFG_FILE"
export CATALINA_OPTS="$CATALINA_OPTS -Dclover.config.file=$CUSTOM_CFG_FILE"
export CATALINA_OPTS="$CATALINA_OPTS -Dclover.clover.home=$CLOVER_HOME_DIR"
export CATALINA_OPTS="$CATALINA_OPTS -Dclover.lib=$CLOVER_LIB_DIR"
export CATALINA_OPTS="$CATALINA_OPTS -Dclover.log4j2.appender.stdout.level=info"

export CATALINA_OPTS="$CATALINA_OPTS ${SERVER_JAVA_OPTS}"
