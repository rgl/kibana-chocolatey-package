$ErrorActionPreference = 'Stop'

$url       = 'https://artifacts.elastic.co/downloads/kibana/kibana-6.2.1-windows-x86_64.zip'
$checksum  = '0628e1c74e7de35f31b00082ed280a39b9680d9206b5784adab428ca88c6b856'

$packageArgs = @{
    packageName     = $env:ChocolateyPackageName
    url64bit        = $url
    checksum64      = $checksum
    checksumType64  = 'sha256'
    unzipLocation   = $env:ChocolateyPackageFolder
}
Install-ChocolateyZipPackage @packageArgs

Move-Item `
    (Resolve-Path "$env:ChocolateyPackageFolder\kibana-*") `
    "$env:ChocolateyPackageFolder\kibana"

# do not create shims.
Get-ChildItem `
    "$env:ChocolateyPackageFolder\kibana" `
    -Include *.exe `
    -Recurse `
    | ForEach-Object {New-Item "$($_.FullName).ignore" -Type File -Force} `
    | Out-Null

$ServiceName = 'kibana'

Write-Host "Installing the $ServiceName service..."

if ($Service = Get-Service $ServiceName -ErrorAction SilentlyContinue) {
    if ($Service.Status -eq "Running") {
        Start-ChocolateyProcessAsAdmin "stop $ServiceName" "sc.exe"
    }
    Start-ChocolateyProcessAsAdmin "delete $ServiceName" "sc.exe"
}

Start-ChocolateyProcessAsAdmin "install $ServiceName $env:ChocolateyPackageFolder\kibana\bin\kibana.bat" nssm
Start-ChocolateyProcessAsAdmin "set $ServiceName Start SERVICE_DEMAND_START" nssm
