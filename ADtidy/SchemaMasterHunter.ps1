if ( (netdom query FSMO | findstr "Schema Master") -match $ENV:COMPUTERNAME){

    REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\CentraStage /v "Custom18" /t REG_SZ /d "True" /f

}
