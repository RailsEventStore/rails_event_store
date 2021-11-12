locals {
  environment = "default"
  aws_region  = "eu-west-1"
}

resource "random_password" "random" {
  length = 28
}

module "runners" {
  source  = "philips-labs/github-runner/aws"
  version = "0.24.0"
  create_service_linked_role_spot = true
  aws_region = local.aws_region
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  environment = local.environment
  tags = {
    Project = "ProjectX"
  }

  github_app = {
    key_base64 = var.github_app_key_base64
    id = var.github_app_id
    webhook_secret = random_password.random.result
  }

  webhook_lambda_zip = "lambdas-download/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas-download/runner-binaries-syncer.zip"
  runners_lambda_zip = "lambdas-download/runners.zip"
  enable_organization_runners = true
  runner_extra_labels = "default,example,ubuntu-20.04"

  enable_ssm_on_runners = true

  userdata_template = "./templates/user-data.sh"
  ami_owners = ["099720109477"] # Canonical's Amazon account ID

  ami_filter = {
    name = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  block_device_mappings = {
    device_name = "/dev/sda1"
  }

  instance_types = ["c6i.large"]

  delay_webhook_event = 5

  scale_down_schedule_expression = "cron(* * * * ? *)"

  runners_maximum_count = 18

  # Useful for debugging
  # log_level = "trace"
}
