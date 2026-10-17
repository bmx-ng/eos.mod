# Epic Online Services for BlitzMax NG

`EOS.SDK` is a BlitzMax NG binding for the Epic Online Services SDK. It gives
desktop games access to Epic account login, player identity, social features,
stats, achievements, leaderboards, lobbies, and peer-to-peer networking.

The binding is independent of GameNet and can be used directly in any BlitzMax
application. The Epic SDK itself is not included in this repository.

## Quick start

### 1. Install the module

Clone the repository into the `mod` directory of the BlitzMax NG SDK you use to
build your game:

```sh
git clone https://github.com/bmx-ng/eos.mod.git /path/to/BlitzMax/mod/eos.mod
```

This module requires the current bcc2-based BlitzMax NG toolchain.

### 2. Install Epic's SDK

Download **Epic Online Services SDK 1.19.2.1** from the EOS Developer Portal.
The included Max2D setup utility accepts either the downloaded ZIP or its
extracted directory:

```sh
cd /path/to/BlitzMax/mod/eos.mod
bmk makeapp -r -t gui -o tools/eos-sdk-setup tools/eos_sdk_setup.bmx
```

Launch the resulting application and drop the ZIP or directory onto its window.
It validates the SDK and copies the required headers and libraries into
`sdk.mod/SDK`. It does not use MaxGUI.

For a terminal or CI installation, run:

```sh
tools/eos-sdk-setup --headless /path/to/EOS-SDK.zip
```

See [SDK_SETUP.md](SDK_SETUP.md) for manual installation, target-specific
runtime libraries, macOS signing and quarantine guidance, and redistribution
notes.

### 3. Configure an EOS product

In the EOS Developer Portal, create or select:

- a Product, Sandbox, and Deployment;
- an Epic Account Services application;
- a Client and Client Policy linked to that application; and
- the feature permissions needed by your game.

Basic Profile is required by Epic Account Services. Enable Friends List or
Presence only if the application requests those scopes. Lobby, Stats,
Achievements, Leaderboards, and P2P actions must also be permitted by the
client policy when you use them.

For local login testing, run Epic's Developer Authentication Tool and add one
or more test accounts.

### 4. Create local test configuration

Copy the example configuration and fill in the values from your product and
Developer Authentication Tool:

```sh
cp sdk.mod/examples/eos.local.conf.example sdk.mod/examples/eos.local.conf
```

`eos.local.conf` is ignored by Git. Keep client secrets, encryption keys,
tokens, and other credentials out of source control.

### 5. Complete the first login

Build the interactive Max2D test client:

```sh
bmk makeapp -r -t gui -o tools/eos_auth_consent tools/eos_auth_consent.bmx
```

On macOS, copy `sdk.mod/SDK/Bin/libEOSSDK-Mac-Shipping.dylib` into
`tools/eos_auth_consent.app/Contents/MacOS`, then launch the `.app`. Epic's
browser-based consent flow requires a GUI application context on macOS; a
console build may not open it correctly.

Press **A** for the Account Portal flow. Epic opens the browser so the account
can grant consent to the application. Consent is normally requested once for
each account/application/permission combination. If Connect reports that no
Product User exists, press **C** when the app offers to create one.

After consent has been granted, press **D** on later runs to use the faster
Developer Authentication Tool login. The client then checks Auth, Connect,
User Info, Friends, Presence, Stats, Achievements, and Leaderboards and reports
the result on screen.

More test modes, including lobbies, writes, and two-account P2P, are documented
in [tools/README.md](tools/README.md).

## Using `EOS.SDK`

A program initializes the process-wide SDK once, creates one or more platform
objects, ticks them from its main loop, and releases every platform before
shutting down:

```blitzmax
SuperStrict

Framework EOS.SDK

Local initialize:TEOSInitializeOptions = New TEOSInitializeOptions
initialize.ProductName = "My Game"
initialize.ProductVersion = "1.0.0"

Local result:EEOSResult = EOSInitialize(initialize)
If result <> EEOSResult.Success Then
	RuntimeError "EOS initialization failed: " + EOSResultString(result)
End If

Local options:TEOSPlatformOptions = New TEOSPlatformOptions
options.ProductId = GetEnv("EOS_PRODUCT_ID")
options.SandboxId = GetEnv("EOS_SANDBOX_ID")
options.DeploymentId = GetEnv("EOS_DEPLOYMENT_ID")
options.ClientId = GetEnv("EOS_CLIENT_ID")
options.ClientSecret = GetEnv("EOS_CLIENT_SECRET")

Local platform:TEOSPlatform = TEOSPlatform.Create(options)
If Not platform Then RuntimeError "EOS platform creation failed"

' Call once per application loop iteration. EOS callbacks are delivered here.
platform.Tick()

platform.Release()
EOSShutdown()
```

In a real application, keep asynchronous request objects alive until their
terminal callback is delivered. Keep notification subscription objects for as
long as notifications are wanted, then call `Remove`. Data returned from EOS
cache-copy methods is owned by BlitzMax and can be retained normally.

## Features and examples

| Area | Module support | Example or test |
| --- | --- | --- |
| Foundation | initialization, platform lifetime, logging, result helpers | [`foundation.bmx`](sdk.mod/examples/foundation.bmx) |
| Auth and Connect | browser or Developer Auth login, logout, Product Users, status and expiry notifications | [`auth_connect.bmx`](sdk.mod/examples/auth_connect.bmx) |
| User Info | account profiles, display-name lookup, linked external accounts | [`user_info.bmx`](sdk.mod/examples/user_info.bmx) |
| Friends | friends, blocklist, relationship state, change notifications | [`friends.bmx`](sdk.mod/examples/friends.bmx) |
| Presence | queries, online state, rich text, product data, notifications | [`presence.bmx`](sdk.mod/examples/presence.bmx) |
| Stats | ingest, query, cached stat results | [`stats.bmx`](sdk.mod/examples/stats.bmx) |
| Achievements | definitions, progress, unlocks, notifications | [`achievements.bmx`](sdk.mod/examples/achievements.bmx) |
| Leaderboards | definitions, ranks, records, user scores | [`leaderboards.bmx`](sdk.mod/examples/leaderboards.bmx) |
| Lobbies | create, search, join, invite, attributes, membership, leave and destroy | [`lobbies.bmx`](sdk.mod/examples/lobbies.bmx) |
| P2P | packets, connection notifications, NAT and relay settings, queue controls | [`p2p_diagnostics.bmx`](sdk.mod/examples/p2p_diagnostics.bmx) and [`eos_p2p_test.bmx`](tools/eos_p2p_test.bmx) |

The interactive [`eos_auth_consent.bmx`](tools/eos_auth_consent.bmx) app is the
best first integration test because it exercises the same complete account and
Product User flow a game needs.

## Shipping the runtime library

Your finished application needs the EOS runtime matching its target:

| Target | Runtime to package |
| --- | --- |
| Windows x64 | `EOSSDK-Win64-Shipping.dll` beside the executable |
| Windows ARM64 | `EOSSDK-Win64-Shippingarm64.dll` beside the executable |
| Linux x64 | `libEOSSDK-Linux-Shipping.so` beside the executable |
| Linux ARM64 | `libEOSSDK-LinuxArm64-Shipping.so` beside the executable |
| macOS x64/ARM64 | `libEOSSDK-Mac-Shipping.dylib` in the app's `Contents/MacOS` directory |

Windows builds link directly against Epic's DLL and do not need the Visual
Studio `.lib` files. Sign and notarize the EOS dylib with the rest of a macOS
application bundle. Full packaging details are in
[SDK_SETUP.md](SDK_SETUP.md#building-and-shipping-on-each-platform).

## Common problems

- **The app exits before making an EOS call:** the platform runtime library is
  probably missing from beside the executable or app-bundle executable.
- **Account Portal does not open on macOS:** build and launch a GUI `.app`, not
  a console executable, and ensure the EOS dylib is inside `Contents/MacOS`.
- **`AuthScopeNotFound`:** enable the requested Friends List or Presence
  permission on the Epic Account Services application, save it, and grant
  consent again.
- **The account cannot access the application:** add it as an organisation
  member or otherwise give it access while the product is not publicly
  available.
- **Connect returns `InvalidUser`:** create the account's Product User. The
  interactive test app makes this an explicit **C** action.
- **A query succeeds but returns no rows:** confirm the definitions and client
  policy are attached to the same Product, Sandbox, and Deployment used by the
  application.
- **macOS stalls while validating the dylib:** follow the narrowly scoped
  quarantine check in [SDK_SETUP.md](SDK_SETUP.md#macos-quarantine).

## GameNet integration

The separate [GameNet](https://github.com/bmx-ng/gamenet.mod) project provides
higher-level, transport-neutral multiplayer building blocks. Its EOS adapters
consume this binding; they are intentionally not part of `eos.mod`.

## Roadmap

The next broad areas are Player Data Storage and Title Storage, followed by
RTC. Ecom, sanctions/reports, anti-cheat, mods, KWS, and other specialised EOS
services can be added as application needs justify them.
