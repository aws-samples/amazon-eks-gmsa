## Sample Application Deployment
*Set Working Directory to ./amazon-eks-gmsa/sample-applications/IIS-auth-application/*

### Create Sample Container Images
```powershell
$containersBuildCommandId =  aws ssm send-command --document-name "AWS-RunPowerShellScript" --parameters "commands=['wget https://raw.githubusercontent.com/aws-samples/amazon-eks-gmsa/master/sample-applications/IIS-auth-application/Build-Container-Images.ps1 -o Build-Container-Images.ps1', 'Invoke-Expression -Command ./Build-Container-Images.ps1']" --targets "Key=tag:aws:autoscaling:groupName,Values=$autoScalingGroup" --query "Command.CommandId" --output text

# Wait for the success
aws ssm list-command-invocations --command-id $containersBuildCommandId
```

### Deploy Applications

*If you are using Kubernetes master v1.14, then use the following command*

```powershell
./Deploy-Applications.ps1 -Namespace $gMSAnamespace -ServiceAccount $serviceaccount -CredSpecResourceName "$credspecResourceName" -WindowsServerApp "windows-server-iis_v14.yaml"
```

*If you are using Kubernetes master v1.16 and beyond, then use the following command*

```powershell
./Deploy-Applications.ps1 -Namespace $gMSAnamespace -ServiceAccount $serviceaccount -CredSpecResourceName "$credspecResourceName" 
```

### Validate the application deployments

```powershell
kubectl get pods -n $gMSAnamespace
kubectl get services -n $gMSAnamespace

##### ACTION REQUIRED - START #####
# On accessing the External IP, you will get a prompt asking for username and password. Enter your gMSA username and password and windows IIS server webpage will get displayed. 
##### ACTION REQUIRED - END #####
```