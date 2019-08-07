# Single Job Container example

This example shows how to run a container with CloverDX Server for a specific job. The image already contains sandbox and uses an embedded Derby database. When the job finishes execution, the container is stopped.

### Running the example

* Build the base image

    ```
    docker build -t cloverdx-server:latest .
    ```

* Copy your license file (``license.dat``) to ``examples/single-job-container/conf`` directory

* Build the image

    ```
    docker build -t cloverdx-single-job-container:latest examples/single-job-container/
    ```

* Run the container

    ```
    docker run --name cloverdx-single-job-container -p 8080:8080 cloverdx-single-job-container:latest
    ```

This command executes ``Example/graph/graph.grf`` (as specified in the Dockerfile).

### Implementation
``conf\configuration_import.xml`` contains a custom event listener written in Groovy. The listener starts the job after Server startup, waits for the job to finish and stops the container.


