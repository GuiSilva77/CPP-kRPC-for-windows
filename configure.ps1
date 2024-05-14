# Step 2: Define the working directory
$workingDir = Split-Path -parent $MyInvocation.MyCommand.Definition

# Step 3: Check if Git, CMake, and Curl are installed
$requiredTools = @("git.exe", "cmake.exe", "curl.exe")
$toolUrls = @(
  "https://git-scm.com/download/win",
  "https://cmake.org/download/",
  "https://curl.haxx.se/windows/"
)

foreach ($tool in $requiredTools) {
  if ($null -eq (Get-Command $tool -ErrorAction SilentlyContinue)) {
    $index = $requiredTools.IndexOf($tool)
    Write-Warning "$($tool.Split('.')[0]) is not installed!`nPlease install $($tool.Split('.')[0]) from $($toolUrls[$index])"
    Set-Location $PSScriptRoot
    Exit
  }
}

# Step 4: Clean up previous installations
$cleanupItems = @("$workingDir\krpc-src", "$workingDir\krpc-cpp-0.5.2.zip")
$cleanupItems | ForEach-Object {
  if (Test-Path $_) {
    Remove-Item -Path $_ -Recurse -Force
  }
}

# Step 5: Check and install Ninja if not present
if ($null -eq (Get-Command ninja.exe -ErrorAction SilentlyContinue)) {
  Write-Host "Downloading and installing Ninja..."
  $ninjaPath = "$workingDir\ninja.exe"
  if (-not (Test-Path $ninjaPath)) {
    curl.exe -L www.github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip > "$workingDir\ninja-win.zip"
    Expand-Archive -Path "$workingDir\ninja-win.zip" -DestinationPath $workingDir
    Remove-Item -Path "$workingDir\ninja-win.zip" -Force
  }
  Write-Host "Ninja installed successfully."
}

# Step 6: Download and prepare kRPC
Clear-Host
Write-Host "Downloading kRPC source code..."
curl.exe -L www.github.com/krpc/krpc/releases/download/v0.5.2/krpc-cpp-0.5.2.zip > "$workingDir\krpc-cpp-0.5.2.zip"

if (-not (Test-Path "$workingDir\krpc-cpp-0.5.2.zip")) {
  Write-Warning "Failed to download the source code!`nPlease check your internet connection and try again."
  Set-Location $PSScriptRoot
  Exit
}

Write-Host "Source code downloaded successfully."
$krpcSRC = New-Item -ItemType Directory -Force -Path "$workingDir\krpc-src"
Move-Item "$workingDir\krpc-cpp-0.5.2.zip" "$krpcSRC\krpc-cpp-0.5.2.zip"
Expand-Archive -Path "$krpcSRC\krpc-cpp-0.5.2.zip" -DestinationPath $krpcSRC

# Step 7: Setup kRPC build environment
Write-Host "Setting up kRPC build environment..."
Set-Location $workingDir
Copy-Item "$workingDir\ninja.exe" "$krpcSRC\krpc-cpp-0.5.2"
Set-Location "$krpcSRC\krpc-cpp-0.5.2"
New-Item -ItemType Directory -Force -Path "$krpcSRC\krpc-cpp-0.5.2\build"

# Step 8: Setup vcpkg and configure
Clear-Host
Write-Host "Setting up vcpkg..."
git clone https://github.com/microsoft/vcpkg.git
Set-Location "$krpcSRC\krpc-cpp-0.5.2\vcpkg"
.\bootstrap-vcpkg.bat

$env:VCPKG_ROOT = "$krpcSRC\krpc-cpp-0.5.2\vcpkg"
$env:PATH = "$env:VCPKG_ROOT;$env:PATH"

# Step 9: Copy necessary files
Clear-Host
Write-Host "Copying necessary files..."
Set-Location $workingDir
Copy-Item ".\vcpkg.json", ".\vcpkg-configuration.json", ".\CMakeLists.txt", ".\CMakePresets.json" -Destination "$krpcSRC\krpc-cpp-0.5.2"

# Step 10: Modify CMake presets and paths
Write-Host "Modifying CMake presets and paths..."
$cmakePresets = Get-Content "$krpcSRC\krpc-cpp-0.5.2\CMakePresets.json"
$vcpkgCMakeFilePath = "$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake"
$vcpkgCMakeFilePath = $vcpkgCMakeFilePath.Replace("\", "\\")
$cmakePresets = $cmakePresets.Replace("vcpkg.cmake", $vcpkgCMakeFilePath)

$ninjaPath = "$krpcSRC\krpc-cpp-0.5.2\ninja.exe"
$ninjaPath = $ninjaPath.Replace("\", "\\")
$cmakePresets = $cmakePresets.Replace("ninja", $ninjaPath)
$cmakePresets | Set-Content "$krpcSRC\krpc-cpp-0.5.2\CMakePresets.json"

Write-Host "Setup complete. Ready to build kRPC."
Set-Location $PSScriptRoot
