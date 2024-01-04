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
        <# 
        In order to generate the required CSV run the following PowerShell commands on the PSM after attempting to use the connector

        function sid { Param($iD) ($(New-Object System.Security.Principal.SecurityIdentifier($iD)).Translate([System.Security.Principal.NTAccount]))}
        Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" |Where-Object {$_.LevelDisplayName -ne "Information"} |Select-Object -Property TimeCreated,  @{label="User";expression={SID($_.UserID)}}, Message |Export-Csv .\AppLocker.csv -NoTypeInformation
        
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

    [string[]]$DefaultIgnoreFile = @("CMD.EXE", "CTFMON.EXE", "SETHC.EXE", "TASKFLOWUI.DLL")
    [string[]]$DefaultIgnorePath = @("%SYSTEM32%\SVCHOST.EXE")

    $ignoreFile += $DefaultIgnoreFile
    $ignorePAth += $DefaultIgnorePath

    Function GetFile([string]$inputString) {
        Return $($inputString.Substring(0, $inputString.IndexOf(" was ")))
    }

    Function ConvertPath([string]$inputString) {
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
        [System.IO.Path]::GetExtension("$($PSItem.file)")
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
        $elem.SetAttribute('Path', $($PSItem.File))
        $doc.AppendChild($elem) *> $null
        $arrExeApps += $doc.InnerXml
        $arrElem += $doc
    }
    Write-Host "Adding the following items to PSMConfigureAppLocker_Update.xml"
    $arrExeApps

    $xmlDoc = New-Object System.Xml.XmlDocument
    $xmlDoc.Load(".\PSMConfigureAppLocker.xml")

    $arrElem.SelectNodes("Application") | ForEach-Object {
        if (![string]::IsNullOrEmpty($PSItem.SessionType)) {
            $node = $xmlDoc.PSMAppLockerConfiguration.InternalApplications
        } else {
            $node = $xmlDoc.PSMAppLockerConfiguration.AllowedApplications
        }
        If ($PSItem.Path -notIn $node.Application.path) {
            $app = $node.Application[0].CloneNode($true)
            $app.Name = $PSitem.Name
            $app.Path = ConvertPath($PSItem.Path)
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
    $xmldoc.save(".\PSMConfigureAppLocker_Update.xml")
    Write-Host "Please review PSMConfigureAppLocker_Update.xml prior to import"
}