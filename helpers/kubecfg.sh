#!/bin/bash

set -euo pipefail

function error() { echo "[!] $@"; exit; }
function info()  { echo "[i] $@"; }

function gcp_k8s_config() {

  which kubectl &> /dev/null \
    || error "kubectl is not installed." \
    && info "kubectl installed with $(kubectl version | sed -n 's/^Client.*GitVersion:"\(v[0-9\.]\+\)".*/\1/p')."

  test ! -z ${K8S_CLUSTER:-} \
    || error "K8S_CLUSTER environment variable must be set." \
    && info  "K8S_CLUSTER cluster set to ${K8S_CLUSTER}.";

  test ! -z ${GCLOUD_PROJECT_ID:-} \
    || error "GCLOUD_PROJECT_ID environment variable must be set." \
    && info  "GCLOUD_PROJECT_ID project set to ${GCLOUD_PROJECT_ID}.";

  # Get cluster location
  export K8S_CLUSTER_LOCATION=$(gcloud deployment-manager deployments describe \
    ${K8S_CLUSTER} --project ${GCLOUD_PROJECT_ID} \
    | sed -n 's/^cluster-location\s\+\(.*\)/\1/p'
  );

  test ! -z ${K8S_CLUSTER_LOCATION:-} \
    || error "K8S_CLUSTER_LOCATION environment variable must be set." \
    && info  "K8S_CLUSTER_LOCATION project set to ${K8S_CLUSTER_LOCATION}.";

  # Get region or zone  flag based on the location
  echo ${K8S_CLUSTER_LOCATION} | egrep -q '[a-z]+-[a-z]+[0-9]-[a-z]' \
    || export GCLOUD_CLUSTER_LOCATION_FLAG="--zone ${K8S_CLUSTER_LOCATION}" \
    && export GCLOUD_CLUSTER_LOCATION_FLAG="--region ${K8S_CLUSTER_LOCATION}";

  # Get cluster credentials
  gcloud --project ${GCLOUD_PROJECT_ID} \
    container clusters get-credentials ${K8S_CLUSTER} ${GCLOUD_CLUSTER_LOCATION_FLAG} \
    || error "kubectl cluster set to ${K8S_CLUSTER} environment variable must be set." \
    && info  "kubectl cluster set to ${K8S_CLUSTER}";

}

gcp_k8s_config
