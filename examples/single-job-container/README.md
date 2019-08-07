# Single Job Container Example

This example shows how to run a container with CloverDX Server for a specific job. The image already contains a sandbox and uses an embedded Derby database. When the job finishes execution, the container is stopped.

### Running the example

* Build the base image

    ```
    docker build -t cloverdx-server .
    ```

* Copy your license file (``license.dat``) to ``examples/single-job-container/conf`` directory

* Build the image

    ```
    docker build -t cloverdx-single-job-container examples/single-job-container
    ```

* Run the job in foreground mode and delete the container afterwards

    ```
    \# executes Examples/graph/sleep.grf (default job from Dockerfile) - it waits 20s and finishes successfully
    docker run --rm cloverdx-single-job-container
    
    \# executes Example/graph/fail.grf - it fails after 5s
    docker run --rm -e JOB_PATH=graph/fail.grf cloverdx-single-job-container 
    ```

This command returns 0 as the exit code if the job finishes successfully and a non-zero exit code if the job fails.

### Implementation
``conf/configuration_import.xml`` contains a custom event listener written in Groovy. The listener starts the job after Server startup, waits for the job to finish and stops the container.


