$VerbosePreference = "Continue"

# 1. Disable Firewall so CRD can tunnel freely
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# 2. Install Chrome and CRD Host
Write-Host "Installing Chrome and CRD..."
$crdUrl = "https://dl.google.com/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi"
$chromeUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
Invoke-WebRequest $crdUrl -OutFile "$env:TEMP\crd.msi"
Invoke-WebRequest $chromeUrl -OutFile "$env:TEMP\chrome.exe"
Start-Process "$env:TEMP\crd.msi" -Wait
Start-Process "$env:TEMP\chrome.exe" -ArgumentList "/install", "--silent" -Wait

# 3. Install Android SDK via Chocolatey
Write-Host "Installing Android SDK (This takes a few minutes)..."
choco install android-sdk -y

# 4. Accept Licenses and Install Image
$sdkManager = "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
# Wait for path to exist
while (!(Test-Path $sdkManager)) { Start-Sleep -Seconds 5 }

Write-Host "Downloading Android Image..."
"y" | & $sdkManager "system-images;android-28;default;x86" "emulator" "platform-tools"

# 5. Create Virtual Phone
Write-Host "Creating AVD..."
$avdManager = "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat"
"no" | & $avdManager create avd -n "Phone" -k "system-images;android-28;default;x86" --force

# 6. Start Emulator in Background
Write-Host "Starting Android Phone..."
$emulator = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"
# '-accel off' is REQUIRED because GitHub Actions is already a Virtual Machine
Start-Process -FilePath $emulator -ArgumentList "-avd Phone -no-boot-anim -accel off -no-snapshot"

Write-Host "Setup Complete. Waiting for RDP connection..."
