![CloverDX Server](https://www.cloverdx.com/hubfs/amidala-images/branding/cloverdx-logo.svg)
 
You can find the repository for this Dockerfile at <https://github.com/CloverDX>.

# Overview

This Docker container provides an easy way to create a CloverDX Server instance. The container is tailored to spin-up a 
standalone CloverDX Server with good defaults, in a recommended environment. 
 
# Quick Start
 
* Checkout or download this repository (Checkout via ``git clone https://github.com/cloverdx/cloverdx-server-docker.git``)
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

    Explanation:
    
    * ``-d`` - detached mode, the container exits when Server exits
    * ``--name`` - name to identify the running container
    * ``--memory=3g`` - allow 3 GB of memory for the container, the container requires at least 2 GB of memory.
    * ``-p 8080:8080`` - publish exposed container port
    * ```-e LOCAL_USER_ID=`id -u $USER``` - set an environment variable, in this case user ID to be used for permissions
    * ``--mount type=bind,source=/data/your-host-clover-home-dir,target=/var/clover`` - mount the ``/data/your-host-clover-home-dir`` directory from the host as a data volume into ``/var/clover`` path inside the container, this will contain the persistent data, configuration, etc.
    * ``cloverdx-server:latest`` - name of the image to run as a container

**Success**. CloverDX Server is now available at <http://localhost:8080/clover>. The Server is running with default settings, and **should be configured further** to get it into production quality (i.e. it should use external database).

---

# Architecture

This Docker container is designed to run a standalone CloverDX Server instance. 

![Container architecture](/docker-architecture.png)

It has external dependencies:

* *system database* - database for storing server's settings, state, history, etc. must be available somewhere. The container does not spin-up the database (except of the default embedded Derby that should be used only for evaluation).
* *data sources/data targets* - the data sources/targets to be processed are expected to be outside of the container (temporary files will be inside)

The container expects a mounted volume that will contain its state and configuration. The volume should be mounted into the ``/var/clover`` directory. Contents of the volume:

* ``conf/`` - configuration of the server, e.g. connection to the system database
* ``sandboxes/`` - sandboxes with jobs, metadata, data, etc.
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

Default exposed ports:

* 8080 - HTTP port of the Server Console and Server's API
* 8686 - JMX port for monitoring of Server Core
* 8687 - RMI port for the above Server Core JMX monitoring
* 8688 - JMX port for monitoring of Worker
* 8689 - RMI port for the above Worker JMX monitoring

Used ports need to be published when running the container via the ``-p HOST_PORT:CONTAINER_PORT`` (this maps the inside ``CONTAINER_PORT`` to be visible from the outside as ``HOST_PORT``). If you enable additional ports (e.g. 8443 for HTTPS), do not forget to publish them.

---

# Configuration

## Data Volume

CloverDX Server needs a persistent storage for its data and configuration, so that the files are not lost when the container is restarted or updated to a newer version. You should bind a host directory to `/var/clover/` inside the container ad a mounted volume:

```bash
# bind host directory: 
--mount type=bind,source=/data/your-host-clover-data-dir,target=/var/clover
```

If you bind a directory from the host OS, the data files will be owned by user with UID 1000. You should override this by setting `LOCAL_USER_ID` environment variable:

```bash
-e LOCAL_USER_ID=`id -u $USER`
```

## Server Configuration

CloverDX Server is configured via configuration properties - e.g. connection information to the system database. See [documentation](https://doc.cloverdx.com/latest/server/list-of-properties.html) for available configuration properties.

### Configuration via clover.properties

The ``clover.properties`` file contains server configuration properties and their values. For example:

```properties
jdbc.driverClassName=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://hostname:3306/clover?useUnicode=true&characterEncoding=utf8
jdbc.username=user
jdbc.password=pass
jdbc.dialect=org.hibernate.dialect.MySQLDialect
```

Put the ``clover.properties`` file in the ``conf`` directory of the data volume and it will be automatically recognized. If the file does not exist in the volume, server will create an empty one and use default settings. It is possible to modify the file via Setup page in Server Console.

### Configuration via environment variables

Server's configuration properties can be set via environment variables in 2 ways:

* *direct override* - override server configuration properties with environment variables that have the same name, but with a ``clover.`` prefix. For example, the environment variable ``clover.sandboxes.home`` will override the configuration property ``sandboxes.home``.
* *placeholders* - configuration properties can reference environment variables using the ``${ENVIRONMENT_VARIABLE}`` syntax. For example, ``sandboxes.home=${SANDBOXES_ROOT}``.

Environment variable values are set when running the container:
``docker run -e "clover.sandboxes.home=/some/path" ...``

## System Database Configuration

By default, CloverDX Server will use an embedded Derby database. In order to use an external database, the container needs a JDBC driver and a configuration file:

1. If necessary, put additional JDBC drivers to `var/dbdrivers/` before building the image and then build the image. The ``gradlew`` build script in this repository downloads some default JDBC drivers.
2. Put [database configuration properties](https://doc.cloverdx.com/latest/server/examples-db-connection-configuration.html) into `clover.properties` configuration file and place it into `/data/your-host-clover-data-dir/conf/` directory in your host file system.
3. Bind `/data/your-host-clover-data-dir/` to `/var/clover/` (see above) and start the container.

## Libraries and Classpath

Libraries are added to the classpath of Tomcat (i.e. Server Core) and Worker via the mounted volume. This action does not modify the build of the Docker image. Place the JARs to the following directories in the volume:

* ``tomcat-lib/`` - libraries to add to Tomcat and Server Core classpath (e.g. JDBC drivers)
* ``worker-lib/`` - libraries to add to Worker classpath (e.g. libraries used by jobs)

## Sandboxes

The container automatically imports all directories from ``sandboxes/`` directory in the mounted volume as sandboxes. This helps with initial set-up of the container, just place your sandboxes and their content into ``sandboxes/`` in the volume and the container automatically imports them without additional configuration needed.

This feature is enabled by default in the container, not in vanilla CloverDX Server. It can be enabled/disabled via the ``sandboxes.autoimport`` configuration property (``true``/``false``). Sandboxes are imported from the ``sandboxes.home`` path, which is set to ``sandboxes/`` in the mounted volume.

The container does not create default example sandboxes by default. To enable them, set the ``installer.BundledSandboxesInstaller.enabled`` configuration property to ``true``.

## License

To activate CloverDX Server, the container by default searches for a license file (text file containing the license key itself) in the ``conf/license.dat`` path in the mounted volume.

Alternative options:

* activate the server via the Server Console in the browser
* modify the ``license.file`` configuration property and set a different path to the license file, e.g. to a different volume

## Tomcat Configuration

The mounted volume contains fragments of Tomcat configuration files that configure various aspects of Tomcat. If the files are not found during the start of the container, the container will create commented-out examples of them.

Configuration files:

* ``conf/https-conf.xml`` - configuration of HTTPS connector of Tomcat, is referenced from ``server.xml`` when running the container. See *Security* / *HTTPS* section below.
* ``conf/jmx-conf.properties`` - Java properties that can be updated to enable JMX monitoring over SSL. See *Security* / *JMX over SSL* section below.
* ``conf/jndi-conf.xml`` - configuration of JNDI resources of Tomcat, is referenced from ``server.xml``when running the container. See the commented ``<Resource>`` example on how to add a JNDI resource. We recommend to use JNDI to connect to server's system database.

Examples of these files are in this repo (see ``tomcat/conf/*example*`` files) - the examples can be used as a starting point for the configuration files before the first start of the container.

## Java Tuning

The container starts two Java processes - one for Tomcat running CloverDX Server Core and one for Worker running jobs. The container sets good default options for Java. For additional tuning of the command line options, use the following environment variables:

* ``SERVER_JAVA_OPTS`` - additional Java command line options for Server Core and Tomcat
* ``WORKER_JAVA_OPTS`` - additional Java command line options for Worker

The command line options in the above environment variables are added to the options that the container sets by default. It's mostly meant for customizing garbage collector, Java performance logging, etc. Do not use this to extend the classpath - see *Libraries and Classpath* section above for that.

## Memory

Important memory settings inside the container are Java heap size for Server Core, Java heap size for Worker and sizes of additional Java memory spaces. The memory settings are automatically calculated based on the memory assigned to the container instance. 

For example, if running the container with 4 GB of RAM:

``docker run -d --name cloverdx --memory=4g  ... ``

Then Server Core will have 1 GB heap, Worker will have 2 GB heap, and the rest is left for additional Java memory spaces and the OS.

The automatic memory settings can be overridden by setting **BOTH** environment properties:

* ``CLOVER_SERVER_HEAP_SIZE`` - heap size of Server Core, value as for the -Xmx Java argument
* ``CLOVER_WORKER_HEAP_SIZE``  - heap size of Worker, value as for the -Xmx Java argument

## CPU

The docker image follows CPU constraints assigned to it, e.g. it sees just a limited number of CPU cores and is assigned a portion of CPU cycles of the host machine.

Useful options of the ``docker run`` commands (see [documentation](https://docs.docker.com/config/containers/resource_constraints/)):

* ``--cpus=<value>`` - portion of host CPUs the container can use. For example, ``--cpus=1.5`` allows at most one and a half CPU of all the host's CPUs. Available in Docker 1.13 and higher.
* ``--cpu-shares=<value>`` - value is a weight of the container, and containers running on a host get their share of CPU cycles based on their weight. Default weight is ``1024``, which also translates into 1 CPU core from the point of view of Java. For example setting this to ``4096`` will cause Java to see 4 CPU cores.

We recommend setting multiple CPU cores for the docker image, e.g. ``--cpus=4``.

## Timezone

Default timezone of the container instance is UTC. The timezone is NOT inherited from the Docker host. To set a specific timezone, set the environment variable ``TZ`` when running the container:

``docker run -e TZ=Europe/Amsterdam ...``

---

# Monitoring

The docker container exposes ports by default for JMX monitoring via tools such as [VisualVM](https://visualvm.github.io/). The JMX monitoring tools are useful to analyse threads, memory usage, classloaders, etc.

Exposed JMX ports:

* ``8686`` - JMX monitoring of Server Core and Tomcat, use to monitor and analyse behavior of the core parts of server, i.e. scheduling, listeners, web UI, etc. Use this port when connecting a **JMX client to Server Core**.
* ``8687`` - RMI port for the above JMX monitoring of Server Core. This port is a utility port transparently used by JMX client.
* ``8688`` - JMX monitoring of Worker, use to monitor and analyse behavior of jobs, jobflows, etc. Use this port when connecting a **JMX client to Worker**.
* ``8689`` - RMI port for the above JMX monitoring of Worker. This port is a utility port transparently used by JMX client.

To enable JMX:

1. set the ``RMI_HOSTNAME`` environment variable to the hostname or IP address of the running container instance (i.e. the instance must know its external address)
1. make sure that the ports above are published

To enable JMX over SSL, see *JMX over SSL* section below.

---

# Security

By default, the ports exposed by the container do not use SSL. To secure them via SSL, additional configuration is needed:

## HTTPS

To enable HTTPS:

1. place the keystore in ``conf/serverKS.jks`` file in the mounted volume
1. modify the file ``conf/https-conf.xml`` in the mounted volume - uncomment the ``<Connector>...`` XML element and update the configuration as a standard Tomcat 9 HTTPS connector (see [documentation](https://tomcat.apache.org/tomcat-9.0-doc/ssl-howto.html)).
1. publish the HTTPS port (8443 be default) when running the container (e.g. ``docker run -p 8443:8443 ...``)
1. we recommend not to publish the unsecured HTTP port (8080 by default) in case HTTPS is enabled.

## JMX over SSL

Currently JMX monitoring over SSL is supported for Server Core. To enable it:

1. place the keystore in ``conf/serverKS.jks`` file in the mounted volume
1. modify the file ``conf/jmx-conf.properties`` in the mounted volume
1. publish the JMX ports (8686 and 8687 for Server Core) when running the container (e.g. ``docker run -p 8686:8686 p 8687:8687 ...``)
