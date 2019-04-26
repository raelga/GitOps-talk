# Helps wiping resources whom deletion is not supported by Deployment manager

#
# Unable to delete compute.v1.globalAddresses ranges with DM
# https://issuetracker.google.com/issues/131072617
#
gcloud compute networks delete base-net
gcloud deployment-manager deployments delete base-network --delete-policy abandon