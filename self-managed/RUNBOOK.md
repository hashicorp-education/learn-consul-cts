## Prerequisites

`aws-cli` with configured AWS Credentials

## Runbook steps

Run the deployment.

`terraform init`
`terraform apply`

Save the address of the CTS instance into an environment variable.

```
export CTSINSTANCEIP=$(terraform output -raw cts_instance_ip)
```

Log on to the CTS instance and inspect the CTS configuration file.

`ssh -i ./consul-client.pem ubuntu@$CTSINSTANCEIP`

`less cts/cts-config.hcl`

``` filename=cts-config.hcl
consul {
  address = "localhost:8500"
  token   = "xxxx-xxxx-xxxx-xxxx-xxxx"
}

driver "terraform" {
  log         = false
  persist_log = true
  path        = ""

  backend "consul" {
    gzip = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
  }
}

terraform_provider "aws" {
}

task {
  name      = "jumphost-ssh"
  module    = "./cts-jumphost-module"
  providers = ["aws"]

  condition "services" {
    regexp = "^nginx.*"
    use_as_module_input = true
    cts_user_defined_meta = {}
  }
}
```

Start consul-terraform-sync on the CTS instance.

`ssh -i ./consul-client.pem ubuntu@$CTSINSTANCEIP`
`cd cts`
`consul-terraform-sync start -config-file=cts-config.hcl`

```
2023-08-09T14:43:25.015Z [INFO]  ctrl: task completed: task_name=jumphost-ssh
2023-08-09T14:43:25.015Z [INFO]  ctrl: all tasks completed once
2023-08-09T14:43:25.016Z [INFO]  ctrl: start task monitoring
```

This output means that the CTS deployment has ran successfully. Leave the CTS process running and open another terminal session on your local machine.

Verify that the EC2 jumphost instance with the related tag is currently running:

```
$ aws --region eu-north-1  ec2 describe-instances --filters "Name=tag-key,Values=CtsJumphostModule" | jq '.Reservations[].Instances[].State.Name'
"running"
```

Verify the current ruleset consists only of one rule for the current one deployed application instance:

```
$ aws --region eu-north-1 ec2 describe-security-groups --filters "Name=tag-key,Values=CtsJumphostModule" | jq -r '.SecurityGroups[].IpPermissionsEgress'
[
  {
    "FromPort": 22,
    "IpProtocol": "tcp",
    "IpRanges": [
      {
        "CidrIp": "<<APPLICATION INSTANCE IP>>"
      }
    ],
    "Ipv6Ranges": [],
    "PrefixListIds": [],
    "ToPort": 22,
    "UserIdGroupPairs": []
  }
]
```

Save the address of the jumphost into an environment variable.

```
export JUMPHOSTIP=$(aws --region eu-north-1  ec2 describe-instances --filters "Name=tag-key,Values=CtsJumphostModule" | jq -r '.Reservations[].Instances[].PublicIpAddress')
```

Save the address of the first application instance into an environment variable.

```
export APPINSTANCE0IP=$(terraform output -json app_instance_ips | jq -r '.[0]')
```

Log on to the first application instance via the jumphost instance.

```
ssh -i ./consul-client.pem -J ubuntu@$JUMPHOSTIP ubuntu@$APPINSTANCE0IP
```

### Scale the application instances up

Modify the `application_instances_amount` variable in terraform.tfvars to `2` and rerun `terraform apply`. 

```
Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_instance.application[1]: Creating...
aws_instance.application[1]: Still creating... [10s elapsed]
aws_instance.application[1]: Creation complete after 15s [id=i-0ccb3e18790036752]
```

Observe the output in the `consul-terraform-sync` session in the running CTS instance:

```
2023-08-09T16:00:48.788Z [INFO]  ctrl: task completed: task_name=jumphost-ssh
```

Verify the current ruleset consists of two rules for the current deployed application instances:

```
$ aws --region eu-north-1 ec2 describe-security-groups --filters "Name=tag-key,Values=CtsJumphostModule" | jq -r '.SecurityGroups[].IpPermissionsEgress'
[
  {
    "FromPort": 22,
    "IpProtocol": "tcp",
    "IpRanges": [
      {
        "CidrIp": "10.0.1.180/32"
      },
      {
        "CidrIp": "10.0.1.189/32"
      }
    ],
    "Ipv6Ranges": [],
    "PrefixListIds": [],
    "ToPort": 22,
    "UserIdGroupPairs": []
  }
]
```

Save the address of the second application instance into an environment variable.

```
export APPINSTANCE1IP=$(terraform output -json app_instance_ips | jq -r '.[1]')
```

Log on to the second application instance via the jumphost instance.

```
ssh -i ./consul-client.pem -J ubuntu@$JUMPHOSTIP ubuntu@$APPINSTANCE1IP
```


# Clean up
Clean-up the infrastructure deployed from the CTS module. Stop the jumphost instance:

```
$ aws --region eu-north-1 ec2 terminate-instances --instance-ids $(aws --region eu-north-1 ec2 describe-instances --filters "Name=tag-key,Values=CtsJumphostModule" | jq -r '.Reservations[].Instances[].InstanceId')
{
    "TerminatingInstances": [
        {
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "InstanceId": "i-002632b147d134600",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        }
    ]
}
```

Delete the jumphost instance's security group. Notice the lack of output means success:

```
$ aws --region eu-north-1 ec2 delete-security-group --group-id $(aws --region eu-north-1 ec2 describe-security-groups --filters "Name=tag-key,Values=CtsJumphostModule" | jq -r '.SecurityGroups[].GroupId')

```

Destroy the environment.

`terraform destroy`

