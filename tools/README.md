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

## Auth and Connect test app

`eos_auth_consent.bmx` is a small Max2D client for testing the complete Epic
Account Services Auth to EOS Connect flow. It has no MaxGUI dependency. Build
it as a GUI application:

```sh
bmk makeapp -r -t gui -o tools/eos_auth_consent tools/eos_auth_consent.bmx
```

On macOS, copy `sdk.mod/SDK/Bin/libEOSSDK-Mac-Shipping.dylib` into the generated
`eos_auth_consent.app/Contents/MacOS` directory before launching the app. The
app locates `sdk.mod/examples/eos.local.conf` when built inside this repository.

Press **A** for Account Portal login. This presents Epic's browser-based consent
flow and is normally needed once per Epic account and EAS application. Press
**D** for the faster Developer Authentication Tool login after consent has been
granted. If Connect reports that the account has no Product User, the app asks
for explicit confirmation before **C** creates one.

After Auth succeeds, the app queries the signed-in account's User Info profile,
friends, blocklist, and presence.
It also verifies that Auth and Connect login-status notifications are delivered
during the normal login sequence.
After Connect succeeds, it performs read-only Stats, Achievements, and
Leaderboards queries and reports the number of configured definitions and
cached player values. It never ingests a stat or unlocks an achievement.

For an explicit integration test, pass `write` as the third argument after the
config path and login mode. The app discovers the first configured
achievement's stat threshold, ingests the amount needed to reach it, and polls
until the stat value, achievement unlock, and leaderboard record propagate:

```sh
open tools/eos_auth_consent.app --args sdk.mod/examples/eos.local.conf developer write
```

This mode changes persistent test-user data and may permanently unlock the
achievement. It is never selected from the normal interactive login screen.

To test Presence publishing and its change notification without changing
Stats or Achievements, use the isolated `presence-write` mode. It publishes an
online status and temporary test rich text, then queries the value back:

```sh
open tools/eos_auth_consent.app --args sdk.mod/examples/eos.local.conf developer presence-write
```

To test the Lobby lifecycle, use the isolated `lobby-write` mode. It creates an
invite-only four-player lobby, publishes and copies a test attribute, verifies
the owner and member snapshot, observes the lobby-update notification, and then
destroys the lobby:

```sh
open tools/eos_auth_consent.app --args sdk.mod/examples/eos.local.conf developer lobby-write
```

The lobby uses disabled host migration so an unexpected app exit also closes
it when the local owner disconnects. This mode does not alter Stats,
Achievements, or Leaderboards.

On macOS the login UI did not progress from a console executable during local
testing. Build Auth clients as `.app` GUI bundles with an active application
event loop; a Max2D window is sufficient and MaxGUI is not required.
