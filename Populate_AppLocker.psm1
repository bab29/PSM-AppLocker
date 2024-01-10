Function Update-PSMConfigureApplocker {
    <#
        .SYNOPSIS
        Using a csv file containing the events generates a new copy of PSMConfigureAppLocker.xml
        .DESCRIPTION
        Using a csv file containing the events generates a new copy of PSMConfigureAppLocker.xml
    #>
    param (
        #Enter the domain and samaccountname of the PSMConnect User
        [Parameter(Mandatory = $true)]
        [string]
        $PSMConnect,
        #Enter the domain and samaccountname of the PSMAdminConnect User
        [Parameter(Mandatory = $true)]
        [string]
        $PSMAdminConnect,
        #Location of PSMConfigureAppLocker.xml
        [string]
        $PSMConfigureAppLocker = ".\PSMConfigureAppLocker.xml",
        <# 
        In order to generate the required CSV run the following PowerShell commands on the PSM after attempting to use the connector

        Function Get-UserFromSID { Param($SID) ($(New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount]))}
        Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" |Where-Object {$_.LevelDisplayName -ne "Information"} |Select-Object -Property TimeCreated,  @{label="User";expression={Get-UserFromSID($_.UserID)}}, Message |Export-Csv .\AppLocker.csv -NoTypeInformation
        
        #>
        [string]
        $ApplockerReportCSV = ".\AppLocker.csv",
        #String Array of files to be added to ignored list
        #(Note: Wildcards not supported at this time)
        # @("File1.exe","File2.dll","File3.exe")
        [string[]]
        $ignoreFile,
        #String Array of file paths to be added to ignored list 
        #(Note: Wildcards not supported at this time)
        # @("C:\Windows\File1.exe","C:\Windows\system32\File2.dll","C:\Program Files (x86)\Folder\File3.exe")
        [string[]]
        $ignorePath
    )

    [string[]]$DefaultIgnoreFile = @("CMD.EXE", "CTFMON.EXE", "SETHC.EXE", "TASKFLOWUI.DLL", "ACLAYERS.DLL")
    [string[]]$DefaultIgnorePath = @("%SYSTEM32%\SVCHOST.EXE")

    $ignoreFile += $DefaultIgnoreFile
    $ignorePAth += $DefaultIgnorePath

    Function GetFile([string]$inputString) {
        Return $($inputString.Substring(0, $inputString.IndexOf(" was ")))
    }

    Function ConvertPath([string]$inputString) {
        IF ($inputString -like "*%PROGRAMFILES%*" ) {
            If (Test-Path $($inputString.Replace("%PROGRAMFILES%", "C:\Program Files"))) {
                $inputString = $inputString.Replace("%PROGRAMFILES%", "C:\Program Files")
            } elseIf (Test-Path $($inputString.Replace("%PROGRAMFILES%", "C:\Program Files (x86)"))) {
                $inputString = $inputString.Replace("%PROGRAMFILES%", "C:\Program Files (x86)")
            } else {
            
                $Choices = @(
                    [System.Management.Automation.Host.ChoiceDescription]::new("&1 Program Files")
                    [System.Management.Automation.Host.ChoiceDescription]::new("&2 Program Files(x86)")
                )
                $file = $(Split-Path $inputString -Leaf)
                $title = "Unable to locate $file"
                $question = "Is `"$file`" in `"Program Files`" or `"Program Files `(x86`)`""
                $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
                If ($decision -eq 0) {
                    $inputString = $inputString.Replace("%PROGRAMFILES%", "C:\Program Files")
                } elseif ($decision -eq 1) {
                    $inputString = $inputString.Replace("%PROGRAMFILES%", "C:\Program Files (x86)")
                }
            }
        }
        $inputString = $inputString.Replace("%SYSTEM32%", "C:\Windows\System32")
        return [System.Environment]::ExpandEnvironmentVariables("$inputString").toUpper()
    }


    $CSVInput = Import-Csv $ApplockerReportCSV

    $targets = $CSVInput | `
            Select-Object -Property Message, User, @{label = "File"; expression = { $(GetFile($_.Message)).trim() } } -Unique | `
            Where-Object { $($(Split-Path $_.file -Leaf) -notin $ignoreFile) -and $($($_.file) -notin $ignorePath) } | `
            Sort-Object File 

    [pscustomobject]$arrExeApps = @()
    [pscustomobject]$arrElem = @()
    $targets | ForEach-Object {

        $doc = New-Object System.Xml.XmlDocument
        if (".EXE" -eq ([System.IO.Path]::GetExtension("$($PSItem.file)"))) {
            $elem = $doc.CreateElement('Application')
            $elem.SetAttribute('Type', 'Exe')
        } else {
            $elem = $doc.CreateElement('Libraries')
            $elem.SetAttribute('Type', 'DLL')
        }
        if ($PSItem.User -eq $PSMConnect) { $elem.SetAttribute('SessionType', '*')
        }

        $elem.SetAttribute('Name', $(Split-Path $_.file -Leaf))
        $elem.SetAttribute('Method', 'Path')
        $elem.SetAttribute('Path', $(ConvertPath($PSItem.File)))
        $doc.AppendChild($elem) *> $null
        $arrExeApps += $doc.InnerXml
        $arrElem += $doc
    }
    Write-Host "Adding the following items to PSMConfigureAppLocker_Update.xml"
    $arrExeApps

    $xmlDoc = New-Object System.Xml.XmlDocument
    $xmlDoc.Load($PSMConfigureAppLocker)

    $arrElem.SelectNodes("Application") | ForEach-Object {
        if (![string]::IsNullOrEmpty($PSItem.SessionType)) {
            $node = $xmlDoc.PSMAppLockerConfiguration.InternalApplications
        } else {
            $node = $xmlDoc.PSMAppLockerConfiguration.AllowedApplications
        }
        If ($PSItem.Path -notIn $node.Application.path) {
            $app = $node.Application[0].CloneNode($true)
            $app.Name = $PSitem.Name
            $app.Path = $PSItem.Path
            $app.Method = $PSItem.Method
            $node.InsertAfter($app, $node.Application[$($node.Application.Count - 1)])  *> $null
        }
    }

    $arrElem.SelectNodes("Libraries") | ForEach-Object {
        if (![string]::IsNullOrEmpty($PSItem.SessionType)) {
            $node = $xmlDoc.PSMAppLockerConfiguration.InternalApplications
        } else {
            $node = $xmlDoc.PSMAppLockerConfiguration.AllowedApplications
        }
        If ($PSItem.Path -notIn $node.Libraries.path) {
            $app = $node.Libraries[0].CloneNode($true)
            $app.Name = $PSitem.Name
            $app.Path = ConvertPath($PSItem.Path)
            $app.Method = $PSItem.Method
            $node.InsertAfter($app, $node.Libraries[$($node.Libraries.Count - 1)])  *> $null
        }
    }
    $xmldoc.save("$(Split-Path $PSMConfigureAppLocker -Parent)\PSMConfigureAppLocker_Update.xml")
    Write-Host "Please review PSMConfigureAppLocker_Update.xml prior to import"
}

Function Export-AppLockerLog {
    
    <#
        .SYNOPSIS
        Exports AppLocker reports required for Update-PSMConfigureApplocker
        .DESCRIPTION
        Exports AppLocker reports required for Update-PSMConfigureApplocker
    #>
    param (
        #Filename to use for AppLocker Report
        [string]
        $ApplockerReportCSV = ".\AppLocker.csv"
    )
    Function Get-UserFromSID {
        <#
            .SYNOPSIS
            Translate SID to String
            .DESCRIPTION
            Translate SID to String
        #> 
        Param(
            #SID to translate
            [Parameter(Mandatory = $true)]
            [string]    
            $SID
        ) 
        Return $(New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount])
    }

    Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" | `
            Where-Object { $_.LevelDisplayName -ne "Information" } | `
            Select-Object -Property TimeCreated, @{label = "User"; expression = { Get-UserFromSID($_.UserID) } }, Message | `
            Export-Csv $ApplockerReportCSV -NoTypeInformation
}     


Function Set-AppLockerLogsSize {
    <#
        .SYNOPSIS
        Set maximum log file size for applocker
        .DESCRIPTION
        Set maximum log file size for applocker
    #> 
    Param(
        #Size in MB
        [int]    
        $LogSizeMB = 1
    ) 
    $appLockerLog = Get-WinEvent -ListLog "Microsoft-Windows-AppLocker/EXE and DLL"
    $appLockerLog.MaximumSizeInBytes = $($LogSize*1048576)
    $appLockerLog.SaveChanges()
}