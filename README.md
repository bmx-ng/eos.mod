# Epic Online Services for BlitzMax NG

`EOS.SDK` is a BlitzMax NG binding for the Epic Online Services SDK. It gives
desktop games access to Epic account login, player identity, social features,
stats, achievements, leaderboards, lobbies, peer-to-peer networking, and
native-platform integration.

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

### Managed login sessions

`TEOSSessionCoordinator` hides the Auth-to-Connect sequence used by games. It
owns the login and status callbacks, copies a fresh Epic ID token into Connect,
refreshes Connect before expiry, retries temporary network failures, and logs
out in the correct order. A game waits for `OnEOSSessionReady` and then uses
`ProductUserId()` for EOS Game Services.

Use `PersistentAuth` with an `AccountPortal` fallback for a normal desktop
release. Developer Authentication Tool credentials remain useful for local
testing:

```blitzmax
Type TGameLogin Extends TEOSSessionListener
	Field session:TEOSSessionCoordinator

	Method OnEOSSessionProductUserCreationRequired() Override
		' Ask the player before doing this in a real game.
		session.CreateProductUser()
	End Method

	Method OnEOSSessionReady(accountId:TEOSEpicAccountId, userId:TEOSProductUserId) Override
		Print "EOS Product User: " + userId.ToString()
	End Method

	Method OnEOSSessionError(result:EEOSResult, recoverable:Int) Override
		If Not recoverable Then
			Print "EOS login failed: " + EOSResultString(result)
		End If
	End Method
End Type

Local persistentCredentials:TEOSAuthCredentials = New TEOSAuthCredentials
persistentCredentials.Type = EEOSLoginCredentialType.PersistentAuth
Local persistentLogin:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
persistentLogin.Credentials = persistentCredentials

Local portalCredentials:TEOSAuthCredentials = New TEOSAuthCredentials
portalCredentials.Type = EEOSLoginCredentialType.AccountPortal
Local portalLogin:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
portalLogin.Credentials = portalCredentials

Local options:TEOSSessionOptions = New TEOSSessionOptions
options.LoginOptions = persistentLogin
options.FallbackLoginOptions = portalLogin

Local listener:TGameLogin = New TGameLogin
Local session:TEOSSessionCoordinator = TEOSSessionCoordinator.Create(platform, listener)
listener.session = session
session.Start(options)

' Call once per main-loop iteration until shutdown.
session.Tick()
```

Product User creation is never automatic. When the coordinator enters
`AwaitingProductUserCreation`, obtain the player's approval and call
`CreateProductUser`, or call `CancelProductUserCreation`. Use `Logout(True)`
for a “sign out and forget me” action; it also removes the credential used by
future `PersistentAuth` login.

### Moderation

`TEOSSanctions` queries active sanctions into the EOS cache, then copies each
result into a `TEOSPlayerSanction`. It also supports an authenticated player
appealing one of their own sanctions. `TEOSReports` submits player behavior
reports directly to EOS.

Reporting is an externally visible moderation action. Present the category and
message to the player for confirmation before calling
`SendPlayerBehaviorReport`; do not use it as an automatic telemetry or testing
endpoint. The supplied `moderation.bmx` diagnostic deliberately queries only
the signed-in user's sanctions and never submits a report.

The EOS client policy must permit the corresponding Sanctions or Reports action.
Report context is optional, but when supplied it must be valid JSON and no more
than `EOS_REPORTS_REPORTCONTEXT_MAX_LENGTH` characters.

### Searchable game sessions

`TEOSSessions` publishes and manages a playable match or server independently
of the Lobby service. Build a `TEOSSessionModification`, set its host address,
permission, capacity, and typed attributes, then pass it to `UpdateSession`.
Public sessions can be found by session ID, registered player, bucket, or
custom attribute through `TEOSSessionSearch`.

A session describes where and how to join a match; it is not a gameplay
transport. After `JoinSession` succeeds, connect using EOS P2P, a dedicated
server address, or another transport. Register and unregister players as match
membership changes, and use `StartSession`, `EndSession`, and `DestroySession`
to publish the match lifecycle. `TEOSActiveSession` provides the local state
and registered-player list.

Invitations can be sent or rejected asynchronously. `QueryInvites` refreshes a
user's invite cache; enumerate its invite IDs and copy the corresponding
session details before joining. Removable subscriptions report invite receipt,
acceptance and rejection, plus join and leave actions initiated through the
EOS Social Overlay. Overlay event IDs can also be resolved directly to session
details.

The EOS client policy must permit the Sessions action. A newly published
session can take several seconds to appear in searches. The supplied
`sessions.bmx` GUI diagnostic publishes and updates a temporary public session,
verifies its capacity and attributes by key, dumps its local state to the EOS
log, finds and inspects it, starts and ends it, and finally removes it. The
two-account `eos_sessions_test.bmx` app verifies invitation delivery,
invite-cache lookup, joining, player registration, leaving, and cleanup using
an independent EOS platform instance for each account. In Developer Auth
testing, EOS populated the receiving account's invite cache without emitting
the invite-received notification, even across independent platform instances.
Applications should treat `QueryInvites` and the resulting cache as
authoritative rather than
depending on notification delivery.

### EOS UI and Social Overlay

`TEOSPlatform.UI()` provides the EOS UI interface. It can show and hide the
Friends overlay, report its visible and exclusive-input state, set the corner
used for EOS notifications, pause overlay display, open the player report or
block dialogs, and acknowledge UI event IDs received from other EOS services.
Keep the display-settings subscription alive while the game needs the events,
and suspend gameplay input whenever EOS reports exclusive input.

Epic currently supports the Social Overlay on Windows x64, but not on macOS,
Linux, Linux ARM64, or Windows ARM64. Games on those targets should provide
their own social UI using the Friends, Presence, Lobbies, and Sessions APIs.
The UI interface can still be obtained on an unsupported target, so use the
result from `EOSSocialOverlaySupportedOnPlatform()` rather than a non-null
handle as proof that the overlay can open. On Windows, install and redistribute
Epic's Social Overlay components as required by the EOS SDK. See Epic's
[Social Overlay integration guide](https://dev.epicgames.com/docs/epic-online-services/accounts-and-social/social-overlay/sdk-integration?lang=en-US)
for the current platform requirements.

### Steam Integrated Platform

Integrated Platform support lets EOS cooperate with the native service already
used by a game. The public EOS SDK currently exposes Steam configuration. This
is separate from EOS Auth and Connect: it allows EOS to observe the local Steam
user, mirror presence, coordinate invites and sessions, and associate native
identity state with the corresponding Epic Account and Product User.

For the usual application-managed setup, initialize Steam first, create a
`TEOSIntegratedPlatformOptionsContainer`, and add
`TEOSIntegratedPlatformSteamOptions` with
`LibraryManagedByApplication`. Assign the container to
`TEOSPlatformOptions.IntegratedPlatformOptions`, create the EOS platform, then
release the container. The Steam SDK major and minor values must match the
Steamworks runtime shipped by the game.

```blitzmax
If Not SteamInit(False) Then
	RuntimeError "Steam initialization failed"
End If

Local integratedOptions:TEOSIntegratedPlatformOptionsContainer
Local result:EEOSResult = ..
	TEOSIntegratedPlatformOptionsContainer.Create(integratedOptions)

Local steamOptions:TEOSIntegratedPlatformSteamOptions = ..
	New TEOSIntegratedPlatformSteamOptions
steamOptions.Flags = ..
	EEOSIntegratedPlatformManagementFlags.LibraryManagedByApplication
steamOptions.SteamMajorVersion = 1
steamOptions.SteamMinorVersion = 65
result = integratedOptions.AddSteam(steamOptions)

platformOptions.IntegratedPlatformOptions = integratedOptions
Local platform:TEOSPlatform = TEOSPlatform.Create(platformOptions)
integratedOptions.Release()
```

Subscribe through `platform.IntegratedPlatform()` to observe native-user login
changes. A pre-logout handler may process logout immediately or defer it while
the game saves progress, leaves a match, or asks the player to confirm. Every
deferred logout must eventually be completed with
`FinalizeDeferredUserLogout`. If the game, rather than EOS, detects local-user
login state, include `ApplicationManagedIdentityLogin` in the configuration and
call `SetUserLoginStatus` whenever it changes.

`LibraryManagedBySDK` is also supported. It requires the absolute Steam runtime
path and the exact null-separated interface-version block generated by the
matching `steam_api.h`; this block is intentionally accepted as `Byte[]` so its
embedded null characters are preserved.

## Features and examples

| Area | Module support | Example or test |
| --- | --- | --- |
| Foundation | initialization, platform lifetime, logging, result helpers | [`foundation.bmx`](sdk.mod/examples/foundation.bmx) |
| Auth and Connect | managed browser, persistent, or Developer Auth sessions; logout; Product Users; refresh and reconnection | [`auth_connect.bmx`](sdk.mod/examples/auth_connect.bmx) |
| User Info | account profiles, display-name lookup, linked external accounts | [`user_info.bmx`](sdk.mod/examples/user_info.bmx) |
| Friends | friends, blocklist, relationship state, change notifications | [`friends.bmx`](sdk.mod/examples/friends.bmx) |
| Presence | queries, online state, rich text, product data, notifications | [`presence.bmx`](sdk.mod/examples/presence.bmx) |
| Stats | ingest, query, cached stat results | [`stats.bmx`](sdk.mod/examples/stats.bmx) |
| Achievements | definitions, progress, unlocks, notifications | [`achievements.bmx`](sdk.mod/examples/achievements.bmx) |
| Leaderboards | definitions, ranks, records, user scores | [`leaderboards.bmx`](sdk.mod/examples/leaderboards.bmx) |
| Lobbies | create, search, join, invite, attributes, membership, leave and destroy | [`lobbies.bmx`](sdk.mod/examples/lobbies.bmx) |
| Sessions | publish, search, inspect, invite, join, register players, overlay events, lifecycle and cleanup | [`sessions.bmx`](sdk.mod/examples/sessions.bmx), [`eos_sessions_test.bmx`](tools/eos_sessions_test.bmx), and [`online_sessions.bmx`](sdk.mod/tests/online_sessions.bmx) |
| P2P | packets, connection notifications, NAT and relay settings, queue controls | [`p2p_diagnostics.bmx`](sdk.mod/examples/p2p_diagnostics.bmx) and [`eos_p2p_test.bmx`](tools/eos_p2p_test.bmx) |
| Title Storage | metadata queries, streamed downloads, cache management | [`storage_streams.bmx`](sdk.mod/examples/storage_streams.bmx) |
| Player Data Storage | metadata queries, streamed upload/download, duplicate, delete, cache management | [`storage_streams.bmx`](sdk.mod/examples/storage_streams.bmx) |
| Sanctions | active-sanction queries, cached copies, player appeals | [`moderation.bmx`](sdk.mod/examples/moderation.bmx) and [`sanctions_reports.bmx`](sdk.mod/tests/sanctions_reports.bmx) |
| Reports | explicitly submitted player behavior reports with optional JSON context | [`moderation.bmx`](sdk.mod/examples/moderation.bmx) and [`sanctions_reports.bmx`](sdk.mod/tests/sanctions_reports.bmx) |
| EOS UI | Social Overlay visibility, input ownership, placement, pause, report/block dialogs, and event acknowledgement | [`ui.bmx`](sdk.mod/examples/ui.bmx) and [`online_ui.bmx`](sdk.mod/tests/online_ui.bmx) |
| Integrated Platform | Steam attachment, presence/session integration, native-user login state, and deferred logout | [`integrated_platform_steam.bmx`](sdk.mod/examples/integrated_platform_steam.bmx) and [`integrated_platform.bmx`](sdk.mod/tests/integrated_platform.bmx) |

The interactive [`eos_auth_consent.bmx`](tools/eos_auth_consent.bmx) app remains
the best first portal and permission test. The smaller
[`auth_connect.bmx`](sdk.mod/examples/auth_connect.bmx) example demonstrates the
managed session API intended for games.

Storage transfers use BlitzMax `TStream` objects. Pass a file stream for direct
disk I/O, a memory stream for in-memory data, or a custom stream for another
destination. EOS requests and supplies the data in chunks, so large files are
not silently collected into a second whole-file buffer. The caller owns the
stream by default; pass `closeStream = True` to have the transfer close it before
the completion listener runs. Set `TEOSPlatformOptions.CacheDirectory` to an
absolute writable path before creating the platform; EOS leaves both storage
interfaces unavailable when no cache directory or encryption key is configured.
The encryption key must be a stable 256-bit value represented by exactly 64
hexadecimal characters. Changing or losing it makes previously stored files
unreadable.

On macOS, build authenticated EOS examples such as `storage_streams.bmx` as a
GUI `.app` and place `libEOSSDK-Mac-Shipping.dylib` in its `Contents/MacOS`
directory. The Max2D event loop and Launch Services application context are
required even when Developer Authentication is used.

```sh
bmk makeapp -r -t gui -o tools/eos_storage_test sdk.mod/examples/storage_streams.bmx
cp sdk.mod/SDK/Bin/libEOSSDK-Mac-Shipping.dylib tools/eos_storage_test.app/Contents/MacOS
open tools/eos_storage_test.app --args sdk.mod/examples/eos.local.conf
```

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
consume this binding; they are intentionally not part of `eos.mod`. Once the
coordinator is ready, pass it directly to `TEOSOnlineService.Create`. GameNet
then consumes the Product User identity, pumps the coordinator, and reports a
confirmed session loss as an authentication failure.

## Roadmap

Potential future areas include Ecom, RTC, anti-cheat, mods, KWS,
and other specialised EOS services as application needs justify them.
