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
        "CidrIp": "10.0.1.180/32"
      }
    ],
    "Ipv6Ranges": [],
    "PrefixListIds": [],
    "ToPort": 22,
    "UserIdGroupPairs": []
  }
]
```

Modify the `count` to `2` in line 49 on the `self-managed/application-instance.tf` file and rerun `terraform apply`. 

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

Delete the jumphost instance's key-pair. Notice the lack of output means success:

```
$ aws --region eu-north-1 ec2 delete-key-pair --key-pair-id $(aws --region eu-north-1 ec2 describe-key-pairs --filters "Name=tag-key,Values=CtsJumphostModule" | jq -r '.KeyPairs[].KeyPairId')

```

Delete the jumphost instance's security group. Notice the lack of output means success:

```
$ aws --region eu-north-1 ec2 delete-security-group --group-id $(aws --region eu-north-1 ec2 describe-security-groups --filters "Name=tag-key,Values=CtsJumphostModule" | jq -r '.SecurityGroups[].GroupId')

```

Destroy the environment.

`terraform destroy`

