#!/bin/sh

# stop on error
set -e

PROJECT_ID=apt-theme-257401; export PROJECT_ID
COMPUTE_ZONE=us-west1-a
CLUSTER_NAME=kube-ctf

# gcloud container clusters get-credentials $CLUSTER_NAME --zone $COMPUTE_ZONE --project $PROJECT_ID
gcloud container clusters delete $CLUSTER_NAME
