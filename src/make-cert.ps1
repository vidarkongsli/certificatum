#requires -version 3
param (
    [ValidateSet('RootCA','ServerAuth')]
    [Parameter(Mandatory=$true)]
    $type,

    [Parameter(Mandatory=$true)]
    $outfile,

    [Parameter(Mandatory=$true)]
    #[ValidateScript({-not($_ -match '-|,|.|;')})]
    $subject,
    [Parameter(Mandatory=$false)]
    [ValidateScript({[System.Xml.XmlConvert]::ToTimeSpan($_)})]
    $validityPeriod = (New-TimeSpan -Days 365),
    
    [Parameter(Mandatory=$false)]
    $infile = $null
    )

$ErrorActionPreference = 'Stop'
get-command makecert -ErrorAction SilentlyContinue 2>&1 | out-null
if (!$?) {
    Write-Error "Makecert.exe not found in the path. Install Visual Studio."
}
get-command pvk2pfx -ErrorAction SilentlyContinue 2>&1 | out-null
if (!$?) {
    Write-Error "pvk2pfx.exe not found in the path. Install Visual Studio."
}

if ($type -eq 'ServerAuth') {
    if (-not($infile)) {
        Write-Error "You have to specify CA key file (.pvk) to use for signing the certificate"
    }
    if (-not(test-path -Path "$infile.pvk" -PathType Leaf)) {
        Write-Error "$infile.pvk not found."
    }
    if (-not(test-path -Path "$infile.cer" -PathType Leaf)) {
        Write-Error "$infile.cer not found."
    }
}

$pfxFile = "$outfile.pfx"
$cerFile = "$outfile.cer"
$pvkFile = "$outfile.pvk"

if (test-path $pfxFile -PathType Leaf) {
    Write-Error "File $pfxFile already exists. So quitting."
}

if (test-path $cerFile -PathType Leaf) {
    Write-Error "File $cerFile already exists. So quitting."
}

if (test-path $pvkFile -PathType Leaf) {
    Write-Error "File $pvkFile already exists. So quitting."
}

$validityStart = get-date
$validityEnd = $validityStart.Add($validityPeriod)

function format ($d) { $d.ToString("MM") + '/' + $d.ToString("dd") + '/' + $d.ToString("yyyy")}

if ($type -eq 'RootCA') {
    $params = "makecert -r -n ""$subject"" -pe -sv ""$pvkFile"" -a sha1 -len 2048 -b $(format $validityStart) -e $(format $validityEnd) -cy authority ""$cerFile"""
} else {
    $params = "makecert.exe -iv ""$infile.pvk"" -ic ""$infile.cer"" -n ""$subject"" -pe -sv ""$pvkFile"" -a sha1 -len 2048 -b $(format $validityStart) -e $(format $validityEnd) -sky exchange ""$cerFile"" -eku 1.3.6.1.5.5.7.3.1"
}
& cmd /c $params

if ($?) {
    & cmd /c "pvk2pfx -pvk ""$pvkFile"" -spc ""$cerFile"" -pfx ""$pfxFile"""
}

#makecert.exe -r -n "CN=UDIR.PAS2.Dev.RootCA" -pe -sv UDIR.PAS2.Dev.RootCA.pvk -a sha1 -len 2048 -b 09/25/2014 -e 09/25/2024 -cy authority UDIR.PAS2.Dev.RootCA.cer

#makecert.exe -iv UDIR.PAS2.Dev.RootCA.pvk -ic UDIR.PAS2.Dev.RootCA.cer -n "CN=UDIR.PAS2.Dev.Id" -pe -sv UDIR.PAS2.Dev.Id.pvk -a sha1 -len 2048 -b 09/25/2014 -e 09/25/2024 -sky exchange UDIR.PAS2.Dev.Id.cer -eku 1.3.6.1.5.5.7.3.1
