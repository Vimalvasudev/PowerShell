function Ignore-SelfSignedCerts
{
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
Ignore-SelfSignedCerts

$username = "root"
$password = "Hello321"
$EncodedAuthorization = [System.Text.Encoding]::UTF8.GetBytes($username + ':' + $password)
$EncodedPassword = [System.Convert]::ToBase64String($EncodedAuthorization)
$headers = @{"Authorization"="Basic $($EncodedPassword)"}
# create Uri
$burl ='https://192.168.245.150'+":8080" 
$r1 = "/platform/3/event/eventlists"
$r2= "/platform/1/protocols/smb/shares?zone=System"
$r3="/namespace/ifs/test1/file1.txt?metadata"
$uri = $burl + $r3
$out=Invoke-RestMethod -Uri $uri -Method get -Headers $headers 
($out.attrs | where { $_.Name -eq "stub" }).value
#$out.eventlists.events | where {$_.severity -eq 'critical'} |Select -ExpandProperty message


