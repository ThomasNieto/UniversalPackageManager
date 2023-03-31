﻿using module AnyPackage

using namespace AnyPackage.Provider
using namespace System.Collections.Generic

[PackageProvider('PowerShell')]
class PowerShellProvider : PackageProvider,
    IFindPackage, IGetPackage,
    IInstallPackage, IPublishPackage,
    ISavePackage, IUninstallPackage, IUpdatePackage,
    IGetSource, ISetSource {
    PowerShellProvider() : base('89d76409-f1b0-46cb-a881-b012be54aef5') { }

    [PackageProviderInfo] Initialize([PackageProviderInfo] $providerInfo) {
        return [PowerShellProviderInfo]::new($providerInfo)
    }

    [void] FindPackage([PackageRequest] $request) {
        if ($request.Source) {
            $sources = $this.ProviderInfo.Sources |
            Where-Object Name -eq $request.Source
        }
        else {
            $sources = $this.ProviderInfo.Sources
        }

        foreach ($source in $sources) {
            $path = Join-Path -Path $source.Location -ChildPath *.json
            Get-ChildItem -Path $path |
            ForEach-Object {
                Get-Content -Path $_.FullName |
                ConvertFrom-Json |
                Where-Object { $request.IsMatch($_.Name, $_.Version) } |
                Write-Package -Request $request -Source $source -Provider $this.ProviderInfo
            }
        }
    }

    [void] GetPackage([PackageRequest] $request) {
        $this.ProviderInfo.Packages |
        Where-Object { $request.IsMatch($_.Name, $_.version) } |
        ForEach-Object {
            $_ | Write-Package -Request $request -Source $_.Source -Provider $this.ProviderInfo
        }
    }

    [void] InstallPackage([PackageRequest] $request) {
        $params = @{
            Name = $request.Name
            Prerelease = $request.Prerelease
            Provider = 'PowerShell'
            ErrorAction = 'Ignore'
        }

        if ($request.Version) {
            $params['Version'] = $request.Version
        }

        if ($request.Source) {
            $params['Source'] = $request.Source
        }

        Find-Package @params |
        Get-Latest |
        ForEach-Object {
            $this.ProviderInfo.Packages += $_
            $_ | Write-Package -Request $request -Source $_.Source -Provider $this.ProviderInfo
        }
    }

    [void] PublishPackage([PackageRequest] $request) {
        if (-not (Test-Path -Path $request.Path)) { return }

        $package = Get-Content -Path $request.Path |
        ConvertFrom-Json

        if ($request.Source) {
            $sourceName = $request.Source
        }
        else {
            $sourceName = 'Default'
        }

        $source = $this.ProviderInfo.Sources |
        Where-Object { $_.Name -eq $sourceName }

        Copy-Item -Path $request.Path -Destination $source.Location -ErrorAction Stop

        $package |
        Write-Package -Request $request -Source $source -Provider $this.ProviderInfo
    }

    [void] SavePackage([PackageRequest] $request) {
        $params = @{
            Name = $request.Name
            Prerelease = $request.Prerelease
            Provider = 'PowerShell'
            ErrorAction = 'Ignore'
        }

        if ($request.Version) {
            $params['Version'] = $request.Version
        }

        if ($request.Source) {
            $params['Source'] = $request.Source
        }

        Find-Package @params |
        Get-Latest |
        ForEach-Object {
            $path = Join-Path -Path $_.Source.Location -ChildPath ("$($_.Name)-$($_.Version).json").ToLower()
            Copy-Item -Path $path -Destination $request.Path

            $_ | Write-Package -Request $request -Source $_.Source -Provider $this.ProviderInfo
        }
    }

    [void] UninstallPackage([PackageRequest] $request) {
        $this.ProviderInfo.Packages = $this.ProviderInfo.Packages |
        ForEach-Object {
            if ($request.IsMatch($_.Name, $_.Version)) {
                $_ |
                Write-Package -Request $request -Source $_.Source -Provider $this.ProviderInfo
            }
            else {
                $_
            }
        }
    }

    [void] UpdatePackage([PackageRequest] $request) {
        $getPackageParams = @{
            Name = $request.Name
            Provider = 'PowerShell'
            ErrorAction = 'Ignore'
        }

        $findPackageParams = @{
            Prerelease = $request.Prerelease
            ErrorAction = 'Ignore'
        }

        if ($request.Version) {
            $findPackageParams['Version'] = $request.Version
        }

        if ($request.Source) {
            $findPackageParams['Source'] = $request.Source
        }

        Get-Package @getPackageParams |
        Select-Object -Property Name -Unique |
        Find-Package @findPackageParams |
        Get-Latest |
        ForEach-Object {
            $this.ProviderInfo.Packages += $_

            $_ | Write-Package -Request $request -Source $_.Source -Provider $this.ProviderInfo
        }
    }

    [void] GetSource([SourceRequest] $sourceRequest) {
        $this.ProviderInfo.Sources |
        Where-Object Name -like $sourceRequest.Name |
        Write-Source -SourceRequest $sourceRequest -Provider $this.ProviderInfo
    }

    [void] RegisterSource([SourceRequest] $sourceRequest) {
        $source = [PSCustomObject]@{
            Name = $sourceRequest.Name
            Location = $sourceRequest.Location
            Trusted = $sourceRequest.Trusted
        }

        $this.ProviderInfo.Sources += $source

        $source |
        Write-Source -SourceRequest $sourceRequest -Provider $this.ProviderInfo
    }

    [void] SetSource([SourceRequest] $sourceRequest) {
        $source = $this.ProviderInfo.Sources |
        Where-Object { $_.Name -eq $sourceRequest.Name }

        if (-not $source) { return }

        if ($sourceRequest.Location) {
            $source.Location = $sourceRequest.Location
        }

        if ($null -ne $sourceRequest.Trusted) {
            $source.Trusted = $sourceRequest.Trusted
        }

        $source |
        Write-Source -SourceRequest $sourceRequest -Provider $this.ProviderInfo
    }

    [void] UnregisterSource([SourceRequest] $sourceRequest) {
        $this.ProviderInfo.Sources = $this.ProviderInfo.Sources |
        ForEach-Object {
            if ($sourceRequest.Name -eq $_.Name) {
                $_ |
                Write-Source -SourceRequest $sourceRequest -Provider $this.ProviderInfo
            }
            else {
                $_
            }
        }
    }
}

class PowerShellProviderInfo : PackageProviderInfo {
    # Installed packages
    [List[object]] $Packages = [List[object]]::new()

    # Registered sources
    [List[object]] $Sources = [List[object]]::new()

    PowerShellProviderInfo([PackageProviderInfo] $providerInfo) : base($providerInfo) {
        $this.Sources += @([PSCustomObject]@{
            Name = 'Default'
            Location = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "../packages")).Path
            Trusted = $true
        })
    }
}

[PackageProviderManager]::RegisterProvider([PowerShellProvider], $MyInvocation.MyCommand.ScriptBlock.Module)

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    [PackageProviderManager]::UnregisterProvider([PowerShellProvider])
}

function Get-Latest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
            ValueFromPipeline)]
        [object]
        $Package
    )

    begin {
        $packages = [List[object]]::new()
    }

    process {
        $packages.Add($Package)
    }

    end {
        $packages |
        Group-Object -Property Name |
        ForEach-Object {
            $_.Group |
            Sort-Object -Property Version -Descending |
            Select-Object -First 1
        }
    }
}

function Write-Source {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline)]
        [object]
        $InputObject,

        [Parameter(Mandatory)]
        [SourceRequest]
        $SourceRequest,

        [Parameter(Mandatory)]
        [PackageProviderInfo]
        $Provider
    )

    process {
        $source = [PackageSourceInfo]::new($InputObject.Name, $InputObject.Location, $InputObject.Trusted, $Provider)
        $SourceRequest.WriteSource($source)
    }
}

function Write-Package {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline)]
        [object]
        $InputObject,

        [Parameter(Mandatory)]
        [PackageRequest]
        $Request,

        [Parameter()]
        [object]
        $Source,

        [Parameter(Mandatory)]
        [PackageProviderInfo]
        $Provider
    )

    process {
        if ($Source) {
            $Source = [PackageSourceInfo]::new($Source.Name, $Source.Location, $Source.Trusted, $Provider)
        }

        $package = [PackageInfo]::new($InputObject.Name,
                                      $InputObject.Version,
                                      $Source,
                                      $InputObject.Description,
                                      $Provider)

        $Request.WritePackage($package)
    }
}
