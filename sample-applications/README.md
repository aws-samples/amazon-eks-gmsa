## Sample Application Deployment
*Set Working Directory to ./amazon-eks-gmsa/sample-applications/*
*Following container images require minimum of 10GB free disk space* 
### Create Sample Container Images
```powershell
$containersBuildCommandId = aws ssm send-command --document-name "AWS-RunPowerShellScript" --parameters "commands=['wget https://raw.githubusercontent.com/aws-samples/amazon-eks-gmsa/master/sample-applications/Build-Container-Images.ps1 -o Build-Container-Images.ps1', 'Invoke-Expression -Command ./Build-Container-Images.ps1']" --targets "Key=tag:aws:autoscaling:groupName,Values=$autoScalingGroup" --query "Command.CommandId" --output text

# Wait for the success
aws ssm list-command-invocations --command-id $containersBuildCommandId
```

### Deploy Applications
```powershell
./Deploy-Applications.ps1 -Namespace $gMSAnamespace -ServiceAccount $serviceaccount -CredSpecResourceName "$credspecResourceName" -SQLSAPassword "$sqlSAPassword" -GMSAUser "$adDirectoryShortName\$gMSAAccountName`$" 
```