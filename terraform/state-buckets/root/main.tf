data "aws_caller_identity" "current" {}

module "state_bucket" {
  source      = "../../lib/aws_tfstate_s3"
  bucket_name = "mozilla-corporation-terraform-${data.aws_caller_identity.current.account_id}"
}
