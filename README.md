# Configure PSMConfigureAppLocker.xml


## Main capabilities
-----------------
- The tool automates the configuration of PSMConfigureAppLocker.xml

## Parameters:
```powershell
Update-PSMConfigureApplocker [-PSMConnect] <String> [-PSMAdminConnect] <String> [[-ApplockerReportCSV] <String>] [[-ignoreFile] <String[]>] [[-ignorePath] <String[]>] [<CommonParameters>]
```
## Install
The module needs to be imported prior to using

## Usage
- Attempt to use the connectors you want
  - If needed use the following to increase the AppLocker log size
```powershell
$appLockerLog = Get-WinEvent -listlog "Microsoft-Windows-AppLocker/EXE and DLL"
$appLockerLog.MaximumSizeInBytes = 10485760
$appLockerLog.SaveChanges()
```
- Generate the CSV feed 
```powershell
function sid { Param($iD) ($(New-Object System.Security.Principal.SecurityIdentifier($iD)).Translate([System.Security.Principal.NTAccount]))}
Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" |Where-Object {$_.LevelDisplayName -ne "Information"} |Select-Object -Property TimeCreated,  @{label="User";expression={SID($_.UserID)}}, Message |Export-Csv .\AppLocker.csv -NoTypeInformation
```
- Run the function and review the output file PSMConfigureAppLocker_Update.xml
  - You must run the function in the location of the existing "PSMConfigureAppLocker.xml" 
- Run PSMConfigureAppLocker.ps1
