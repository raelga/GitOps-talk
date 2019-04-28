FROM google/cloud-sdk:243.0.0-slim

RUN apt-get install -qqy kubectl

RUN gcloud --version && \
    kubectl version --client=true
