# EOS modules for BlitzMax NG

Independent BlitzMax NG bindings for Epic Online Services. The public namespace
starts at `EOS.SDK`; it has no dependency on GameNet and is intended to remain
usable by applications and by higher-level adapters alike.

The current foundation covers:

- SDK initialization and shutdown
- platform creation, release, and explicit main-thread ticking
- SDK logging and result helpers
- Epic Account ID and Product User ID wrappers
- Auth login/logout, account enumeration, and auth-token copying
- Connect login/logout, Product User enumeration, and explicit user creation
- Stats ingest and query, with copied access to cached stat results
- Achievement definition/player-progress queries, explicit unlocks, and notifications
- Leaderboard definition, ranked-record, and multi-user score queries
- User Info account, display-name, and external-account queries with copied cache access
- Friends list, blocklist, and relationship-status queries
- retained asynchronous requests with terminal-result and platform-release handling

The Epic Online Services SDK is not included in this repository. See
[`SDK_SETUP.md`](SDK_SETUP.md) for the expected SDK version and layout.
The Max2D setup utility in [`tools`](tools/README.md) accepts either Epic's ZIP
or extracted directory and installs the required files for you.

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

The [`auth_connect.bmx`](sdk.mod/examples/auth_connect.bmx) example demonstrates
the Developer Authentication Tool flow. Copy its
[`eos.local.conf.example`](sdk.mod/examples/eos.local.conf.example) to the
ignored `eos.local.conf`, supply your portal values, and run the example from
that directory. New Product User creation is an explicit opt-in in the config.

For an interactive client test, build the Max2D
[`eos_auth_consent.bmx`](tools/eos_auth_consent.bmx) utility. It supports both
the Account Portal consent flow and Developer Authentication Tool login, then
continues through Connect, optional Product User creation, and read-only Stats,
User Info, Achievements, and Leaderboards checks. On macOS, Auth UI requires a GUI `.app`
context; see [`tools/README.md`](tools/README.md).
An explicitly selected `write` mode can validate the complete stat ingestion,
automatic achievement unlock, and leaderboard propagation pipeline.

The [`stats.bmx`](sdk.mod/examples/stats.bmx) example continues from Developer
Auth through Connect, ingests a configured stat, queries it, and reads the
result from the local EOS cache. Add `STAT_NAME` and `STAT_INGEST_AMOUNT` to
your ignored local configuration; the named stat must already exist in the EOS
Developer Portal. A successful ingest callback means the request reached EOS,
but backend processing and achievement updates can take additional time.

The [`achievements.bmx`](sdk.mod/examples/achievements.bmx) example queries the
configured achievement definitions and the signed-in Product User's progress.
The deployment and client policy must permit the corresponding read actions.
Unlock testing is disabled by default. Set both `ACHIEVEMENT_ID` and
`UNLOCK_ACHIEVEMENT=1` only when that permanent account mutation is intended.

The [`leaderboards.bmx`](sdk.mod/examples/leaderboards.bmx) example queries the
deployment's leaderboard definitions, then fetches ranked records for the first
configured leaderboard.
It then demonstrates an ad-hoc score query for the signed-in Product User.

The [`user_info.bmx`](sdk.mod/examples/user_info.bmx) example signs in through
Epic Account Services, queries the signed-in account's profile, and copies its
display name, permitted profile fields, and linked external-account information
from the local EOS cache. The interface also supports finding an account by its
display name or by a linked external account.

The [`friends.bmx`](sdk.mod/examples/friends.bmx) example requests the Friends
List Auth scope, queries the signed-in account's friends and blocklist, and
prints each cached relationship status.

## Status and roadmap

The suggested implementation sequence is:

1. Auth and Connect (core login lifecycle implemented; account linking and notifications remain)
2. Achievements, Stats, and Leaderboards (core interfaces implemented)
3. User Info and Friends (core implemented), then Presence
4. Lobbies and Sessions
5. P2P
6. Player Data Storage and Title Storage
7. RTC
8. Ecom, UI, sanctions/reports, anti-cheat, mods, KWS, and other specialised services

GameNet adapters such as `GameNet.EOSOnline` and `GameNet.EOSP2P` belong in a
different repository and should consume this binding rather than being added
here.
