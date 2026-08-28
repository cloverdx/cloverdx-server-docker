# Example 2: 3-Node CloverDX Cluster

A 3-node CloverDX Cluster with PostgreSQL database.

## How to create this deployment

This example expects the cluster to be configured with an Envoy Gateway that has:

* A `GatewayClass` named `envoy`.
* A shared `public` Gateway in the `envoy-gateway` namespace with `http` and `https` listeners.
* TLS configured on the `https` listener for the deployment domain.
* Permission for HTTPRoutes from the `example02-ns` namespace.

Edit the [example02-deployment.yaml](example02-deployment.yaml) file and replace:

* `<your-domain>`: Domain name covered by the TLS certificate configured on the `public` Gateway.
* `<your-base64-license.dat>` (use if you want to load a license during deployment): CloverDX license in base64 format (see instructions below under Inserting CloverDX license to YAML configuration file).

To deploy the Cluster, use the following command:

```
kubectl create -f example02-deployment.yaml
```

## The above will start CloverDX Cluster with

* 3-node CloverDX Cluster from the [official Docker image](https://hub.docker.com/r/cloverdx/cloverdx-server).
* Default admin user: `clover` (password: `clover`) with built-in user management available.
* Resource limits: 8 GiB memory for CloverDX, 2 GiB for PostgreSQL.
* Apache Tomcat web server hosting CloverDX instance on internal HTTP port.
* [Envoy Gateway](https://gateway.envoyproxy.io/) providing load balancing and session affinity through the existing `public` Gateway. TLS termination is configured by that Gateway. CloverDX Server console will be accessible on `https://<your-domain>/clover`.
* Persistent storage:
    * `example02-postgres-pvc` for CloverDX system database ([Longhorn block storage](https://longhorn.io/))
    * `example02-sandboxes-pvc` for CloverDX sandboxes ([Longhorn block storage](https://longhorn.io/))
    * `example02-cloverlogs-volume-<pod-name>` (e.g. `example02-cloverlogs-volume-example02-app-0`) for CloverDX logs, one for each pod of a CloverDX cluster node ([Longhorn block storage](https://longhorn.io/))
* License: Included in deployment if added to the yaml file prior to deployment (alternative: use REST API after deployment as in [Example 1](../Example01_CloverDX-Server/README.md#inserting-license-with-rest-api)).
* External database support: See Example 1 for [instructions](../Example01_CloverDX-Server/README.md#configuring-external-database).


## Inserting CloverDX license to YAML configuration file

1. Encode the license file into base64 format, for example, in Linux using the following command:

    ```
    base64 license.txt > license_64.txt
    ```

2. Copy the content of `license_64.txt` and replace `<your-base64-license.dat>` in [example02-deployment.yaml](example02-deployment.yaml).

    NOTE: The text must be indented.

## Known Issues

* [Incorrect URL Display in Resource Page](https://cloverdx.atlassian.net/browse/CLO-29422)
