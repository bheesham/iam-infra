data "google_project" "project" {}

resource "google_project_service" "gke_hub" {
  project = data.google_project.project.id
  service = "gkehub.googleapis.com"
}

resource "google_project_service" "anthos" {
  project = data.google_project.project.id
  service = "anthos.googleapis.com"
}

resource "google_project_service" "container" {
  project = data.google_project.project.id
  service = "container.googleapis.com"
}

resource "google_gke_hub_fleet" "iam" {
  display_name = "IAM Kubernetes"
  default_cluster_config {
    security_posture_config {
      mode               = "BASIC"
      vulnerability_mode = "VULNERABILITY_BASIC"
    }
  }
  depends_on = [google_project_service.gke_hub, google_project_service.anthos, google_project_service.container]
}
