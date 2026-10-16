# Binding design

## ABI boundary

EOS exposes a C ABI, opaque pointer handles, 32-bit enums and booleans, and
API-versioned option structures packed to 8 bytes. BlitzMax does not construct
EOS structures directly. Small native glue functions zero-initialize each
structure, select the SDK's `*_API_LATEST` constant, and call the C API. This
keeps packing, pointer width, and future version changes on the C++ side of the
boundary.

## Lifecycle

`EOS_Initialize` is process-global and may be called only once. Every successful
`EOS_Platform_Create` owns one platform handle. Applications call
`TEOSPlatform.Tick()` regularly—normally once per frame on the main thread—and
release all platforms before calling `EOSShutdown()`. No EOS function may be
called after shutdown.

The wrapper tracks live platform objects and rejects shutdown while handles are
still live. `TEOSPlatform.Release()` is idempotent; `Delete()` is a safety net,
not a substitute for deterministic release.

## Callbacks and client data

EOS asynchronous APIs associate a `void *ClientData` pointer with a completion
callback. Each request wrapper uses a native context containing a retained
BlitzMax request object. The context is created immediately before the EOS call
and released exactly once when `EOS_EResult_IsOperationComplete` reports a
terminal result. Non-terminal callbacks such as retry or PIN-grant progress keep
the same request and listener alive. Releasing a platform completes its pending
requests with `EOS_Canceled` before releasing the native platform handle.
Persistent notifications will keep their context until the matching
`RemoveNotify...` call.

Completion callbacks are normally dispatched by `EOS_Platform_Tick`, so user
listeners run on the thread that calls `Tick`. Buffer-oriented callbacks such as
P2P receive and storage transfer will pass caller-owned native buffers and
lengths across the boundary instead of allocating managed arrays per packet.

SDK logging is exceptional because EOS may emit logs from its worker threads.
The native log callback copies messages into a bounded queue. `Tick()` drains
that queue and invokes the BlitzMax listener on the ticking thread. This avoids
entering the managed runtime from EOS-owned threads.

Completion listeners may release their platform. Terminal request contexts are
removed from the platform registry before listener invocation, which makes that
re-entrant teardown safe and prevents a second cancellation callback.
Listeners should allow callbacks to return normally rather than throwing across
the native C callback boundary.

## Identity and handles

Epic Account IDs and Product User IDs are opaque SDK handles. Their BlitzMax
wrappers do not free the handles. `FromString` recreates an SDK handle but EOS
explicitly does not validate that the supplied text came from a legitimate
source; callers must not treat `IsValid()` as proof of authenticity.

Continuance tokens are also opaque, SDK-owned handles. Auth and Connect use
different wrapper types so a token cannot accidentally cross service boundaries.
Login listeners receive them only when the returned flow requires a follow-up
such as account linking or Product User creation. They have no public string
form and become unusable when their platform is released.
