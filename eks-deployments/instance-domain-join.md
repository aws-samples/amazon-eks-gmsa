# EKS Windows Worker changes
This document gives list of steps to enable gMSA feature-gates and to attach to domain join SSM document.

## 1. Launch EKS Windows worker instances with gMSA feature-gates
*gMSA is an alpha feature in Kubernetes 1.14. For details refer [here](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)*
*For alpha features we need to enable the feature-gates.* 

```powershell
# In EKS Windows worker CloudFormation stack, paste the following argument
BootstrapArguments: --feature-gates="WindowsGMSA=true"
```

```powershell
##### ACTION REQUIRED - START #####
$eksWindowsStack = "xxxxx" # Name of the Cloudformation stack that created EKS Windows worker nodes.
##### ACTION REQUIRED - END #####
```

## 2. Attach Customer Master Key IAM Policy to EKS Windows NodeInstanceRole
```powershell
# Retrieve the EKS Windows Worker nodeinstancerole.
$nodeInstanceRole = aws cloudformation describe-stack-resources --stack-name $eksWindowsStack --query "StackResources[?ResourceType=='AWS::IAM::Role'].PhysicalResourceId" --output text

# Retrieve the EKS Windows Autoscaling group name.
$autoScalingGroup = aws cloudformation describe-stack-resources --stack-name $eksWindowsStack --query "StackResources[?ResourceType=='AWS::AutoScaling::AutoScalingGroup'].PhysicalResourceId" --output text

# Attach Customer Master key IAM policy to EKS Windows nodeinstancerole.
aws iam attach-role-policy --role-name $nodeInstanceRole --policy-arn $CMKPolicyArn

# Attach SSM Policy to EC2 Instance
aws iam attach-role-policy --role-name $nodeInstanceRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM
```

## 3. Attach Domain Join SSM document to EKS Windows Autoscaling group
```powershell
# Create SSM association between autoscaling group and SSM Document
aws ssm create-association --name $domainjoinSSMdoc --document-version 1 --targets "Key=tag:aws:autoscaling:groupName,Values=$autoScalingGroup"

# Validate the association is created
aws ssm list-associations --association-filter-list "key=Name, value=$domainjoinSSMdoc"
```

## 4. Create and join gMSA AD security group (Optional)
*If the AD security group exists already prior to domain join, the worker instance will be added to that security group during domain join. Otherwise, you need to execute this document to create and join AD. AD security group creation shouldn't be executed concurrently. Concurrent execution will result into duplicate AD group creation. Hence this needs to be run one instance at a time. This SSM document shoudn't be attached to autoscaling group*

```powershell
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $autoScalingGroup --query "AutoScalingGroups[*].Instances[*].InstanceId" --output text

##### ACTION REQUIRED - START #####
# Replace XXXXX with each of the above instance id.
# You need to send the following commands one by one.
$commandId = aws ssm send-command --document-name $adGroupCreateSSMdoc --targets "Key=InstanceIds, Values=XXXXX" --parameters "ADSecurityGroup=$gMSAADSecurityGroup" --query "Command.CommandId" --output text

aws ssm list-command-invocations --command-id $commandId
##### ACTION REQUIRED - END #####
```