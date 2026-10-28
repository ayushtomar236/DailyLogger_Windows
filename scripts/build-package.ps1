<#
.SYNOPSIS
    Builds and stages the self-contained DailyLogger Windows distribution package.

.DESCRIPTION
    Stages the WPF executable, bundled Python embedded runtime, backend scripts,
    and one-click batch runners into a ready-to-distribute package directory.
#>

[CmdletBinding()]
param(
    [string]$OutputDir = "$PSScriptRoot\..\package",
    [string]$PythonVersion = "3.11.9",
    [string]$DotNetProjectPath = "$PSScriptRoot\..\windows\src\DailyLogger.App",
    [switch]$SkipDotNetBuild,
    [switch]$SkipPythonDownload,
    [switch]$CreateZip
)

$ErrorActionPreference = "Stop"

$RootPath = Resolve-Path "$PSScriptRoot\.."
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " DailyLogger Package Staging Script" -ForegroundColor Cyan
Write-Host " Output Directory: $OutputDir" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Ensure output structure exists
$binDir = Join-Path $OutputDir "bin"
$backendDir = Join-Path $OutputDir "backend"
$runtimePythonDir = Join-Path $OutputDir "runtime\python"
$scriptsDir = Join-Path $OutputDir "scripts"

foreach ($dir in @($binDir, $backendDir, $runtimePythonDir, $scriptsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# 2. Stage Backend Python Script
$sourceBackend = Join-Path $RootPath "backend\logger.py"
if (Test-Path $sourceBackend) {
    Write-Host "[1/5] Staging backend script..." -ForegroundColor Green
    Copy-Item -Path $sourceBackend -Destination $backendDir -Force
} else {
    Write-Warning "Source backend script not found at $sourceBackend"
}

# 3. Stage Embedded Python Runtime
if (-not $SkipPythonDownload) {
    Write-Host "[2/5] Staging embedded Python runtime ($PythonVersion)..." -ForegroundColor Green
    $pythonZipUrl = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-embed-amd64.zip"
    $cacheDir = Join-Path $RootPath "cache"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    $cachedZip = Join-Path $cacheDir "python-$PythonVersion-embed-amd64.zip"

    if (-not (Test-Path $cachedZip)) {
        Write-Host "Downloading $pythonZipUrl to $cachedZip..."
        try {
            Invoke-WebRequest -Uri $pythonZipUrl -OutFile $cachedZip -UseBasicParsing
        } catch {
            Write-Warning "Failed to download embedded Python: $_. Proceeding if local runtime exists."
        }
    }

    if (Test-Path $cachedZip) {
        Write-Host "Extracting embedded Python to $runtimePythonDir..."
        Expand-Archive -Path $cachedZip -DestinationPath $runtimePythonDir -Force
        
        # Enable site-packages in embedded python ._pth file
        $pthFile = Get-ChildItem -Path $runtimePythonDir -Filter "*._pth" | Select-Object -First 1
        if ($pthFile) {
            $pthContent = Get-Content $pthFile.FullName
            if ($pthContent -match "#import site") {
                $pthContent = $pthContent -replace "#import site", "import site"
                Set-Content -Path $pthFile.FullName -Value $pthContent
            }
        }
    }
} else {
    Write-Host "[2/5] Skipping embedded Python download as requested." -ForegroundColor Yellow
}

# 4. Stage .NET WPF Application
if (-not $SkipDotNetBuild) {
    Write-Host "[3/5] Publishing self-contained .NET application..." -ForegroundColor Green
    if (Test-Path $DotNetProjectPath) {
        dotnet publish $DotNetProjectPath `
            -c Release `
            -r win-x64 `
            --self-contained true `
            -p:PublishSingleFile=true `
            -o $binDir
        if ($LASTEXITCODE -ne 0) {
            throw ".NET publish failed with exit code $LASTEXITCODE"
        }
    } else {
        Write-Host "WPF project not found at $DotNetProjectPath. Creating standalone launcher wrapper..." -ForegroundColor Yellow
        # Create lightweight standalone launcher script/executable wrapper
        $launcherBat = Join-Path $binDir "DailyLogger.App.cmd"
        $launcherContent = @"
@echo off
setlocal
set "APP_DIR=%~dp0.."
set "PYTHON_EXE=%APP_DIR%\runtime\python\python.exe"
if not exist "%PYTHON_EXE%" set "PYTHON_EXE=python"
"%PYTHON_EXE%" "%APP_DIR%\backend\logger.py" %*
"@
        Set-Content -Path $launcherBat -Value $launcherContent
    }
} else {
    Write-Host "[3/5] Skipping .NET publish as requested." -ForegroundColor Yellow
}

# 5. Copy Installation Scripts & Runners
Write-Host "[4/5] Copying installation scripts and batch runners..." -ForegroundColor Green
$sourceScripts = Join-Path $RootPath "scripts"
if (Test-Path $sourceScripts) {
    Copy-Item -Path "$sourceScripts\*.ps1" -Destination $scriptsDir -Force -ErrorAction SilentlyContinue
}

# Copy root batch runners to package root
foreach ($runner in @("install.cmd", "uninstall.cmd", "run-now.cmd", "status.cmd")) {
    $srcRunner = Join-Path $RootPath $runner
    if (Test-Path $srcRunner) {
        Copy-Item -Path $srcRunner -Destination $OutputDir -Force
    }
}

# 6. Optional Zip Archive Creation
if ($CreateZip) {
    Write-Host "[5/5] Creating distribution zip archive..." -ForegroundColor Green
    $zipPath = Join-Path $RootPath "DailyLogger-Windows-x64.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    Compress-Archive -Path "$OutputDir\*" -DestinationPath $zipPath -Force
    Write-Host "Created release archive: $zipPath" -ForegroundColor Cyan
}

Write-Host "========================================" -ForegroundColor Green
Write-Host " DailyLogger staging complete!" -ForegroundColor Green
Write-Host " Location: $OutputDir" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
