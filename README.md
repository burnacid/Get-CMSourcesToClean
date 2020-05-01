# Get-CMSourcesToClean
MECM (SCCM) Detect unused source folders

This script allows you to collect all folders that can be cleaned up since they are not used as a package source.
This scripts searches for sources from
* Applications
* Driver Packages
* Drivers
* Boot Images
* OS Images
* Software Update Packages
* Packages

It outputs the unused folders with their size in MB

## How to use
```
.\Get-CMSourcesToClean.ps1 -SiteCode SMS -SiteServer "MECM001.domain.local" -SourceShare "\\MECM001.domain.local\sources"
```
