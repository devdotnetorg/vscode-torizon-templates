$errorActionPreference = "Stop"
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', "Internal PS variable"
)]
$PSNativeCommandUseErrorActionPreference = $true

$_HOME = $env:HOME
$_wicPath = "$_HOME/.torizon/emulator/torizon-core-common-docker-dev-qemuarm64.wic"
$_romPath = "$_HOME/.torizon/emulator/u-boot.bin"

# run the qemu
$_qemuCmd =  `
    "qemu-system-aarch64 " +
        "-M virt " +
        "-cpu cortex-a57 " +
        "-smp 4 " +
        "-m 2048 " +
        "-device virtio-gpu-pci " +
        "-drive if=virtio,file=$_wicPath,format=raw " +
        "-nic bridge,br=br0,model=virtio-net-pci " +
        "-no-reboot " +
        "-no-acpi " +
        "-bios $_romPath " +
        "-d unimp " +
        "-semihosting-config enable=on,target=native " +
        "-serial mon:stdio " +
        "-serial null " +
        "-display gtk,gl=on " +
        "-device virtio-tablet-pci"

bash -c "$_qemuCmd"
