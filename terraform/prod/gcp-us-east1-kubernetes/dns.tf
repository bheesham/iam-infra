resource "google_dns_managed_zone" "gke_iam_dev" {
  name     = "gke-iam-dev"
  dns_name = "gke-iam-dev.iam.mozilla.com."
}

resource "google_dns_record_set" "gke_iam_dev" {
  name         = google_dns_managed_zone.gke_iam_dev.dns_name
  managed_zone = google_dns_managed_zone.gke_iam_dev.name
  type         = "A"
  rrdatas = [
    google_compute_global_address.gke_iam_dev.address
  ]
}

data "aws_route53_zone" "iam" {
  name = "iam.mozilla.com"
}

resource "aws_route53_record" "gke_iam_dev_iam" {
  name    = trimsuffix(google_dns_managed_zone.gke_iam_dev.dns_name, ".")
  ttl     = 172800
  type    = "NS"
  zone_id = data.aws_route53_zone.iam.zone_id
  records = google_dns_managed_zone.gke_iam_dev.name_servers
}
