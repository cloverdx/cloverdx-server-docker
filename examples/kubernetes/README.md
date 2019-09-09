# Kubernetes Deployment Example

This example runs CloverDX Server with PostreSQL database as a deployment in Kubernetes.
It contains a sample echo data service, which simply prints the string passed as a path parameter.

### Requirements
* bash + envsubst
* Docker + docker CLI
* Kubernetes + kubectl
* Java
* Docker image registry accessible from Kubernetes
* ``license.dat``

---

### Running the example

* Put your ``license.dat`` file to ``examples/kubernetes`` directory.
* Execute `run.sh` and pass the hostname and port of your Docker registry as a parameter. The script will deploy the example and start port forwarding to localhost:8090.

    ```
    ./run.sh my-docker-registry:5000
    ```

The data service is now available at <http://localhost:8090/clover/data-service/echo/Hello+World!>.
