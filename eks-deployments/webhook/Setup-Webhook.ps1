# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

<#
.DESCRIPTION
Creates a webhook deployment config yaml for an EKS kubernetes cluster

.SYNOPSIS
Creates a webhook deployment config yaml for an EKS kubernetes cluster

.PARAMETER DeploymentTemplate
(Required) The path to the template yaml file for the webhook

.PARAMETER Namespace
The kubernetes namespace to target

.PARAMETER Outfile
The file to write the deployment configuration out to

.PARAMETER ServiceName
The name of the webhook

.PARAMETER SecretName
The name of the secret deployed for use with the webhook

.PARAMETER DryRun
A switch that, when enabled, will generate the artifacts and pre-requisites for
deploying the webhook, but will return the config yaml content
rather than applying it to the cluster

#>
Param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$DeploymentTemplate,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Outfile = 'webhook.yaml',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName = 'webhook-svc',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SecretName = 'webhook-certs',

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

# Check for the namespace, if it doesn't exist, create one.
try {
    $k8sNamespace = Invoke-Expression -command "kubectl get namespaces --field-selector metadata.name==$Namespace -o jsonpath='{.items[].metadata.name}'" 2>&1
} catch {
    Write-Verbose $_
} 

if (-not $k8sNamespace) {
    Write-Verbose "Creating namespace $Namespace"
    Invoke-Expression -Command "kubectl create namespace $Namespace"
}


$createCertScript = [System.IO.Path]::Combine($PSScriptRoot, 'create-signed-cert.ps1')
$pathTemplateScript = [System.IO.Path]::Combine($PSScriptRoot, 'patch-webhook-template.ps1')
if (-not (Test-Path -Path $createCertScript)) {
    throw "File missing: $createCertScript"
}
if (-not (Test-Path -Path $pathTemplateScript)) {
    throw "File missing: $pathTemplateScript"
}

# Setup secret for secure communication
Invoke-Expression -Command "& '$createCertScript' -ServiceName $ServiceName -SecretName $SecretName -Namespace $Namespace"

# Verify secret
Invoke-Expression -Command "kubectl get secret -n $Namespace $SecretName" | Select-String -NotMatch "Warning" 2>&1

# Configure webhook and create deployment file
Invoke-Expression -Command "& '$pathTemplateScript' -DeploymentTemplateFilePath `"$DeploymentTemplate`" -ServiceName `"$ServiceName`" -Namespace `"$Namespace`" -OutputFilePath `"$Outfile`""

if ($DryRun) {
    Write-Output (Get-Content -Path $Outfile)
} else {
    Invoke-Expression -Command "kubectl -n $Namespace apply -f `"$Outfile`"" | Select-String -NotMatch "Warning" 2>&1

    # Verify that both mutating and validating webhooks are installed correctly
    $CmdOutput = Invoke-Expression -Command "kubectl get mutatingwebhookconfigurations $ServiceName"
    if (($CmdOutput.IndexOf("Error") -ge 0) -or ($CmdOutput.IndexOf("Not Found") -ge 0)) {
        Write-Output ($CmdOutput)
    }
    $CmdOutput = Invoke-Expression -Command "kubectl get validatingwebhookconfigurations $ServiceName"
    if (($CmdOutput.IndexOf("Error") -ge 0) -or ($CmdOutput.IndexOf("Not Found") -ge 0)) {
        Write-Output ($CmdOutput)
    }
}