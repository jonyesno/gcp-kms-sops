# Terraformed GCP KMS for SOPS

This sets up a new GCP project and uses Terraform to create a KMS key to use
with [SOPS](https://github.com/getsops/sops)

## Requirements

* `gcloud` cli installed and authenticated
* `terraform` >= 1.5 or `tofu` (opentofu) >= 1.5
* `sops` (optional, for encryption/decryption operations)
* a gcp project (`project_id` tfvar)
* a gcp billing account (`gcp_admins_group` tfvar)
* a gcp region choice (`region` tfvar)
* `tflint` and `trivy` for code checks
* Docker binaries for `trivy` updates (?)

## Initial setup

* Run bootstrap script

The bootstrap script sets up the minimal infrastructure needed before terraform can manage everything:

This will:
  * create a gcloud configuration for the project
  * associate the billing account
  * enable required apis
  * create the terraform state bucket
  * create a bootstrap service account with necessary permissions

The script expects the following variables to be defined in the environment:

  * `PROJECT_ID`
  * `BILLING_ACCOUNT`
  * `REGION`

* Initialize terraform

Terraform expects the followig variables to be defined:

*  `project_id`
*  `gcp_admins_group`
*  `region`

Either add them to a `tfvars` file or define their `TF_VAR_` environment equivalend

```bash
terraform init
```

This will configure terraform to use the gcs backend for state storage.

* apply terraform configuration

```bash
terraform plan
terraform apply
```

This will create:
   * production terraform service account
   * iam binding for `gcp_admins_group` with token creator role
   * kms keyring in `region`
   * kms crypto key for sops encryption
   * iam permissions for the kms key

This setup uses two service accounts:

    * `terraform-bootstrap` (created by `bootstrap.sh`)

    This is created with the `gcloud` cli and is used for the initial apply to get things going

    * `terraform` (created by terraform, see `terraform_sa_name` tfvar)

    Created in `main.tf`, TF managed, onward use

## Linting and security checks

This project uses `tflint` and `trivy`:

```bash
make init
make validate check
```

## Using SOPS with the KMS key

* Retrive the kms key resource id

```bash
terraform output -raw sops_kms_key
```

* Encrypt a file

```bash
SOPS_KMS_KEY=$( terraform output -raw sops_kms_key )
sops --encrypt \
  --gcp-kms ${SOPS_KMS_KEY} \
  secrets.yaml > secrets.enc.yaml
```

* Decrypt a file

```bash
sops --decrypt secrets.enc.yaml > secrets.yaml
```

* Create `.sops.yaml` for automatic key selection

Create a `.sops.yaml` that uses the `sops_kms_key` TF output as the `gcp_kms` value:

```yaml
creation_rules:
  - gcp_kms: projects/.../sops-key
```

Then it's just:

```bash
sops secrets.yaml
```

## IAM permissions summary

### `terraform-bootstrap` service account (bootstrap only)
- `roles/editor` - manage most gcp resources
- `roles/resourcemanager.projectIamAdmin` - manage iam policies
- `roles/storage.admin` on tfstate bucket - manage terraform state

### `terraform` service account (onwards)
- `roles/editor` - manage most gcp resources
- `roles/resourcemanager.projectIamAdmin` - manage iam policies
- `roles/cloudkms.cryptoKeyEncrypterDecrypter` on sops kms key - encrypt/decrypt with sops

### `gcp-admin@example.com` group
- `roles/iam.serviceAccountTokenCreator` on terraform service account - impersonate production sa
- `roles/cloudkms.cryptoKeyEncrypterDecrypter` on sops kms key - encrypt/decrypt secrets with sops

## License

Released under the MIT License, see `LICENSE`. Non-warranty in there too.

## Author

Jon Stuart, Zikomo Technology, 2025
