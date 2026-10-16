# EOS SDK Setup

`eos_sdk_setup.bmx` is a Max2D utility—there is no MaxGUI dependency. Build it
into this directory, launch it, and drop either Epic's EOS SDK ZIP or the
extracted SDK directory onto the window:

```sh
bmk makeapp -r -t gui -o tools/eos-sdk-setup tools/eos_sdk_setup.bmx
```

On macOS this produces `eos-sdk-setup.app`; Windows produces an `.exe`, and
Linux produces a native executable. The app searches upward from its own
location to find the `eos.mod` repository, including from inside a macOS app
bundle.

The executable also accepts a dropped path from the desktop or an explicit
command-line path. For CI and terminal use:

```sh
tools/eos-sdk-setup --headless /path/to/EOS-SDK.zip
```

If the executable is not inside `eos.mod/tools`, specify the repository:

```sh
eos-sdk-setup --headless --module-root /path/to/eos.mod /path/to/EOS-SDK
```

The helper validates EOS SDK version 1.19.2.1 and the Windows x64/ARM64, Linux
x64/ARM64, and universal macOS runtime libraries. It copies only `Include`,
`Bin`, and `ThirdPartyNotices` into `sdk.mod/SDK`. Copying rather than preserving
archive metadata also avoids carrying a browser-applied macOS quarantine
attribute into the installed module directory.
