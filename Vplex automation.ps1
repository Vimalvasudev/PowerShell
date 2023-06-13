function Ignore-SelfSignedCerts{
    try
    {

        Write-Host "Adding TrustAllCertsPolicy type." -ForegroundColor White
        Add-Type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy
        {
             public bool CheckValidationResult(
             ServicePoint srvPoint, X509Certificate certificate,
             WebRequest request, int certificateProblem)
             {
                 return true;
            }
        }
"@

        Write-Host "TrustAllCertsPolicy type added." -ForegroundColor White
      }
    catch
    {
        Write-Host $_ -ForegroundColor "Yellow"
    }

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
function logintest(){
Ignore-SelfSignedCerts
$err=@{}
$header=@{}
$uname=Read-host "Enter username for",$vplex
$pw=Read-host "Enter password for user",$uname -AsSecureString
$pwd=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw))
$header = @{'Username' = $uname; 'Password' = $pwd}
$url="https://$vplex/vplex/cluster+summary"
Write-Host ".........checking credentials.........." -ForegroundColor Yellow
try
{
$x=Invoke-WebRequest -Uri $url -Method post -Header $header -UseBasicParsing
}
catch
{$err.err=$_.Exception.Message}
$err.header=$header
return ($err)
}
function compare {
$o=import-csv "$fpath\$k.csv"
$errindex=@{}
foreach ($lin in $o) {
if($lin.vvwwn -eq $lin.cvvwwn){write-host $lin.index ,"matches"}
else {$errindex+=$lin.index}
}
write-host {"WWPN under the index are not same " }
write-host {$errindex}
}
function unmap (){
Write-Host "   "
$o=import-csv "$fpath\$k.csv"
foreach ($lin in $o) {
$a1,$a2,$a3=$null
if($lin.mv1){$a1=$lin.mv1}  
if($lin.mv2){$a2=",",$lin.mv2} 
if($lin.mv3){$a3=",",$lin.mv3} 
write-host " removevirtualvolume --virtual-volumes ",$lin.vvolname," --view "$a1 $a2 $a3}
}
function dismantle(){
Write-Host "   "
$o=import-csv "$fpath\$k.csv"
foreach ($lin in $o) {
write-host "advadm dismantle --virtual-volumes" $lin.vvolname "--unclaim-storage-volumes -f --verbose"
}
}
function collect () {
$Vplex1='USCA-VPLEX1P'
$vplex2='USCA-VPLEX1D'
$vplex3='CHBS-VPLEX1P'
$vplex4='CHBS-VPLEX1D'
Write-Host "Choose the Vplex from below list and provide the login credentials `n1. USCA-VPLEX1P `n2. USCA-VPLEX1D `n3. CHBS-VPLEX1P `n4. CHBS-VPLEX1D "
$i=read-host "Enter your selection "
$vplex=get-variable -name vplex$i -ValueOnly
$err=logintest $vplex
while ($err.err){
Write-host "Login failed with error:",$err.err, `n"  Re-enter credentials"
$err=logintest $vplex
}
if (!$err.err){write-host 'Login success'}
$header=$err.header 
#create csv file
$fpath=$home
$k=read-Host -prompt "Please enter the ticket number for decomm in 'IT-XX' format "
if (test-path $fpath\$k.csv ) {write-host "csv file ",$k,"exist" -foregroundcolor red } 
else {Set-Content "$fpath\$k.csv" -Value "Index,vvolname,Custwwn,VVWWN,SWWN,MV1,MV2,MV3"}
write-host "The CSV file will now open in your window, please populate tabs with Vplex volume name or virtual volume wwn which needs deletion. `nSave and close once done, file will be saved in user home directory" -ForegroundColor Yellow
$l=read-host -prompt "Are you ready(Enter yes or no)"
if ($l -eq 'No' -or $l -eq 'n') {exit} else {start $fpath\$k.csv}
write-host "Waiting for the file to be saved and closed" -ForegroundColor Yellow
Read-Host "Press any key to start..." 
write-host "Working on data collection now........" -ForegroundColor Green

#collecting masking view and wwn details

$o=import-csv "$fpath\$k.csv"
foreach ($lin in $o) {$lu=$lin.vvolname
#drill-down
$dr="https://$vplex/vplex/drill-down"
$vol=@{"args"="-o $lu"} |ConvertTo-Json
$w=Invoke-RestMethod -uri $dr -Method post -Headers $header -UseBasicParsing -Body $vol
$q=($w.response.'custom-data').split("`n").trim()
foreach ($ku in $q) {if (($ku -match 'local-device') -and ($ku -match 'cluster-\d'))
 {$clu=$matches[0]}}
#$lu='nrchbs-slt0040_VMWare-ESX_data_001'
$her="https://"+$vplex+":443/vplex/show-use-hierarchy"
$vvol=@{"args"="clusters/$clu/virtual-volumes/$lu"} |ConvertTo-Json
$pp=Invoke-RestMethod -uri $her -Method post -Headers $header -UseBasicParsing -Body $vvol
$v=$pp.response.'custom-data'
$s=$v.Split("`n").trim()
#$c=Select-String -InputObject $s -Pattern 'storage-view' -AllMatches
$sv=@()
foreach ($line in $s) {if ($line -match 'storage-view')
 {$x=[regex]::match($line,"(?<=: ).+?(?=0m)").value.trim('[')
 $sv+=$x
 }}
foreach ($line in $s) {if ($line -match 'logical-unit'){$pv= [regex]::match($line,"(?<=: ).+?(?=0m)").value.trim('[')}}
foreach ($line in $s) {if ($line -match 'storage-array'){$array= [regex]::match($line,"(?<=: ).+?(?=0m)").value.trim('[')}}
#Collect wwpn of devices and update to excel sheet directly from VPLEX.
$vvl="https://"+$vplex+":443/vplex/clusters/$clu/virtual-volumes/$lu"
$a=Invoke-RestMethod -Uri $vvl -Method get -Header $header -UseBasicParsing
$vpid=((($a.response.context.attributes |where name -eq vpd-id).value).split(":")[1])
$lin.vvwwn='VPD83T3:'+$vpid.trim()
$lin.swwn=$pv.trim('')
if ($sv[0]) {$lin.MV1=$sv[0].trim()}
if ($sv[1]) {$lin.MV2=$sv[1].trim()}
if ($sv[1]) {$lin.MV3=$sv[2].trim()}
#if ($sv.count -eq 4 ) {$line | Select *,@{Name="MV4";Expression={"$sv[2]"}} |Export-Csv "$home\$k.csv" -NoTypeInformation}
}
#Saving contents to CSV
$o |Export-Csv "$fpath\$k.csv" -NoTypeInformation
Write-host "Data collection completed. The csv file" $fpath\$k "will open in some time" -ForegroundColor Cyan
start $fpath\$k.csv
}
Write-Host "********************************************************************************************"
Write-Host "This is a script to collect VPLEX local device details and generate scripts for decommission" -ForegroundColor cyan -BackgroundColor black
Write-Host "********************************************************************************************"
#Login and credential verification stage
$fpath=$HOME
write-host "Below options are available `n`n1.Collect volume details from Vplex `n2.Compare collected volums wwn `n3.Prepare unmap script `n4.Prepare dismantle script"
write-host ".................."
$sel=read-host "Input the selection"
if ($sel -eq 1 ) {
collect}
elseif ($sel -eq 2 ) {
Write-host "This step will verify the virtual volume wwn if provided by customer against the script collected wwn's, Skip if not required"
$check= Read-host -prompt "Press Yes or else No to skip the verification"
If ($check -eq 'y' -or $check -eq 'Yes' ) {
compare $fpath $k}}
elseif ($sel -eq 3){
Write-host "This step will generate scripts for virtual lun unmap based on populated csv, Skip if not required" -foregroundcolor cyan
$check= Read-host -prompt "Press Yes or else No to skip the step"
If ($check -eq 'y' -or $check -eq 'Yes' ) {
$k=read-host "Enter the file name in csv format"
unmap $fpath $k}
}
elseif ($sel -eq 4) {
write-host "This step will generate tear down script for vvols based on the populated csv sheet, skip if not required" -ForegroundColor Cyan
$check= Read-host -prompt "Press Yes or else No to skip the step"
If ($check -eq 'y' -or $check -eq 'Yes' ) {
$k=Read-Host "Enter the file name in csv format"
dismantle $fpath $k}}
