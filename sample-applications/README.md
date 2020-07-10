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

*If you are using Kubernetes master v1.14, then use the following command*

```powershell
./Deploy-Applications.ps1 -Namespace $gMSAnamespace -ServiceAccount $serviceaccount -CredSpecResourceName "$credspecResourceName" -SQLSAPassword "$sqlSAPassword" -GMSAUser "$adDirectoryShortName\$gMSAAccountName`$" -MVCSampleApp "containermvc-web_v14.yaml" -BookstoreDBApp "containersql-bookstore_v14.yaml"
```

*If you are using Kubernetes master v1.16 and beyond, then use the following command*

```powershell
./Deploy-Applications.ps1 -Namespace $gMSAnamespace -ServiceAccount $serviceaccount -CredSpecResourceName "$credspecResourceName" -SQLSAPassword "$sqlSAPassword" -GMSAUser "$adDirectoryShortName\$gMSAAccountName`$" 
```

### Validate the application deployments

```powershell
kubectl get pods -n $gMSAnamespace
kubectl get services -n $gMSAnamespace

##### ACTION REQUIRED - START #####
# Access the containermvc externalIP in browser.
# DNS records take sometime. Access it after a while.
##### ACTION REQUIRED - END #####
```