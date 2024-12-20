resource "google_container_cluster" "iam_dev" {
  name                     = "iam-dev"
  location                 = "us-east1"
  remove_default_node_pool = true
  initial_node_count       = 1
  fleet {
    project = data.google_project.project.project_id
  }
  release_channel {
    channel = "REGULAR"
  }
  secret_manager_config {
    enabled = true
  }
  # See also:
  # * https://cloud.google.com/iam/docs/federated-identity-supported-services
  workload_identity_config {
    workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
  }
  maintenance_policy {
    recurring_window {
      start_time = "2024-12-21T04:00:00Z"
      end_time   = "2024-12-21T16:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA"
    }
  }
  enterprise_config {
    desired_tier = "STANDARD"
  }
  timeouts {
    create = "60m"
    read   = "60m"
    update = "60m"
    delete = "60m"
  }
}

resource "google_service_account" "gke_iam_dev_default_node" {
  account_id   = "gke-iam-dev-default-node"
  display_name = "GKE IAM Develop Default Node"
}

resource "google_container_node_pool" "iam_dev_default" {
  name     = "iam-dev-default"
  location = "us-east1"
  cluster  = google_container_cluster.iam_dev.name
  node_config {
    preemptible     = true
    machine_type    = "e2-small"
    service_account = google_service_account.gke_iam_dev_default_node.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  network_config {
    enable_private_nodes = true
  }
  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 6
  }
  management {
    auto_upgrade = true
    auto_repair  = true
  }
  upgrade_settings {
    strategy = "BLUE_GREEN"
    blue_green_settings {
      standard_rollout_policy {
        batch_percentage    = 0.34 # Max of 3 batches
        batch_soak_duration = "30s"
      }
      node_pool_soak_duration = "300s"
    }
  }
}

resource "google_compute_global_address" "gke_iam_dev" {
  name = "gke-iam-dev"
}
