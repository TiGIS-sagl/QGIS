# Building QGIS on Windows with vcpkg SDK

## Prerequisites

- Visual Studio 2022 (with "Desktop Development with C++")
- CMake 3.31+
- Pre-built vcpkg SDK
- winflexbison 2.5.25
- **Ninja** — optional but recommended for command-line builds

> **Where to place the tools**
>
> This guide does **not** assume fixed paths on your machine. Choose a working folder (for example `C:\QGIS-dev\`) and place everything there:
>
> | Component | Suggested location | What to adjust in the commands below |
> |-----------|-------------------|--------------------------------------|
> | QGIS source code | `C:\QGIS-dev\QGIS` | Change the working directory (`-S .`) |
> | vcpkg SDK | `C:\QGIS-dev\vcpkg-sdk` | Replace `SDK_PATH` |
> | winflexbison | `C:\QGIS-dev\winflexbison` | Replace `FLEX_EXECUTABLE` and `BISON_EXECUTABLE` |
> | Ninja | Anywhere in your `PATH` | Only needed if you use Ninja |
>
> The commands below use these placeholder paths. **Adapt them to your setup.**

## Preparing the SDK

The vcpkg SDK contains files with very long paths. Before extracting it:

1. **Enable Windows Long Paths** in your system:
   - Open `gpedit.msc` → Computer Configuration → Administrative Templates → System → Filesystem → **Enable Win32 long paths** → Set to **Enabled**.
   - Or via registry: set `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem\LongPathsEnabled` to `1`.
   - **Restart your computer** after this change.

2. **Extract the SDK with 7-Zip**. The Windows built-in extraction tool does **not** support paths longer than 260 characters and will silently fail or skip files.

## Detecting your toolchain versions

Before configuring, verify which MSVC and Windows SDK versions are installed on your system:

```powershell
# Find your MSVC version
Get-ChildItem "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC" -Directory

# Find your Windows SDK version
Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\Lib" -Directory
```

Use the exact version numbers you find in the commands below.

## Configuration

> **Important:** You must use the **x64** MSVC toolchain. By default PowerShell may pick up the x86 compiler, causing a 32/64-bit mismatch with the SDK's x64 libraries.
>
> **Unfortunately, CMake is NOT able to figure out the correct x64 toolchain automatically**, even if you pass `-A x64`, set environment variables, or use the Visual Studio Developer Prompt. After running the initial `cmake` command below, **you will always have to manually fix the generated files** (see the "Fixing x86/x64 mismatch" section).

### Option A — Build with Ninja (recommended for command line)

```powershell
# Configure
cmake -S . `
      -B build-ninja `
      -G Ninja `
      -D CMAKE_BUILD_TYPE=Release `
      -D SDK_PATH="C:/QGIS-dev/vcpkg-sdk" `
      -D VCPKG_TARGET_TRIPLET=x64-windows-release `
      -D FLEX_EXECUTABLE="C:/QGIS-dev/winflexbison/win_flex.exe" `
      -D BISON_EXECUTABLE="C:/QGIS-dev/winflexbison/win_bison.exe" `
      -D CMAKE_MT="C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/mt.exe" `
      -D CMAKE_RC_COMPILER="C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/rc.exe" `
      -D CMAKE_INSTALL_PREFIX="C:/QGIS-dev/QGIS/build-ninja/output" `
      -D WITH_QTWEBENGINE=OFF `
      -D WITH_3D=OFF `
      -D WITH_SERVER=OFF `
      -D ENABLE_TESTS=OFF
```

> **Note:** Even though `CMAKE_MT` and `CMAKE_RC_COMPILER` are passed as x64 above, CMake often ignores them and caches the x86 versions anyway. You **must** verify and fix this afterwards as described below.

### Option B — Build with Visual Studio (no Ninja)

Open a **Developer PowerShell for VS 2022** and run:

```powershell
cmake -S . `
      -B build `
      -G "Visual Studio 17 2022" -A x64 `
      -D SDK_PATH="C:/QGIS-dev/vcpkg-sdk" `
      -D VCPKG_TARGET_TRIPLET=x64-windows-release `
      -D FLEX_EXECUTABLE="C:/QGIS-dev/winflexbison/win_flex.exe" `
      -D BISON_EXECUTABLE="C:/QGIS-dev/winflexbison/win_bison.exe" `
      -D CMAKE_MT="C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/mt.exe" `
      -D CMAKE_RC_COMPILER="C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/rc.exe" `
      -D CMAKE_INSTALL_PREFIX="C:/QGIS-dev/QGIS/build/output" `
      -D WITH_QTWEBENGINE=OFF `
      -D WITH_3D=OFF `
      -D WITH_SERVER=OFF `
      -D ENABLE_TESTS=OFF
```

Then open the generated `.sln` in Visual Studio, or build from the command line.

> **Note:** As with Ninja, passing `-A x64` is **not sufficient** to make CMake use the x64 toolchain for all tools. The generated `.vcxproj` files may still contain x86 paths and must be corrected manually (see below).

## Fixing x86/x64 mismatch

### With Ninja (CMakeCache.txt)

After running `cmake`, open `build-ninja\CMakeCache.txt` and look for these lines:

```
CMAKE_MT:FILEPATH=C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x86/mt.exe
CMAKE_RC_COMPILER:FILEPATH=C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x86/rc.exe
CMAKE_INSTALL_PREFIX:PATH=C:/Program Files (x86)/qgis
```

Change them to:

```
CMAKE_MT:FILEPATH=C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/mt.exe
CMAKE_RC_COMPILER:FILEPATH=C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/rc.exe
CMAKE_INSTALL_PREFIX:PATH=C:/QGIS-dev/QGIS/build-ninja/output
```

Then verify no x86 library paths are left:

```powershell
Select-String -LiteralPath build-ninja\CMakeCache.txt -Pattern 'lib\\x86' -CaseSensitive
```

If nothing is printed, the cache is clean. **Do not** re-run a bare `cmake -S . -B build-ninja` afterwards — it would drop the manually passed variables (e.g. `FLEX_EXECUTABLE`). If you need to regenerate, re-run the **full** `cmake` command from the Configuration section above.

### With Visual Studio (.vcxproj files)

When building with Visual Studio, there is **no CMakeCache.txt** to edit. Instead, CMake generates `.vcxproj` files inside the `build\` folder, and the x86/x64 mismatch appears there.

1. Search the generated projects for x86 paths:

```powershell
Select-String -Path "build\*.vcxproj" -Pattern 'bin\\10\.0\.26100\.0\\x86' -SimpleMatch
```

2. Open the affected `.vcxproj` files and replace every occurrence of:
   - `\x86\` with `\x64\` in paths such as:
     - `<ExecutablePath>...\Windows Kits\10\bin\10.0.26100.0\x86;...</ExecutablePath>`
     - `<LibraryPath>...\lib\x86;...</LibraryPath>`
     - Any custom tool paths pointing to `Hostx86\x86` or `bin\x86`.

3. Also verify that the project platform is actually `x64` and not `Win32`:
   - In Visual Studio, check **Build → Configuration Manager** and ensure the active solution platform is **x64**.
   - If it shows **Win32**, create the **x64** platform via the Configuration Manager and set it for all projects.

> **Why this happens:** CMake on Windows frequently auto-detects the x86 versions of `mt.exe`, `rc.exe`, and other tools even when explicitly told to use x64. There is **no known flag or environment setting** that prevents this reliably. Manual correction of the generated files is currently the only working workaround.

## Build

### With Ninja

```powershell
cmake --build build-ninja
```

### With Visual Studio

From the command line:

```powershell
cmake --build build --config Release
```

Or open `build\QGIS.sln` in Visual Studio and build the `Release` configuration.

## Running QGIS (after build)

Regardless of the build method, the binaries alone are not enough to run QGIS. You must **install** the runtime dependencies and **copy the Qt plugins** manually.

1. **Install dependencies** (Python, MSVC runtime, GDAL tools, etc.):

```powershell
# If you built with Ninja:
cmake --install build-ninja

# If you built with Visual Studio:
cmake --install build --config Release
```

2. **Copy Qt plugins** from the vcpkg SDK. `windeployqt` does not work on `qgis.exe`, so copy the plugins folder manually:

```powershell
# If you built with Ninja:
Copy-Item -Path "C:\QGIS-dev\vcpkg-sdk\installed\x64-windows-release\Qt6\plugins\*" `
          -Destination "C:\QGIS-dev\QGIS\build-ninja\output\bin" `
          -Recurse -Force

# If you built with Visual Studio:
Copy-Item -Path "C:\QGIS-dev\vcpkg-sdk\installed\x64-windows-release\Qt6\plugins\*" `
          -Destination "C:\QGIS-dev\QGIS\build\output\bin" `
          -Recurse -Force
```

> **Note:** Adjust `SDK_PATH` and `CMAKE_INSTALL_PREFIX` in the paths above if you used different values during configuration.

After these steps, launch QGIS from:

```
# Ninja build:
C:\QGIS-dev\QGIS\build-ninja\output\bin\qgis.exe

# Visual Studio build:
C:\QGIS-dev\QGIS\build\output\bin\qgis.exe
```

## Build + Bundle (requires NSIS)

To also produce the installer/package, install [NSIS](https://nsis.sourceforge.net) first, then run:

```powershell
# Ninja:
cmake --build build-ninja --target bundle

# Visual Studio:
cmake --build build --target bundle --config Release
```

The `bundle` target builds all of QGIS and produces a package in the build directory.

## Notes

- `--config Release` is pointless with Ninja — the build type is already fixed at configure time.
- If you use a different SDK, change `SDK_PATH` accordingly.
- `LIB` and `INCLUDE` paths depend on your installed Visual Studio and Windows SDK versions; verify with `Get-ChildItem` before configuring.
