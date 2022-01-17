
$MAJOR_REASON_CODE = @{

	Other				= 0
	ApplicationIssue	= 4
	HardwareIssue		= 1
	OperatingSystem 	= 2

}

$MINOR_REASON_CODE = @{

	Other 		                   	=  0
	HotFix 							= 11
	HotFixUninstallation			= 17
    Installation                    =  2
    Maintenance                     =  1
    Reconfigure                     =  4
	SecurityIssue					= 13
	SecurityPatch					= 12
	SecurityPatchUninstallation		= 18
	ServicePack						= 10
	ServicePackUninstallation		= 16
	Unstable						=  6
	Upgrade							=  3
    Uresponsive                     =  5  

}

$Arguments = "/c shutdown /r /t "+$ENV:TIMEOUT+" /c "+'"'+$ENV:COMMENT+'"'+" /d "+"$ENV:PLANNED"+":"+$MAJOR_REASON_CODE[$ENV:MAJORREASON]+":"+$MINOR_REASON_CODE[$ENV:MINORREASON]
$arguments 

if ( $ENV:OverrideCheck -match "False" ) {

    if ( ($ENV:UDF_16 -match "true") -or !($ENV:UDF_17 -match "false") ) {

        start-process cmd.exe -ArgumentList $Arguments
    
    } else {

        Write-Host "`n"
        Write-Host "============================================================"
        Write-Host "This server does not have a recent backup or snapshot, and the script was not instructed to override this check." 
        Write-Host "If you have evaluated this to be ok, Run the script again with the 'OverrideCheck' field showing 'TRUE'"
        Write-Host "============================================================"
        Write-Host "`n"
        exit 1
    
    }

} else {

    Write-Host "`n"
    Write-Host "============================================================"
    Write-Host "This job was instructed to ignore the DWA and ESXI snapshot checks."
    Write-Host "Rebooting." 
    Write-Host "Good luck. " 
    Write-Host "============================================================"
    Write-Host "`n"
    start-process cmd.exe -ArgumentList $Arguments
    
}
