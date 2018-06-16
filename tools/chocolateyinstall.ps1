$ErrorActionPreference = 'Stop'

$url       = 'https://artifacts.elastic.co/downloads/kibana/kibana-oss-6.3.0-windows-x86_64.zip'
$checksum  = '675cc4d3fbeb2a1df4dca4338dfbb811a85d980ca9edb0107803afcce24b7f09a8209280764a6ca426921b20a81e5d58544b35db03b5a4b4744b77874b2ab6bf'

$packageArgs = @{
    packageName     = $env:ChocolateyPackageName
    url64bit        = $url
    checksum64      = $checksum
    checksumType64  = 'sha512'
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
