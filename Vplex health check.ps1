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

$uname='service'
$pwd1='xxxx'
$pwd3='xxx'
$pwd4='xxxx'
$Vplex1='usca-vplex1p'
$vplex3='chbs-vplex1p'
$vplex4='chbs-vplex1d'
foreach($i in 1,3,4)
{
$vplex=get-variable -name vplex$i -ValueOnly
$pwd=get-variable -name pwd$i -ValueOnly
$url="https://$vplex/vplex/cluster+summary"
$header = @{'Username' = $uname; 'Password' = $pwd}
$x=Invoke-WebRequest -Uri $url -Method post -Header $header -UseBasicParsing
$y=$x.Content.split('\')[1,4].trim('\n')
$y[1]|where { $_ -match '[A-Z]{3}\d+'} 
$z=$matches[0]
$bod=$y|Out-String
if ($z-eq 'FNM00141100304') {$a='usca-vplex1p'} elseif ($z='CKM00142000953') {$a='chbs-vplex1p'} elseif ($z='CKM00142000964') {$a='chbs-vplex1d'}
Send-MailMessage -From "vimal_kumar.k_v@novartis.com" -To "vimal_kumar.k_v@novartis.com" -Subject $a -Body $bod -SmtpServer "mail.novartis.com"
}
