#!/bin/bash

set -exuo pipefail

source $(dirname $0)/providercfg.sh

function error() { echo "[!] $@"; exit; }
function info()  { echo "[i] $@"; }

function main() {

  ACTION=${1:-update};
  BUCKET_FOLDER=${2:-};
  check;

  case ${PROVIDER:-}_${ACTION} in
    gcp_update)
      gcp_update $BUCKET_FOLDER;;
    gcp_sync)
      gcp_sync $BUCKET_FOLDER;;
    *)
      echo "Action ${ACTION} not implemented in provider ${PROVIDER:-}.";;
  esac;
}

function check() {
  test ! -z ${PROVIDER:-} || error "PROVIDER environment variable must be set.";
  test ! -z ${ACTION:-}   || error "ACTION parameter must be set.";
  test -d ${BUCKET_FOLDER:-} || error "BUCKET_FOLDER folder \"${BUCKET_FOLDER:-}\" not found.";
}

function gcp_update() {

  gcp_config;

  BUCKET_SRC=${BUCKET_FOLDER}
  BUCKET_DST=$(basename ${BUCKET_SRC})
  gsutil rsync -r -J -C -c ${BUCKET_SRC}/ gs://${BUCKET_DST}

#-C       If an error occurs, continue to attempt to copy the remaining files.
#-c       Causes the rsync command to compute and compare checksums for files
#         if the size of source and destination match.
#-J       Applies gzip transport encoding to file uploads. T
#-R, -r   Causes directories, buckets, and bucket subdirectories to be
#         synchronized recursively.

}

function gcp_sync() {

  gcp_config;

  BUCKET_SRC=${BUCKET_FOLDER}
  BUCKET_DST=$(basename ${BUCKET_SRC})
  gsutil rsync -r -J -C -c -d ${BUCKET_SRC}/ gs://${BUCKET_DST}

#-d       Delete extra files under dst_url not found under src_url.
#-C       If an error occurs, continue to attempt to copy the remaining files.
#-c       Causes the rsync command to compute and compare checksums for files
#         if the size of source and destination match.
#-J       Applies gzip transport encoding to file uploads. T
#-R, -r   Causes directories, buckets, and bucket subdirectories to be
#         synchronized recursively.

}

main $@;
