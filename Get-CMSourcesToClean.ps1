<#
.SYNOPSIS
    MECM Detect unused source folders

.DESCRIPTION
	This script allows you to collect all folders that can be cleaned up since
    they are not used as a package source

.INPUTS
	The script has two switches for either Applications or Packages and requires you to enter
	the site server name.

.EXAMPLE
	.\Get-CMSourcesToClean.ps1 -SiteCode SMS -SiteServer "MECM001.domain.local" -SourceShare "\\MECM001.domain.local\sources"

.NOTES
    FileName:    Get-CMSourcesToClean.ps1
    Authors:     Stefan Lenders
    Created:     2020-05-01
    Updated:     2020-05-01
    
    Version history:
    1.0.0 - (2020-05-01) Script created (Stefan Lenders)
#>

param (
    [parameter(Position = 0, HelpMessage = "Please specify your SCCM Site Code")]
    [ValidateNotNullOrEmpty()]
	[int] $SiteCode,
	
    [parameter(Position = 0, HelpMessage = "Please specify your SCCM Server")]
	[ValidateNotNullOrEmpty()]
	[string] $SiteServer,
	
    [parameter(Position = 0, HelpMessage = "Please specify the source share. This must be with the FQDN of the server")]
	[ValidateNotNullOrEmpty()]
	[string] $SourceShare,

    [switch] $debug
)

$ProviderMachineName = $SiteServer

## DO NOT CHANGE BELOW ##
$SourceShare = $SourceShare.ToLower()

# Get netbios from SourceShare variable
$NetBiosName = $SourceShare.Split(".")
$NetBiosName = $NetBiosName[0]
$FQDNName = $SourceShare.Substring(0,$SourceShare.IndexOf("\",3)).ToLower()

# Create NetBios path
$FolderPath = $SourceShare.Substring($SourceShare.IndexOf("\",3)+1)
$NetBiosPath = ($NetBiosName+"\"+$folderPath).ToLower()

# Get share local path
$share = gwmi Win32_Share | Where{ $_.Name -eq $folderPath}
$sharePath = $share.Path.ToLower()

# Get posible drive share paths 
$diskShare = ($FQDNName+"\"+$sharePath.Replace(":","$")).ToLower()
$diskShareNetbios = ($NetBiosName+"\"+$sharePath.Replace(":","$")).ToLower()

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}
# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
}
# Set the current location to be the site code.
Set-Location "$($SiteCode):\"

function GetInfoPackages()
{
$xPackages = Get-CMPackage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name Source -Value $xpack.PkgSourcePath
    $info += $object
    }
$info
}
 
function GetInfoDriverPackage()
{
$xPackages = Get-CMDriverPackage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name Source -Value $xpack.PkgSourcePath
    $info += $object
 
    }
    $info
}
 
function GetInfoBootimage()
{
$xPackages = Get-CMBootImage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name Source -Value $xpack.PkgSourcePath
    $info += $object
    
    }
    $info
}
 
function GetInfoOSImage()
{
$xPackages = Get-CMOperatingSystemImage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name Source -Value $xpack.PkgSourcePath
    $info += $object
    
    }
    $info
}
 
function GetInfoDriver()
{
$xPackages = Get-CMDriver | Select-object LocalizedDisplayName, ContentSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.LocalizedDisplayName
    $object | Add-Member -MemberType NoteProperty  -Name Source -Value $xpack.ContentSourcePath
    $info += $object
    
    }
    $info
}
 
function GetInfoSWUpdatePackage()
{
$xPackages = Get-CMSoftwareUpdateDeploymentPackage | Select-object Name, PkgSourcePath, PackageID
$info = @()
foreach ($xpack in $xPackages) 
    {
    #write-host $xpack.Name
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
    $object | Add-Member -MemberType NoteProperty  -Name Source -Value $xpack.PkgSourcePath
    $info += $object
    
    }
    $info
}
 
function GetInfoApplications {
   
    foreach ($Application in Get-CMApplication) {
 
        $AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
        $AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title
 
        foreach ($DeploymentType in $AppMgmt.DeploymentType) {
 
            # Fill properties
            $AppData = @{            
                Package            = $AppName
                Source           = $DeploymentType.Installer.Contents.Content.Location
             }

            # Create object
            $Object = New-Object PSObject -Property $AppData
    
            # Return it
            $Object
        }
    }
 }


Write-Host "Getting Package info from SCCM Database..."

$packages = @()
Write-Progress -Activity "Get packages" -status "Applications" -percentComplete (0 / 7 * 100)
$packages += GetInfoApplications
Write-Progress -Activity "Get packages" -status "Driver Packages" -percentComplete (1 / 7 * 100)
$packages += GetInfoDriverPackage
Write-Progress -Activity "Get packages" -status "Drivers" -percentComplete (2 / 7 * 100)
$packages += GetInfoDriver
Write-Progress -Activity "Get packages" -status "Boot Images" -percentComplete (3 / 7 * 100)
$packages += GetInfoBootimage
Write-Progress -Activity "Get packages" -status "OS Images" -percentComplete (4 / 7 * 100)
$packages += GetInfoOSImage
Write-Progress -Activity "Get packages" -status "Update Packages" -percentComplete (5 / 7 * 100)
$packages += GetInfoSWUpdatePackage
Write-Progress -Activity "Get packages" -status "Packages" -percentComplete (6 / 7 * 100)
$packages += GetInfoPackages
Write-Progress -Activity "Get packages" -status "Done..." -percentComplete (7 / 7 * 100) -Completed

$dirs = @{}
$foundDirKeys = @()
$dirCount = 0

$i = 0
$total = $packages.Count
$foundDirs = @{}
$sccmSourceDirs = @()
$maxDepth = 0

$sccmSourcesDirs = @()

#Rewrite all paths to the local path for a propper compair
ForEach($source in $packages){
    if($source.Source){
        $sourceLower = $source.Source.ToLower()

        # Check and replace if NetBiosPath, localpath or diskshare is used to FQDN
        if($sourceLower -like "$NetBiosPath*"){
            # Translate \\SCCMHOST\Share

            if($debug){
                Write-Host "Unknown Folder Path: $sourceLower" -ForegroundColor Yellow -NoNewline
            }
            $sourceLower = $sourceLower.Replace($NetBiosPath, $sharePath)
            if($debug){
                Write-Host " -> $sourceLower" -ForegroundColor Green
            }
        }elseif($sourceLower -like "$SourceShare*"){
            # Translate \\SCCMHOST.FQDN.LOCAL\Share

            if($debug){
                Write-Host "Unknown Folder Path: $sourceLower" -ForegroundColor Yellow -NoNewline
            }
            $sourceLower = $sourceLower.Replace($SourceShare, $sharePath)
            if($debug){
                Write-Host " -> $sourceLower" -ForegroundColor Green
            }
        }elseif($sourceLower -like "$diskShare*"){
            # Translate \\SCCMHOST.FQDN.LOCAL\C$\folderpath

            if($debug){
                Write-Host "Unknown Folder Path: $sourceLower" -ForegroundColor Yellow -NoNewline
            }
            $sourceLower = $sourceLower.Replace($diskShare, $sharePath)
            if($debug){
                Write-Host " -> $sourceLower" -ForegroundColor Green
            }
        }elseif($sourceLower -like "$diskShareNetbios*"){
            # Translate \\SCCMHOST\X$\folderpath
            if($debug){
                Write-Host "Unknown Folder Path: $sourceLower" -ForegroundColor Yellow -NoNewline
            }
            $sourceLower = $sourceLower.Replace($diskShareNetbios, $sharePath)
            if($debug){
                Write-Host " -> $sourceLower" -ForegroundColor Green
            }
        }elseif($sourceLower -notlike $SourceShare.ToLower()+"*"){
            # Error if non of the above / not like expected format
            if($debug){
                Write-Host "Unknown Folder Path: $sourceLower" -ForegroundColor Red
            }
            continue
        }

        # calculate max search depth
        $folder = $sourceLower.Substring($sourceLower.IndexOf("\",4)+1)
        $folderArray = $folder.Split("\")

        if($folderArray.Count-1 -gt $maxDepth){
            $maxDepth = $folderArray.Count - 1 
        }

        if(-not $sccmSourcesDirs.Contains($sourceLower.ToLower())){
            $sccmSourceDirs += $sourceLower.ToLower().trim("\")
        }   
    }
}

$allPaths = $sccmSourceDirs

#Get file extensions from Sources
$Extensions = @()
$allPaths | ForEach-Object{
    if(Test-Path -Path $_){
    $Item = Get-Item $_    
        if($Item.PSIsContainer -eq $false -and $Item.Extension -notin $Extensions){
            $Extensions += $Item.Extension
        }
    }
}

Set-Location C:

$storageRoot = $sharePath

#Define an empty array to hold the removable paths i.e paths that aren't in $allPath nor have any children in $allPath
$removablePaths = @()
Function WalkTree($path){
    $path = $path.ToLower()
    if(CanBeRemoved $path){
        #If this is a file return it
        $item = Get-Item -Path $path | select *
        if($item.PSIsContainer -eq $false){
            return $path
        }

        #This folder is not in $allPath and can be removed only if it has no subfolders or all subfolders also can be deleted
        $children = Get-ChildItem $path | Where-Object{$_.Extension -in $Extensions -or $_.PSIsContainer -eq $true} | select -ExpandProperty fullName
        if($children.Count -eq 0){
            #The folder has no children and can be removed
            $global:removablePaths += $path
            return $path
        }
        else{
            #Start a new counter for subfolders (children)
            $removableChildren = @()
            $children | ForEach-Object {
                #Run this function for all subfolders
                $removableChildren += WalkTree ($_)
            }
            if($children.Count -eq $removableChildren.Count){
                #If the number of removeable subfolders are the same as the number of subfolders
                #Clean up the $removeablePaths array by deleteing all subfolders from it
                $global:removablePaths = @($global:removablePaths | Where-Object {$_ -notlike "$path*"})
                $global:removablePaths += $path
                return $path
            }
        }
    }
    else{
        return 
    }
    return $removableChildren
}

Function CanBeRemoved($path){
    if($allPaths -notcontains $path.ToLower()){
        return $true
    }
    return $false
}

WalkTree $storageRoot | Out-Null

$PathsToClean = @()
foreach($path in $removablePaths){
    try{
        $size = ((Get-ChildItem $path -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)
    }catch{
        $size = 0
    }
    
    $PathToClean = New-Object PSObject
	$PathToClean | Add-Member -type NoteProperty -Name 'Path' -Value $path
    $PathToClean | Add-Member -type NoteProperty -Name 'Size (MB)' -Value $size

    $PathsToClean += $PathToClean
}

$PathsToClean | Out-GridView

"Size to cleanup {0} GB" -f ((Get-ChildItem $removablePaths -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)