#!/bin/sh

# stop on error
set -e
CLUSTER_NAME=kube-ctf

gcloud container clusters delete $CLUSTER_NAME
