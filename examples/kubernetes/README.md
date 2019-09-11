# Kubernetes Deployment Example

This example runs CloverDX Server with PostreSQL database as a deployment in Kubernetes.
It contains a sample echo data service, which simply prints the string passed as a path parameter.

### Requirements
* bash + envsubst
* Java
* Docker + docker CLI
* Kubernetes + kubectl
* Docker image registry accessible from Kubernetes
* ``clover.war``
* ``license.dat``

---

### Running the example

* Put ``clover.war`` into the project root directory.
* Switch to ``examples/kubernetes`` directory and put your ``license.dat`` file there.
* Execute `run.sh` and pass the hostname and port of your Docker registry as a parameter. The script will build and deploy the example and start port forwarding to localhost:8090.

    ```
    ./run.sh my-docker-registry:5000
    ```

Thanks to port forwarding, you can now access the application at the following URLs:
* <http://localhost:8090/data-service/echo/Hello+World!> - sample Data Service
* <http://localhost:8090/clover> - CloverDX Server Console
* <http://localhost:8090/monitoring> - Grafana monitoring dashboard

