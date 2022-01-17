<# 
This Script is intended to enable WOL by magic packet on DELL devices. 
This is achieved by use of the Dell Powershell Provider Module, which allows BIOS settings to be set trough the powershell. 
Next, NIC devices are given the ability to change power states, and lastly the NIC settings are instated.

For and questions, bugs, or suggestions, please feel free to contact me on Teams or email me at tfern@hctechguys.com
#>

#SET UP 
$Version =  $PSVersionTable.PSVersion.major
$ModuleDir = "C:\PROGRA~1\WindowsPowerShell\Modules\DellBIOSProvider\*"
$DLLpickle = "DLLpickle.zip"

if (!($Version -ge 3)) {
    Write-Host 'The Powershell verion is Obsolete. the "DELL COMMAND | POWERSHELL PROVIDER" Requires powershell verison 3 minimum.'
    Write-Host "The current Powershell version is $Verison"
    exit 1
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force

#download DCPP extension
Install-PackageProvider -Name nuget -Force
Install-Module -Name DellBIOSProvider -Force

#unzip to appropriate location
Start-Process 7za.exe -ArgumentList "x $DLLpickle  -o$ModuleDir -y" -Wait

#Import
Import-Module -Name DellBIOSProvider -Force 
  
#activate in BIOS
#de-activate deepsleep 
Set-Item DellSmbios:\PowerManagement\DeepSleepCtrl Disabled
#Set WakeOnLan     
Set-Item  DellSmbios:\PowerManagement\WakeOnLan LANOnly
#activate in windows/on interface  
$TargetInterfaces = @(Get-NetAdapter | Where-Object -FilterScript {($_.Name -match "Ethernet") -or ($_.Name -match "Wi-Fi")})

#activate in windows/on interface  
#iterate over 
foreach ($Interface in $TargetInterfaces) {
    #allow to wake computer
    powercfg.exe /deviceenablewake $Interface.InterfaceDescription
}
  
foreach ($Interface in $TargetInterfaces) {
    #only magic packet
    enable-NetAdapterPowerManagement -Name $Interface.Name -WakeOnMagicPacket
}

#VERIFY
################################
$SettingsTally = 0
$WakeableTally = 0
$WakeIntTally = 0

$WOLstatus = Get-ChildItem DellSmbios:\PowerManagement\WakeOnLan
$SleepStatus = Get-ChildItem DellSmbios:\PowerManagement\DeepSleepCtrl
$WakePermStatus = powercfg.exe /devicequery wake_armed

$WakeableDevices = @()
$WakeableInterfaces = @()

if ($WOLstatus.CurrentValue -match "LanOnly"){
    $SettingsTally ++
}

if ($SleepStatus.CurrentValue -match "Disabled"){
    $SettingsTally ++
}

foreach ( $Device in $WakePermStatus ){
    
    if ( !($Device -match "mouse") -or !($Device -match "keyboard") ){
        
        $WakeableDevices += $Device

    }

}


foreach ($Interface in $TargetInterfaces){

    if ( $Interface.InterfaceDescription -in $WakeableDevices){
    
        $WakeableTally ++

    }

}

if( $WakeableTally -eq $TargetInterfaces.Count ){

    $SettingsTally ++

}


foreach ($Interface in $TargetInterfaces){

    $WakeableInterfaces += Get-NetAdapterPowerManagement -Name $Interface.name | Select-Object -Property WakeOnMagicPacket, WakeOnPattern

}

foreach ( $Interface in $WakeableInterfaces ){

    if ( ($Interface.WakeOnMagicPacket -eq "Enabled") -and ($Interface.WakeOnPattern -eq "Enabled") ){
    
        $WakeIntTally ++
        
    }

}

if( $WakeIntTally -eq $TargetInterfaces.Count ){

    $SettingsTally ++

}

if ($SettingsTally -eq 4) {

    Write-Host "SUCCESS"

}else{

    Write-Host "FAILURE. REVIEW RESULTS"
    Write-Host "======================="
    #VERIFY
    Write-Host "########################################"
    Write-Host "VERIFICATION"
    Write-Host "########################################"
    Write-Host "Dell Provider, check settings"
    Write-Host "---------------------"
    $WOLstatus
    $SleepStatus
    Write-Host "---------------------"
    Write-Host "Devices Permitted to wake, check NICs listed"
    Write-Host "---------------------"
    $WakePermStatus
    Write-Host "---------------------"
    Write-Host "NICs with WakeOnLAN set, should be same NIC's in prev list."
    Write-Host "---------------------"
    foreach ($Interface in $TargetInterfaces){
        Get-NetAdapterPowerManagement -Name $Interface.name | Format-List -Property "*"
    }

    exit 1
}

<#  SOURCES FOR DOCS USED 

    COMMANDS
    https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options#option_deviceenablewake
    https://docs.microsoft.com/en-us/powershell/module/netadapter/get-netadapter?view=win10-ps
    https://docs.microsoft.com/en-us/powershell/module/netadapter/enable-netadapterpowermanagement?view=win10-ps
    https://devblogs.microsoft.com/oldnewthing/20080213-00/?p=23473
    https://docs.microsoft.com/en-us/powershell/module/netadapter/get-netadapterpowermanagement?view=win10-ps

    DELL COMMAND | POWERSHELL PROVIDER
    https://www.dell.com/support/home/en-us/product-support/product/command-powershell-provider/docs
    https://www.dell.com/support/kbdoc/en-us/000175283/how-to-setup-wake-on-lan-wol-on-your-dell-system
    https://www.dell.com/support/kbdoc/en-za/000175490/dell-command-powershell-provider-wakeon-lan-wlan
    https://www.dell.com/support/kbdoc/en-gd/000146531/installing-the-dell-smbios-powershell-provider-in-windows-pe

#>
