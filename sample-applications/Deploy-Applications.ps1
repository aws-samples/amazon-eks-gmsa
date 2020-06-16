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
Deploys a two tier application with gMSA credential spec.

.SYNOPSIS
Creates a secret for SA password and deploys ASP .NET core webapplication 
and bookstore database.

.PARAMETER Namespace
The kubernetes namespace to target.

.PARAMETER ServiceAccount
The application service account.

.PARAMETER CredSpecResourceName
The name of credentialspec resource deployed to eks.

.PARAMETER SQLSAPassword
The sql server SA password that will be created as 
kubernetes secret "mssql/SA_PASSWORD"

.PARAMETER GMSAUser
The gMSA user name to be added to SQL server.
It will be in the form of netbiosname\gMSAUser$.
Example : gMSA\foouser$

.PARAMETER MVCSampleApp
Path to sample ASP .NET Core front end web application template file.

.PARAMETER BookstoreDBApp
Path to sample bookstore database backend application template file.

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

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SQLSAPassword,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$GMSAUser,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$MVCSampleApp = 'containermvc-web.yaml',

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$BookstoreDBApp = 'containersql-bookstore.yaml',

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

if (!(Get-Command -Name 'kubectl' -ErrorAction:SilentlyContinue)) {
    throw 'kubectl not found'
}

Write-Output "Creating eks secret mssql/SA_PASSWORD"
Invoke-Expression -Command "kubectl create secret generic mssql -n $Namespace --from-literal=password=`"$SQLSAPassword`""

Write-Output "Deploy Bookstore sql db application"
$applicationContent = (Get-Content -Path $BookstoreDBApp) | Foreach-Object {
    $_ -replace '\${NAMESPACE}', $Namespace `
        -replace '\${CREDSPECRESOURCE}', $CredSpecResourceName `
        -replace '\${SERVICEACCOUNTNAME}', $ServiceAccount `
        -replace '\${GMSAUSER}', $GMSAUser
}

$tempFile = [System.IO.Path]::Combine($PSScriptRoot, "bookdb.yaml")
Out-File -FilePath $tempFile -InputObject $applicationContent -Force

if($DryRun) {
    Write-Output ("Bookstore database application deployment file is generated at :{0}" -f $tempFile)
} else {
    Write-Output ("Deplying Bookstore database application.")
    Invoke-Expression -Command "kubectl apply -f $tempFile"
    Remove-Item -Path $tempFile -Force
}

$applicationContent = (Get-Content -Path $MVCSampleApp) | Foreach-Object {
    $_ -replace '\${NAMESPACE}', $Namespace `
        -replace '\${CREDSPECRESOURCE}', $CredSpecResourceName `
        -replace '\${SERVICEACCOUNTNAME}', $ServiceAccount
}

$tempFile = [System.IO.Path]::Combine($PSScriptRoot, "mvc.yaml")
Out-File -FilePath $tempFile -InputObject $applicationContent -Force

if($DryRun) {
    Write-Output ("ASP .NET Core mvc application deployment file is generated at :{0}" -f $tempFile)
} else {
    Write-Output ("Deploying ASP .NET Core mvc application.")
    Invoke-Expression -Command "kubectl apply -f $tempFile"
    Remove-Item -Path $tempFile -Force
}