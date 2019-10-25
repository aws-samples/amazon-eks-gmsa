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
Patches coredns configmap to add Active Directory DNS servers.

.SYNOPSIS
Patches the existing coredns config file and restarts the coredns pods.

.PARAMETER ActiveDirectoryDNS
Active Directory DNS name.

.PARAMETER DNSServerIPs
One or more DNS server IPs separated by space.

.PARAMETER CorednsTemplateConfig
Coredns confgimap template file with Active Directory settings.

.PARAMETER DryRun
A switch that, when enabled, will generate the patch for the coredns configmap.
It will return the config yaml content rather than applying it to the cluster.
#>

[CmdLetBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ActiveDirectoryDNS = 'gmsa.corp.com',

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DNSServerIPs,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$CorednsTemplateConfig = "patch-coredns-template.yaml",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

if (!(Get-Command -Name 'kubectl' -ErrorAction:SilentlyContinue)) {
    throw 'kubectl not found'
}

$patchContent = (Get-Content -Path $CorednsTemplateConfig) | ForEach-Object {
    $_ -replace '\${ACTIVEDIRECTORYDNS}', $ActiveDirectoryDNS `
       -replace '\${DNSSERVERIPS}', $DNSServerIPs
}

$tempFile = [System.IO.Path]::Combine($PSScriptRoot, "patch.yaml")
Out-File -FilePath $tempFile -InputObject $patchContent -Force
if($DryRun) {
    Write-Output ("coredns patch content is generated at :{0}" -f $tempFile)
} else {
    Write-Output ("Applying coredns patch.")
    Invoke-Expression -Command "kubectl apply -f $tempFile"
    Remove-Item -Path $tempFile -Force
    Write-Output "Restarting coredns pods."
    Invoke-Expression -Command "kubectl delete pods -n kube-system -l  eks.amazonaws.com/component=coredns"
}