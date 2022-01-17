

function Invoke-Shedder {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline)]
        [array]
        $List
    )

    PROCESS {

        $ShedList = @()

        foreach ( $item in $List ) {
            
            if ( !($item -match "null") ) {
                
                $ShedList += $item

            }

        }

        Write-Output $ShedList

    }

}


function Install-KB {


    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline)]
        [array]
        $KBlist
    )
    
    PROCESS {
		
		foreach ($KB in $KBlist) {
			
			Get-WindowsUpdate -KBArticleID $KB -Install -AcceptAll -IgnoreReboot -Verbose

		}

    }

}


function Uninstall-KB {
    
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline)]
        [array]
        $KBlist
    )
    
    PROCESS {

        foreach ($KB in $KBlist) {
            
            $SearchUpdates = dism /online /get-packages | findstr "Package_for"
            $updates = $SearchUpdates.replace("Package Identity : ", "") | findstr $KB
            DISM.exe /Online /Remove-Package /PackageName:$updates /quiet /norestart

        }

		$list = Get-HotFix

		foreach ($kb in $list) { if ($KBlist -contains $kb.HotFixID) { Write-Host "$kb remains present"; exit 1 } }

    }

}


function Approve-Reboot {
    
    [CmdletBinding(SupportsShouldProcess)]
    param (

        [ValidateSet("YES", "Y", "N", "NO")]
        [Parameter(Mandatory)]
        [String]
        $Reboot

        )
    
    if ( $reboot -match "Y" ) {
        Write-Host "Rebooting Per Instruction."
        Shutdown /r     
        exit 0
    } else {
        Write-Host "Not Rebooting."   
        exit 0
    }

}


function UnInstall-Main {
    
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter()]
        [string]
        $Reboot,
        [Parameter()]
        [array]
        $KBlist
    )

    PROCESS {

        $KBlist | Invoke-Shedder | UnInstall-KB

		Approve-Reboot -Reboot $Reboot

    }

}


function Install-Main {
    
	[CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter()]
        [string]
        $Reboot,

        [Parameter()]
        [array]
        $KBlist
    )
	
	BEGIN {

		Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
		Install-PackageProvider -Name nuget -Force
		Install-Module -Name PSwindowsUpdate -Force	
		Import-Module -Name PSwindowsUpdate -Force

	}

	PROCESS {

        $KBlist | Invoke-Shedder | Install-KB

        Approve-Reboot -Reboot $Reboot

    }

}


# function Main {

#     param (
#         [Parameter()]
#         [string]
#         $Reboot,

# 		[Parameter()]
#         [switch]
#         $Uninstall,

#         [Parameter(Mandatory,
#             ValueFromPipeline)]
#         [array]
#         $KBlist
#     )
	
# 	PROCESS {

# 		if ($Uninstall -eq $False) {
			
# 			Install-Main -Reboot $Reboot -KBlist $KBlist

# 		}else {

# 			UnInstall-Main -Reboot $Reboot -KBlist $KBlist

# 		}

# 	}

# }


# $Reboot = "N"
# #$Uninstall = $false
# $Uninstall = $True

# if ($Uninstall -eq $True) {
	
# 	$KBlist = @("null", "KB4589212")

# 	Main -Reboot $Reboot -KBlist $KBlist -Uninstall

# } else {

# 	$KBlist = @("null", "KB4481252")

# 	Main -Reboot $Reboot -KBlist $KBlist

# }


function Main {

    param (
        [Parameter()]
        [string]
        $Reboot,

        [Parameter(Mandatory,
            ValueFromPipeline)]
        [array]
        $KBlist
    )
	
	PROCESS {

		if ($ENV:Uninstall -match "False") {
			
			Install-Main -Reboot $Reboot -KBlist $KBlist

		}else {

			UnInstall-Main -Reboot $Reboot -KBlist $KBlist

		}

	}

}


$KBlist = ($ENV:KB1, $ENV:KB2, $ENV:KB3, $ENV:KB4, $ENV:KB5)

Main -Reboot $ENV:Reboot -KBlist $KBlist
