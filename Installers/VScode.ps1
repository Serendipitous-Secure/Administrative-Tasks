
.\VSCodeSetup-x64-1.60.2.exe /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /FORCECLOSEAPPLICATIONS

$Users = (Get-ChildItem C:\Users).Name

ForEach($User in $Users) {

    New-Item -Path "C:\Users\$User\Code" -ItemType "directory"
    
}