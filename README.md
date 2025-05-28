![CloverDX Server](https://www.cloverdx.com/hubfs/amidala-images/branding/cloverdx-logo.svg)
 
You can find the repository for this Dockerfile at <https://github.com/CloverDX>.

# Overview

This Docker container provides an easy way to create a CloverDX Server instance. The container is tailored to spin-up a 
standalone CloverDX Server with good defaults, in a recommended environment. 
 
# Quick Start
 
* Clone or download this repository and checkout the corresponding branch. For example, clone and checkout branch for release 6.4.0 via ``git clone https://github.com/cloverdx/cloverdx-server-docker.git -b release-6-4``.
* Download `clover.war` for Tomcat from <https://www.cloverdx.com>
* Put `clover.war` into `cloverdx-server-docker` directory (current working directory containing the `Dockerfile`).
* Optional: run `gradlew` to download additional dependencies, e.g. JDBC drivers, BouncyCastle.
* Build the Docker image:

    ```
    $ docker build -t cloverdx-server:latest .
    ```

* Start CloverDX Server on Linux:

    ```
    $ docker run -d --name cloverdx --memory=3g -p 8080:8080 -e LOCAL_USER_ID=`id -u $USER` --mount type=bind,source=/data/your-host-clover-home-dir,target=/var/clover cloverdx-server:latest
    ```  
    
* Start CloverDX Server on Windows:

    ```
    docker run -d --name cloverdx --memory=3g -p 8080:8080 --mount type=bind,source=C:/your-host-clover-home-dir,target=/var/clover cloverdx-server:latest
    ```      

    Explanation:
    
    * ``-d`` - detached mode, the container exits when Server exits
    * ``--name`` - name to identify the running container
    * ``--memory=3g`` - allow 3 GB of memory for the container, the container requires at least 2 GB of memory.
    * ``-p 8080:8080`` - publish exposed container port
    * ```-e LOCAL_USER_ID=`id -u $USER``` - set an environment variable, in this case user ID to be used for permissions (only on Linux)
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
* ``clover-lib/`` - libraries to add to Tomcat, Server Core classpath and Worker classpath 
* ``tomcat-lib/`` - libraries to add to Tomcat and Server Core classpath
* ``worker-lib/`` - libraries to add to Worker classpath

Internal structure of the container:

* ``/opt/tomcat/`` - installation directory of Tomcat running the server
* ``/var/clover/`` - directory with persistent data, visible to users (config, jobs, logs, ...). It is expected that a volume is mounted into this directory from the host. See above for its structure
* ``/var/cloverdata/`` - directory with non-persistent data, not visible to users
* ``/var/clover-lib/`` - libraries to add to Tomcat, Server Core classpath and Worker classpath 
* ``/var/tomcat-lib/`` - libraries to add to Tomcat and Server Core classpath
* ``/var/worker-lib/`` - libraries to add to Worker classpath

Environment:

* Ubuntu Linux
* Eclipse Temurin JDK 17
* Tomcat 10.1

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

CloverDX Server needs a persistent storage for its data and configuration, so that the files are not lost when the container is restarted or updated to a newer version. You should bind a host directory to `/var/clover/` inside the container as a mounted volume:

```bash
# bind host directory on Linux: 
--mount type=bind,source=/data/your-host-clover-data-dir,target=/var/clover
```

```bash
# bind host directory on Windows: 
--mount type=bind,source=C:/your-host-clover-data-dir,target=/var/clover
```

On Linux, if you bind a directory from the host OS, the data files will be owned by user with UID 1000. You should override this by setting `LOCAL_USER_ID` environment variable:

```bash
-e LOCAL_USER_ID=`id -u $USER`
```

## Server Configuration

CloverDX Server is configured via configuration properties - e.g. connection information to the system database. See [documentation](https://doc.cloverdx.com/latest/admin/list-of-properties.html) for available configuration properties.

### Configuration via clover.properties

The ``clover.properties`` file contains server configuration properties and their values. For example:

```properties
jdbc.driverClassName=com.mysql.cj.jdbc.Driver
jdbc.url=jdbc:mysql://hostname:3306/clover?useUnicode=true&characterEncoding=utf8
jdbc.username=user
jdbc.password=pass
jdbc.dialect=org.hibernate.dialect.MySQLDialect
```

Put the ``clover.properties`` file in the ``conf`` directory of the data volume and it will be automatically recognized. If the file does not exist in the volume, server will create an empty one and use default settings. It is possible to modify the file via Setup page in Server Console.

### Configuration via environment variables

Server's configuration properties can be set via environment variables in 2 ways:

* *direct override* - override server configuration properties with environment variables that have the same name, but with a ``clover.`` prefix. For example, the environment variable ``clover.sandboxes.home`` will override the configuration property ``sandboxes.home``.
* *placeholders* - configuration properties can reference environment variables using the ``${env:ENVIRONMENT_VARIABLE}`` syntax. For example, ``sandboxes.home=${env:SANDBOXES_ROOT}``.

Environment variable values are set when running the container:
``docker run -e "clover.sandboxes.home=/some/path" ...``

## System Database Configuration

By default, CloverDX Server will use an embedded Derby database. In order to use an external database, the container needs a JDBC driver and a configuration file:

1. If necessary, put additional JDBC drivers to `var/dbdrivers/` before building the image and then build the image. The ``gradlew`` build script in this repository downloads some default JDBC drivers.
2. Put [database configuration properties](https://doc.cloverdx.com/latest/admin/examples-db-connection-configuration.html) into `clover.properties` configuration file and place it into `/data/your-host-clover-data-dir/conf/` directory in your host file system.
3. Bind `/data/your-host-clover-data-dir/` to `/var/clover/` (see above) and start the container.

## Libraries and Classpath

Libraries are added to the classpath of Tomcat (i.e. Server Core) and Worker via the mounted volume. This action does not modify the build of the Docker image. Place the JARs to the following directories in the volume:

* ``tomcat-lib/`` - libraries to add to Tomcat and Server Core classpath (e.g. JDBC drivers)
* ``worker-lib/`` - libraries to add to Worker classpath (e.g. libraries used by jobs)

## Sandboxes

The container automatically imports all directories from ``sandboxes/`` directory in the mounted volume as sandboxes. This helps with initial set-up of the container, just place your sandboxes and their content into ``sandboxes/`` in the volume and the container automatically imports them without additional configuration needed.

This feature is enabled by default in the container, not in vanilla CloverDX Server. It can be enabled/disabled via the ``sandboxes.autoimport`` configuration property (``true``/``false``). Sandboxes are imported from the ``sandboxes.home`` path, which is set to ``sandboxes/`` in the mounted volume.

The container does not create default example sandboxes by default. To enable them, set the ``installer.BundledSandboxesInstaller.enabled`` configuration property to ``true``.

## Schedules, Listeners, Data Services

During the first startup, the container automatically imports configuration XML from ``${CLOVER_HOME_DIR}/conf/configuration_import.xml``. This way you can set up schedulers, event listeners and data services, for example. The file can be obtained by [exporting configuration](https://doc.cloverdx.com/latest/admin/server-config.html#id_server_config_export) from an existing Server instance. You can edit the exported file and replace hard-coded values with placeholders, e.g. ``${env:VARIABLE_NAME}`` will be replaced with the value of ``VARIABLE_NAME`` environment variable during the import.

This feature is enabled by default in the container, not in vanilla CloverDX Server. It can be enabled/disabled via the ``configuration.autoimport.file`` configuration property.

Additionally, during the first startup the container also automatically imports configuration from each of the automatically created sandboxes (see   section [Sandboxes](#sandboxes) above). In each sandbox there can be a ``sandbox_configuration.xml`` file that can contain sandbox-related configuration entities (schedules, event listeners, data services, job config properties). See [documentation](https://doc.cloverdx.com/latest/operations/sandboxes.html#id_sandbox_config_import) for more details. This simplifies deployment of sandbox content and related configuration.

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
* ``conf/jndi-conf.xml`` - configuration of JNDI resources of Tomcat, is referenced from ``server.xml`` when running the container. See the commented ``<Resource>`` example on how to add a JNDI resource. We recommend to use JNDI to connect to server's system database.

Examples of these files are in this repo (see ``public/tomcat/defaults`` directory) - the examples can be used as a starting point for the configuration files before the first start of the container.

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

* ``CLOVER_SERVER_HEAP_SIZE`` - heap size of Server Core (in MB)
* ``CLOVER_WORKER_HEAP_SIZE``  - heap size of Worker (in MB)

Note that if the memory for the container is not limited with the ``--memory`` option, the memory settings will be calculated as though only 2 GB of memory were available (Server Core will have 0.5 GB heap, Worker will have 1 GB heap).

## CPU

The docker image follows CPU constraints assigned to it, e.g. it sees just a limited number of CPU cores and is assigned a portion of CPU cycles of the host machine.

Useful options of the ``docker run`` commands (see [documentation](https://docs.docker.com/config/containers/resource_constraints/)):

* ``--cpus=<value>`` - portion of host CPUs the container can use. For example, ``--cpus=1.5`` allows at most one and a half CPU of all the host's CPUs. Available in Docker 1.13 and higher.
* ``--cpu-shares=<value>`` - value is a weight of the container, and containers running on a host get their share of CPU cycles based on their weight. Default weight is ``1024``, which also translates into 1 CPU core from the point of view of Java. For example setting this to ``4096`` will cause Java to see 4 CPU cores.

We recommend setting multiple CPU cores for the docker image, e.g. ``--cpus=4``.

## Timezone

Default timezone of the container instance is UTC. The timezone is NOT inherited from the Docker host. To set a specific timezone, set the environment variable ``TZ`` when running the container:

``docker run -e TZ=Europe/Amsterdam ...``

## Healthcheck

The container reports its health via the Docker HEALTHCHECK instruction.

The healthcheck periodically calls ``http://localhost:8080/clover/accessibilityTest.jsp`` to check the health of CloverDX Server. By default it is set-up to survive short restarts of the Worker.

Default setting in our container:

* --start-period=120s - two minutes for the container to initialize
* --interval=30s - thirty seconds between running the check
* --timeout=5s
* --retries=4 - four consecutive failures needed to set unhealthy state. In combination with thirty seconds interval above allows short Worker restarts.

## Custom Entrypoint Scripts

If you need to run some script before CloverDX Server starts, but after ``$CLOVER_HOME_DIR`` directory is created, put your code into ``public/docker/hooks/init.sh`` file. Alternatively, you can also mount your own script as the ``init.sh`` file:

``docker run -v /your/hook/script.sh:/opt/tomcat/hooks/init.sh``

---
# Monitoring

The docker container exposes ports by default for JMX monitoring via tools such as [VisualVM](https://visualvm.github.io/). The JMX monitoring tools are useful to analyze threads, memory usage, classloaders, etc.

Exposed JMX ports:

* ``8686`` - JMX monitoring of Server Core and Tomcat, use to monitor and analyze behavior of the core parts of server, i.e. scheduling, listeners, web UI, etc. Use this port when connecting a **JMX client to Server Core**.
* ``8687`` - RMI port for the above JMX monitoring of Server Core. This port is a utility port transparently used by JMX client.
* ``8688`` - JMX monitoring of Worker, use to monitor and analyze behavior of jobs, jobflows, etc. Use this port when connecting a **JMX client to Worker**.
* ``8689`` - RMI port for the above JMX monitoring of Worker. This port is a utility port transparently used by JMX client.

To enable JMX:

1. set the ``RMI_HOSTNAME`` environment variable to the hostname or IP address of the running container instance (i.e. the instance must know its external address)
1. make sure that the ports above are published. Container ports have to be mapped to the same ports on the Docker host (e.g. -p 8686:8686 -p 8687:8687...)

See also [JMX over SSL](#jmx-over-ssl) section below.

---

# Security

This section describes security related aspects of the container. Some secure configuration cannot be enabled by default, because it requires additional information from the users (e.g. certificates for SSL) or 3rd party libraries that must be downloaded separately (e.g. Bouncy Castle for stronger cryptography).

 By default, the ports exposed by the container do not use SSL. To secure them via SSL, additional configuration is needed - see subsection below.

## HTTPS

To enable HTTPS:

1. place the keystore in ``conf/serverKS.jks`` file in the mounted volume
1. modify the file ``conf/https-conf.xml`` in the mounted volume - uncomment the ``<Connector>...`` XML element and update the configuration as a standard Tomcat 10.1 HTTPS connector (see [documentation](https://tomcat.apache.org/tomcat-10.1-doc/ssl-howto.html)).
1. publish the HTTPS port (8443 be default) when running the container (e.g. ``docker run -p 8443:8443 ...``)
1. we recommend not to publish the unsecured HTTP port (8080 by default) in case HTTPS is enabled.

## JMX over SSL

JMX monitoring over SSL is supported for both Server Core and Worker. To enable it:

1. place the keystore in ``conf/serverKS.jks`` file in the mounted volume
1. modify the file ``conf/jmx-conf.properties`` in the mounted volume
1. publish the JMX ports (8686 and 8687 for Server Core, 8688 and 8689 for Worker) when running the container (e.g. ``docker run -p 8686:8686 -p 8687:8687 ...``)

## Stronger Cryptography

Cryptography in CloverDX is used primarily for [Secure Parameters](https://doc.cloverdx.com/latest/admin/secure-parameters.html) and [Secure Configuration Properties](https://doc.cloverdx.com/latest/admin/secure-configuration-properties.html). It is possible to use stronger cryptographic algorithms than those available in the JVM, by installing a custom JCE provider. We recommend using [Bouncy Castle](https://www.bouncycastle.org/). The steps below are a simplified version of our documentation, the only difference from non-Docker deployment is getting Bouncy Castle on classpath of the server.

### Install Bouncy Castle

* Download Bouncy Castle JAR ( e.g. ``bcprov-jdk15on-1.70.jar`` from [here](https://www.bouncycastle.org/latest_releases.html)).
* Place it in ``var/bouncy-castle`` before building the image and then build the image. Optionally, the ``gradlew`` build script in this repository downloads it.

### Secure Configuration Properties

*Secure configuration properties* are server's configuration properties that have encrypted values. They are used to encrypt sensitive values in the configuration file, e.g. credentials used to connect Server to the system database.

* select Bouncy Castle as encryption provider and select the encryption algorithm - configure this via configuration properties:

    ```properties
    ...
    security.config_properties.encryptor.providerClassName=org.bouncycastle.jce.provider.BouncyCastleProvider
    security.config_properties.encryptor.algorithm=PBEWITHSHA256AND256BITAES-CBC-BC
    ...
    ```

* use the same encryption provider and algorithm when using ``encrypt.sh`` tool (from our ``secure-cfg-tool.zip`` package) to encrypt the configuration property values:

    ``encrypt.sh -a PBEWITHMD5AND256BITAES-CBC-OPENSSL -c org.bouncycastle.jce.provider.BouncyCastleProvider -l bcprov-jdk15on-149.jar``

### Secure Parameters

*Secure parameters* are graph parameters that have encrypted values. Typically they are used to store credentials used by jobs to connect to external systems and they prevent storage of the credentials in plain text.

* select Bouncy Castle as encryption provider and select the encryption algorithm - configure this via configuration properties:

    ```properties
    ...
    security.job_parameters.encryptor.providerClassName=org.bouncycastle.jce.provider.BouncyCastleProvider
    security.job_parameters.encryptor.algorithm=PBEWITHSHA256AND256BITAES-CBC-BC
    ...
    ```

* set the master password in Server Console (in *Configuration* > *Security* page) or use autoimport (below)

### Master password autoimport

During the first startup, the container automatically imports master password from `${CLOVER_HOME_DIR}/conf/master-password.txt`, if the file exists.
The file can be created manually. *The whole file content* is imported as the new password.

This feature is enabled by default in the container, not in vanilla CloverDX Server. It can be enabled/disabled via the `masterpassword.autoimport.file` configuration property.

After server start, you can check that the password is set in *Configuration* > *Security* page.

# Stack Deployment

You can deploy CloverDX Server and its system database together as a stack using [docker compose](https://github.com/docker/compose) or [stack deploy](https://docs.docker.com/engine/swarm/stack-deploy/) in swarm mode. There is a provided example of compose file in ``examples/compose`` for deployment of PostgreSQL database and CloverDX Server built from Dockerfile.

To build and run the stack in docker compose, use:

``docker compose -f examples/compose/stack.yml up -d``

or in a Docker swarm:

``docker stack deploy -c examples/compose/stack.yml cloverdx``

# Kubernetes

You can deploy CloverDX Server to Kubernetes. There are examples of deployment of a standalone CloverDX Server and a 3-node CloverDX Cluster in [examples/kubernetes](examples/kubernetes)

# Building and Running the AI-Enabled Docker Image

[Dockerfile.AI](./Dockerfile.AI) allows to build an alternative Docker image that enables CloverDX Server to run AI components on systems with NVIDIA GPU support. This setup leverages an NVIDIA-provided base image that includes CUDA and related dependencies, allowing seamless execution of GPU-accelerated tasks. Note that only Linux x86_64 platform is currently supported.

## Prerequisites

To run the AI-enabled container, your host machine must meet the following requirements:

* **NVIDIA GPU with compatible drivers** installed (see [installation guide](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/index.html))
* **NVIDIA Container Toolkit** installed - this allows Docker to interface with the GPU hardware (see [installation guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html))
* Docker runtime configured for GPU support (see [installation guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#configuring-docker))

You can test if your setup is working with:

``docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi``

You should see details about the NVIDIA GPU(s) if everything is configured correctly.

## Building the AI-Enabled Docker Image

From the root of the repository:

* Optional: Run ``./gradlew`` to download additional dependencies, e.g. JDBC drivers, BouncyCastle.
* Download DJL native PyTorch driver for GPU runtime support (note that the driver has ~2.3GiB):

    ``./gradlew copyDjlPytorchLib``

* Build the Docker image using Dockerfile.AI:

    ``docker build -f Dockerfile.AI -t cloverdx-server-ai:latest .``

## Running the AI-Enabled Container

Running the AI-enabled container is nearly identical to the standard CloverDX container, with one important addition:

* Add the ``--gpus all`` option to enable GPU access.

Example (on Linux):

```
docker run -d --name cloverdx-ai --gpus all --memory=6g -p 8080:8080 -e LOCAL_USER_ID=`id -u $USER` --mount type=bind,source=/data/your-host-clover-home-dir,target=/var/clover cloverdx-server-ai:latest
```

**Note:** The ``--gpus all`` parameter enables the container to access all available NVIDIA GPUs. Without this flag, GPU acceleration will not be available, and AI components may fail to start. Learn more in the [Docker GPU runtime docs](https://docs.docker.com/reference/cli/docker/container/run/#gpus).

## Verifying GPU Access

Once the container is running, you can verify that the GPU is visible to the AI components from within the container:

    ``docker exec -it cloverdx-ai /bin/bash``

Then inside the container:

    ``nvidia-smi``

You should see details about the NVIDIA GPU(s) if everything is configured correctly.