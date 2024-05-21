# C++ kRPC Client installer for windows

This is a simple script to install the C++ kRPC client on windows. It downloads the latest release from the kRPC github page and installs it using CMake and Ninja.

## Requirements

- Git
- CMake
- Visual Studio with C++ and Cross Platform Development tools
- Windows SDK

## Usage

1. Make sure you have the requirements installed
2. Clone or download this repository, it has the scripts and the modified CMakeLists.txt to use vcpkg's toolchain file
3. Run powershell and navigate to the folder where you downloaded the repository
4. Run the script `.\configure.ps1`, this will download the latest release of the kRPC client and configure the environment for building the project
5. Open the folder `krpc-src\krpc-cpp-0.5.2` on Visual Studio, and let it run Cmake automatically
6. Once finished, get a terminal on `krpc-src\krpc-cpp-0.5.2\build` and run `ninja install` to build the project
7. You can now delete this folder, the kRPC client is installed in the %APPDATA%\kRPC folder.
8. You can now use the library in your projects by including the headers and linking the library with your project.

# Using kRPC

To use kRPC in your project you need to add the `%APPDATA%\kRPC\krpc.pb.cpp` as a source file in your project, this file is generated by the Ninja and contains the protobuf generated code.

## Using vcpkg

You can use the vcpkg file in this repository to manage the dependencies of your project as they are needed to use the kRPC client.

### If you use MSBuild:

0. Make sure you have the vcpkg installed and integrated with Visual Studio, and add the vcpkg file to your project root
1. Open the project properties
2. Go to `vcpkg` settings and set YES to `Use Vcpkg` and `Use Vcpkg Manifest`
3. Go to `C/C++ -> Code Generation` and set `Runtime Library` to `Multi-threaded (/MT)`
4. Go to `Linker -> Input` and add `%APPDATA%\kRPC\lib\krpc.lib` to the `Additional Dependencies`
5. Run `vcpkg install` to install the dependencies on the root of your project
6. Run `vcpkg integrate install` to integrate the dependencies with your project
7. Add the `%APPDATA%\kRPC\krpc.pb.cpp` to your project as a source file

### If you use CMake:

## OBS: I don't use CMake, I don't know if this works, please add an issue if you have any problems.

0. Make sure you have the vcpkg installed and integrated with Visual Studio, and add the vcpkg file to your project root
1. Run `vcpkg install` to install the dependencies on the root of your project
2. Add these lines to your CMakeLists.txt file:

```cmake
find_package(Protobuf 3.2 REQUIRED)
find_package(ZLIB REQUIRED)
find_package(asio CONFIG REQUIRED)
```

And add the libraries to your target:

```cmake
target_link_libraries(<your target> PRIVATE protobuf::libprotobuf ZLIB::ZLIB)
```

4. Add the `%APPDATA%\kRPC\krpc.pb.cpp` to your project as a source file
5. Add `-DCMAKE_TOOLCHAIN_FILE=<path to vcpkg.cmake>` to your cmake command to use the vcpkg toolchain file

# Known issues

I don't know if this script works with another compiler than Visual Studio, I have only tested it with Visual Studio 2022 and 2019. If you have any issues with another compiler, please add a new issue.

# Disclaimer

I am not affiliated with the kRPC project, nor do I own any of the code in the kRPC repository. This script is just a helper to install the kRPC client on windows, all the credit goes to the kRPC developers. Use at your own risk.
