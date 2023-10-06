$errorActionPreference = "Stop"
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', "Internal PS variable"
)]
$PSNativeCommandUseErrorActionPreference = $true

# check if we already have the wic file
$_HOME = $env:HOME

if ($env:ARCH -eq "aarch64") {
    $_wicPath = "$_HOME/.torizon/emulator/torizon-core-common-docker-dev-qemuarm64.wic"
    $_wicURL = "https://github.com/commontorizon/meta-common-torizon/releases/download/emulator-rc1/aarch64.zip"
    $_zipFile = "aarch64.zip"
} elseif ($env:ARCH -eq "x86_64") {
    $_wicPath = "$_HOME/.torizon/emulator/torizon-core-common-docker-dev-qemux86-64.wic"
    $_wicURL = "https://github.com/commontorizon/meta-common-torizon/releases/download/emulator-rc2/torizon-core-common-docker-dev-qemux86-64.wic.zip"
    $_zipFile = "torizon-core-common-docker-dev-qemux86-64.wic.zip"
}

$_emulatorPath = "$_HOME/.torizon/emulator"

if (Test-Path -Path $_wicPath) {
    Write-Host "✅ WIC file found"
} else {
    Write-Host "⚠️ WIC file not found"

    Write-Host -ForegroundColor Yellow "Checking dependencies ..."

    $_packagesToInstall = New-Object Collections.Generic.List[string]

    if ($env:ARCH -eq "aarch64") {
        $_packages = @(
            "qemu-system-arm",
            "qemu-utils",
            "qemu-system-common"
        )
    } elseif ($env:ARCH -eq "x86_64") {
        $_packages = @(
            "qemu-system-x86",
            "qemu-utils",
            "qemu-system-common",
            "ovmf"
        )
    }

    foreach ($package in $_packages) {
        dpkg -s $package > /dev/null 2>&1
        
        if ($? -eq $false) {
            $_packagesToInstall.Add($package)
            Write-Host -ForegroundColor DarkRed "😵 $package not installed"
        } else {
            Write-Host -ForegroundColor DarkGreen "👍 $package installed"
        }
    }

    # if we have packages to install, let's install them
    if ($_packagesToInstall.Count -gt 0) {
        Write-Host "Installing missing dependencies ..."
        $_packInline = $_packagesToInstall -join " "
        # install the packages
        sudo apt-get update
        sudo apt-get install $_packInline

        if ($? -eq $false) {
            Write-Host -ForegroundColor DarkRed "❌ failed to install dependencies"
            exit 69
        }
    }

    Write-Host "Downloading WIC..."

    # download the .zip file
    Invoke-WebRequest `
        -Uri $_wicURL `
        -OutFile $_zipFile

    # unzip the .zip file
    Expand-Archive `
        -Path $_zipFile `
        -DestinationPath $_emulatorPath

    # remove the .zip file
    Remove-Item `
        -Path $_zipFile

    Write-Host "✅ WIC file downloaded"

    # let's resize the wic file
    Write-Host "Resizing..."
    qemu-img resize $_wicPath +8G

    Write-Host "✅ WIC file resized"
}
