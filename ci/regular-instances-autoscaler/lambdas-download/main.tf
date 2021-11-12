locals {
  version = "v0.24.0"
}

module "lambdas" {
  source  = "philips-labs/github-runner/aws//modules/download-lambda"
  version = "0.24.0"

  lambdas = [
    {
      name = "webhook"
      tag  = local.version
    },
    {
      name = "runners"
      tag  = local.version
    },
    {
      name = "runner-binaries-syncer"
      tag  = local.version
    }
  ]
}

output "files" {
  value = module.lambdas.files
}
