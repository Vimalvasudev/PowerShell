function logintest(){
$err=@{}
$headers=@{}
$user=Read-host "Enter username for the cluster"
$pass=Read-host "Enter password for user",$user 
#$user ="adm_kvvi3@eu.novartis.net"
#$pass= "Welcome@07novartis"
#$secpasswd = ConvertTo-SecureString $pass -AsPlainText -Force
#$credential = New-Object System.Management.Automation.PSCredential($user, $pass)
$credPair = "$($user):$($pass)"
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
$headers = @{ Authorization = "Basic $encodedCredentials" }
$LoginUri = "https://"+$ip+":4443"+'/login'
Write-Host ".........Validating credentials.........." -ForegroundColor Yellow
try
{
$request=Invoke-WebRequest -Uri $LoginUri -Method get -SessionVariable session -Headers $headers
$token=$request.Headers.'X-SDS-AUTH-TOKEN'
$headers.add('X-SDS-AUTH-TOKEN', $token)
}
catch
{$err.err=$_.Exception.Message}
return ($err,$headers)}

Write-Host "********************************************************************************************"
Write-Host "This is a script to validate if the isilon files are smart linked or not" -ForegroundColor cyan -BackgroundColor black
Write-Host "********************************************************************************************"
$ip=Read-host "Enter ip address of the cluster"
$err,$headers=logintest $ip


<#$ip = '10.241.207.93'  
$LoginUri = "https://"+$ip+":4443"+'/login'
$l2 = "https://"+$ip+":4443"+'/object/capacity'
$l3="https://"+$ip+":4443"+'/vdc/alerts/latest'
$l4="https://"+$ip+":4443"+'/dashboard/zones/localzone/disks' 


$c=Invoke-RestMethod -Uri $l3 -Method get -Headers $headers
$c.alerts.alert.'description'

#disk
$d._embedded._instances |select nodeDisplayName,ssmL1Status,slotid
'#>