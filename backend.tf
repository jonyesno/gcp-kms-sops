terraform {
  # FIXME - using variables in backend config is `tofu` specific
  backend "gcs" {
    bucket = "${var.project_id}-tfstate"
    prefix = "terraform/state"
  }
}
