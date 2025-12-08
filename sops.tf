# kms keyring for sops encryption
resource "google_kms_key_ring" "sops" {
  name     = var.kms_keyring_name
  location = var.region
}

# kms crypto key for sops with encrypt/decrypt purpose
resource "google_kms_crypto_key" "sops" {
  name            = var.kms_key_name
  key_ring        = google_kms_key_ring.sops.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }

  purpose = "ENCRYPT_DECRYPT"
}

# grant gcp-admins permission to use the kms key for sops operations
resource "google_kms_crypto_key_iam_member" "admins_encrypter_decrypter" {
  crypto_key_id = google_kms_crypto_key.sops.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = var.gcp_admins_group
}
