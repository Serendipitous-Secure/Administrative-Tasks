
function Resolve-Files {

    <#
    .Synopsis
        This function resolves an array of file paths into their concrete paths.    
    .Description
        This function takes an array of file paths containg wildcards and resolves it to an array of 
        concrete paths. This can be tested for content in a conditional structure. 
    .Parameter FileList
        This is the list of files you would like to resolve into concrete paths.
    .Example
        #FileList passed as a paramter
        Resolve-Files -FileList $FileList 
        #FileList on stdin
        $FileList | Resolve-Files
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, 
            ValueFromPipeline)]
        [array] $FileList
    )

    PROCESS {

        $ConcretePaths = @()

        foreach ($File in $FileList) {

            $ConcretePaths += Resolve-Path -Path $File

        }

        Write-Output $ConcretePaths

    }

}


function Purge-Files {
    
    <#
    .Synopsis
        This function resolves an array of file paths into their concrete paths.    
    .Description
        This function takes an array of file paths containg wildcards and resolves it to an array of 
        concrete paths. This can be tested for content in a conditional structure. 
    .Parameter FileList
        This is the list of files you would like to resolve into concrete paths.
    .Example
        #FileList passed as a paramter
        Resolve-Files -FileList $FileList 
        #FileList on stdin
        $FileList | Resolve-Files
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, 
            ValueFromPipeline)]
        [array] $FileList
    )
    
    PROCESS {

        ForEach ($File in $FileList){
            
            If(Test-Path -Path $File -PathType Container){
                Remove-Item $File -Recurse -Force
            }elseif (Test-Path -Path $File -PathType Leaf) {
                Remove-Item $File -Force
            }
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

    $FileList = @($ENV:Path1, $ENV:Path2, $ENV:Path3, $ENV:Path4, $ENV:Path5)

    $FileList | Resolve-Files | Purge-Files

    $FileTest = $FileList | Resolve-Files
    
    Check-Work -FileList $FileTest -ToggleExitCondition 1

}

Main
