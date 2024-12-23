# See the comment below, re: workloads.

# You _will_ run into errors if you try setting this up for another cluster. I
# (bhee) have not spent time making this friendly to use for that scenario,
# since this is just a MVP.

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

resource "kubernetes_deployment_v1" "gke_iam_dev_web" {
  metadata {
    labels = {
      app = "web"
    }
    name      = "web"
    namespace = "default"
  }
  spec {
    replicas = "1"
    selector {
      match_labels = {
        app = "web"
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }
    template {
      metadata {
        labels = {
          app = "web"
        }
      }
      spec {
        container {
          image             = "gcr.io/google-samples/hello-app:1.0"
          image_pull_policy = "Always"
          name              = "hello-app"
          resources {
            limits = {
              memory = "64Mi"
            }
            requests = {
              memory = "64Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "gke_iam_dev_web" {
  metadata {
    name      = "web"
    namespace = "default"
    labels = {
      app = "web"
    }
    annotations = {
      "cloud.google.com/neg" = jsonencode({ ingress = true })
    }
  }
  spec {
    selector = {
      app = "web"
    }
    type = "ClusterIP"
    port {
      port        = 8080
      protocol    = "TCP"
      target_port = "8080"
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cloud.google.com/neg-status"],
    ]
  }
}

resource "kubernetes_manifest" "gke_iam_dev" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "gke-iam-dev"
      namespace = "default"
    }
    spec = {
      domains = [
        trimsuffix(google_dns_managed_zone.gke_iam_dev.dns_name, "."),
      ]
    }
  }
}

resource "kubernetes_ingress_v1" "gke_iam_dev" {
  metadata {
    name      = "gke-iam-dev"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.gke_iam_dev.name
      "networking.gke.io/managed-certificates"      = kubernetes_manifest.gke_iam_dev.manifest.metadata.name
      "kubernetes.io/ingress.class"                 = "gce"
    }
  }
  spec {
    default_backend {
      service {
        name = kubernetes_service_v1.gke_iam_dev_web.metadata[0].name
        port {
          number = kubernetes_service_v1.gke_iam_dev_web.spec[0].port[0].port
        }
      }
    }
  }
}
