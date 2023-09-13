terraform {
  backend "s3" {
    bucket = "S3-denstit-tf-files"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}
