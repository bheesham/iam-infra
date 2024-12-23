provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      Managed-By  = "Terraform"
      Owner       = "IAM"
      Environment = "Development"
      Lifecycle   = "MVP"
    }
  }
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

data "google_client_config" "default" {}

# Be sure to run:
# gcloud container clusters get-credentials iam-dev --region us-east1 --project iam-auth0
#provider "kubernetes" {
#  config_path    = "~/.kube/config"
#  config_context = "gke_iam-auth0_us-east1_iam-dev"
#}
provider "kubernetes" {
  host                   = "https://${google_container_cluster.iam_dev.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.iam_dev.master_auth[0].cluster_ca_certificate)
}

terraform {
  backend "gcs" {
    bucket = "iam-auth0-terraform-state"
    prefix = "terraform/prod/gcp-us-east1-kubernetes/state"
  }
}
