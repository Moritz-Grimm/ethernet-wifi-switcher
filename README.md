# Ethernet-WLAN-Switcher

## Overview

This PowerShell script provides a quick and easy way to switch between LAN (Ethernet) and mobile hotspot connections to minimize mobile data usage. When you need faster internet access for downloads or other tasks, you can run the script to switch to your mobile hotspot, and when you're done, run it again to switch back to LAN and stop consuming mobile data.

I originally built this script for my personal use to quickly manage my mobile data and LAN connection without manually switching network adapters every time, but if you find it useful, feel free to use it as well.

---

## Use Case

- You have **limited but faster mobile data** than your home network and want to avoid unnecessary consumption.
- You use a **mobile hotspot** (iPhone, Android, etc.) as internet source when LAN is slow again.
- You want a **quick way to switch to hotspot** when you need internet access for downloads, updates, etc.
- You want to **easily switch back to LAN** when you're done to stop using mobile data.
- You need **one-click switching** instead of manually managing network adapters through buggy and slow Windows settings.
- You want to **avoid the hassle** of constantly enabling/disabling network adapters manually.

---

## Requirements

- Windows PowerShell (Administrator rights required)
- Windows operating system with network adapter management capabilities
- LAN (Ethernet) adapter configured and accessible
- Wi-Fi adapter configured with saved hotspot credentials
- Network adapters must be named consistently (configurable in script)

---

## Setup Instructions

1. **Configure network adapter names**
   
   Verify your adapter names in Network Settings and update these variables:
   ```powershell
   $ethernetName = "Ethernet"  # Your LAN adapter name
   $wifiName = "WLAN"          # Your Wi-Fi adapter name
   ```

2. **Set hotspot configuration**
   
   Configure your target Wi-Fi hotspot:
   ```powershell
   $hotspotSSID = "Your Hotspot Name"
   ```

3. **Adjust timing parameters**
   
   Customize timeouts and delays according to your needs:
   ```powershell
   $maxAttempts = 10           # Connection attempts before giving up
   $timeoutInSeconds = 3       # Wait time between attempts
   $switchDelaySeconds = 5     # Countdown before switching adapters
   ```

4. **Run as Administrator**
   
   Right-click PowerShell and select "Run as Administrator", then execute the script.

5. Optional: Use the included `startup.bat`
    If you want to start the script more easily without opening PowerShell manually, you can use the provided startup.bat file.

    Place the .bat file in the same folder as the script.

    Edit it to match the path to your .ps1 file if needed.

    Double-click the script and confirm the Windows prompt asking for administrator rights.

---

## Script Behavior

The script follows this logic:

### Initial Assessment
- Checks current status of both LAN and Wi-Fi adapters
- Determines which connections are active and working

### LAN Priority Mode
- When **LAN is active**: Attempts to connect Wi-Fi, then switches if internet access is fully established
- When **Wi-Fi is active**: Attempts to connect LAN, then switches if internet access is fully established

### Fallback Mode
- When **no connection is active**: Tries LAN first, then Wi-Fi as fallback
- Ensures at least one working internet connection is established

### Connectivity Testing
- Performs ping tests to 8.8.8.8 (Google DNS)
- Tests HTTP connectivity to multiple URLs:
  - `http://www.msftconnecttest.com/connecttest.txt`
  - `http://www.google.com`
  - `http://1.1.1.1`
- Only switches adapters when internet connectivity is confirmed

---

## Key Features

- **Administrator Rights Check**: Ensures script has necessary permissions
- **Intelligent Switching**: Only switches when a connection is confirmed
- **Connection Verification**: Multiple-layer internet connectivity testing
- **Timeouts**: Configurable delays and attempt limits
- **User Feedback**: Colored console output with clear status messages
- **Cancellation Support**: Ctrl+C during switching interrupts the connection switch
- **Error Handling**: Comprehensive error handling and recovery

---

## Customization

### Adapter Names
Modify these variables to match your system's adapter names:
```powershell
$ethernetName = "Ethernet 2"  # Example: Different LAN adapter name
$wifiName = "Wi-Fi"           # Example: Different Wi-Fi adapter name
```

### Hotspot Configuration
```powershell
$hotspotSSID = "CompanyWiFi"  # Your preferred Wi-Fi network
```

### Timing Configuration
```powershell
$maxAttempts = 15             # More connection attempts
$timeoutInSeconds = 5         # Longer wait between attempts
$switchDelaySeconds = 10      # Longer countdown before switching
```

### Test URLs
Add or modify connectivity test endpoints:
```powershell
$testUrls = @(
    "http://www.msftconnecttest.com/connecttest.txt",
    "http://www.google.com",
    "http://your-internal-server.com"  # Add internal connectivity tests
)
```

---

## Important Notes & Potential Issues

- **Administrator rights are mandatory** - The script cannot modify network adapters without elevated permissions
- Network adapter names must match exactly (case-sensitive) - Use `Get-NetAdapter` to verify correct names
- Wi-Fi networks must be previously configured and saved in Windows - The script cannot handle first-time Wi-Fi setup or password entry
- The script assumes standard Windows network adapter behavior - Some custom network drivers or virtual adapters may not work correctly
- Rapid switching between adapters is prevented by design - The countdown delay ensures stability but may seem slow in some scenarios
- Internet connectivity tests may fail in corporate networks with restrictive firewalls - Consider customizing `$testUrls` for internal networks
- VPN connections may interfere with connectivity testing - The script may not account for VPN-specific routing requirements
- Power management settings on network adapters can cause delays - Disable power saving on critical network adapters if needed
- Some enterprise networks require specific authentication that may not be handled automatically

---

## Troubleshooting

### Common Issues

**"This script requires administrator rights!"**
- Run PowerShell as Administrator (Right-click → "Run as administrator")

**"Adapter not found" errors**
- Verify adapter names with `Get-NetAdapter` in PowerShell
- Update `$ethernetName` and `$wifiName` variables accordingly

**Wi-Fi connection fails repeatedly**
- Ensure the hotspot is within range and credentials are saved
- Try connecting manually first: `netsh wlan connect name="YourSSID"`

**Internet tests fail despite connection**
- Check if corporate firewall blocks test URLs
- Modify `$testUrls` to include internal test endpoints
- Verify DNS resolution works correctly

---

## Disclaimer

This script modifies network adapter states and connectivity. Use at your own risk in production environments. Test thoroughly in your specific network configuration before deploying. The author is not responsible for any network disruptions, connectivity issues or unintended consequences.

## License

[MIT License](./LICENSE)

---

## Contributing

If you want to help improve this script, just fork the repo and open a pull request with your changes!
