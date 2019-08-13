FROM cloverdx-server:latest

# use e.g. 'docker run --rm -e JOB_PATH=graph/fail.grf cloverdx-single-job-container' to override env variables
ENV SANDBOX=Example
ENV JOB_PATH=graph/sleep.grf

COPY conf $CLOVER_HOME_DIR/conf
COPY sandboxes $CLOVER_HOME_DIR/sandboxes