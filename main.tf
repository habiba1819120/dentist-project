terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #       version = "4.61.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Update with appropriate region
  access_key = "AKIAV2OBSZ2QIR4D5UHC"
  secret_key = "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"
}
