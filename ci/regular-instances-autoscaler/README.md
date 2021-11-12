# Self-hosted runners for Github Actions

## Setup

1. You need terraform variables file (`terraform.auto.tfvars`) with github credentials:

```
github_app_key_base64 = "..."
github_app_id = "..."
```

2. You need to set your AWS credentials file (`aws_credentials`) with aws credentials:

```
[default]
aws_access_key_id=...
aws_secret_access_key=...
```

3. Refresh the lambda files. This will download zipped lambda files to `lambdas-download/` directory.

```
cd lambdas-download
terraform apply
```

4. Refreshing the AWS state:

```
terraform apply
```


## Debugging

* lambda `webhook` logs (the one which receives webhooks from github): [https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fdefault-webhook]()
* lambda `scale-up` logs (the one which scales up the machines): [https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fdefault-scale-up]()
* lambda `scale-down` logs (the one which goes over machines and terminates them): [https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fdefault-scale-down]()
* list of EC2 machines: [https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Instances:]()
* userdata logs (userdata is the script which prepares the machine after start): [https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:log-groups/log-group/$252Fgithub-self-hosted-runners$252Fdefault$252Fuser_data]()
* runner logs (runner is the github agent which execute the jobs): [https://eu-west-1.console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:log-groups/log-group/$252Fgithub-self-hosted-runners$252Fdefault$252Frunner]()
* autoscaler github app settings: [https://github.com/organizations/RailsEventStore/settings/apps/ci-autoscaler]()
* autoscaler github app webhook logs: [https://github.com/organizations/RailsEventStore/settings/apps/ci-autoscaler/advanced]()
* autoscaler github app settings on the repository: [https://github.com/organizations/RailsEventStore/settings/installations/20651084]()
