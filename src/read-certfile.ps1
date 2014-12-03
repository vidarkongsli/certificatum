param (
    [ValidateScript({test-path $_})]
    [Parameter(Mandatory=$true)]
    $file,
    [Parameter(Mandatory=$false)]
    [string]$password = $null
    )
$ErrorActionPreference = 'stop'
$filetype = [System.IO.Path]::GetExtension($file)
if ($filetype -eq '.pfx') {
    if (-not($password)) {
        Write-Error "You have to enter password for .pfx file"
    }
}
$cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @(,(resolve-path $file),$password, 0)
$cert