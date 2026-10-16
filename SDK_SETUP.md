# EOS SDK setup

This binding currently targets **Epic Online Services SDK 1.19.2.1**.

Obtain the SDK under the terms presented by Epic, then place or link its `SDK`
directory at:

```text
eos.mod/sdk.mod/SDK/
  Include/
  Bin/
  Lib/
```

The easiest route is the included Max2D setup utility. Build it once, launch
it, and drop Epic's downloaded ZIP or extracted directory onto its window:

```sh
bmk makeapp -r -t gui -o tools/eos-sdk-setup tools/eos_sdk_setup.bmx
```

It validates the SDK and installs only the headers, runtime libraries, and
legal notices required by the binding. See [`tools/README.md`](tools/README.md)
for command-line and CI use.

The `SDK` path is intentionally ignored by Git. Epic's SDK agreement, rather
than this binding's zlib licence, controls whether and how the SDK headers,
libraries, tools, and notices may be redistributed. The SDK's
`ThirdPartySoftwareNotice.txt` must also accompany distributions whenever the
applicable notices require it. Confirm the current Epic agreement before
publishing any SDK artifact.

## Supported desktop binaries in SDK 1.19.2.1

| Target | Link/runtime library |
| --- | --- |
| Windows x64 | `Bin/EOSSDK-Win64-Shipping.dll` |
| Windows ARM64 | `Bin/EOSSDK-Win64-Shippingarm64.dll` |
| Linux x64 | `Bin/libEOSSDK-Linux-Shipping.so` |
| Linux ARM64 | `Bin/libEOSSDK-LinuxArm64-Shipping.so` |
| macOS x64 and ARM64 | `Bin/libEOSSDK-Mac-Shipping.dylib` (universal binary) |

There are no 32-bit desktop libraries in this SDK release.

The BlitzMax Windows build links directly against the DLL, matching the
MinGW-oriented approach used by the Steam module. Epic's `.lib` files are COFF
import archives and expose the expected `EOS_*` and `__imp_EOS_*` symbols, but
the binding does not require them.

## Building and shipping on each platform

The helper prepares the module for compilation; the final application still
needs the one runtime library matching its target. Do not ship every platform's
binary with every application.

### Windows (MinGW)

Build normally with BlitzMax NG. The module links directly to Epic's DLL, so no
Visual Studio `.lib` file or manual linker option is needed.

- x64: copy `sdk.mod/SDK/Bin/EOSSDK-Win64-Shipping.dll` beside the `.exe`.
- ARM64: copy `sdk.mod/SDK/Bin/EOSSDK-Win64-Shippingarm64.dll` beside the `.exe`.

The DLL filename must not be changed. If it is absent, Windows will reject the
application at startup before any EOS call is made.

### Linux

Build normally for x64 or ARM64, then copy the matching shared library beside
the executable:

- x64: `sdk.mod/SDK/Bin/libEOSSDK-Linux-Shipping.so`
- ARM64: `sdk.mod/SDK/Bin/libEOSSDK-LinuxArm64-Shipping.so`

The module embeds an `$ORIGIN` runtime search path, so placing the `.so` beside
the executable is sufficient. Preserve its executable/read permissions when
packaging it.

### macOS

The single `sdk.mod/SDK/Bin/libEOSSDK-Mac-Shipping.dylib` is universal and
contains both x64 and ARM64 code. For a command-line executable, place it beside
the executable. For an application bundle, place it in `Contents/MacOS` beside
the bundle executable. The module supplies the loader-relative rpath needed by
the dylib's `@rpath` install name.

Sign the finished application bundle after adding the dylib. For distribution,
the dylib must be included in the same signing and notarization workflow as the
rest of the application.

### macOS quarantine

Browsers may attach `com.apple.quarantine` to a downloaded SDK archive and its
contents. If macOS stalls or refuses while validating the signed EOS dylib,
inspect and clear that attribute on the extracted EOS SDK directory only:

```sh
xattr -lr /path/to/EOS-SDK | grep com.apple.quarantine
xattr -dr com.apple.quarantine /path/to/EOS-SDK
```

Do not apply the recursive command to a workspace, home directory, or other
broad location.

## Developer Portal values

Platform creation normally requires these values from the EOS Developer Portal:

- Product ID
- Sandbox ID
- Deployment ID
- Client ID
- Client secret

Storage features additionally require a 64-character hexadecimal encryption
key and a writable absolute cache directory. Auth requires an Epic Account
Services application with Basic Profile permission and the chosen client added
under Linked Clients. Each Epic account must grant the application consent;
the Max2D test app documented in [`tools/README.md`](tools/README.md) can start
that Account Portal flow and then verify Connect. None of these values belongs
in source control.
