terraform {
  backend "s3" {
    bucket         = "itssamplebuckets"        # Reference the S3 bucket
    key            = "terraform.tfstate"     # Path to store the state file (e.g., "project/terraform.tfstate")
    dynamodb_table = "terraform-state-lock-dynamo"
    region         = "us-east-1"
    encrypt        = true                     # Encrypt the state file in S3 (recommended)
  }
}
