# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
Deploys an application which opens only with gMSA credential spec.

.SYNOPSIS
Deploys windows iis server which shows authentication dialog box asking for username
and password.

.PARAMETER Namespace
The kubernetes namespace to target.

.PARAMETER ServiceAccount
The application service account.

.PARAMETER CredSpecResourceName
The name of credentialspec resource deployed to eks.

.PARAMETER WindowsServerApp
Path to sample Windows IIS Server web application template file.

.PARAMETER DryRun
A switch that, when enabled, will generate the artifacts and pre-requisites for
deploying the applications, but will return the config yaml content
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
    [string]$CredSpecResourceName,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$WindowsServerApp = 'windows-server-iis.yaml',

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

if (!(Get-Command -Name 'kubectl' -ErrorAction:SilentlyContinue)) {
    throw 'kubectl not found'
}

Write-Output "Deploy Windows IIS Server with Authentication web app"
$applicationContent = (Get-Content -Path $WindowsServerApp) | Foreach-Object {
    $_ -replace '\${NAMESPACE}', $Namespace `
        -replace '\${CREDSPECRESOURCE}', $CredSpecResourceName `
        -replace '\${SERVICEACCOUNTNAME}', $ServiceAccount 
}

$tempFile = [System.IO.Path]::Combine($PSScriptRoot, "iis.yaml")
Out-File -FilePath $tempFile -InputObject $applicationContent -Force

if($DryRun) {
    Write-Output ("Windows IIS Server application deployment file is generated at :{0}" -f $tempFile)
} else {
    Write-Output ("Deploying Windows IIS Server application.")
    Invoke-Expression -Command "kubectl apply -f $tempFile"
    Remove-Item -Path $tempFile -Force
}