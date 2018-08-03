$ErrorActionPreference = 'Stop'

$url       = 'https://artifacts.elastic.co/downloads/kibana/kibana-oss-6.3.2-windows-x86_64.zip'
$checksum  = '50f1b3dfd454f1c74a4256fb46d5d8adcd4b8c067a1e6195c897e64178084daa53be5c97b47c490255701f92da0394f960741da8bd481ac7aaf01684eb71407b'

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
