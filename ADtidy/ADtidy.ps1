#grabbing OS archetecture to get accurate datto path
$bits_OS = (Get-WmiObject Win32_OperatingSystem).OSArchitecture.Substring(0,2)

if ($bits_OS -eq 32) {

    $path_CS = $env:ProgramFiles + '\CentraStage\'

} elseif ($bits_OS -eq 64) {

    $path_CS = ${env:ProgramFiles(x86)} + '\CentraStage\'

}

Set-Location $path_CS


#Prepare Data files
if ((Test-Path "users_audit_inactive.txt") -eq 0) {

    New-Item -Path "users_audit_inactive.txt" -ItemType "file"

}else {

    Remove-Item -Path "users_audit_inactive.txt"
    New-Item -Path "users_audit_inactive.txt" -ItemType "file"

}

if ((Test-Path "users_audit_active.txt") -eq 0) {

    New-Item -Path "users_audit_active.txt" -ItemType "file"

}else {

    Remove-Item -Path "users_audit_active.txt"
    New-Item -Path "users_audit_active.txt" -ItemType "file"

}

if ((Test-Path "users_count.xml") -eq 0) {

    New-Item -Path "users_count.xml" -ItemType "file"

}else{

    $UserCount = Import-Clixml -Path "users_count.xml"
    Remove-Item -Path "users_count.xml"

}

#this is the filter by which we grab accounts
$LDAPPath = ''
$CountDisabled = 0
$LastLogonAgeDaysLimit = 30
$RootDomainOU = [ADSI]$LDAPPath

#create an instance of a searcher object.
$Searcher = New-Object System.DirectoryServices.DirectorySearcher($RootDomainOU)
$Filter = '(objectCategory=person)(objectClass=user)'

if ($CountDisabled -eq 0){

    $Filter = $Filter + '(!(userAccountControl:1.2.840.113556.1.4.803:=2))'

}

$Filter = '(&' + $Filter + ')'
$Searcher.Filter = $Filter

[Void]$Searcher.PropertiesToLoad.Add('cn')
[Void]$Searcher.PropertiesToLoad.Add('lastLogonTimestamp')

Try {
   
    $Objects = $Searcher.findall()

} Catch {

    Write-Host $($_.Exception.Message)

    exit 1

}

$LLDays = (Get-Date).AddDays(-$LastLogonAgeDaysLimit).ToFileTime()
$OldObjects = $Objects | Where-Object {$_.properties.lastlogontimestamp -le $LLDays}
$CurrentObjects = $Objects | Where-Object {$_.properties.lastlogontimestamp -ge $LLDays}


#load Data to files
$CurrentObjects | Format-Table -AutoSize > users_audit_active.txt
$OldObjects | Format-Table -AutoSize > users_audit_inactive.txt

$NewUserCount = @{

    ActiveUsers = $CurrentObjects.Count

}

$Count = $NewUserCount.ActiveUsers - $UserCount.ActiveUsers
 
Export-Clixml -Path users_count.xml -InputObject $NewUserCount

#Update UDF
Set-ItemProperty -Path HKLM:\SOFTWARE\CentraStage -Name $ENV:Customfield1  -Value $CurrentObjects.Count -Type String
Set-ItemProperty -Path HKLM:\SOFTWARE\CentraStage -Name $ENV:Customfield2  -Value $Count -Type String

#Compose Report
Write-Host 'Total users found in Active Directory:' $Objects.Count
Write-Host 'Total active users found in Active Directory (used last 30 days):' $CurrentObjects.Count
Write-Host 'Changed from last Audit:' $Count
Write-Host 'DETAILS:'
Write-Host 'All active users:'

$CurrentObjects | ForEach-Object {

    $TimeStamp = [DateTime]::FromFileTime([string]$_.properties.lastlogontimestamp).tostring("G")

    Write-Host $_.Properties.cn "          " $TimeStamp

}

Write-Host "`n"

Write-Host 'Inactive users:'
$OldObjects | ForEach-Object {

    if ([DateTime]::FromFileTime([string]$_.properties.lastlogontimestamp).tostring("G") -eq "12/31/1600 6:00:00 PM"){
        
        $TimeStamp = ""

    }else {
    
        $TimeStamp = [DateTime]::FromFileTime([string]$_.properties.lastlogontimestamp).tostring("G")
    
    }

    Write-Host $_.Properties.cn "          " $TimeStamp

}

exit 0