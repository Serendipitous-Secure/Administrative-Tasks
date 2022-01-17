function Get-InstalledPrograms {

    <#
    .Synopsis
        This funcion retrieves installed programs. 
    .Description
        This function accepts an array of strings containing program names and queries the regisrty paths 
        HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall 
        and HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall for their presence. Returns an array  
    .Parameter ProgramList
        The array containing strings you would like matched to program names to test for. This is done by matching, not requiring the exact name. Use caution. 
    .Example
        #ProgramList as parameter
            Get-UninstallString -ProgramList $ProgramList
        #ProgramList from stdin
            $ProgramList | Get-UninstallString
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, 
            ValueFromPipeline)]
        [array] $ProgramList
    )

    PROCESS {
        
        $Programs = @()

        forEach ( $Program in $ProgramList ){
            $Programs += Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, 
                HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall  |
                Get-ItemProperty |
                    Where-Object -FilterScript {($_.DisplayName -match $Program)} |
                        Select-Object -Property DisplayName
        }
          Write-Output $Programs
            
    }

}


function Get-UninstallString {
    
    <#
    .Synopsis
        This funcion retrieves uninstall strings. 
    .Description
        This function accepts an array of strings containing program names and queries the regisrty paths 
        HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall 
        and HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall for uninstall strings. 
    .Parameter ProgramList
        The array containing strings you would like matched to program names to get strings for. This is done by matching, not requiring the exact name. Use caution. 
    .Example
        #ProgramList as parameter
            Get-UninstallString -ProgramList $ProgramList
        #ProgramList from stdin
            $ProgramList | Get-UninstallString
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, 
            ValueFromPipeline)]
        [array] $ProgramList
    )
    
    PROCESS {
        
        $PreStrings = @()
        $PostStrings = @()

        forEach ( $Program in $ProgramList ){
            $PreStrings += Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, 
                HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall  |
                Get-ItemProperty |
                    Where-Object -FilterScript {if(!($Program -is [string])){$_.DisplayName -eq $Program.DisplayName}else{$_.DisplayName -match $Program}} |
                        Select-Object -Property UninstallString
        }

        foreach ( $String in $PreStrings ){
         $PostStrings += -join("/c ", $PreStrings.UninstallString.Replace("/I", "/Uninstall ").Replace("/X", "/Uninstall "), " /quiet /norestart")
        }

        Write-Output $PostStrings

    }

}


function Uninstall-FromString {
    
    <#
    .Synopsis
        This function attempts to uninstall programs from Registry uninstall strings.
    .Description
        This function takes an array of strings created by the "Get-UninstallString" function, and passes it 
        to a silent CMD instance that waits for uninstallation to complete as it iterates through the array. 
    .Parameter StringList
        This is the list of uninstall strings. For best results, source this array from Get-UninstallString. This is done by matching, not requiring the exact name. Use caution. 
    .Example
        #as a variable passed as a parameter
        Uninstall-FromString -StringList $StringList
        #as a variable on stdin
        $StringList | Uninstall-FromString
        #From Get-UninstallString on stdin
        <programlist> | Get-UninstallString | Uninstall-FromString
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, 
            ValueFromPipeline)]
        [array] $StringList
    )
    
    PROCESS {

        foreach ($String in $StringList){

            Write-Progress "Attempting to uninstall program."
            Start-Process cmd.exe -ArgumentList $String -Wait -NoNewWindow 

        }

    }
}


function Check-Work {
    
    <#
    .Synopsis
        This function Preforms checks on arrays and creates according output and exit conditions.
    .Description
        This function takes multiple arrays as arguments and preforms checks on content. 
        This will then be the basis for reporting output and exit conditions. The arrays are handled the same, 
        but best results are acheived by matching the content of your array to the parameter to get the correct reporting. 
    .Parameter FileList
        This is the array of files you would like to evaluate.
    .Parameter ProgList
        This is the array of Programs you would like to evaluate.
    .Parameter GPOList
        This is the array containing GPO's
    .Parameter ToggleExitCondition
        This parameter take a 1 or a 0, to set the behavior when any of the arrays evaluates to true. This defaults to 1, 
        meaning it will exit the program as a failure if any array passed to this function evaluates to true.
    .Example
        #Testing for Files and Programs and Failing if found.
        Check-Work -File-List $FileList -Program-List $ProgramList -ToggleExitCondition 1
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [array] $FileList,

        [array] $ProgramList,

        #[Parameter(Mandatory)]
        [array] $GPOList,

        [ValidateSet (0,1)]
        [ValidateNotNullOrEmpty()]
        [int] $ToggleExitCondition = 1

    ) 

    $Count = 0

    if ( $FileList ) {
        Write-Host "Files are present"
        $Count++
    }
    if ( $ProgramList ) {
        Write-Host "Programs are present"
        $Count++
    }
    if ( $GPOList ) {
        Write-Host "GPO's are present"
        $Count++
    }
    
    if ( $ToggleExitCondition = 1 ) { 

        if ($Count -gt 0) {
            exit 1
        } else { exit 0 }

    } else {

        if ($Count -gt 0) {
            exit 0
        } else { exit 1 }

    }

}


function Main {
    
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, 
            ValueFromPipeline)]
        [array] $ProgramList
    )
    
    PROCESS {

        Write-Host "Attempting to remove programs..."
        $ProgramList | Get-InstalledPrograms | Get-UninstallString | Uninstall-FromString 

    }
    
    END {
    
        Write-Host "Checking Work..."
        $ProgramTest = $ProgramList | Get-InstalledPrograms
        Check-Work -ProgramList $ProgramTest -ToggleExitCondition 1 
    
    }

}

$ProgramList = @($ENV:Program1, $ENV:Program2, $ENV:Program3, $ENV:Program4, $ENV:Program5)

$ProgramList | Main
