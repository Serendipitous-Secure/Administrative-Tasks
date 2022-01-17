function Disable-UAC {

    <#
    .Synopsis
        This Function Disable's the UAC prompt so we can run programs as needed.
    .Description
        This Function checks the statys of, and then disable's, the UAC prompt by setting regitry value at keys 
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorAdmin and 
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA to 0.
    .Parameter Reboot
        This mandatory parameter sets reboot usage. Defaults to no, and will fail a script if 
    .Example
        #With reboot in 7 minutes
        Disable-UAC -Reboot true -Delay 420
        #Without reboot.
        Disable-UAC -Reboot false
        Disable-UAC 
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [ValidateSet("false", "true", IgnoreCase=$true)]
        [string]$Reboot 
        ,
        [ValidateNotNullOrEmpty()][ ValidateRange(60, 600)]
        [int]$Delay = 60
    )

    $AdminPromptStatus = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin
    $UACstatus = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA
    
    if ($AdminPromptStatus.ConsentPromptBehaviorAdmin -ne 0){
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin  -Value 0
    }
    if ($UACstatus.EnableLUA -ne 0){
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 0
    }

    $AdminPromptStatus = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin
    $UACstatus = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA

    if (($AdminPromptStatus.ConsentPromptBehaviorAdmin -ne 0) -and ($UACstatus.EnableLUA -ne 0)){
        Write-Host "Could Not Disable UAC"
        exit 1
    }else{
        Write-Host "UAC Disabled."
        
        if ( $Reboot -match "true" ) {
            Write-Host "This Device is rebooting as per instruction."
            Start-Sleep -Seconds $Delay
            Restart-Computer -Force
        } elseif ( $Reboot -match "false" ) {
            Write-Host "This computer needs to reboot for the changes you have made to take place."
        }
        exit 0
    }
}

function Enable-UAC {

    <#
    .Synopsis
        This Function enable's the UAC prompt so we can run programs as needed.
    .Description
        This Function checks the statys of, and then enable's, the UAC prompt by setting regitry value at keys 
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorAdmin and 
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA to 0.
    .Parameter Reboot
        This mandatory parameter sets reboot usage. Defaults to no, and will fail a script if 
    .Example
        #With reboot in 7 minutes
        Enable-UAC -Reboot true -Delay 420
        #Without reboot.
        Enable-UAC -Reboot false
        Enable-UAC 
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [ValidateSet("false", "true", IgnoreCase=$true)]
        [string]$Reboot 
        ,
        [ValidateNotNullOrEmpty()][ ValidateRange(60, 600)]
        [int]$Delay = 60
    )

    $AdminPromptStatus = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin
    $UACstatus = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA
    
    if ($AdminPromptStatus -ne 1){
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin  -Value 1
    }
    if ($UACstatus -ne 1){
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 1
    }
    
    $AdminPromptStatus = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin
    $UACstatus = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA

    if (($AdminPromptStatus.ConsentPromptBehaviorAdmin -ne 1) -and ($UACstatus.EnableLUA -ne 1)){
        Write-Host "Could Not Enable UAC"
        exit 1
    }else{
        Write-Host "UAC Enabled."
        
        if ( $Reboot -match "true" ) {
            Write-Host "This Device is rebooting as per instruction."
            Start-Sleep -Seconds $Delay
            Restart-Computer -Force
        } elseif ( $Reboot -match "false" ) {
            Write-Host "This computer needs to reboot for the changes you have made to take place."
        }
        exit 0
    }

}


function Main {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("On", "Off", IgnoreCase=$true)]
        [String]
        $Toggle
    )

    if ( $Toggle -match "off") {

        Disable-UAC -Reboot $ENV:Reboot -Delay $ENV:Delay
        
    } elseif ( $Toggle -match "on") {
        
        Enable-UAC -Reboot $ENV:Reboot -Delay $ENV:Delay

    }

}

Main -Toggle $ENV:Toggle