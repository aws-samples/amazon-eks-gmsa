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

[CmdLetBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DeploymentTemplateFilePath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName = 'webhook-svc',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace = 'kube-system',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SecretName = 'webhook-certs',

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFilePath
)

if (!(Get-Command -Name 'kubectl' -ErrorAction:SilentlyContinue)) {
    throw 'kubectl not found'
}

Write-Verbose 'Getting CA bundle'
$cmd = 'kubectl config view --raw -o json --minify'
Write-Verbose $cmd
[string]$ret = Invoke-Expression -Command $cmd
$kubeConfig = ConvertFrom-Json -InputObject $ret
$clusterConfig = $kubeConfig.clusters[0].cluster
$CaBundle = $clusterConfig."certificate-authority-data"

# Get the Server's Kubernetes Version
$cmd = 'kubectl version --short=true -o json'
[string]$ret = Invoke-Expression -Command $cmd
$fullVersion = ConvertFrom-Json -InputObject $ret
$serverVersion = $fullVersion.serverVersion.minor

$webhookVersion = 'latest'
if ($serverVersion -lt 16) {
    $webhookVersion='v1.14'
}

Write-Verbose 'Constructing new deployment YAML content'
$newTemplate = (Get-Content -Path $DeploymentTemplateFilePath) | ForEach-Object {
    $_ -replace '\${CA_BUNDLE}', $CaBundle `
       -replace '\${NAME}', $ServiceName `
       -replace '\${SECRETNAME}', $SecretName `
       -replace '\${NAMESPACE}', $Namespace `
       -replace '\${WEBHOOKIMAGE}', $webhookVersion
}

Write-Verbose ('Updating deployment YAML: {0}' -f $OutputFilePath)
Write-Verbose ($newTemplate | Out-String)
Out-File -FilePath $OutputFilePath -InputObject $newTemplate -Force -Confirm:$false