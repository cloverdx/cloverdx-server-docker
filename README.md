![CloverDX Server](https://www.cloverdx.com/hubfs/amidala-images/branding/cloverdx-logo.svg)
 
You can find the repository for this Dockerfile at <https://github.com/CloverDX>.

# Overview

This Docker container provides an easy way to create an CloverDX Server instance. The container is tailored to spin-up a 
standalone CloverDX Server with good defaults, in a recommended environment. 
 
# Quick Start
 
* Download `clover.war` for Tomcat from <https://www.cloverdx.com>
* Checkout or download this repository
* Put `clover.war` into `tomcat/webapps` directory.
* Optional: run `gradlew` to download additional dependencies, e.g. JDBC drivers.
* Build the Docker image:

    ```
    $ docker build -t cloverdx-server:latest .
    ```

* Start CloverDX Server:

    ```
    $ docker run -d --name cloverdx --memory=3g -p 8080:8080 --e "TZ=America/New_York" --mount type=bind,source=/data/your-host-clover-home-dir,target=/var/clover cloverdx-server:latest
    ```  
The container requires at least 3 GB memory.

**Success**. CloverDX Server is now available at <http://localhost:8080/clover>.

# Architecture

This Docker container is designed to run a standalone CloverDX Server instance. It has external dependencies:

* *system database* - database for storing server's settings, state, history etc must be available somewhere. The container does not spin-up the database (except the default embedded Derby that should be used only for evaluation).
* *data sources/data targets* - the data to be processes are expected to be outside of the container (temporary
files will be inside)

The container expects a mounted volume that will contain its state and configuration. The volume should be mounted into the ``/var/clover`` directory. Contents of the volume:

* ``conf`` - configuration of the server, e.g. connection to the system database
* ``sandboxes`` - sandboxes with jobs, metadata, data etc
* ``cloverlogs`` - server logs
* ``tomcatlogs`` - Tomcat logs
* ``tomcat-lib`` - libraries to add to Tomcat and Server Core classpath
* ``worker-lib`` - libraries to add to Worker classpath

Internal structure of the container:

* ``/opt/tomcat`` - installation directory of Tomcat running the server
* ``/var/clover`` - directory with persistent data, visible to users (config, jobs, logs, ...). It is expected that a volume is mounted into this directory from the host. See above for its structure
* ``/var/cloverdata`` - directory with non-persistent data, not visible to users

Environment:

* Ubuntu Linux
* OpenJDK 11 from AdoptOpenJDK (slim version ... TODO what is it?)
* Tomcat 9



# Mount Data Directory

CloverDX Server needs a persistent storage for its data and configuration, so that the files are not lost when the container is restarted or updated to a newer version. By default, sandboxes, logs and configuration files are stored in an anonymous Docker volume. This makes them persistent across container restarts, but not across updates. You can bind a host directory to `/var/clover` or mount a named Docker volume:

```bash
# bind host directory: 
--mount type=bind,source=/data/your-host-clover-data-dir,target=/var/clover
# mount a named volume:
--mount type=volume,source=name-of-your-volume,target=/var/clover
```

If you bind a directory from the host OS, the data files will be owned by user with UID 9001. You can override this by setting `LOCAL_USER_ID` environment variable:

```bash
-e LOCAL_USER_ID=`id -u $USER`
```

# Use External Database

By default, CloverDX Server will use an embedded Derby database. In order to use an external database, the container needs a JDBC driver and a configuration file:

1. If necessary, put additional JDBC drivers to `var/dbdrivers` before building the image and then build the image.
2. Put [database configuration properties](https://doc.cloverdx.com/latest/server/examples-db-connection-configuration.html) into `clover.properties` configuration file and place it into `/data/your-host-clover-data-dir/conf` directory in your host file system.
3. Bind `/data/your-host-clover-data-dir` to `/var/clover` (see above) and start the container.