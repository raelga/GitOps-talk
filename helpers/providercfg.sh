#!/bin/bash

set -exuo pipefail

function gcp_config() {

  which -s gcloud \
    || error "gcloud SDK is not installed." \
    && info "gcloud installed with $(gcloud version | grep 'Google Cloud SDK')."

  test ! -z ${GCLOUD_SERVICE_ACCOUNT:-} \
    || error "GCLOUD_SERVICE_ACCOUNT environment variable must be set." \
    && {
      gcloud auth activate-service-account \
        --key-file <(echo ${GCLOUD_SERVICE_ACCOUNT} | base64 -D) \
      || error "Unable to activate the service account." \
      && info  "Service account set to $(gcloud config get-value account)."
    }

  test ! -z ${GCLOUD_PROJECT_ID:-} \
    || error "GCLOUD_PROJECT_ID environment variable must be set." \
    && info  "GCLOUD_PROJECT_ID project set to ${GCLOUD_PROJECT_ID}.";

  gcloud config set project ${GCLOUD_PROJECT_ID} \
    || error "Unable to set project ${GCLOUD_PROJECT_ID}." \
    && info  "gcloud project set to $(gcloud config get-value project)."

}
