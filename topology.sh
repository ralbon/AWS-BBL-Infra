#!/bin/sh
set -o nounset
set -o errexit

BASE_DIR=$(dirname $(realpath $0))
TF_LOG=DEBUG
TF_LOG_PATH=/tmp/log/

cd $BASE_DIR/$2

rm -rf ./.terraform/
rm -f terraform.tfstate.backup
rm -f terraform.tfstate

# remove potential trailing slash in topology name
KEY=${2%/}


terraform init \
    -backend-config="bucket=$TF_BACKEND_STORAGE_ACCOUNT_NAME" \
    -backend-config="key=$KEY/terraform.tfstate" \
    -backend-config="region=$REGION"
terraform get .

terraform $1

rm -rf ./.terraform/
rm -f terraform.tfstate.backup
rm -f terraform.tfstate
