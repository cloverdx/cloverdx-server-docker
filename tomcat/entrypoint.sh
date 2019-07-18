#!/bin/bash

# Min memory limits in bytes
MIN_MEMORY_SIZE=2147483648
MIN_SERVER_HEAP_SIZE=512
MIN_WORKER_HEAP_SIZE=1024

# Load functions for computing memory
. memory-utils.sh

#############################################################################
# Start of the script                                                       #
#############################################################################

compute_memory

# Print info about memory settings
echo -e $(print_mem_info)

USER=cloverdx
# If not specified otherwise, user "cloverdx" will have UID 1000
# Used when $CLOVER_HOME_DIR is bind-mounted to the host OS
USER_ID=${LOCAL_USER_ID:-1000}

echo "Creating $USER user"
adduser \
	--disabled-password \
	--gecos "" \
	--home "/home/$USER" \
	--shell "/bin/bash" \
	--uid "$USER_ID" \
	"$USER"

echo "Changing ownership of working directories"
chown -R $USER:$USER $CATALINA_HOME
chown -R $USER:$USER $CLOVER_HOME_DIR
chown -R $USER:$USER $CLOVER_DATA_DIR

if [ ! -d $CLOVER_HOME_DIR ]; then
	echo "Creating empty folder for Clover home directory $CLOVER_HOME_DIR"
	gosu $USER mkdir -p $CLOVER_HOME_DIR
fi	

if [ ! -d $CLOVER_CONF_DIR ]; then
	echo "Creating empty folder for config files $CLOVER_CONF_DIR"
	gosu $USER mkdir -p $CLOVER_CONF_DIR
fi	

if [ ! -f $CLOVER_CONF_FILE ]; then
	echo "Creating default Clover config file $CLOVER_CONF_FILE"
	gosu $USER cp "$CATALINA_CONF_DIR/clover_example.properties" $CLOVER_CONF_FILE
fi

if [ ! -f $JNDI_CONF_FILE ]; then
	echo "Creating default JNDI config file $JNDI_CONF_FILE"
	gosu $USER cp "$CATALINA_CONF_DIR/jndi-conf_example.xml" $JNDI_CONF_FILE
fi

if [ ! -f $JMX_CONF_FILE ]; then
	echo "Creating default JMX config file $JMX_CONF_FILE"
	gosu $USER cp "$CATALINA_CONF_DIR/jmx-conf_example.properties" $JMX_CONF_FILE
fi

# If SSL is used, jmx-conf.properties must only be readable by the owner (r--,---,---).
# Therefore we make a copy of the file and mark it as read-only.
gosu $USER cp $JMX_CONF_FILE $CATALINA_HOME/cloverconf
chmod 0400 $CATALINA_HOME/cloverconf/jmx-conf.properties

if [ ! -f $HTTPS_CONF_FILE ]; then
	echo "Creating default HTTPS config file $HTTPS_CONF_FILE"
	gosu $USER cp "$CATALINA_CONF_DIR/https-conf_example.xml" $HTTPS_CONF_FILE
fi

if [ ! -d $CLOVER_HOME_DIR/tomcat-lib ]; then
	echo "Creating ${CLOVER_HOME_DIR}/tomcat-lib"
	gosu $USER mkdir $CLOVER_HOME_DIR/tomcat-lib
	echo "Copying JDBC drivers to ${CLOVER_HOME_DIR}/tomcat-lib"
	gosu $USER cp /var/dbdrivers/* ${CLOVER_HOME_DIR}/tomcat-lib/
fi

# Create an empty directory for additional worker jars
gosu $USER mkdir -p $CLOVER_HOME_DIR/worker-lib

# Set SERVER_JAVA_OPTS to empty string if not set
if [ -z "$SERVER_JAVA_OPTS" ]; then
	export SERVER_JAVA_OPTS=""
fi

# Set WORKER_JAVA_OPTS to empty string if not set
if [ -z "$WORKER_JAVA_OPTS" ]; then
	export WORKER_JAVA_OPTS=""
fi

echo "Starting Tomcat"
exec gosu $USER ./bin/catalina.sh run
