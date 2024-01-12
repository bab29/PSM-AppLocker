# Populate AppLocker Module

## Main capabilities
- Module to automate the configuration of PSMConfigureAppLocker.xml

-----------------
# Update-PSMConfigureApplocker

## SYNOPSIS
Using a csv file containing the events generates a new copy of PSMConfigureAppLocker.xml

## SYNTAX

```powershell
Update-PSMConfigureApplocker [-PSMConnect] <String> [-PSMAdminConnect] <String>
 [[-PSMConfigureAppLocker] <String>] [[-ApplockerReportCSV] <String>] [[-ignoreFile] <String[]>]
 [[-ignorePath] <String[]>] [-SuppressOutput] [-DoNotAddUnknownPaths] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Using a csv file containing the events generates a new copy of PSMConfigureAppLocker.xml

## PARAMETERS

### -PSMConnect
Enter the domain and samaccountname of the PSMConnect User

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PSMAdminConnect
Enter the domain and samaccountname of the PSMAdminConnect User

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PSMConfigureAppLocker
Location of PSMConfigureAppLocker.xml

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: "$PWD\PSMConfigureAppLocker.xml"
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplockerReportCSV
In order to generate the required CSV run the following PowerShell commands on the PSM after attempting to use the connector
```powershell
Function Get-UserFromSID { Param($SID) ($(New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate(\[System.Security.Principal.NTAccount\]))}
Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" |Where-Object {$_.LevelDisplayName -ne "Information"} |Select-Object -Property TimeCreated,  @{label="User";expression={Get-UserFromSID($_.UserID)}}, Message |Export-Csv .\AppLocker.csv -NoTypeInformation
```
```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: "$PWD\AppLocker.csv"
Accept pipeline input: False
Accept wildcard characters: False
```

### -ignoreFile
String Array of files to be added to ignored list
(Note: Wildcards not supported at this time)
 @("File1.exe","File2.dll","File3.exe")

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ignorePath
String Array of file paths to be added to ignored list 
(Note: Wildcards not supported at this time)
 @("C:\Windows\File1.exe","C:\Windows\system32\File2.dll","C:\Program Files (x86)\Folder\File3.exe")

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SuppressOutput
Suppress the output of lines to be added to PSMConfigureAppLocker.xml to the screen

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotAddUnknownPaths
If it is unable to determine the proper path for %PROGRAMFILES%, do not add the line
Normal behavior is to prompt

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).
# Export-AppLockerLog

## SYNOPSIS
Exports AppLocker reports required for Update-PSMConfigureApplocker

## SYNTAX

```powershell
Export-AppLockerLog [[-ApplockerReportCSV] <String>]
```

## DESCRIPTION
Exports AppLocker reports required for Update-PSMConfigureApplocker

## PARAMETERS

### -ApplockerReportCSV
Filename to use for AppLocker Report

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: .\AppLocker.csv
Accept pipeline input: False
Accept wildcard characters: False
```
# Set-AppLockerLogsSize

## SYNOPSIS
Set maximum log file size for applocker

## SYNTAX

```powershell
Set-AppLockerLogsSize [[-LogSizeMB] <Int32>]
```

## DESCRIPTION
Set maximum log file size for applocker

## PARAMETERS

### -LogSizeMB
Size in MB

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```
# Clear-AppLockerLogs

## SYNOPSIS
Clears Microsoft-Windows-AppLocker/EXE and DLL

## SYNTAX

```powershell
Clear-AppLockerLogs [[-DestinationPath] <String>] [-ExportLog]
```

## DESCRIPTION
Clears Microsoft-Windows-AppLocker/EXE and DLL

## PARAMETERS

### -DestinationPath
Destination for the log to be saved to

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ".\Microsoft-Windows-AppLocker EXE and DLL $(Get-Date -Format yy-MM-dd-THH-mm )"
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExportLog
Export Event log automatically

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```
