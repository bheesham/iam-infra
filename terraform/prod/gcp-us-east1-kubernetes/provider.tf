provider "aws" {
  region = "us-west-2"
}

provider "google" {
  project = "iam-auth0"
  region  = "us-east1"
  default_labels = {
    managed-by  = "terraform"
    owner       = "iam"
    environment = "development"
    lifecycle   = "mvp"
  }
}

terraform {
  backend "gcs" {
    bucket = "iam-auth0-terraform-state"
    prefix = "terraform/prod/gcp-us-east1-kubernetes/state"
  }
}
