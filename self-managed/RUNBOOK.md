## Prerequisites

`aws-cli` with configured AWS Credentials

## Runbook steps

Run the deployment.

`terraform init`
`terraform apply`

Log on to the CTS instance.

`ssh -i ./consul-client.pem ubuntu@XX.XX.XX.XX`
`cd cts`
`consul-terraform-sync start -config-file=cts-config.hcl`

```
2023-08-09T14:43:25.015Z [INFO]  ctrl: task completed: task_name=jumphost-ssh
2023-08-09T14:43:25.015Z [INFO]  ctrl: all tasks completed once
2023-08-09T14:43:25.016Z [INFO]  ctrl: start task monitoring
```

This output means that the CTS deployment has ran successfully.

Verify that the EC2 jumphost instance with the related tag is currently running:

```
$ aws --region eu-north-1  ec2 describe-instances --filters "Name=tag-key,Values=CtsCleanup" | jq '.Reservations[].Instances[].State.Name'
"running"
```

Verify the current ruleset consists only of one rule for the current one deployed application instance:

```
$ aws --region eu-north-1 ec2 describe-security-groups --filters "Name=tag-key,Values=CtsCleanup" | jq -r '.SecurityGroups[].IpPermissionsEgress'
[
  {
    "FromPort": 22,
    "IpProtocol": "tcp",
    "IpRanges": [
      {
        "CidrIp": "10.0.1.93/32"
      }
    ],
    "Ipv6Ranges": [],
    "PrefixListIds": [],
    "ToPort": 22,
    "UserIdGroupPairs": []
  }
]
```

Modify the `count` to `2` in the `self-managed/application-instance.tf` file and rerun `terraform apply`. Observe the output in the `consul-terraform-sync` session in the running CTS instance:

```

```