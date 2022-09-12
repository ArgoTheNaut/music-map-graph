<#
.SYNOPSIS
    Automatically installs the Chocolatey, GraphViz, and the PowerSHell GraphViz library

.DESCRIPTION
    Version:         0.1
    Author:          argothenaut@gmail.com
    Date Created:    2021/07/01
    Last Modified:   2022/09/12

    This script does the following tasks:
    Requirements:
        Internet connection
        Administrative execution

    Patch Notes:
        0.1:    Forked from install-DevStack.ps1

.LINK
    https://chocolatey.org/install
.LINK
    https://community.chocolatey.org/packages/Graphviz
.LINK
    https://psgraph.readthedocs.io/en/latest/Quick-Start-Installation-and-Example/
.LINK
    https://graphviz.org/doc/info/attrs.html

#>



[string]$installationPathRoot = "C:\temp\"


$installPsGraphViz = $true

$webClient = (New-Object System.Net.WebClient)
$webPageFilePath = $installationPathRoot +"site.html"


if(-not (Test-Path -Path $installationPathRoot -PathType Container)){
    Write-Host "Creating $installationPathRoot"
    mkdir $installationPathRoot
}


# Check if chocolatey is already installed.  If it isn't. install it.
if(-not (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")){
    Write-Host "Installing chocolatey"

    # Source: https://chocolatey.org/install
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

}else{
    # If it's already installed, check what the latest version is
    $VersionSite = "https://github.com/chocolatey/choco/releases/latest"
    $webClient.DownloadFile($VersionSite, $webPageFilePath)

    $fileData = (Get-Content -Path $webPageFilePath) -join "\r\n"

    ### Execution Section
    $startText = "<title>Release "
    $endText =   " "
    
    $fileFromStartText = $fileData.Substring($fileData.IndexOf($startText) + $startText.Length)
    $latestChocoVersion = $fileFromStartText.Substring(0, $fileFromStartText.IndexOf($endText))

    $installedVersion = (choco -v)

    if($installedVersion -ne $latestChocoVersion){
        choco upgrade chocolatey
    }else{
        Write-Host "Latest version is already installed: Chocolatey - $latestChocoVersion" -ForegroundColor Green
    }
}


# Check if Graphviz is installed
if(Test-Path 'C:\Program Files\Graphviz\bin\'){
    # If it's already installed, report success
    Write-Host "Already installed: Graphviz" -ForegroundColor Green
    
    # $versionInfo = (choco info Graphviz)[1]
    # $gv = "Graphviz "
    # $versionInfo = $versionInfo.Substring($versionInfo.IndexOf($gv) + $gv.Length)
    # $versionInfo = $versionInfo.Substring($versionInfo.IndexOf(" "))
}else{
    Write-Host "Installing graphviz"
    choco install graphviz
}


# Check if PSGraph powershell module is installed
if(Get-InstalledModule | where {$_.Name -eq "PSGraph"}){
    Write-Host "Already installed: Module PSGraph" -ForegroundColor Green
}else{
    Write-Host "Installing powershell graphviz library"
    Find-Module PSGraph | Install-Module
}
