param(
    [string]$ip = "",
    [string]$port = "5000"
)

if ([string]::IsNullOrWhiteSpace($ip)) {
    $ip = (
        Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.InterfaceAlias -notmatch "Loopback|vEthernet|VirtualBox|VMware|Hyper-V" -and
            $_.IPAddress -ne "127.0.0.1" -and
            $_.PrefixOrigin -in @("Dhcp", "Manual")
        } |
        Select-Object -First 1
    ).IPAddress

    if (-not $ip) {
        $ip = (
            Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object {
                $_.InterfaceAlias -notmatch "Loopback|vEthernet|VirtualBox|VMware|Hyper-V" -and
                $_.IPAddress -ne "127.0.0.1"
            } |
            Select-Object -First 1
        ).IPAddress
    }
}

if (-not $ip) {
    Write-Host "ERROR: Tidak bisa mendeteksi IP lokal!" -ForegroundColor Red
    Write-Host "Gunakan manual: .\run.ps1 -ip 192.168.x.x -port 3000" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "  PinjamIN Mobile" -ForegroundColor Cyan
Write-Host "  Server IP : $ip" -ForegroundColor Green
Write-Host "  Port      : $port" -ForegroundColor Green
Write-Host ""

flutter run --dart-define="SERVER_IP=$ip" --dart-define="SERVER_PORT=$port"