' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

SuperStrict

Rem
bbdoc: Epic Online Services SDK foundation.
about: Provides an independent C-ABI binding for SDK lifecycle, platforms,
logging, result codes, and EOS identity handles. Call #TEOSPlatform.Tick once
per main-loop iteration and release every platform before #EOSShutdown.
End Rem
Module EOS.SDK

ModuleInfo "Version: 0.1.0"
ModuleInfo "License: zlib/libpng"
ModuleInfo "Copyright: Epic Online Services SDK - Epic Games, Inc."
ModuleInfo "Copyright: Wrapper - 2026 Bruce A Henderson"
ModuleInfo "History: 0.1.0"
ModuleInfo "History: Initial lifecycle, platform, logging, result, and identity foundation."

?win32x64
ModuleInfo "LD_OPTS: -L%PWD%/SDK/Lib"
Import "-lEOSSDK-Win64-Shipping"
?win32arm64
ModuleInfo "LD_OPTS: -L%PWD%/SDK/Lib"
Import "-lEOSSDK-Win64-Shippingarm64"
?linuxx64
ModuleInfo "LD_OPTS: -L%PWD%/SDK/Bin"
ModuleInfo "LD_OPTS: -Wl,-rpath,'$ORIGIN'"
Import "-lEOSSDK-Linux-Shipping"
?linuxarm64
ModuleInfo "LD_OPTS: -L%PWD%/SDK/Bin"
ModuleInfo "LD_OPTS: -Wl,-rpath,'$ORIGIN'"
Import "-lEOSSDK-LinuxArm64-Shipping"
?macos
ModuleInfo "LD_OPTS: -L%PWD%/SDK/Bin"
ModuleInfo "LD_OPTS: -Wl,-rpath,@loader_path"
Import "-lEOSSDK-Mac-Shipping"
?

Import "SDK/Include/*.h"
Import "glue/glue.cpp"

Const EOS_EPIC_ACCOUNT_ID_MAX_LENGTH:Int = 32
Const EOS_PRODUCT_USER_ID_MAX_LENGTH:Int = 32

Rem
bbdoc: Results shared by EOS interfaces.
about: Service-specific result values will be added with their corresponding
interfaces. #EOSResultString can describe any numeric result returned by the SDK.
End Rem
Enum EEOSResult
	Success = 0
	NoConnection = 1
	InvalidCredentials = 2
	InvalidUser = 3
	InvalidAuth = 4
	AccessDenied = 5
	MissingPermissions = 6
	TokenNotAccount = 7
	TooManyRequests = 8
	AlreadyPending = 9
	InvalidParameters = 10
	InvalidRequest = 11
	UnrecognizedResponse = 12
	IncompatibleVersion = 13
	NotConfigured = 14
	AlreadyConfigured = 15
	NotImplemented = 16
	Canceled = 17
	NotFound = 18
	OperationWillRetry = 19
	NoChange = 20
	VersionMismatch = 21
	LimitExceeded = 22
	Disabled = 23
	DuplicateNotAllowed = 24
	MissingParametersDeprecated = 25
	InvalidSandboxId = 26
	TimedOut = 27
	PartialResult = 28
	MissingRole = 29
	MissingFeature = 30
	InvalidSandbox = 31
	InvalidDeployment = 32
	InvalidProduct = 33
	InvalidProductUserId = 34
	ServiceFailure = 35
	CacheDirectoryMissing = 36
	CacheDirectoryInvalid = 37
	InvalidState = 38
	RequestInProgress = 39
	ApplicationSuspended = 40
	NetworkDisconnected = 41
	InsufficientOutputBuffer = 42
	ClientPolicyMissingAction = 43
End Enum

Enum EEOSLogLevel
	Off = 0
	Fatal = 100
	Error = 200
	Warning = 300
	Info = 400
	Verbose = 500
	VeryVerbose = 600
End Enum

Enum EEOSLogCategory
	Core = 0
	Auth = 1
	Friends = 2
	Presence = 3
	UserInfo = 4
	HttpSerialization = 5
	Ecom = 6
	P2P = 7
	Sessions = 8
	RateLimiter = 9
	PlayerDataStorage = 10
	Analytics = 11
	Messaging = 12
	Connect = 13
	Overlay = 14
	Achievements = 15
	Stats = 16
	UI = 17
	Lobby = 18
	Leaderboards = 19
	Keychain = 20
	IntegratedPlatform = 21
	TitleStorage = 22
	Mods = 23
	AntiCheat = 24
	Reports = 25
	Sanctions = 26
	ProgressionSnapshots = 27
	KWS = 28
	RTC = 29
	RTCAdmin = 30
	CustomInvites = 31
	HTTP = 41
	AllCategories = $7fffffff
End Enum

Enum EEOSPlatformFlags Flags
	None = 0
	LoadingInEditor = $00001
	DisableOverlay = $00002
	DisableSocialOverlay = $00004
	WindowsEnableOverlayD3D9 = $00010
	WindowsEnableOverlayD3D10 = $00020
	WindowsEnableOverlayOpenGL = $00040
	EnableOverlayDebugLogging = $00100
End Enum

Rem
bbdoc: Process-global SDK initialization values.
End Rem
Type TEOSInitializeOptions
	Field ProductName:String
	Field ProductVersion:String
End Type

Rem
bbdoc: Values used to create one EOS platform instance.
about: Product, sandbox, deployment, and client credential values come from the
EOS Developer Portal. Do not commit secrets or storage encryption keys.
End Rem
Type TEOSPlatformOptions
	Field ProductId:String
	Field SandboxId:String
	Field DeploymentId:String
	Field ClientId:String
	Field ClientSecret:String
	Field EncryptionKey:String
	Field OverrideCountryCode:String
	Field OverrideLocaleCode:String
	Field CacheDirectory:String
	Field IsServer:Int
	Field Flags:EEOSPlatformFlags
	Field TickBudgetInMilliseconds:UInt
	Field UseTaskNetworkTimeout:Int
	Field TaskNetworkTimeoutSeconds:Double
End Type

Interface IEOSLogListener
	Method OnEOSLog(category:String, message:String, level:EEOSLogLevel)
End Interface

Private

Global _eosInitialized:Int
Global _eosShutdown:Int
Global _eosLivePlatforms:Int

Public

Rem
bbdoc: Initializes the process-global EOS SDK.
about: Call exactly once before any other EOS operation. A successful call must
be paired with #EOSShutdown after all platform instances have been released.
End Rem
Function EOSInitialize:EEOSResult(options:TEOSInitializeOptions)
	If Not options Then Return EEOSResult.InvalidParameters
	If _eosInitialized Or _eosShutdown Then Return EEOSResult.AlreadyConfigured

	Local result:EEOSResult = bmx_eos_initialize(options.ProductName, options.ProductVersion)
	If result = EEOSResult.Success Then _eosInitialized = True
	Return result
End Function

Rem
bbdoc: Shuts down the process-global EOS SDK.
about: Every #TEOSPlatform must be released first. After successful shutdown,
no EOS function may be called again in this process.
End Rem
Function EOSShutdown:EEOSResult()
	If Not _eosInitialized Then Return EEOSResult.NotConfigured
	If _eosLivePlatforms Then Return EEOSResult.InvalidState

	TEOSLogging.SetListener(Null)
	Local result:EEOSResult = bmx_eos_shutdown()
	If result = EEOSResult.Success Then
		_eosInitialized = False
		_eosShutdown = True
	End If
	Return result
End Function

Rem
bbdoc: Returns True while EOS is initialized and has not been shut down.
End Rem
Function EOSIsInitialized:Int()
	Return _eosInitialized And Not _eosShutdown
End Function

Rem
bbdoc: Returns the version reported by the linked EOS SDK binary.
End Rem
Function EOSVersion:String()
	Return bmx_eos_version()
End Function

Rem
bbdoc: Returns the SDK name for a result value.
End Rem
Function EOSResultString:String(result:EEOSResult)
	Return bmx_eos_result_string(result)
End Function

Rem
bbdoc: Returns True when a callback result represents terminal completion.
End Rem
Function EOSResultIsOperationComplete:Int(result:EEOSResult)
	Return bmx_eos_result_is_operation_complete(result)
End Function

Rem
bbdoc: Controls SDK logging and dispatches queued messages on the ticking thread.
End Rem
Type TEOSLogging Abstract
	Private
	Global _listener:IEOSLogListener

	Public
	Rem
	bbdoc: Sets the listener for SDK log messages, or Null to stop delivery.
	about: EOS worker threads enqueue messages natively. Listeners are called only
	when a platform is ticked or #Pump is called explicitly.
	End Rem
	Function SetListener:EEOSResult(listener:IEOSLogListener)
		If Not EOSIsInitialized() Then Return EEOSResult.NotConfigured
		_listener = listener
		Return bmx_eos_logging_set_enabled(listener <> Null)
	End Function

	Rem
	bbdoc: Sets the maximum logging level for one category.
	End Rem
	Function SetLevel:EEOSResult(category:EEOSLogCategory, level:EEOSLogLevel)
		If Not EOSIsInitialized() Then Return EEOSResult.NotConfigured
		Return bmx_eos_logging_set_level(category, level)
	End Function

	Rem
	bbdoc: Delivers queued SDK log messages on the calling thread.
	End Rem
	Function Pump()
		Local category:String
		Local message:String
		Local level:EEOSLogLevel
		While bmx_eos_logging_poll(category, message, level)
			If _listener Then _listener.OnEOSLog(category, message, level)
		Wend
	End Function
End Type

Rem
bbdoc: An owned EOS platform handle.
End Rem
Type TEOSPlatform
	Private
	Field _handle:Byte Ptr

	Function _Create:TEOSPlatform(handle:Byte Ptr)
		If Not handle Then Return Null
		Local platform:TEOSPlatform = New TEOSPlatform
		platform._handle = handle
		_eosLivePlatforms :+ 1
		Return platform
	End Function

	Public
	Rem
	bbdoc: Creates a platform instance from developer-portal configuration.
	End Rem
	Function Create:TEOSPlatform(options:TEOSPlatformOptions)
		If Not EOSIsInitialized() Or Not options Then Return Null
		Return _Create(bmx_eos_platform_create(
			options.ProductId,
			options.SandboxId,
			options.DeploymentId,
			options.ClientId,
			options.ClientSecret,
			options.EncryptionKey,
			options.OverrideCountryCode,
			options.OverrideLocaleCode,
			options.CacheDirectory,
			options.IsServer,
			options.Flags,
			options.TickBudgetInMilliseconds,
			options.UseTaskNetworkTimeout,
			options.TaskNetworkTimeoutSeconds))
	End Function

	Rem
	bbdoc: Allows EOS to dispatch callbacks and perform queued work.
	about: Call once per main-loop iteration on the thread where application
	listeners should run.
	End Rem
	Method Tick()
		If Not _handle Then Return
		bmx_eos_platform_tick(_handle)
		TEOSLogging.Pump()
	End Method

	Rem
	bbdoc: Releases this platform. The operation is idempotent.
	End Rem
	Method Release()
		If Not _handle Then Return
		bmx_eos_platform_release(_handle)
		_handle = Null
		_eosLivePlatforms :- 1
	End Method

	Method IsValid:Int()
		Return _handle <> Null
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type

Rem
bbdoc: Opaque Epic Account Services identity.
End Rem
Type TEOSEpicAccountId
	Private
	Field _handle:Byte Ptr

	Function _Create:TEOSEpicAccountId(handle:Byte Ptr)
		If Not handle Then Return Null
		Local accountId:TEOSEpicAccountId = New TEOSEpicAccountId
		accountId._handle = handle
		Return accountId
	End Function

	Public
	Rem
	bbdoc: Recreates an ID from trusted text previously produced by #ToString.
	about: EOS does not authenticate or validate the provenance of this text.
	End Rem
	Function FromString:TEOSEpicAccountId(value:String)
		Return _Create(bmx_eos_epic_account_id_from_string(value))
	End Function

	Method IsValid:Int()
		Return _handle And bmx_eos_epic_account_id_is_valid(_handle)
	End Method

	Method ToString:String()
		If Not _handle Then Return ""
		Return bmx_eos_epic_account_id_to_string(_handle)
	End Method
End Type

Rem
bbdoc: Opaque EOS game-services product identity.
End Rem
Type TEOSProductUserId
	Private
	Field _handle:Byte Ptr

	Function _Create:TEOSProductUserId(handle:Byte Ptr)
		If Not handle Then Return Null
		Local productUserId:TEOSProductUserId = New TEOSProductUserId
		productUserId._handle = handle
		Return productUserId
	End Function

	Public
	Rem
	bbdoc: Recreates an ID from trusted text previously produced by #ToString.
	about: EOS does not authenticate or validate the provenance of this text.
	End Rem
	Function FromString:TEOSProductUserId(value:String)
		Return _Create(bmx_eos_product_user_id_from_string(value))
	End Function

	Method IsValid:Int()
		Return _handle And bmx_eos_product_user_id_is_valid(_handle)
	End Method

	Method ToString:String()
		If Not _handle Then Return ""
		Return bmx_eos_product_user_id_to_string(_handle)
	End Method
End Type

Private

Extern
	Function bmx_eos_initialize:EEOSResult(productName:String, productVersion:String)
	Function bmx_eos_shutdown:EEOSResult()
	Function bmx_eos_version:String()
	Function bmx_eos_result_string:String(result:EEOSResult)
	Function bmx_eos_result_is_operation_complete:Int(result:EEOSResult)

	Function bmx_eos_logging_set_enabled:EEOSResult(enabled:Int)
	Function bmx_eos_logging_set_level:EEOSResult(category:EEOSLogCategory, level:EEOSLogLevel)
	Function bmx_eos_logging_poll:Int(category:String Var, message:String Var, level:EEOSLogLevel Var)

	Function bmx_eos_platform_create:Byte Ptr(productId:String, sandboxId:String, deploymentId:String, clientId:String, clientSecret:String, encryptionKey:String, overrideCountryCode:String, overrideLocaleCode:String, cacheDirectory:String, isServer:Int, flags:EEOSPlatformFlags, tickBudgetInMilliseconds:UInt, useTaskNetworkTimeout:Int, taskNetworkTimeoutSeconds:Double)
	Function bmx_eos_platform_tick(handle:Byte Ptr)
	Function bmx_eos_platform_release(handle:Byte Ptr)

	Function bmx_eos_epic_account_id_from_string:Byte Ptr(value:String)
	Function bmx_eos_epic_account_id_is_valid:Int(handle:Byte Ptr)
	Function bmx_eos_epic_account_id_to_string:String(handle:Byte Ptr)
	Function bmx_eos_product_user_id_from_string:Byte Ptr(value:String)
	Function bmx_eos_product_user_id_is_valid:Int(handle:Byte Ptr)
	Function bmx_eos_product_user_id_to_string:String(handle:Byte Ptr)
End Extern
