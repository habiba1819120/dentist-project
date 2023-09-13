terraform {
  backend "s3" {
    bucket         = "your-unique-s3-bucket-name"
    key            = "terraform.tfstate"
    region         = "us-east-1"  # Replace with your desired AWS region
    encrypt        = true         # Enable state file encryption (recommended)
    
  }
}
