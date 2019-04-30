#!/bin/bash

set -euo pipefail

source $(dirname $0)/providercfg.sh

function error() { echo "[!] $@"; exit; }
function info()  { echo "[i] $@"; }

function main() {

  ACTION=${1:-apply};
  MANIFEST=${2:-};
  PREFIX=${3:-};

  check;

  case ${PROVIDER:-}_${ACTION} in
    gcp_diff)
      gcp_diff $MANIFEST;;
    gcp_apply)
      gcp_apply $MANIFEST;;
    gcp_delete)
      gcp_delete $MANIFEST;;
    *)
      echo "Action ${ACTION} not implemented in provider ${PROVIDER:-}.";;
  esac;
}

function check() {
  test ! -z ${PROVIDER:-} || error "PROVIDER environment variable must be set.";
  test ! -z ${ACTION:-}   || error "ACTION parameter must be set.";
  test -f ${MANIFEST:-}   || error "MANIFEST file \"${MANIFEST:-}\" not found.";
}

function gcp_deployment_config() {

  DEPLOYMENT_CONF=${MANIFEST}
  DEPLOYMENT_FILE=$(basename ${DEPLOYMENT_CONF})
  DEPLOYMENT_PATH=$(dirname ${DEPLOYMENT_CONF})
  DEPLOYMENT_NAME=$(basename ${DEPLOYMENT_PATH})-${DEPLOYMENT_FILE%.*}

  test -z ${PREFIX} || DEPLOYMENT_NAME=${PREFIX}-${DEPLOYMENT_NAME};

}

function gcp_diff() {

  gcp_config;
  gcp_deployment_config;

  info "Previewing ${DEPLOYMENT_NAME} deployment with ${DEPLOYMENT_CONF}.";
  gcloud deployment-manager deployments \
    update ${DEPLOYMENT_NAME} --config ${DEPLOYMENT_CONF} --preview \
    --create-policy CREATE_OR_ACQUIRE --delete-policy DELETE \
    || error "Previewing of ${DEPLOYMENT_NAME} failed.";

  info "Canceling ${DEPLOYMENT_NAME} deployment preview.";
  gcloud deployment-manager deployments cancel-preview ${DEPLOYMENT_NAME} \
    || error "Previewing of ${DEPLOYMENT_NAME} failed.";

}

function gcp_apply() {

  gcp_config;
  gcp_deployment_config;

  gcloud deployment-manager deployments describe ${DEPLOYMENT_NAME} \
    && info "Deployment ${DEPLOYMENT_NAME} already exists." \
    || {
      info "Creating empty ${DEPLOYMENT_NAME} deployment before updating.";
      gcloud deployment-manager deployments \
        create ${DEPLOYMENT_NAME} --config <(echo "resources:");
    }

    info "Previewing ${DEPLOYMENT_NAME} deployment with ${DEPLOYMENT_CONF}."
    gcloud deployment-manager deployments \
      update ${DEPLOYMENT_NAME} --config ${DEPLOYMENT_CONF} --preview \
      --create-policy CREATE_OR_ACQUIRE --delete-policy DELETE \
      || error "Previewing of ${DEPLOYMENT_NAME} failed.";

    info "Updating ${DEPLOYMENT_NAME} deployment with ${DEPLOYMENT_CONF}."
    gcloud deployment-manager deployments \
      update ${DEPLOYMENT_NAME} \
      --create-policy CREATE_OR_ACQUIRE --delete-policy DELETE \
      || error "Update of ${DEPLOYMENT_NAME} failed.";

}

function gcp_delete() {

  gcp_config;
  gcp_deployment_config;

  gcloud deployment-manager deployments delete ${DEPLOYMENT_NAME} --quiet \
    --async \
    && info "Deployment ${DEPLOYMENT_NAME} deleted." \
    || error "Unable to delete ${DEPLOYMENT_NAME}.";

}

main $@;