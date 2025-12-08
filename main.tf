# terraform service account for managing infrastructure
resource "google_service_account" "terraform" {
  account_id   = var.terraform_sa_name
  display_name = "terraform service account"
  description  = "service account used by terraform to manage gcp infrastructure"
}

# grant gcp-admins the ability to impersonate the terraform service account
resource "google_service_account_iam_member" "terraform_token_creator" {
  service_account_id = google_service_account.terraform.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.gcp_admins_group
}

# grant the terraform service account necessary permissions
resource "google_project_iam_member" "terraform_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_member" "terraform_project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}
