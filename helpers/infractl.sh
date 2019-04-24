#!/bin/bash

set -euo pipefail

source $(dirname $0)/providercfg.sh

function error() { echo "[!] $@"; exit; }
function info()  { echo "[i] $@"; }

function main() {

  ACTION=${1:-apply};
  MANIFEST=${2:-};
  check;

  case ${PROVIDER:-}_${ACTION} in
    gcp_apply)
      gcp_apply $MANIFEST;;
    *)
      echo "Action ${ACTION} not implemented in provider ${PROVIDER:-}.";;
  esac;
}

function check() {
  test ! -z ${PROVIDER:-} || error "PROVIDER environment variable must be set.";
  test ! -z ${ACTION:-}   || error "ACTION parameter must be set.";
  test -f ${MANIFEST:-}   || error "MANIFEST file \"${MANIFEST:-}\" not found.";
}

function gcp_apply() {

  gcp_config;

  DEPLOYMENT_CONF=${MANIFEST}
  DEPLOYMENT_FILE=$(basename ${DEPLOYMENT_CONF})
  DEPLOYMENT_PATH=$(dirname ${DEPLOYMENT_CONF})
  DEPLOYMENT_NAME=$(basename ${DEPLOYMENT_PATH})-${DEPLOYMENT_FILE%.*}

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

main $@;