# Example

This example shows how to run a container with CloverDX Server for a specific job. The image already contains sandbox and uses an embedded Derby database. When the job finishes execution, the container is stopped.

### Running the example

* Build the base image

    ```
    docker build -t cloverdx-server:latest .
    ```

* Copy your license file (``license.dat``) to ``examples/ondemand/conf`` directory

* Build the image

    ```
    docker build -t cloverdx-server-ondemand:latest examples/ondemand/
    ```

* Run the container

    ```
    docker run --name cloverdx-server-ondemand -p 8080:8080 cloverdx-server-ondemand:latest
    ```

This command executes ``Example/graph/graph.grf`` (as specified in the Dockerfile).

### Implementation
``conf\configuration.xml`` contains a custom event listener written in Groovy. The listener starts the job after Server startup, waits for the job to finish and stops the container.


