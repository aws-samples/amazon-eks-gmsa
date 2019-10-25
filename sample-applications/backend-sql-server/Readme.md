# Bookstore SQL database
This is a sample Bookstore sql database hosted in container.

## Building Bookstore sql container image
# Download SQL Server 2017 express edition to current folder
```
wget https://go.microsoft.com/fwlink/?linkid=853017 -o SQLEXPR_x64_ENU
docker build . -t bookstoresqldb:latest
```

## Pushing container image to ECR
```
docker tag bookstoresqldb:latest *****.dkr.ecr.us-west-2.amazonaws.com/bookstoresqldb:latest
# ECR login
$(aws ecr get-login --no-include-email --region us-west-2) OR Invoke-Expression -Command (Get-ECRLoginCommand -Region us-west-2).Command
docker push *****.dkr.ecr.us-west-2.amazonaws.com/bookstoresqldb:latest
```

## Running bookstoresqldb with gMSA
```
# Update the Environment variables for SQL sa password and gmsa_user. gMSA user format is domain\gMSAusername$
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=*****"  -e "gmsa_user=gmsa\foouser1$" -p 1434:1433 -d *****.dkr.ecr.us-west-2.amazonaws.com/bookstoresqldb:latest
```
# During the startup, start.ps1 will be executed which will create Bookstore database with Books table. 

## Connecting to SQL server
```
SQL server Name : <<hostname>>,1434
Authentication  : SQL Server Authentication
User Name : sa
Password : *****
```