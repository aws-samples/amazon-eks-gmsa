## Infrastructure Setup

*Set Working Directory to ./amazon-eks-gmsa/cloud-formation-templates/*

### SSM Parameter Names
```powershell
$directorNameParam = "gMSA-blog-DirectoryName"
$adUserParam = "gMSA-blog-ADUser"
$adUserPasswordParam = "gMSA-blog-ADUserPassword"
$dnsIPAddressesParam = "gMSA-blog-AD-dnsIPAddresses"

##### ACTION REQUIRED - START #####
$adUserPassword = "xxxxx" # AD User password.Substitute xxxxx with a strong password.
$vpcId = "xxxxx" # Active Director VPC ID. It should be same as EKS Workers VPC. Cross VPC AD communication is not discussed here.
$subnets = "subnet-0xxxxx\,subnet-0xxxxx" # Replace 0xxxxx with subnet Ids in the VPC. Pick two subnet ids and make sure AD is available in those availability zones. Don't remove "\". AD is only available in certain AZs.
$sqlSAPassword = "xxxxx" # SQL SA password will be created as a kubernetes secret (mssql/password).
##### ACTION REQUIRED - START - END #####

##### DEFAULT VALUES - START #####
# Use lower cases, some of these are going to be used in Kubernetes deployments.
$adDirectoryName = "gmsa.blog.corp.com" # Active Directory Domain/Directory name.
$adDirectoryShortName = "gmsa" # AD NetBios name.
$adUserName = "admin" # For this demo, it uses admin  
$gMSAADSecurityGroup = "gmsa-container-securitygroup" # AD Security group to which gMSA account will be associated and EKS Workers will be member of this AD security group.
$gMSAAccountName = "foouser1" # gMSA account name that will be created in AD.
$gMSAnamespace = "gmsa" # Kuberenets namespace to be used with credspec resources, deployments ...
$serviceaccount = "gmsaserviceaccount" # POD service account.
$credspecResourceName = "foouser1resource" # Custom resourcename in the kubernetes
##### DEFAULT VALUES - END #####
```

### Customer Managed Key
```powershell
$cmkstack = aws cloudformation create-stack --stack-name cmkstack --template-body file://kms-custom-cmk.yaml --parameters ParameterKey=CMKAlias,ParameterValue="gMSAKey" ParameterKey=CMKDescription,ParameterValue="Encrypt or Decrypt gMSA active directory admin password" --output text

# Wait for the cloud formation to be completed
aws cloudformation describe-stack-events --stack-name $cmkstack
 
# Retrieve Customer Master Key Id and ARN
$CMKeyId = aws cloudformation describe-stacks --stack-name $cmkstack --query "Stacks[*].Outputs[?OutputKey=='CMKID'].OutputValue" --output text
 
$CMKARN = aws cloudformation describe-stacks --stack-name $cmkstack --query "Stacks[*].Outputs[?OutputKey=='CMKARN'].OutputValue" --output text
```

### IAM Policy for Customer Managed Key
```powershell
$CMKPolicyContent = Get-Content -Path ./kmspolicy.json | Foreach-Object {$_ -replace '\${CMKARN}', $CMKARN}

$CMKPolicyArn = aws iam create-policy --policy-name "cmk-decrypt" --policy-document ("$CMKPolicyContent" | ConvertTo-Json) --query "Policy.Arn"
```

### SSM Parameters to store AWS Managed AD information
```powershell
# Create SSM Parameters
aws ssm put-parameter --name "$directorNameParam" --value "$adDirectoryName" --type "String"

aws ssm put-parameter --name "$adUserParam" --value "$adUserName" --type "String"

aws ssm put-parameter --name "$adUserPasswordParam" --value "$adUserPassword" --key-id "$CMKeyId" --type SecureString
```

### Create AWS Managed AD
#### AD Creation takes about ~20 minutes. If you have your own AD, please use that.
```powershell
$adstack = aws cloudformation create-stack --stack-name gmsaADstack --template-body file://aws_managed_ad_cloudformation.yaml --parameters ParameterKey=DirectoryNameParameter,ParameterValue="$directorNameParam" ParameterKey=ShortName,ParameterValue="$adDirectoryShortName" ParameterKey=Subnets,ParameterValue="$subnets" ParameterKey=VpcId,ParameterValue="$vpcId" --output text

# Validate the stack creation
aws cloudformation describe-stack-events --stack-name $adstack
 
# Create SSM parameter store for the DNS IP addresses. If you are using your AD, you should just store the IP address to $dnsIPAddress (comma separated)
$dnsIPAddresses  = aws cloudformation describe-stacks --stack-name $adstack --query "Stacks[*].Outputs[?OutputKey=='DnsIpAddresses'].OutputValue" --output text
 
aws ssm put-parameter --name "$dnsIPAddressesParam" --value  $dnsIPAddresses --type "String" 
```

### Generate SSM Documents
* GMSA-DomainJoin-Document
```powershell
$domainjoinSSMStack = aws cloudformation create-stack --stack-name gmsaDomainJoinSSM --template-body file://ssm-document-domain-join.yaml --parameters ParameterKey=DirectoryNameParameter,ParameterValue="$directorNameParam" ParameterKey=ADUserNameParameter,ParameterValue="$adUserParam" ParameterKey=ADUserPasswordParameter,ParameterValue="$adUserPasswordParam" ParameterKey=ADDNSIPAddressesParameter,ParameterValue="$dnsIPAddressesParam" ParameterKey=gMSAADSecurityGroup,ParameterValue="$gMSAADSecurityGroup" --output text
 
aws cloudformation describe-stack-events --stack-name $domainjoinSSMStack
 
$domainjoinSSMdoc = aws cloudformation describe-stacks --stack-name $domainjoinSSMStack --query "Stacks[*].Outputs[?OutputKey=='DocumentName'].OutputValue" --output text
```

* GMSA-CredSpec-Document
```powershell
$credspecSSMStack = aws cloudformation create-stack --stack-name credspecGeneratorSSM --template-body file://ssm-document-credspec-generator.yaml --parameters ParameterKey=DirectoryNameParameter,ParameterValue="$directorNameParam" ParameterKey=ADUserNameParameter,ParameterValue="$adUserParam" ParameterKey=ADUserPasswordParameter,ParameterValue="$adUserPasswordParam" ParameterKey=gMSAAccountName,ParameterValue="$gMSAAccountName" ParameterKey=CredSpecAdditionalAccounts,ParameterValue="" ParameterKey=gMSAADSecurityGroup,ParameterValue="$gMSAADSecurityGroup" --output text
 
aws cloudformation describe-stack-events --stack-name $credspecSSMStack
 
$credspecSSMdoc = aws cloudformation describe-stacks --stack-name $credspecSSMStack --query "Stacks[*].Outputs[?OutputKey=='DocumentName'].OutputValue" --output text
```
