# Get the directory of the script
$workingDir = Split-Path -parent $MyInvocation.MyCommand.Definition
Write-Host "Script directory obtained."

# Check if kRPC source code directory exists
if (-not (Test-Path "$workingDir\krpc-src\krpc-cpp-0.5.2")) {
  Write-Warning "krpc-cpp-0.5.2 source code not found!`nPlease run the configure.ps1 script first."
  Set-Location $PSScriptRoot
  Exit
}
Write-Host "kRPC source code directory found."

# Set working directory to kRPC source code directory
$workingDir = "$workingDir\krpc-src\krpc-cpp-0.5.2"

# Check if CMake is installed
if ($null -eq (Get-Command cmake.exe -ErrorAction SilentlyContinue)) {
  Write-Warning "CMake is not installed!`nPlease install CMake from https://cmake.org/download/"
  Set-Location $PSScriptRoot
  Exit
}
Write-Host "CMake found."

# Check if Ninja is installed
if (-not (Test-Path "$workingDir\ninja.exe")) {
  Write-Warning "Ninja is not installed!`nPlease install Ninja from https://ninja-build.org/ or rerun the configure.ps1 script"
  Set-Location $PSScriptRoot
  Exit
}
Write-Host "Ninja found."

# Add Ninja to the PATH
$env:PATH = "$workingDir;$env:PATH"
Write-Host "Ninja added to the PATH."

# Clean up the build directory
if (Test-Path "$workingDir\build") {
  Remove-Item -Recurse -Force "$workingDir\build"
}
New-Item -ItemType Directory -Force -Path "$workingDir\build"
Clear-Host
Write-Host "Build directory cleaned up and created."

# Set VCPKG_ROOT environment variable and update PATH
$env:VCPKG_ROOT = "$workingDir\vcpkg"
$env:PATH = "$env:VCPKG_ROOT;$env:PATH"

# Install dependencies using vcpkg
Write-Host "Installing dependencies using vcpkg..."
vcpkg.exe install

# Configure the build with CMake
Set-Location "$workingDir"
Write-Host "Configuring the build with CMake..."
cmake.exe . --preset=Release

# Check if the build was successful
if (-not (Test-Path "$workingDir\build\build.ninja")) {
  Write-Warning "Failed to configure the build!`nPlease check the error messages above and try again."
  Set-Location $PSScriptRoot
  Exit
}

# Build the project with Ninja
Set-Location "$workingDir\build"
Write-Host "Building the project with Ninja..."
ninja.exe

# Check if the build was successful
if (-not (Test-Path "$workingDir\build\krpc.lib")) {
  Write-Warning "Failed to build the library!`nPlease check the error messages above and try again."
  Set-Location $PSScriptRoot
  Exit
}

# Install the built library
Clear-Host
Write-Host "Installing the built library..."
ninja.exe install

# Check if the library was installed successfully
$appdata = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)
if (-not (Test-Path "$appdata\kRPC\lib\krpc.lib")) {
  Write-Warning "Failed to install the library!`nPlease check the error messages above and try again."
  Set-Location $PSScriptRoot
  Exit
}

# Copy krpc.pb.cpp to the appropriate location
Write-Host "Copying krpc.pb.cpp to the appropriate location..."
Copy-Item "$workingDir\build\protobuf\src\krpc.pb.cpp" -Destination "$appdata\kRPC" -Force

# Display success message
Write-Host "krpc-cpp-0.5.2 has been successfully built and installed! see README.md for usage instructions."
Set-Location $PSScriptRoot
