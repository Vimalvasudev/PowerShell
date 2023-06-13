$Isilon ='192.168.245.150'
$KeyFile ='C:\scripts\ssh.key'
New-SshSession -ComputerName $Isilon -Credential root -KeyFile $KeyFile