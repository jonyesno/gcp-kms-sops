#!/usr/bin/env bash
set -uo pipefail

trace() {
  local STAMP
  STAMP=$( date '+%Y-%m-%dT%H:%M:%S' )
  echo "[bootstrap] ${STAMP} $*" >&2
}

fail() {
  local MSG
  MSG="FATAL $* at line ${BASH_LINENO[0]}"
  trace "${MSG}"
  exit 1
}
trap fail ERR

HERE=$( cd "$(dirname "$0")" && pwd )
cd "${HERE}" || fail cd
#!/bin/bash
set -e

if [[ -z "${PROJECT_ID:-}" ]] || \
  [[ -z "${BILLING_ACCOUNT:-}" ]] || \
  [[ -z "${REGION:-}" ]] ; then

  fail "define all of PROJECT_ID, BILLING_ACCOUNT, REGION in env"
fi

TF_STATE_BUCKET="${PROJECT_ID}-tfstate"
BOOTSTRAP_SA="terraform-bootstrap@${PROJECT_ID}.iam.gserviceaccount.com"

trace "creating gcloud configuration..."
gcloud config configurations create "${PROJECT_ID}" || echo "configuration already exists"

trace "activating configuration..."
gcloud config configurations activate "${PROJECT_ID}"

trace "setting default project..."
gcloud config set project "${PROJECT_ID}"

trace "associating billing account..."
gcloud billing projects link "${PROJECT_ID}" --billing-account="${BILLING_ACCOUNT}"

trace "enabling required apis..."
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable serviceusage.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable iamcredentials.googleapis.com

trace "creating terraform state bucket..."
gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
  --location="${REGION}" \
  --uniform-bucket-level-access

trace "enabling versioning on state bucket..."
gcloud storage buckets update gs://"${TF_STATE_BUCKET}" \
  --versioning

trace "creating bootstrap service account..."
gcloud iam service-accounts create terraform-bootstrap \
  --display-name="Terraform Bootstrap Service Account" \
  --description="bootstrap service account for initial terraform setup and emergency access"

trace "granting necessary permissions to bootstrap sa..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${BOOTSTRAP_SA}" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${BOOTSTRAP_SA}" \
  --role="roles/resourcemanager.projectIamAdmin"

trace "granting storage admin on tfstate bucket..."
gcloud storage buckets add-iam-policy-binding "gs://${TF_STATE_BUCKET}" \
  --member="serviceAccount:${BOOTSTRAP_SA}" \
  --role="roles/storage.admin"

trace "done"

echo "next steps:"
echo "export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=${BOOTSTRAP_SA}"
echo "terraform init"
echo "terraform plan"
echo "terraform apply"
