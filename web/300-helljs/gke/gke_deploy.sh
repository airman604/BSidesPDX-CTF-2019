#!/bin/sh

# stop on error
set -e

export PROJECT_ID=
if [ -z "$PROJECT_ID" ]; then
    echo "You have to set PROJECT_ID variable before you can run the provisioning script!"
    exit 1
fi

CONTAINER_TAG="gcr.io/${PROJECT_ID}/hell_js"
export FRONTEND_TAG="${CONTAINER_TAG}_frontend"
export SECURE_BACKEND_TAG="${CONTAINER_TAG}_secure_backend"
export VULNERABLE_BACKEND_TAG="${CONTAINER_TAG}_vulnerable_backend"
export JWT_SECRET="6330a524-2c2a-43e9-b240-651dc6d2d19c"
COMPUTE_ZONE=us-west1-a
CLUSTER_NAME=kube-ctf
NUM_NODES=2
# uncomment to skip cluster creation
# SKIP_CLUSTER_PROVISIONING=1
# comment to skip build step and use existing images
BUILD=1

if [ -z "$SKIP_CLUSTER_PROVISIONING" ]; then
    echo "Setting GKE config"
    gcloud config set project $PROJECT_ID
    gcloud config set compute/zone $COMPUTE_ZONE

    echo "Provisioning Kubernetes cluster"
    gcloud container clusters create $CLUSTER_NAME --num-nodes=$NUM_NODES
    gcloud compute instances list
fi

echo "Deploying Mongo"
cat deployment/deploy_mongodb.yaml | envsubst | kubectl apply -f -
cat deployment/service_mongodb.yaml | envsubst | kubectl apply -f -

echo "Deployig secure backend"
if [ ! -z "$BUILD" ]; then
    docker build --no-cache --tag ${CONTAINER_TAG}_secure_backend ../src/secure-backend/
    docker push ${CONTAINER_TAG}_secure_backend
fi
cat deployment/deploy_secure_backend.yaml | envsubst | kubectl apply -f -
cat deployment/service_secure_backend.yaml | envsubst | kubectl apply -f -

echo "Deploying vulnerable backend"
if [ ! -z "$BUILD" ]; then
    docker build --no-cache --tag ${CONTAINER_TAG}_vulnerable_backend ../src/vulnerable-backend/
    docker push ${CONTAINER_TAG}_vulnerable_backend
fi
cat deployment/deploy_vulnerable_backend.yaml | envsubst | kubectl apply -f -
cat deployment/service_vulnerable_backend.yaml | envsubst | kubectl apply -f -

echo "Deploying frontend"
# always build as it needs URL of both backends
while ! SECURE_IP=$(kubectl get services hell-js-secure-backend -o json | jq -r -e .status.loadBalancer.ingress[0].ip); do
    sleep 5
done

while ! VULNERABLE_IP=$(kubectl get services hell-js-vulnerable-backend -o json | jq -r -e .status.loadBalancer.ingress[0].ip); do
    sleep 5
done

docker build \
	--build-arg VULNERABLE_API_URL="http://$VULNERABLE_IP:27331" \
	--build-arg SECURE_API_URL="http://$SECURE_IP:27332" \
	--no-cache --tag ${CONTAINER_TAG}_frontend ../src/frontend/
docker push ${CONTAINER_TAG}_frontend
cat deployment/deploy_frontend.yaml | envsubst | kubectl apply -f -
cat deployment/service_frontend.yaml | envsubst | kubectl apply -f -

while ! FRONTEND_IP=$(kubectl get services hell-js-frontend -o json | jq -r -e .status.loadBalancer.ingress[0].ip); do
    sleep 5
done
echo "Access the app at http://$FRONTEND_IP:27330"