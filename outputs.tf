output "terraform_service_account_email" {
  description = "email of the terraform service account"
  value       = google_service_account.terraform.email
}

output "kms_keyring_id" {
  description = "id of the kms keyring"
  value       = google_kms_key_ring.sops.id
}

output "kms_crypto_key_id" {
  description = "id of the kms crypto key for sops"
  value       = google_kms_crypto_key.sops.id
}

output "sops_kms_key" {
  description = "full resource id for use with sops --gcp-kms flag"
  value       = "projects/${var.project_id}/locations/${var.region}/keyRings/${var.kms_keyring_name}/cryptoKeys/${var.kms_key_name}"
}

output "impersonation_command" {
  description = "command to set up service account impersonation"
  value       = "export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=${google_service_account.terraform.email}"
}
