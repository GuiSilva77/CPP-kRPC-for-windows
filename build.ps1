$workingDir = Split-Path -parent $MyInvocation.MyCommand.Definition

if (-not (Test-Path "$workingDir\krpc-src\krpc-cpp-0.5.2")) {
  Write-Warning "krpc-cpp-0.5.2 source code not found!`nPlease run the configure.ps1 script first."
  Exit
}

$workingDir = "$workingDir\krpc-src\krpc-cpp-0.5.2"

if ($null -eq (Get-Command cmake.exe -ErrorAction SilentlyContinue)) {
  Write-Warning "CMake is not installed!`nPlease install CMake from https://cmake.org/download/"
  Exit
}

if (-not (Test-Path "$workingDir\ninja.exe")) {
  Write-Warning "Ninja is not installed!`nPlese install Ninja from https://ninja-build.org/ or rerun the configure.ps1 script"
  Exit
}

# add ninja to the PATH
$env:PATH = "$workingDir; $env:PATH"

# clean up the build directory
if (Test-Path "$workingDir\build") {
  Remove-Item -Recurse -Force "$workingDir\build"
}

New-Item -ItemType Directory -Force -Path "$workingDir\build"

$env:VCPKG_ROOT = "$workingDir\vcpkg"
$env:PATH = "$env:VCPKG_ROOT; $env:PATH"

vcpkg.exe install

Set-Location "$workingDir"

cmake.exe . --preset=Release

# check if the build was successful, by checking if build.ninja exists at build
if (-not (Test-Path "$workingDir\build\build.ninja")) {
  Write-Warning "Failed to configure the build!`nPlease check the error messages above and try again."
  Exit
}

Set-Location "$workingDir\build"

ninja.exe

# check if the build was successful, by checking if krpc.lib exists at build
if (-not (Test-Path "$workingDir\build\krpc.lib")) {
  Write-Warning "Failed to build the library!`nPlease check the error messages above and try again."
  Exit
}

ninja.exe install

$appdata = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)
if (-not (Test-Path "$appdata\kRPC\lib\krpc.lib")) {
  Write-Warning "Failed to install the library!`nPlease check the error messages above and try again."
  Set-Location $PSScriptRoot
  Exit
}

#copy build\protobuf\krpc.pb.cpp to C:\Program Files\krpc\krpc.pb.cpp
Copy-Item "$workingDir\build\protobuf\src\krpc.pb.cpp" -Destination "$appdata\kRPC" -Force

Write-Host "krpc-cpp-0.5.2 has been successfully built and installed!"
