![CloverDX Server](https://www.cloverdx.com/hubfs/amidala-images/branding/cloverdx-logo.svg)
 
You can find the repository for this Dockerfile at <https://github.com/CloverDX>.

# Overview

This Docker container provides an easy way to create an CloverDX Server instance. The container is tailored to spin-up a 
standalone CloverDX Server with good defaults, in a recommended environment. 
 
# Quick Start
 
* Checkout or download this repository
* Download `clover.war` for Tomcat from <https://www.cloverdx.com>
* Put `clover.war` into `tomcat/webapps` directory.
* Optional: run `gradlew` to download additional dependencies, e.g. JDBC drivers.
* Build the Docker image:

    ```
    $ docker build -t cloverdx-server:latest .
    ```

* Start CloverDX Server:

    ```
    $ docker run -d --name cloverdx --memory=3g -p 8080:8080 -e LOCAL_USER_ID=`id -u $USER` --mount type=bind,source=/data/your-host-clover-home-dir,target=/var/clover cloverdx-server:latest
    ```  
The container requires at least 2 GB memory.

**Success**. CloverDX Server is now available at <http://localhost:8080/clover>. The Server is running with default settings, ie. embedded Derby system database, and should be configured further - see below.

# Architecture

This Docker container is designed to run a standalone CloverDX Server instance. It has external dependencies:

* *system database* - database for storing server's settings, state, history etc must be available somewhere. The container does not spin-up the database (except the default embedded Derby that should be used only for evaluation).
* *data sources/data targets* - the data sources/targets to be processed are expected to be outside of the container (temporary
files will be inside)

The container expects a mounted volume that will contain its state and configuration. The volume should be mounted into the ``/var/clover`` directory. Contents of the volume:

* ``conf/`` - configuration of the server, e.g. connection to the system database
* ``sandboxes/`` - sandboxes with jobs, metadata, data etc
* ``cloverlogs/`` - server logs
* ``tomcatlogs/`` - Tomcat logs
* ``tomcat-lib/`` - libraries to add to Tomcat and Server Core classpath
* ``worker-lib/`` - libraries to add to Worker classpath

Internal structure of the container:

* ``/opt/tomcat/`` - installation directory of Tomcat running the server
* ``/var/clover/`` - directory with persistent data, visible to users (config, jobs, logs, ...). It is expected that a volume is mounted into this directory from the host. See above for its structure
* ``/var/cloverdata/`` - directory with non-persistent data, not visible to users

Environment:

* Ubuntu Linux
* OpenJDK 11 from AdoptOpenJDK (slim JDK build with removed functionality that's typically not needed in cloud)
* Tomcat 9

Exposed ports:

* 8080 - HTTP port of the Server Console and Server's API
* 8686 - JMX port for monitoring of Server Core
* 8687 - JMX port for monitoring of Worker

# Configuration

## Data Volume

CloverDX Server needs a persistent storage for its data and configuration, so that the files are not lost when the container is restarted or updated to a newer version. By default, sandboxes, logs and configuration files are stored in an anonymous Docker volume. This makes them persistent across container restarts, but not across updates. You can bind a host directory to `/var/clover/` or mount a named Docker volume:

```bash
# bind host directory: 
--mount type=bind,source=/data/your-host-clover-data-dir,target=/var/clover
# mount a named volume:
--mount type=volume,source=name-of-your-volume,target=/var/clover
```

If you bind a directory from the host OS, the data files will be owned by user with UID 9001. You should override this by setting `LOCAL_USER_ID` environment variable:

```bash
-e LOCAL_USER_ID=`id -u $USER`
```

## Server Configuration

CloverDX Server is configured via configuration properties - e.g. connection information to the system database.

### Configuration via clover.properties

The ``clover.properties`` file contains server configuration properties and their values. For example:

```properties
jdbc.driverClassName=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://hostname:3306/clover?useUnicode=true&characterEncoding=utf8
jdbc.username=user
jdbc.password=pass
jdbc.dialect=org.hibernate.dialect.MySQLDialect
```

Put the ``clover.properties`` file in the ``conf`` directory of the data volume and it will be automatically recognized. If the file does not exist in the volume, server will create an empty
one and use default settings. It is possible to modify the file via Setup page in Server Console.

### Configuration via environment variables

Server's configuration properties can be set via environment variables in 2 ways:

* *direct override* - override server configuration properties with environment variables that have the same name, but with a ``clover.`` prefix. For example, the environment variable ``clover.sandboxes.home`` will override the configuration property ``sandboxes.home``.
* *placeholders* - configuration properties can reference environment variables using the ``${ENVIRONMENT_VARIABLE}`` syntax. For example, ``sandboxes.home=${SANDBOXES_ROOT}``.

Environment variable values are set when running the container:
``docker run -e "clover.sandboxes.home=/some/path" image_name``

## System Database Configuration

By default, CloverDX Server will use an embedded Derby database. In order to use an external database, the container needs a JDBC driver and a configuration file:

1. If necessary, put additional JDBC drivers to `var/dbdrivers/` before building the image and then build the image.
2. Put [database configuration properties](https://doc.cloverdx.com/latest/server/examples-db-connection-configuration.html) into `clover.properties` configuration file and place it into `/data/your-host-clover-data-dir/conf/` directory in your host file system.
3. Bind `/data/your-host-clover-data-dir/` to `/var/clover/` (see above) and start the container.

TODO update this section, does it belong here?

## Libraries and Classpath

Libraries are added to the classpath of Tomcat (ie Server Core) and Worker via the mounted volume. This action does not modify the build of the Docker image. Place the JARs to the following directories in the volume:

* ``tomcat-lib/`` - libraries to add to Tomcat and Server Core classpath (e.g. JDBC drivers)
* ``worker-lib/`` - libraries to add to Worker classpath (e.g. libraries used by jobs)

## Tomcat Configuration

The mounted volume contains fragments of Tomcat configuration files that configure various aspects of Tomcat. If the files are not found during the start of the Docker container, the container will create commented-out examples of them.

Configuration files:

* ``conf/https-conf.xml`` - configuration of HTTPS connector of Tomcat, is inserted into ``server.xml`` when running the container. Uncomment the ``<Connector>...`` XML element and update the configuration as a standard Tomcat 9 HTTPS connector (see [documentation](https://tomcat.apache.org/tomcat-9.0-doc/ssl-howto.html)). Export the port of the connector from the container (port 8443 by default). Put the keystore in the mounted volume, e.g. if it's in ``conf/keystore.jks`` in the volume, then the path to it in the ``https-conf.xml`` file is ``/var/clover/conf/keystore.jks``. We recommend to not expose the unsecured HTTP port (8080 by default) in case HTTPS is enabled.
* ``conf/jmx-conf.properties`` - Java properties that can be updated to enable JMX monitoring over SSL (disabled by default). Put the keystore in the mounted volume, e.g. if it's in ``conf/keystore.jks`` in the volume, then the path to it in the ``jmx-conf.properties`` file is ``/var/clover/conf/keystore.jks``.
* ``conf/jndi-conf.xml`` - configuration of JNDI resources of Tomcat, is inserted into ``server.xml``when running the container. See the commented ``<Resource>`` example on how to add a JNDI resource. We recommend to use JNDI to connect to server's system database.

Examples of these files are in this repo (see ``tomcat/conf/*example*`` files) - the examples can be used as a starting point for the configuration files before the first start of the container.

## Memory

Important memory settings inside the container are Java heap size for Server Core, Java heap size for Worker and sizes of additional Java memory spaces. The memory settings are automatically calculated based on the memory assigned to the container instance. 

For example, if running the container with 4GB of RAM:

``docker run -d --name cloverdx --memory=4g  ... ``

Then Server Core will have 1GB heap, Worker will have 2GB heap, and the rest is left for additional Java memory spaces and the OS.

The automatic memory settings can be overridden by setting both properties:

* ``CLOVER_SERVER_HEAP_SIZE`` - heap size of Server Core, value as for the -Xmx Java argument
* ``CLOVER_WORKER_HEAP_SIZE``  - heap size of Worker, value as for the -Xmx Java argument

## CPU

The docker image follows CPU constraints assigned to it, e.g. it sees just a limited number of CPU cores and is assigned a portion of CPU cycles of the host machine.

Usefull options of the ``docker run`` commands (see [documentation](https://docs.docker.com/config/containers/resource_constraints/)):

* ``--cpus=<value>`` - portion of host CPUs the container can use. For example, ``--cpus=1.5`` allows at most one and a half CPU from all the hosts CPUs. Available in Docker 1.13 and higher.
* ``--cpu-shares=<value>`` - value is weight of the container, and containers running on a host get their share of CPU cycles based on their weight. Default weight is ``1024``, which also translates into 1 CPU core from the point of view of Java. For example setting this to ``4096`` will cause Java to see 4 CPU cores.

We recommend setting multiple CPU cores for the docker image, e.g. ``--cpus=4``.

## Timezone

Default timezone of the container instance is UTC. The timezone is NOT inherited from the Docker host. To set a specific timezone, set the environment variable ``TZ`` when running the container:

``docker run -e TZ=Europe/Amsterdam ...``

# Monitoring

The docker container exposes ports by default for JMX monitoring via tools such as [VisualVM](https://visualvm.github.io/). The JMX monitoring tools are useful to analyse threads, memory usage, classloaders etc.

Exported JMX ports:

* ``8686`` - JMX monitoring of Server Core and Tomcat, use to monitor and analyse behavior of the core parts of server, i.e. scheduling, listeners, web UI, etc.
* ``8687`` - JMX monitoring of Worker, use to monitor and analyse behavior of jobs, jobflows etc

# Security

By default, the ports exposed by the container (8080, 8686, 8687) do not use SSL. To secure them via SSL, additional configuration is needed:

## HTTP(S) port

To enable HTTPS, modify the file ``conf/https-conf.xml`` in the mounted volume, place the keystore in the mounted volume and export the HTTPS port (8443 be default). See ``conf/https-conf.xml`` in (#tomcat-configuration) for more details.

## JMX ports

To enable JMX monitoring over SSL, modify the file ``conf/jmx-conf.properties`` in the mounted volume and place the keystore in the mounted volume. See ``conf/jmx-conf.properties`` in (#tomcat-configuration) for more details.
