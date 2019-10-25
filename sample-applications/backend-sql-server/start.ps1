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
#
# The script sets the sa password and start the SQL Service 
# It creates a BookStore Database for the gMSA demo
# It also adds gMSA account to the DB with Sysadmin privilege

param(
[Parameter(Mandatory=$false)]
[string]$sa_password,

[Parameter(Mandatory=$false)]
[string]$ACCEPT_EULA,


[Parameter(Mandatory=$false)]
[string]$gMSA_User
)


if($ACCEPT_EULA -ne "Y" -And $ACCEPT_EULA -ne "y")
{
	Write-Verbose "ERROR: You must accept the End User License Agreement before this container can start."
	Write-Verbose "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."

    exit 1 
}

$hostname = Invoke-Expression -Command "HostName"

# start the service
Write-Verbose "Starting SQL Server on host : $hostname"
start-service MSSQL`$SQLEXPRESS

if($sa_password -eq "_") {
    $secretPath = $env:sa_password_path
    if (Test-Path $secretPath) {
        $sa_password = Get-Content -Raw $secretPath
    }
    else {
        Write-Verbose "WARN: Using default SA password, secret file not found at: $secretPath"
    }
}

if($sa_password -ne "_")
{
    Write-Verbose "Changing SA login credentials"
    $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $sa_password + "'" + ";ALTER LOGIN sa ENABLE;"
    & sqlcmd -S "$hostname" -Q "$sqlcmd"
}


Write-Verbose "Started SQL Server."


$sqlcmd = "CREATE LOGIN [$gMSA_User] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [$gMSA_User]

GO
CREATE DATABASE Bookstore
GO
USE Bookstore
GO
CREATE TABLE [dbo].[Books]
	(
	[Id] INT NOT NULL PRIMARY KEY Identity,
	[Title] varchar(50) Not Null,
	[AuthorFirstName] varchar(50) Not Null,
	[AuthorLastName] varchar(50) Not Null,
	[AvgCustomerReviews] INT,
	[Price] numeric(9,2),
	[BookLanguage] varchar(10) Not Null,
	[Publisher] varchar(255) Not null,
	[CreatedBy] varchar(255) Not Null DEFAULT SUSER_SNAME(),
	[CreatedOn] DateTime Not Null DEFAULT GetDATE()
	);
	
	
	INSERT INTO Books(Title, AuthorFirstName, AuthorLastName, AvgCustomerReviews, Price, BookLanguage, Publisher) VALUES ('Beneath a Scarlet Sky: A Novel', 'Mark', 'Sullivan', 26944, 14.00, 'English', 'Lake Union Publishing (May 1, 2018)')
	INSERT INTO Books(Title, AuthorFirstName, AuthorLastName, AvgCustomerReviews, Price, BookLanguage, Publisher) VALUES ('The Nightingale: A Novel', 'Kristin', 'Hannah', 38900, 8.29, 'English', 'St. Martin''s Griffin; Reprint edition (April 25, 2017)')
	INSERT INTO Books(Title, AuthorFirstName, AuthorLastName, AvgCustomerReviews, Price, BookLanguage, Publisher) VALUES ('We Were the Lucky Ones: A Novel', 'Georgia', 'Hunter', 2553, 9.99, 'English', 'Penguin Books; Reprint edition (February 14, 2017)')
	INSERT INTO Books(Title, AuthorFirstName, AuthorLastName, AvgCustomerReviews, Price, BookLanguage, Publisher) VALUES ('Little Fires Everywhere: A Novel', 'Celeste', 'Ng', 4695, 10.29, 'English', 'Penguin Books (September 12, 2017)')
	INSERT INTO Books(Title, AuthorFirstName, AuthorLastName, AvgCustomerReviews, Price, BookLanguage, Publisher) VALUES ('All the Light We Cannot See: A Novel', 'Anthony', 'Doerr', 28800, 10.79, 'English', 'Scribner; Reprint edition (April 4, 2017)')
	INSERT INTO Books(Title, AuthorFirstName, AuthorLastName, AvgCustomerReviews, Price, BookLanguage, Publisher) VALUES ('Before We Were Yours: A Novel', 'Lisa', 'Wingate', 10849, 10.29, 'English', 'Ballantine Books; Reprint edition (May 21, 2019)')
	INSERT INTO Books(Title, AuthorFirstName, AuthorLastName, AvgCustomerReviews, Price, BookLanguage, Publisher) VALUES ('Then She Was Gone: A Novel', 'Lisa', 'Jewell', 1493, 8.79, 'English', 'Atria Books; Reprint edition (November 6, 2018)')
	INSERT INTO Books(Title, AuthorFirstName, AuthorLastName, AvgCustomerReviews, Price, BookLanguage, Publisher) VALUES ('Where the Crawdads Sing', 'Delia', 'Owens', 23269, 14.29, 'English', 'G.P. Putnam''s Sons; Later Printing edition (August 14, 2018)')
    "
Write-Verbose "Invoke-Sqlcmd -Query $($sqlcmd)"
& sqlcmd -S "$hostname" -Q "$sqlcmd" -U "sa" -P $sa_password

$lastCheck = (Get-Date).AddSeconds(-2) 
while ($true) 
{ 
    Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 
    $lastCheck = Get-Date 
    Start-Sleep -Seconds 2 
}