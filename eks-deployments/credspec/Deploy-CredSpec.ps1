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
Replaces a credspec template with actual credspec and deploys to EKS cluster.

.SYNOPSIS
Creates a webhook deployment config yaml for an EKS kubernetes cluster

.PARAMETER Namespace
The kubernetes namespace to target

.PARAMETER ServiceAccount
The application service account

.PARAMETER CredSpecName
The name of the Credspec

.PARAMETER CredSpecFile
The file path to the Credential spec json file generated from Active Directory

.PARAMETER CredSpecTemplate
The path to the Credential Spec Template json file to deploy to kubernetes cluster

.PARAMETER CredSpecClusterRole
The path to the credential Spec cluster role template file to
configure cluster role to enable RBAC on specific GMSA credential specs

.PARAMETER DryRun
A switch that, when enabled, will generate the artifacts and pre-requisites for
deploying the credspec, but will return the config yaml content
rather than applying it to the cluster

#>

[CmdLetBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceAccount,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CredSpecName,

    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$CredSpecFile,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$CredSpecTemplate = 'gmsa-credspec-template.json',

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$CredSpecClusterRole = 'credspec-cluster-role-template.yaml',

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (!(Get-Command -Name 'kubectl' -ErrorAction:SilentlyContinue)) {
    throw 'kubectl not found'
}

$k8sNamespace = Invoke-Expression -command "kubectl get namespaces --field-selector metadata.name==$Namespace -o jsonpath='{.items[].metadata.name}'" 2>&1

if (-not $k8sNamespace) {
    Write-Verbose "Creating namespace $Namespace"
    Invoke-Expression -Command "kubectl create namespace $Namespace"
}

$tempaccount = Invoke-Expression -command "kubectl get serviceaccount -n $Namespace --field-selector metadata.name==$ServiceAccount -o jsonpath='{.items[].metadata.name}'"  2>&1

if (-not $tempaccount) {
    Write-Verbose "Creating Serviceaccount $ServiceAccount"
    Invoke-Expression -Command "kubectl create Serviceaccount $ServiceAccount -n $Namespace"
}

$credSpecContent = Get-Content -Path $CredSpecFile

$newCredSpec = Get-Content -Path $CredSpecTemplate | ForEach-Object {
    $_ -replace '\${CREDSPEC}', $credSpecContent `
       -replace '\${CREDSPECNAME}', $CredSpecName `
       -replace '\${NAMESPACE}', $Namespace
}

if ($DryRun) {
    Write-Output ($newCredSpec | Out-String)
} else {
    $tempOutFile = "newcredspec.json"
    Out-File -FilePath $tempOutFile -InputObject $newCredSpec -Force
    Invoke-Expression -Command "kubectl apply -f $tempOutFile"
    Remove-Item -Path $tempOutFile -Force
}

Write-Verbose "Assign role to service accounts to use specific GMSA credspecs"
$clusterRole = (Get-Content -Path $CredSpecClusterRole) | Foreach-Object {
    $_ -replace '\${CREDSPECNAME}', $CredSpecName `
        -replace '\${NAMESPACE}', $Namespace `
        -replace '\${SERVICEACCOUNTNAME}', $ServiceAccount
}

$tempOutFile = "newclusterrole.yaml"
Out-File -FilePath $tempOutFile -InputObject $clusterRole -Force

if ($DryRun) {
    Write-Output ("Cluster role file for credspec :{0} is generated at : {1}" -f $CredSpecName, $tempOutFile)
} else {
    Invoke-Expression -Command "kubectl apply -f $tempOutFile"
    Remove-Item -Path $tempOutFile -Force
}