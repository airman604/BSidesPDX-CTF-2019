Google Kubernetes Engine Deployment
===
1. Create a new Project in GCP and note the project ID
1. Update gke_deploy.sh and set PROJECT_ID variable to your project ID
1. Run gke_deploy.sh provisioning script. The easiest way is to do this inside the Google Cloud Console.

The script will:
* create a new Kubernetes cluster named kube-ctf
* deploy "mongo" pod and service running MongoDB (used by the "vulnerable backend")
* build Docker image for "secure backend", push it to Google Cloud Registry as "gcr.io/${PROJECT_ID}/hell_js_secure_backend", and deploy hell-js-secure-backend pod and service
* build Docker image for "vulnerable backend", push it to Google Cloud Registry as "gcr.io/${PROJECT_ID}/hell_js_vulnerable_backend", and deploy hell-js-vulnerable-backend pod and service
* build Docker image for "frontend", push it to Google Cloud Registry as "gcr.io/${PROJECT_ID}/hell_js_frontend", and deploy hell-js-frontend pod and service
* show you the URL to access the frontend
