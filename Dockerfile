FROM rbillon59/jmeter-k8s-base:5.4.1

ARG JMETER_VERSION=5.4.1
ARG MODULE_DIR="scenario/module"
ARG DATASET_DIR="scenario/dataset"
ARG SCENARIO_DIR="scenario/my-scenario"

USER root
## Installing java and dependencies
RUN  mkdir -p /opt/jmeter/apache-jmeter/bin/${MODULE_DIR} \
    && mkdir /opt/jmeter/apache-jmeter/bin/${DATASET_DIR}

COPY scenario/module /opt/jmeter/apache-jmeter/bin/${MODULE_DIR}
COPY scenario/dataset /opt/jmeter/apache-jmeter/bin/${DATASET_DIR}
COPY scenario/my-scenario/*.jmx /opt/jmeter/apache-jmeter/bin/

COPY ./start_test.sh /opt/start_test.sh
ENV HOME /opt/jmeter/


