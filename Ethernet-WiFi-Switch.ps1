# Config
$ethernetName = "Ethernet"
$wifiName = "WIFI"
$hotspotSSID = "Your Hotspot/Wi-Fi Name"
$maxAttempts = 10   # Connection attempts before giving up 
$timeoutInSeconds = 3   # Timeout if the connection refuses
$switchDelaySeconds = 5     # Countdown before switching adapters
$testUrls = @("http://www.msftconnecttest.com/connecttest.txt", "http://www.google.com", "http://1.1.1.1")

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Wait-ForInternetConnection {
    param (
        [int]$maxWaitSeconds = 30,
        [int]$checkInterval = 2
    )
    
    $waited = 0
    while ($waited -lt $maxWaitSeconds) {
        Write-Host "Testing internet... ($waited/$maxWaitSeconds Seconds)"
        
        if (Test-InternetConnectivity) {
            return $true
        }
        
        Start-Sleep -Seconds $checkInterval
        $waited += $checkInterval
    }
    
    Write-Host "Internet-Tests canceled after  $maxWaitSeconds seconds." -ForegroundColor Yellow
    return $false
}

function Test-InternetConnectivity {
    param (
        [string]$adapterName = $null
    )
    
    Write-Host "Testing Internet connection..."
    
    # Simple Ping Test
    try {
        if (-not (Test-Connection -Count 1 -ComputerName 8.8.8.8 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Host "Ping-Test failed" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "Ping-Test failed" -ForegroundColor Yellow
        return $false
    }
    
    # HTTP-Tests to check if there really is a internet connection
    foreach ($url in $testUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "Internet connection successfully verified via $url" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "HTTP-Test to $url failed: $($_.Exception.Message)" -ForegroundColor Yellow
            continue
        }
    }
    
    Write-Host "All Internet tests failed" -ForegroundColor Red
    return $false
}

function Enable-AdapterAndWait {
    param (
        [string]$adapterName,
        [int]$timeoutSeconds = 15
    )
    Write-Host ""
    Write-Host "Activating adapter '$adapterName'..."
    
    try {
        Enable-NetAdapter -Name $adapterName -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Host "Error while activating '$adapterName': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    $timePassed = 0
    while ($timePassed -lt $timeoutSeconds) {
        try {
            $adapter = Get-NetAdapter -Name $adapterName -ErrorAction Stop
            if ($adapter.Status -ne "Disabled") {
                Write-Host "Adapter '$adapterName' is enabled (Status: $($adapter.Status))."
                return $true
            }
        }
        catch {
            Write-Host "Error checking adapter status: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
        
        Start-Sleep -Seconds 1
        $timePassed++
    }
    Write-Host "Timeout: Adapter '$adapterName' could not be activated." -ForegroundColor Red
    return $false
}

function Is-LanConnected {
    try {
        $adapter = Get-NetAdapter -Name $ethernetName -ErrorAction Stop
        return ($adapter.Status -eq "Up" -and $adapter.LinkSpeed -gt 0)
    }
    catch {
        return $false
    }
}

function Is-WifiConnected {
    try {
        $adapter = Get-NetAdapter -Name $wifiName -ErrorAction Stop
        if ($adapter.Status -eq "Disabled") {
            return $false
        }

        $profile = Get-NetConnectionProfile -InterfaceAlias $wifiName -ErrorAction Stop
        return $profile.Name -eq $hotspotSSID
    }
    catch {
        return $false
    }
}

function Connect-Hotspot {
    for ($i = 1; $i -le $maxAttempts; $i++) {
        Write-Host ""
        Write-Host "Trying to connect to the hotspot via Wi-Fi (Attempt $i of $maxAttempts)..."
        
        try {
            $result = netsh wlan connect name="$hotspotSSID" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Netsh command failed: $result" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error while establishing Wi-Fi Connection: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        Start-Sleep -Seconds 5

        if (Is-WifiConnected) {
            Write-Host "Wifi-Fi connected via Hotspot." -ForegroundColor Green
            Write-Host ""
            return $true
        }

        if ($i -lt $maxAttempts) {
            Write-Host "Wi-Fi connection failed, trying again in $timeoutInSeconds seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds $timeoutInSeconds
        }
    }
    Write-Host "Wi-Fi connection failed after $maxAttempts attempts." -ForegroundColor Red
    return $false
}

function Connect-Lan {
    if (-not (Enable-AdapterAndWait -adapterName $ethernetName)) {
        return $false
    }

    for ($i = 1; $i -le $maxAttempts; $i++) {
        if (Is-LanConnected) {
            Write-Host "LAN connected." -ForegroundColor Green
            return $true
        }
        
        if ($i -lt $maxAttempts) {
            Write-Host ""
            Write-Host "LAN connection not established, trying again in $timeoutInSeconds seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds $timeoutInSeconds
        }
    }
    Write-Host "LAN connection failed after $maxAttempts attempts." -ForegroundColor Red
    return $false
}

function Switch-ToAdapter {
    param (
        [string]$enableAdapter,
        [string]$disableAdapter,
        [string]$adapterType
    )
    
    Write-Host "Working Internet connection confirmed via $adapterType. Disabling $disableAdapter in $switchDelaySeconds seconds..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to cancel..." -ForegroundColor Yellow
    
    for ($i = $switchDelaySeconds; $i -gt 0; $i--) {
        Write-Host "Switching in $i seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    
    try {
        Disable-NetAdapter -Name $disableAdapter -Confirm:$false -ErrorAction Stop
        Write-Host "$disableAdapter disabled." -ForegroundColor Green
    }
    catch {
        Write-Host "Error while disabling $disableAdapter : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Main-Logic ---

if (-not (Test-AdminRights)) {
    Write-Host "This script requires administrator rights!" -ForegroundColor Red
    Write-Host "Start PowerShell as an administrator and run the script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Network-Switching Script started ===" -ForegroundColor Cyan
Write-Host "LAN-Adapter: $ethernetName" -ForegroundColor Gray
Write-Host "Wi-Fi adapter: $wifiName" -ForegroundColor Gray
Write-Host "Hotspot-SSID: $hotspotSSID" -ForegroundColor Gray
Write-Host "Switch-Delay: $switchDelaySeconds seconds" -ForegroundColor Gray
Write-Host ""

$lanConnected = Is-LanConnected
$wifiConnected = Is-WifiConnected

Write-Host "Status: LAN=$lanConnected, Wi-Fi=$wifiConnected" -ForegroundColor Gray

if ($lanConnected) {
    Write-Host "LAN is active. Wi-Fi is being activated and connected..."
    if (-not (Enable-AdapterAndWait -adapterName $wifiName)) {
        Write-Host "Wi-Fi adapter could not be activated." -ForegroundColor Red
        exit 1
    }

    if (Connect-Hotspot) {
        Write-Host "Waiting for internet availability via Wi-Fi..."
        if (Wait-ForInternetConnection -maxWaitSeconds 30) {
            Switch-ToAdapter -enableAdapter $wifiName -disableAdapter $ethernetName -adapterType "WLAN"
        }
        else {
            Write-Host "Wi-Fi connected, but no internet available. LAN remains active." -ForegroundColor Red
        }
    }
    else {
        Write-Host "Unable to connect to Wi-Fi Hotspot, LAN remains active." -ForegroundColor Red
    }
}
elseif ($wifiConnected) {
    Write-Host "Wi-Fi is active. LAN is being activated and connected..."
    if (Connect-Lan) {
        Write-Host ""
        Write-Host "Waiting for internet availability via LAN..."
        if (Wait-ForInternetConnection -maxWaitSeconds 15) {
            Switch-ToAdapter -enableAdapter $ethernetName -disableAdapter $wifiName -adapterType "LAN"
        }
        else {
            Write-Host "LAN connected, but no internet available. Wi-Fi remains active." -ForegroundColor Red
        }
    }
    else {
        Write-Host "LAN could not be connected, Wi-Fi remains active." -ForegroundColor Red
    }
}
else {
    Write-Host "No active network detected. Trying to activate LAN..."
    if (Connect-Lan) {
        Write-Host "LAN connected."
        Write-Host ""
        if (-not (Test-InternetConnectivity)) {
            Write-Host "LAN has no internet access, trying Wi-Fi..." -ForegroundColor Yellow
        }
    }
    
    if (-not $lanConnected) {
        Write-Host "LAN failed or no Internet connection. Trying Wi-Fi..."
        if (-not (Enable-AdapterAndWait -adapterName $wifiName)) {
            Write-Host "Wi-Fi adapter could not be activated." -ForegroundColor Red
            exit 1
        }

        if (Connect-Hotspot) {
            Write-Host "Wi-Fi connected."
        }
        else {
            Write-Host "No network available." -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "=== Script finished ===" -ForegroundColor Cyan