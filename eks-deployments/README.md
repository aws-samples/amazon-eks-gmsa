# EKS Deployment
This documemt gives list of steps to deploy credspec resources and gMSA webhook.

*Set Working Directory to ./amazon-eks-gmsa/eks-deployments/*

## Install the GMSACredentialSpec Custom Resource Definition (CRD)
```powershell
kubectl apply -f ./credspec/CustomResourceDefinition.yml
```

## gMSA Webhook deployment
```powershell
./webhook/Setup-Webhook.ps1 -DeploymentTemplate "./webhook/gmsa-webhook-template.yaml" -Namespace $gMSAnamespace
```

## Deploy Credspec and Create gMSA account
```powershell
# Check SSM document for the default parameter values
aws ssm describe-document --name $credspecSSMdoc 

# Pick an instance to run the SSM command.
$firstInstanceId = aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $autoScalingGroup --query "AutoScalingGroups[*].Instances[0].InstanceId" --output text

# Overwride the default values by passing additional parameters.
$commandId = aws ssm send-command --document-name $credspecSSMdoc --targets "Key=InstanceIds,Values=$firstInstanceId" --parameters "gMSAAccount=$gMSAAccountName,ADSecurityGroup=$gMSAADSecurityGroup,ADUserNameParameter=$adUserParam,ADUserPasswordParameter=$adUserPasswordParam" --query "Command.CommandId" --output text

# Wait for the success
aws ssm list-command-invocations --command-id $commandId
 
# Format the output and save it as a json file (credspec.json)
# If the json file is generated, save the content to credspec.json and format the json.
aws ssm get-command-invocation --command-id "$commandId" --instance-id "$firstInstanceId" --plugin-name "GenerateCredspec" --query "StandardOutputContent" --output json > credspec.json
 
##### ACTION REQUIRED - Format JSON #####
# Make sure credspec.json is a valid json content. 
# We still need to perform the following cleanups.
# Remove \r\n. 
# Remove the backslahes preceeding the double quote (Example: \" ==> ")
# Remove the " at the beginning and end of the file, if it's present.
##### ACTION REQUIRED - Format JSON - END #####

# Deploy Credspec.json to kubernetes (Specify the full qualified name to the credspec.json)
./credspec/Deploy-CredSpec.ps1 -Namespace $gMSAnamespace -ServiceAccount $serviceaccount -CredSpecName "$credspecResourceName" -CredSpecFile "./credspec.json"
```

## Patch CoreDNS Corefile
Follow the instructions from [./amazon-eks-gmsa/eks-deployments/patch-coredns/README.md](https://github.com/aws-samples/amazon-eks-gmsa/blob/master/eks-deployments/patch-coredns/README.md) to patch the CoreDNS configuration.
