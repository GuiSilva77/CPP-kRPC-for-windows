$workingDir = Split-Path -parent $MyInvocation.MyCommand.Definition

if ($null -eq (Get-Command git.exe -ErrorAction SilentlyContinue)) {
  Write-Warning "Git is not installed!`nPlease install Git from https://git-scm.com/download/win"
  Exit
}

if ($null -eq (Get-Command cmake.exe -ErrorAction SilentlyContinue)) {
  Write-Warning "CMake is not installed!`nPlease install CMake from https://cmake.org/download/"
  Exit
}

if ($null -eq (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
  Write-Warning "Curl is not installed!`nPlease install Curl from https://curl.haxx.se/windows/"
  Exit
}
if (Test-Path "$workingDir\krpc-src") {
  Remove-Item -Recurse -Force "$workingDir\krpc-src"
}

if (Test-Path "$workingDir\krpc-cpp-0.5.2.zip") {
  Remove-Item -Force "$workingDir\krpc-cpp-0.5.2.zip"
}

if ($null -eq (Get-Command ninja.exe -ErrorAction SilentlyContinue)) {
  if (-not (Test-Path "$workingDir\ninja.exe")) {
    # get a portable version of ninja
    curl.exe -L www.github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip > "$workingDir\ninja-win.zip"
    Expand-Archive -Path .\ninja-win.zip -DestinationPath .
    Remove-Item -Force .\ninja-win.zip 
  }
}


curl.exe -L www.github.com/krpc/krpc/releases/download/v0.5.2/krpc-cpp-0.5.2.zip > "$workingDir\krpc-cpp-0.5.2.zip"

if (-not (Test-Path "$workingDir\krpc-cpp-0.5.2.zip")) {
  Write-Warning "Failed to download the source code!`nPlease check your internet connection and try again."
  Exit
}

$krpcSRC = New-Item -ItemType Directory -Force -Path "$workingDir\krpc-src"

Move-Item "$workingDir\krpc-cpp-0.5.2.zip" "$krpcSRC\krpc-cpp-0.5.2.zip"

Expand-Archive -Path "$krpcSRC\krpc-cpp-0.5.2.zip" -DestinationPath "$krpcSRC"

Set-Location "$workingDir"

Copy-Item ".\ninja.exe" "$krpcSRC\krpc-cpp-0.5.2"

Set-Location "$krpcSRC\krpc-cpp-0.5.2"

if (-not (Test-Path "$krpcSRC\krpc-cpp-0.5.2\build")) {
  New-Item -ItemType Directory -Force -Path "$krpcSRC\krpc-cpp-0.5.2\build"
}

git clone https://github.com/microsoft/vcpkg.git

Set-Location "$krpcSRC\krpc-cpp-0.5.2\vcpkg"

.\bootstrap-vcpkg.bat

$env:VCPKG_ROOT = "$krpcSRC\krpc-cpp-0.5.2\vcpkg"
$env:PATH = "$env:VCPKG_ROOT; $env:PATH"

Set-Location "$workingDir"

Copy-Item ".\vcpkg.json" "$krpcSRC\krpc-cpp-0.5.2\vcpkg.json"
Copy-Item ".\vcpkg-configuration.json" "$krpcSRC\krpc-cpp-0.5.2\vcpkg-configuration.json"

Remove-Item -Force "$krpcSRC\krpc-cpp-0.5.2\CMakeLists.txt"

Copy-Item ".\CMakeLists.txt" "$krpcSRC\krpc-cpp-0.5.2\CMakeLists.txt"
Copy-Item ".\CMakePresets.json" "$krpcSRC\krpc-cpp-0.5.2\CMakePresets.json"

$cmakePresets = Get-Content "$krpcSRC\krpc-cpp-0.5.2\CMakePresets.json"

$vcpkgCMakeFilePath = "$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake"
$vcpkgCMakeFilePath = $vcpkgCMakeFilePath.Replace("\", "\\")

$cmakePresets = $cmakePresets.Replace("vcpkg.cmake", "$vcpkgCMakeFilePath")

$ninjaPath = "$krpcSRC\krpc-cpp-0.5.2\ninja.exe"
$ninjaPath = $ninjaPath.Replace("\", "\\")

$cmakePresets = $cmakePresets.Replace("ninja", "$ninjaPath")
$cmakePresets | Set-Content "$krpcSRC\krpc-cpp-0.5.2\CMakePresets.json"

Set-Location $PSScriptRoot
