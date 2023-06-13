#''', simplfy links,error handling'''
#$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)


#Base details here.

$appsyncServer = '192.168.245.129'
$burl="https://"+$appsyncServer+":8445/appsync/rest"
 
  
add-type @"  
    using System.Net;  
    using System.Security.Cryptography.X509Certificates;  
    public class TrustAllCertsPolicy : ICertificatePolicy {  
        public bool CheckValidationResult(  
            ServicePoint srvPoint, X509Certificate certificate,  
            WebRequest request, int certificateProblem) {  
            return true;  
        }  
    }  
"@  
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy  
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
[string]$LoginUri = "https://"+$appsyncServer+":8444/cas-server/login?TARGET=https://"+$appsyncServer+":8445/appsync/"  
$request = Invoke-WebRequest -Uri $LoginUri -SessionVariable session  

#Login to the CAS server
#password encryption ->"password" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File xxx.txt
$securestring = convertto-securestring -string (get-content sec.txt)
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
$pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
$form = $request.Forms[0]  
$form.Fields["username"] = 'admin'  
$form.Fields["password"] = $pass  
$request = Invoke-RestMethod -Uri $LoginUri -WebSession $session -Method POST -Body $form.Fields  

# Done with authentication!  
#[string]$RestUri = $burl+"/types/servicePlan/instances"  
#[string]$RestUri = $burl+"/types/servicePlan/instances?application=sql&name=sql silver"  
#$result = Invoke-RestMethod -Uri $RestUri -WebSession $session -Method GET

[string]$geturi=$burl+"/types/servicePlan/instances?application=filesystem&displayName=Test"
$result1 = Invoke-RestMethod -Uri $getUri -WebSession $session -Method GET
$inst=($result1.feed.entry.id -split '::')[1]
#write-host 'Service Plan Instance name is',$inst
<#

#identify current date and run the schedule.
$cud=get-date
$Som = Get-Date -day 1 -hour 0 -minute 0 -second 0
$Eom=(($som).AddMonths(1).AddSeconds(-1))
#if ($cud.Day -eq $eom.day) {Write-Host 'Last day of month'} else { write-host 'Not the last day'}
#$run=$burl+"/instances/servicePlan::$inst/action/run"
#$result= Invoke-RestMethod -uri $run -WebSession $session -method post -ErrorAction SilentlyContinue
#$error[0].ErrorDetails.Message -> list errors 
#>

<# Detailing SP to get mount host inf

$t=$burl+"/instances/servicePlan::"+$inst+"/relationships/phases"
#$t=$burl+"/instances/servicePlan::"+$inst+"?format=xml"
$test=Invoke-RestMethod -Uri $t -WebSession $session -Method Get
$t2=$burl+"instances/phase::be1bab84-0569-486a-af19-9f3f5e99e662"
$test2=Invoke-RestMethod -Uri $t2 -WebSession $session -Method Get
#($test.serviceplan.phase.options.option)[25].value

#>
<#

#creating user : Needs two roles
$userlist=$Burl+"/types/user/instances"
$k=@{
    name='user1234'
    password='Welcome@01'
    type='local'
    role='Data Administrator','Resource Administrator'}
$l=$k |ConvertTo-Json
$j=Invoke-RestMethod -uri $userlist -WebSession $session -Method post -Body $l -ContentType 'application/json'
#>
$userlist=$Burl+"/types/user/instances?username=admin"

<#
#check user exist
$user='test1'
$feed=Invoke-RestMethod -Uri $userlist -WebSession $session -Method GET
if($feed.feed.entry.title -eq $user) {write-host $user ,'exist in the system'  
 #Collect user instance 
 $userinst=(($feed.feed.entry)|Where-Object {$_."title" -eq $user})
 Write-Host 'Instance for',$user,'is',$userinst.id
 #check user is part of what roles
 Write-Host 'User:',$user,'is part of group:',$userinst.content.user.role}
else {write-host 'User: ',$user,'Not found in system'} 
#deleting an user using instance
#Invoke-RestMethod -Method Delete -Uri $userinst.id -WebSession $session
#>







