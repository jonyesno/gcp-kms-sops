variable "project_id" {
  description = "gcp project id"
  type        = string
}

variable "region" {
  description = "default gcp region for resources"
  type        = string
}

variable "gcp_admins_group" {
  description = "google group for gcp administrators"
  type        = string
}

variable "kms_keyring_name" {
  description = "name of the kms keyring"
  type        = string
  default     = "sops"
}

variable "kms_key_name" {
  description = "name of the kms crypto key for sops"
  type        = string
  default     = "sops-key"
}

variable "terraform_sa_name" {
  description = "name of the terraform service account"
  type        = string
  default     = "terraform"
}
