$errorActionPreference = "Stop"
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', "Internal PS variable"
)]
$PSNativeCommandUseErrorActionPreference = $true

$_HOME = $env:HOME
$_ARCH = $env:ARCH

if ($_ARCH -eq "aarch64") {
    $_wicPath = "$_HOME/.torizon/emulator/torizon-core-common-docker-dev-qemuarm64.wic"
    $_romPath = "$_HOME/.torizon/emulator/u-boot.bin"
} elseif ($_ARCH -eq "x86_64") {
    $_wicPath = "$_HOME/.torizon/emulator/torizon-core-common-docker-dev-qemux86-64.wic"
    $_romPath = "/usr/share/ovmf/OVMF.fd"
}

if ($_ARCH -eq "aarch64") {
    $_qemuCmd =  `
        "qemu-system-aarch64 " +
            "-M virt " +
            "-cpu cortex-a57 " +
            "-smp 4 " +
            "-m 2048 " +
            "-device virtio-gpu-pci " +
            "-drive if=virtio,file=$_wicPath,format=raw " +
            "-nic bridge,br=br0,model=virtio-net-pci " +
            "-no-acpi " +
            "-bios $_romPath " +
            "-d unimp " +
            "-semihosting-config enable=on,target=native " +
            "-serial mon:stdio " +
            "-serial null " +
            "-display gtk,gl=on " +
            "-device virtio-tablet-pci"
} elseif ($_ARCH -eq "x86_64") {
    $_qemuCmd =  `
        "qemu-system-x86_64 " +
            "-cpu host " +
            "-machine pc " +
            "-smp 4 " +
            "-m 2048 " +
            "-device virtio-gpu-pci " +
            "-drive file=$_wicPath,format=raw " +
            "-nic bridge,br=br0,model=virtio-net-pci " +
            "-bios $_romPath " +
            "-d unimp " +
            "-serial mon:stdio " +
            "-serial null " +
            "-display gtk,gl=on " +
            "-device virtio-tablet-pci " +
            "-vga none " +
            "-enable-kvm"
}

# run the qemu
bash -c "$_qemuCmd"
