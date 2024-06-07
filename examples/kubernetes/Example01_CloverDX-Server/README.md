# Readme Example 1: Standalone CloverDX Server

Standalone CloverDX Server with PostgreSQL database.

## How to create this deployment

Use the following command to create the deployment:

```
kubectl create -f example01-deployment.yaml
```

## The above will start CloverDX Server with

* CloverDX Server from the [official Docker image](https://hub.docker.com/r/cloverdx/cloverdx-server).
* Default admin user: `clover` (password: `clover`) with built-in user management.
* Resource limits: 4 GiB memory for CloverDX, 0.5 GiB for PostgreSQL.
* Apache Tomcat web server hosting CloverDX instance on internal port 8080, forwarded to external port 30001.
* Persistent storage:
    * `example01-postgres-pvc` volume: CloverDX system database ([Longhorn block storage](https://longhorn.io/))
    * `example01-sandboxes-pvc` volume: CloverDX sandboxes ([Longhorn block storage](https://longhorn.io/))
* License: Not included. Use the REST API to load the license.

## Configuring external database
This example uses an internal PostgreSQL database (i.e. the database is deployed together with CloverDX Server in K8s). To configure an external database (i.e. a database running outside K8s), replace the environment variables in [example01-deployment.yaml](example01-deployment.yaml). Refer below for an example for connection to an MSSQL database:

```
 env:
          - name: clover.datasource.type
            value: JDBC
          - name: clover.jdbc.url
            value: jdbc:sqlserver://<host-name>:1433;database=<db-name>
          - name: clover.jdbc.driverClassName
            value: com.microsoft.sqlserver.jdbc.SQLServerDriver
          - name: clover.jdbc.dialect
            value: org.hibernate.dialect.SQLServerDialect
          - name: clover.jdbc.username
            value: <username>
          - name: clover.jdbc.password
            value: <password>
```

## Inserting license with REST API

To insert a license using the CloverDX REST API, follow these steps:

1. Obtain a license file from our [Customer portal](https://support.cloverdx.com/login).
2. Use the following curl command to send the license to the CloverDX Server:

```
    curl -X 'PUT' \
      'https://your-domain:443/clover/api/rest/v1/server/license' \
      -H 'accept: application/json' \
      -H 'Content-Type: application/octet-stream' \
      -H 'X-Requested-By: Clover REST API' \
      -u "clover:clover" \
      --data-binary '@license.txt'
```
 
Make sure to:
* Replace `your-domain` with the actual domain where your CloverDX Server is hosted.
* Replace `clover:clover` with the actual username and password.
* Adjust the path to the `license.txt` file as needed.
