param(
    [string]$choice
)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$binDir = Join-Path $scriptPath bin
$tmpDir = Join-Path $scriptPath tmp
$libffi = Join-Path $scriptPath build-libffi.bat
$buildx86 = Join-Path $scriptPath build-ultimate-x86.bat
$buildx64 = Join-Path $scriptPath build-ultimate-x64.bat
$buildPath = Join-Path $scriptPath Ultimate
$QT32 = "C:\Qt\5.12.12\msvc2017"
$QT64 = "C:\Qt\5.12.12\msvc2017_64"
if (!(Test-Path $QT32)) {
    Write-Host "Missing Path $QT32"
    Write-Host "Execute this 1st: python -m aqt install-qt windows desktop 5.12.12 win32_msvc2017"
    exit
}
if (!(Test-Path $QT64)) {
    Write-Host "Missing Path $QT64"
    Write-Host "Execute this 1st: python -m aqt install-qt windows desktop 5.12.12 win64_msvc2017_64"
    exit
}
function DoCleanBinObj {
    if (Test-Path $binDir) {
        Remove-Item $binDir -Recurse -Force
    }
    if (Test-Path $tmpDir) {
        Remove-Item $tmpDir -Recurse -Force
    }
}
function DoCleanBuildPath {
    if (!(Test-Path $buildPath -PathType Container)) {
        New-Item -ItemType Directory -Path $buildPath
    }else{
        Remove-Item $buildPath -Recurse -Force
        New-Item -ItemType Directory -Path $buildPath
    }
}
DoCleanBinObj
$vswhere = ${env:ProgramFiles(x86)} + "\Microsoft Visual Studio\Installer\vswhere.exe";
$devShell = &$vswhere -latest -find Common7\**\Microsoft.VisualStudio.DevShell.dll
$vsVersion = &$vswhere -latest -property catalog_productLineVersion
$vsInstance = &$vswhere -latest -property instanceId
if ($vsVersion -ne "2019" -and $vsVersion -ne "2022") {
    Write-Host "Visual 2019-2022 not detected!"
    for ($i = 10; $i -ge 1; $i--) {
        Write-Host "Exiting at: $i"
        Start-Sleep -Seconds 1
    }
}
# reason for this is -wait and -wait-process sometimes waiting forever even tho the process is done XD
function RunPS { 
    param(
        [string]$Command
    )

    $installinfo = New-Object System.Diagnostics.ProcessStartInfo
    $installinfo.FileName = "powershell"
    $installinfo.Arguments = $Command
    $install = New-Object System.Diagnostics.Process
    $install.StartInfo = $installinfo
    [void]$install.Start()
    $install.WaitForExit()
    return $install.ExitCode
}

switch ($choice) {
    "step1" {
        Write-Host "Building VMProtect LibFFI..."
        &Import-Module $devShell;
        Enter-VsDevShell $vsInstance
        Set-Location $scriptPath
        Write-Host $libffi
        &$libffi
        for ($i = 3; $i -ge 1; $i--) {
            Write-Host "Wait: $i"
            Start-Sleep -Seconds 1
        }
        Write-Host "Wait finished!"
        exit
    }
    "step2" {
        Write-Host "Building VMProtect x86..."
        $env:QTDIR = $QT32
        $env:PATH += ";$QT32\bin"
        &Import-Module $devShell;
        Enter-VsDevShell $vsInstance
        Set-Location $scriptPath
        &$buildx86
        # msbuild -- help
        for ($i = 3; $i -ge 1; $i--) {
            Write-Host "Wait: $i"
            Start-Sleep -Seconds 1
        }
        Write-Host "Wait finished!"
        exit
    }
    "step3" {
        Write-Host "Building VMProtect x64..."
        $env:QTDIR = $QT64
        $env:PATH += ";$QT64\bin"
        &Import-Module $devShell;
        Enter-VsDevShell $vsInstance
        Set-Location $scriptPath
        &$buildx64
        # msbuild -- help
        for ($i = 3; $i -ge 1; $i--) {
            Write-Host "Wait: $i"
            Start-Sleep -Seconds 1
        }
        Write-Host "Wait finished!"
        exit
    }
    "step4"{
          Write-Host "Testing.."
        for ($i = 3; $i -ge 1; $i--) {
            Write-Host "Wait: $i"
            Start-Sleep -Seconds 1
        }
        Write-Host "Wait finished!"
        exit
    }
    default {
        Write-Host "Building VMProtect.."
        DoCleanBuildPath
        $script_path = "$PSScriptRoot\build-ultimate-x86-x64.ps1"
        # Start-Process "powershell.exe" -ArgumentList "-noprofile -executionpolicy bypass -file $script_path step1" -Wait
        RunPS("-noprofile -executionpolicy bypass -file $script_path step1")
        # Start-Process "powershell.exe" -ArgumentList "-noprofile -executionpolicy bypass -file $script_path step2" -Wait
        RunPS("-noprofile -executionpolicy bypass -file $script_path step2")
        if (Test-Path "$scriptPath\bin\32\Ultimate") {
            Copy-Item "$scriptPath\bin\32\Ultimate\*" -Destination "$scriptPath\Ultimate\" -Recurse -Force
        }
        # Start-Process "powershell.exe" -ArgumentList "-noprofile -executionpolicy bypass -file $script_path step3" -Wait
        RunPS("-noprofile -executionpolicy bypass -file $script_path step3")
        if (Test-Path "$scriptPath\bin\64\Ultimate") {
            Copy-Item "$scriptPath\bin\64\Ultimate\*" -Destination "$scriptPath\Ultimate\" -Recurse -Force
        }
        # RunPS("-noprofile -executionpolicy bypass -file $script_path step4")
        Copy-Item "$scriptPath\core\VMProtectLicense.ini" -Destination "$scriptPath\Ultimate\" -Recurse -Force
        DoCleanBinObj
        Write-Host "Save at: $scriptPath\Ultimate\"
    }
}


#powershell.exe -noprofile -executionpolicy bypass -file .\build-ultimate-x86-x64.ps1