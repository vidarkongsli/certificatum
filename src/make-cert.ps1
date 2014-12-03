#requires -version 3
param (
    [ValidateSet('RootCA')]
    [Parameter(Mandatory=$true)]
    $type,

    [Parameter(Mandatory=$true)]
    $file,

    [Parameter(Mandatory=$true)]
    #[ValidateScript({-not($_ -match '-|,|.|;')})]
    $subject,
    [Parameter(Mandatory=$false)]
    [ValidateScript({[System.Xml.XmlConvert]::ToTimeSpan($_)})]
    $validityPeriod = (New-TimeSpan -Days 365)
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

$pfxFile = "$file.pfx"
$cerFile = "$file.cer"

if (test-path $pfxFile -PathType Leaf) {
    Write-Error "File $pfxFile already exists. So quitting."
}

if (test-path $cerFile -PathType Leaf) {
    Write-Error "File $cerFile already exists. So quitting."
}

$tempFileName = [System.IO.Path]::GetRandomFileName()

function format ($d) { $d.ToString("MM") + '/' + $d.ToString("dd") + '/' + $d.ToString("yyyy")}

$validityStart = get-date
$validityEnd = $validityStart.Add($validityPeriod)

$params = "makecert -r -n ""$subject"" -pe -sv ""$tempFileName"" -a sha1 -len 2048 -b $(format $validityStart) -e $(format $validityEnd) -cy authority ""$cerFile"""
$params2 = "pvk2pfx -pvk ""$tempFileName"" -spc ""$cerFile"" -pfx ""$pfxFile"""
if ($type -eq 'RootCA') {
    & cmd /c $params
    if ($?) {
        & cmd /c $params2
    }
}

if (test-path $tempFileName) { del $tempFileName}


#makecert.exe -r -n "CN=UDIR.PAS2.Dev.RootCA" -pe -sv UDIR.PAS2.Dev.RootCA.pvk -a sha1 -len 2048 -b 09/25/2014 -e 09/25/2024 -cy authority UDIR.PAS2.Dev.RootCA.cer
