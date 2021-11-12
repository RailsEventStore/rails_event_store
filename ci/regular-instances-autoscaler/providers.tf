provider "aws" {
  region = local.aws_region
  shared_credentials_file = "aws_credentials"
}
