# Example 2: 3-Node CloverDX Cluster

A 3-node CloverDX Cluster with PostgreSQL database.

## How to create this deployment

This example expects [Envoy Gateway](https://gateway.envoyproxy.io/) to be installed in the cluster, with a gateway that has:

* An HTTP listener and an HTTPS listener.
* TLS configured on the HTTPS listener for the deployment domain.
* `allowedRoutes` permitting HTTPRoutes from the `example02-ns` namespace.

Envoy Gateway is not a hard requirement. The HTTPRoutes, including their timeouts, are standard Gateway API resources and work with any implementation of it, for example Istio or Traefik. An ingress controller providing cookie based session affinity can be used instead as well.

This example uses Envoy Gateway because session affinity, which the CloverDX Server console requires, is only available in the experimental channel of the Gateway API. The `example02-session-affinity` BackendTrafficPolicy is therefore specific to Envoy Gateway and has to be replaced with the corresponding resource if you use a different implementation.

The example does not create the gateway. Its name, namespace and listener names differ between clusters, so they have to be filled in before deploying. You can list the gateways in the cluster and their listeners using the following command:

```
kubectl get gateway -A -o 'custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,LISTENERS:.spec.listeners[*].name,ADDRESS:.status.addresses[*].value'
```

The deployment domain must have a DNS record pointing to the address of the gateway.

Edit the [example02-deployment.yaml](example02-deployment.yaml) file and replace:

* `<your-gateway-name>`: Name of the gateway that the CloverDX HTTPRoutes attach to.
* `<your-gateway-namespace>`: Namespace of that gateway.
* `<your-gateway-http-listener>`: Name of the HTTP listener of that gateway, used for the redirect to HTTPS.
* `<your-gateway-https-listener>`: Name of the HTTPS listener of that gateway, used for the CloverDX Server console.
* `<your-domain>`: Domain name covered by the TLS certificate configured on the gateway.
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
* [Envoy Gateway](https://gateway.envoyproxy.io/) providing load balancing and session affinity through the gateway. TLS termination is configured by that gateway. HTTP requests are redirected to HTTPS. CloverDX Server console will be accessible on `https://<your-domain>/clover`.
    * Session affinity: the `example02-session-affinity` policy pins each browser session to a single cluster node using the `example02-affinity` cookie, with a lifetime of 48 hours. The cookie is marked `Secure`, so session affinity works over HTTPS only.
    * Request timeout: 600 seconds, configured on the `example02-route` HTTPRoute. Without it, Envoy applies its default timeout of 15 seconds and long-running jobs or transfers of large sandbox files might fail with HTTP 504.
* Persistent storage:
    * `example02-postgres-pvc` for CloverDX system database ([Longhorn block storage](https://longhorn.io/))
    * `example02-sandboxes-pvc` for CloverDX sandboxes ([Longhorn block storage](https://longhorn.io/))
    * `example02-cloverlogs-volume-<pod-name>` (e.g. `example02-cloverlogs-volume-example02-app-0`) for CloverDX logs, one for each pod of a CloverDX cluster node ([Longhorn block storage](https://longhorn.io/))
* License: Included in deployment if added to the yaml file prior to deployment (alternative: use REST API after deployment as in [Example 1](../Example01_CloverDX-Server/README.md#inserting-license-with-rest-api)).
* External database support: See Example 1 for [instructions](../Example01_CloverDX-Server/README.md#configuring-external-database).


## Connecting to a specific cluster node

The console is served through the gateway, which balances requests across all cluster nodes, so `https://<your-domain>/clover` does not target a particular node. To reach one node directly, for example for administration or troubleshooting, forward its port to your machine:

```
kubectl port-forward -n example02-ns pod/example02-app-0 8080:8080
```

The console of that node is then available on `http://localhost:8080/clover`. Use `example02-app-1` or `example02-app-2` to reach the remaining nodes.

## Inserting CloverDX license to YAML configuration file

1. Encode the license file into base64 format, for example, in Linux using the following command:

    ```
    base64 license.txt > license_64.txt
    ```

2. Copy the content of `license_64.txt` and replace `<your-base64-license.dat>` in [example02-deployment.yaml](example02-deployment.yaml).

    NOTE: The text must be indented.

## Known Issues

* [Incorrect URL Display in Resource Page](https://cloverdx.atlassian.net/browse/CLO-29422)
