# EOS modules for BlitzMax NG

Independent BlitzMax NG bindings for Epic Online Services. The public namespace
starts at `EOS.SDK`; it has no dependency on GameNet and is intended to remain
usable by applications and by higher-level adapters alike.

The current foundation covers:

- SDK initialization and shutdown
- platform creation, release, and explicit main-thread ticking
- SDK logging and result helpers
- Epic Account ID and Product User ID wrappers
- a documented ownership model for future asynchronous callbacks

The Epic Online Services SDK is not included in this repository. See
[`SDK_SETUP.md`](SDK_SETUP.md) for the expected SDK version and layout.

## Minimal lifecycle

```blitzmax
SuperStrict

Framework EOS.SDK

Local initOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initOptions.ProductName = "My Game"
initOptions.ProductVersion = "1.0.0"

Local result:EEOSResult = EOSInitialize(initOptions)
If result <> EEOSResult.Success Then
	RuntimeError "EOS initialization failed: " + EOSResultString(result)
End If

' Create a TEOSPlatform with developer-portal values, then call Tick once per
' main-loop iteration. Release every platform before shutdown.

EOSShutdown()
```

Do not commit client secrets, encryption keys, exchange codes, access tokens,
or other developer-portal credentials. Load them from an ignored local config
file or the process environment.

## Status and roadmap

The suggested implementation sequence is:

1. Auth and Connect
2. Achievements, Stats, and Leaderboards
3. Friends, Presence, and User Info
4. Lobbies and Sessions
5. P2P
6. Player Data Storage and Title Storage
7. RTC
8. Ecom, UI, sanctions/reports, anti-cheat, mods, KWS, and other specialised services

GameNet adapters such as `GameNet.EOSOnline` and `GameNet.EOSP2P` belong in a
different repository and should consume this binding rather than being added
here.

