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

The matching dynamic library must be shipped beside the application or in a
loader search path. On macOS the dylib uses an `@rpath` install name. On Linux
the module requests an `$ORIGIN` runtime search path. Windows applications must
copy the matching DLL beside the executable. Packaging automation will be
added after the binding is exercised on each target.

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
key and a writable absolute cache directory. Auth and Connect tests will later
need the appropriate client policy permissions and a chosen login flow. None of
these values belongs in source control.
