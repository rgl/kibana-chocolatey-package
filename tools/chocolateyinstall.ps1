$ErrorActionPreference = 'Stop'

$url       = 'https://artifacts.elastic.co/downloads/kibana/kibana-6.2.4-windows-x86_64.zip'
$checksum  = 'd9fe5dcb8d4d931317d25c16ccaf2e8dbc6464eb1dd22d081c33822d2993dab4'

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
