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
Builds a containersql-bookstore and containermvc-web container images locally.
#>
Write-Information "Downloading amazon-eks-gmsa github repo as an archive"
wget https://github.com/aws-samples/amazon-eks-gmsa/archive/master.zip -o amazon-eks-gmsa.zip
Write-Information "Expanding the archive"
Expand-Archive -Path ./amazon-eks-gmsa.zip -DestinationPath ./amazon-eks-gmsa -Force
Write-Information "Building sql server image containersql-bookstore:latest"
pushd ./amazon-eks-gmsa/amazon-eks-gmsa-master/sample-applications/backend-sql-server/
docker build . -t containersql-bookstore:latest
Write-Information "Building sql server image containermvc-web:latest"
popd 
pushd ./amazon-eks-gmsa/amazon-eks-gmsa-master/sample-applications/frontend-mvc/
docker build . -t containermvc-web:latest
popd
Remove-Item -Force -Recurse ./amazon-eks-gmsa