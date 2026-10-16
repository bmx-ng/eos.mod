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

ModuleInfo "Version: 0.2.0"
ModuleInfo "License: zlib/libpng"
ModuleInfo "Copyright: Epic Online Services SDK - Epic Games, Inc."
ModuleInfo "Copyright: Wrapper - 2026 Bruce A Henderson"
ModuleInfo "History: 0.1.0"
ModuleInfo "History: Initial lifecycle, platform, logging, result, and identity foundation."
ModuleInfo "History: 0.2.0"
ModuleInfo "History: Added Auth and Connect login, logout, token, enumeration, and user creation foundations."

?win32x64
ModuleInfo "LD_OPTS: -L%PWD%/SDK/Bin"
Import "-l:EOSSDK-Win64-Shipping.dll"
?win32arm64
ModuleInfo "LD_OPTS: -L%PWD%/SDK/Bin"
Import "-l:EOSSDK-Win64-Shippingarm64.dll"
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
	AuthAccountLocked = 1001
	AuthAccountLockedForUpdate = 1002
	AuthInvalidRefreshToken = 1003
	AuthInvalidToken = 1004
	AuthAuthenticationFailure = 1005
	AuthInvalidPlatformToken = 1006
	AuthWrongAccount = 1007
	AuthWrongClient = 1008
	AuthFullAccountRequired = 1009
	AuthHeadlessAccountRequired = 1010
	AuthPasswordResetRequired = 1011
	AuthPasswordCannotBeReused = 1012
	AuthExpired = 1013
	AuthScopeConsentRequired = 1014
	AuthApplicationNotFound = 1015
	AuthScopeNotFound = 1016
	AuthAccountFeatureRestricted = 1017
	AuthAccountPortalLoadError = 1018
	AuthCorrectiveActionRequired = 1019
	AuthPinGrantCode = 1020
	AuthPinGrantExpired = 1021
	AuthPinGrantPending = 1022
	AuthExternalAuthNotLinked = 1030
	AuthExternalAuthRevoked = 1032
	AuthExternalAuthInvalid = 1033
	AuthExternalAuthRestricted = 1034
	AuthExternalAuthCannotLogin = 1035
	AuthExternalAuthExpired = 1036
	AuthExternalAuthIsLastLoginType = 1037
	AuthExchangeCodeNotFound = 1040
	AuthOriginatingExchangeCodeSessionExpired = 1041
	AuthAccountNotActive = 1050
	AuthMFARequired = 1060
	AuthParentalControls = 1070
	AuthNoRealId = 1080
	AuthUserInterfaceRequired = 1090
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

Enum EEOSLoginCredentialType
	Password = 0
	ExchangeCode = 1
	PersistentAuth = 2
	DeviceCode = 3
	Developer = 4
	RefreshToken = 5
	AccountPortal = 6
	ExternalAuth = 7
End Enum

Enum EEOSExternalCredentialType
	Epic = 0
	SteamAppTicket = 1
	PSNIdToken = 2
	XBLXSTSToken = 3
	DiscordAccessToken = 4
	GOGSessionTicket = 5
	NintendoIdToken = 6
	NintendoNSAIdToken = 7
	UplayAccessToken = 8
	OpenIDAccessToken = 9
	DeviceIdAccessToken = 10
	AppleIdToken = 11
	GoogleIdToken = 12
	OculusUserIdNonce = 13
	ItchioJWT = 14
	ItchioKey = 15
	EpicIdToken = 16
	AmazonAccessToken = 17
	SteamSessionTicket = 18
	ViveportUserToken = 19
End Enum

Enum EEOSAuthScopeFlags Flags
	None = 0
	BasicProfile = $1
	FriendsList = $2
	Presence = $4
	FriendsManagement = $8
	Email = $10
	Country = $20
End Enum

Enum EEOSAuthLoginFlags Flags
	None = 0
	NoUserInterface = $1
End Enum

Enum EEOSAuthTokenType
	Client = 0
	User = 1
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

Type TEOSAuthCredentials
	Field Id:String
	Field Token:String
	Field Type:EEOSLoginCredentialType
	Field ExternalType:EEOSExternalCredentialType
End Type

Type TEOSAuthLoginOptions
	Field Credentials:TEOSAuthCredentials
	Field ScopeFlags:EEOSAuthScopeFlags = EEOSAuthScopeFlags.BasicProfile
	Field LoginFlags:EEOSAuthLoginFlags
End Type

Type TEOSConnectCredentials
	Field Token:String
	Field Type:EEOSExternalCredentialType
End Type

Type TEOSConnectUserLoginInfo
	Field DisplayName:String
	Field NsaIdToken:String
End Type

Type TEOSConnectLoginOptions
	Field Credentials:TEOSConnectCredentials
	Field UserLoginInfo:TEOSConnectUserLoginInfo
End Type

Type TEOSAuthPinGrantInfo
	Field UserCode:String
	Field VerificationURI:String
	Field ExpiresIn:Int
	Field VerificationURIComplete:String
End Type

Rem
bbdoc: A copied Epic Account Services authentication token.
about: Access and refresh tokens are credentials. Do not log, commit, or store
them without appropriate protection.
End Rem
Type TEOSAuthToken
	Field App:String
	Field ClientId:String
	Field AccountId:TEOSEpicAccountId
	Field AccessToken:String
	Field ExpiresIn:Double
	Field ExpiresAt:String
	Field AuthType:EEOSAuthTokenType
	Field RefreshToken:String
	Field RefreshExpiresIn:Double
	Field RefreshExpiresAt:String
End Type

Rem
bbdoc: A copied Epic Account Services ID token suitable for Connect login.
End Rem
Type TEOSAuthIdToken
	Field AccountId:TEOSEpicAccountId
	Field JsonWebToken:String
End Type

Rem
bbdoc: An opaque Auth follow-up token owned by EOS.
about: It remains usable only while its originating platform is valid.
End Rem
Type TEOSAuthContinuanceToken
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSAuthContinuanceToken(handle:Byte Ptr, owner:TEOSPlatform)
		If Not handle Or Not owner Then Return Null
		Local token:TEOSAuthContinuanceToken = New TEOSAuthContinuanceToken
		token._owner = owner
		token._handle = handle
		Return token
	End Function

	Method IsValid:Int()
		Return _handle And _owner And _owner.IsValid()
	End Method

	Method _NativeHandle:Byte Ptr()
		If Not IsValid() Then Return Null
		Return _handle
	End Method
End Type

Rem
bbdoc: An opaque Connect follow-up token owned by EOS.
about: It remains usable only while its originating platform is valid and
cannot be substituted with an Auth continuance token.
End Rem
Type TEOSConnectContinuanceToken
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSConnectContinuanceToken(handle:Byte Ptr, owner:TEOSPlatform)
		If Not handle Or Not owner Then Return Null
		Local token:TEOSConnectContinuanceToken = New TEOSConnectContinuanceToken
		token._owner = owner
		token._handle = handle
		Return token
	End Function

	Method IsValid:Int()
		Return _handle And _owner And _owner.IsValid()
	End Method

	Method _NativeHandle:Byte Ptr()
		If Not IsValid() Then Return Null
		Return _handle
	End Method
End Type

Interface IEOSAuthLoginListener
	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
End Interface

Interface IEOSAuthLogoutListener
	Method OnEOSAuthLogout(result:EEOSResult, localUserId:TEOSEpicAccountId)
End Interface

Interface IEOSConnectLoginListener
	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken)
End Interface

Interface IEOSConnectCreateUserListener
	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId)
End Interface

Interface IEOSConnectLogoutListener
	Method OnEOSConnectLogout(result:EEOSResult, localUserId:TEOSProductUserId)
End Interface

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

	Public
	Function _Create:TEOSPlatform(handle:Byte Ptr)
		If Not handle Then Return Null
		Local platform:TEOSPlatform = New TEOSPlatform
		platform._handle = handle
		_eosLivePlatforms :+ 1
		Return platform
	End Function

	Method _NativeHandle:Byte Ptr()
		Return _handle
	End Method

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
	bbdoc: Returns the Epic Account Services authentication interface.
	End Rem
	Method Auth:TEOSAuth()
		If Not _handle Then Return Null
		Return TEOSAuth._Create(Self, bmx_eos_platform_get_auth_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS game-services Connect interface.
	End Rem
	Method Connect:TEOSConnect()
		If Not _handle Then Return Null
		Return TEOSConnect._Create(Self, bmx_eos_platform_get_connect_interface(_handle))
	End Method

	Rem
	bbdoc: Releases this platform. The operation is idempotent.
	End Rem
	Method Release()
		If Not _handle Then Return
		Local handle:Byte Ptr = _handle
		_handle = Null
		_eosLivePlatforms :- 1
		bmx_eos_platform_release(handle)
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

	Public
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

	Method _NativeHandle:Byte Ptr()
		Return _handle
	End Method
End Type

Rem
bbdoc: Opaque EOS game-services product identity.
End Rem
Type TEOSProductUserId
	Private
	Field _handle:Byte Ptr

	Public
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

	Method _NativeHandle:Byte Ptr()
		Return _handle
	End Method
End Type

Rem
bbdoc: One pending Auth login operation.
End Rem
Type TEOSAuthLoginRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSAuthLoginListener
	Field _complete:Int

	Public
	Function _Create:TEOSAuthLoginRequest(owner:TEOSPlatform, listener:IEOSAuthLoginListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSAuthLoginRequest = New TEOSAuthLoginRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSAuthLoginRequest, result:EEOSResult, localUserHandle:Byte Ptr, userCode:String, verificationURI:String, expiresIn:Int, verificationURIComplete:String, continuanceHandle:Byte Ptr, selectedAccountHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSAuthLoginListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If Not listener Then Return

		Local pinGrant:TEOSAuthPinGrantInfo
		If userCode Or verificationURI Or verificationURIComplete Then
			pinGrant = New TEOSAuthPinGrantInfo
			pinGrant.UserCode = userCode
			pinGrant.VerificationURI = verificationURI
			pinGrant.ExpiresIn = expiresIn
			pinGrant.VerificationURIComplete = verificationURIComplete
		End If
		listener.OnEOSAuthLogin(result, TEOSEpicAccountId._Create(localUserHandle), pinGrant, TEOSAuthContinuanceToken._Create(continuanceHandle, request._owner), TEOSEpicAccountId._Create(selectedAccountHandle))
	End Function

	Function _Cancel(request:TEOSAuthLoginRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, "", "", 0, "", Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSAuthLogoutRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSAuthLogoutListener
	Field _complete:Int

	Public
	Function _Create:TEOSAuthLogoutRequest(owner:TEOSPlatform, listener:IEOSAuthLogoutListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSAuthLogoutRequest = New TEOSAuthLogoutRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSAuthLogoutRequest, result:EEOSResult, localUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSAuthLogoutListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSAuthLogout(result, TEOSEpicAccountId._Create(localUserHandle))
	End Function

	Function _Cancel(request:TEOSAuthLogoutRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSConnectLoginRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSConnectLoginListener
	Field _complete:Int

	Public
	Function _Create:TEOSConnectLoginRequest(owner:TEOSPlatform, listener:IEOSConnectLoginListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSConnectLoginRequest = New TEOSConnectLoginRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSConnectLoginRequest, result:EEOSResult, localUserHandle:Byte Ptr, continuanceHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSConnectLoginListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSConnectLogin(result, TEOSProductUserId._Create(localUserHandle), TEOSConnectContinuanceToken._Create(continuanceHandle, request._owner))
	End Function

	Function _Cancel(request:TEOSConnectLoginRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSConnectCreateUserRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSConnectCreateUserListener
	Field _complete:Int

	Public
	Function _Create:TEOSConnectCreateUserRequest(owner:TEOSPlatform, listener:IEOSConnectCreateUserListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSConnectCreateUserRequest = New TEOSConnectCreateUserRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSConnectCreateUserRequest, result:EEOSResult, localUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSConnectCreateUserListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSConnectCreateUser(result, TEOSProductUserId._Create(localUserHandle))
	End Function

	Function _Cancel(request:TEOSConnectCreateUserRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSConnectLogoutRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSConnectLogoutListener
	Field _complete:Int

	Public
	Function _Create:TEOSConnectLogoutRequest(owner:TEOSPlatform, listener:IEOSConnectLogoutListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSConnectLogoutRequest = New TEOSConnectLogoutRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSConnectLogoutRequest, result:EEOSResult, localUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSConnectLogoutListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSConnectLogout(result, TEOSProductUserId._Create(localUserHandle))
	End Function

	Function _Cancel(request:TEOSConnectLogoutRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Rem
bbdoc: Epic Account Services authentication for one platform.
End Rem
Type TEOSAuth
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSAuth(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local auth:TEOSAuth = New TEOSAuth
		auth._owner = owner
		auth._handle = handle
		Return auth
	End Function

	Rem
	bbdoc: Starts an asynchronous Epic Account Services login.
	about: Keep ticking the owning platform until the listener receives a
	terminal result. The returned request reports that terminal state.
	End Rem
	Method Login:TEOSAuthLoginRequest(options:TEOSAuthLoginOptions, listener:IEOSAuthLoginListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not options.Credentials Or Not listener Then Return Null
		Local request:TEOSAuthLoginRequest = TEOSAuthLoginRequest._Create(_owner, listener)
		bmx_eos_auth_login(_owner._NativeHandle(), _handle, request, options.Credentials.Id, options.Credentials.Token, options.Credentials.Type, options.Credentials.ExternalType, options.ScopeFlags, options.LoginFlags)
		Return request
	End Method

	Rem
	bbdoc: Logs out one Epic Account asynchronously.
	End Rem
	Method Logout:TEOSAuthLogoutRequest(localUserId:TEOSEpicAccountId, listener:IEOSAuthLogoutListener)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId._NativeHandle() Or Not listener Then Return Null
		Local request:TEOSAuthLogoutRequest = TEOSAuthLogoutRequest._Create(_owner, listener)
		bmx_eos_auth_logout(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle())
		Return request
	End Method

	Method LoggedInAccountsCount:Int()
		If Not _owner Or Not _owner.IsValid() Then Return 0
		Return bmx_eos_auth_get_logged_in_accounts_count(_handle)
	End Method

	Method LoggedInAccountByIndex:TEOSEpicAccountId(index:Int)
		If Not _owner Or Not _owner.IsValid() Or index < 0 Then Return Null
		Return TEOSEpicAccountId._Create(bmx_eos_auth_get_logged_in_account_by_index(_handle, index))
	End Method

	Rem
	bbdoc: Copies the current authentication token for a logged-in account.
	about: The returned token contains credentials and must be handled as secret.
	End Rem
	Method CopyUserAuthToken:EEOSResult(localUserId:TEOSEpicAccountId, token:TEOSAuthToken Var)
		token = Null
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId._NativeHandle() Then Return EEOSResult.InvalidParameters

		Local app:String, clientId:String, accountHandle:Byte Ptr, accessToken:String, expiresIn:Double, expiresAt:String
		Local authType:EEOSAuthTokenType, refreshToken:String, refreshExpiresIn:Double, refreshExpiresAt:String
		Local result:EEOSResult = bmx_eos_auth_copy_user_auth_token(_handle, localUserId._NativeHandle(), app, clientId, accountHandle, accessToken, expiresIn, expiresAt, authType, refreshToken, refreshExpiresIn, refreshExpiresAt)
		If result <> EEOSResult.Success Then Return result

		token = New TEOSAuthToken
		token.App = app
		token.ClientId = clientId
		token.AccountId = TEOSEpicAccountId._Create(accountHandle)
		token.AccessToken = accessToken
		token.ExpiresIn = expiresIn
		token.ExpiresAt = expiresAt
		token.AuthType = authType
		token.RefreshToken = refreshToken
		token.RefreshExpiresIn = refreshExpiresIn
		token.RefreshExpiresAt = refreshExpiresAt
		Return result
	End Method

	Rem
	bbdoc: Copies an Epic ID token for a logged-in account.
	about: Passing this token to Connect with EpicIdToken credentials is the
	recommended bridge from Epic Account Services to game services.
	End Rem
	Method CopyIdToken:EEOSResult(accountId:TEOSEpicAccountId, token:TEOSAuthIdToken Var)
		token = Null
		If Not _owner Or Not _owner.IsValid() Or Not accountId Or Not accountId._NativeHandle() Then Return EEOSResult.InvalidParameters

		Local tokenAccountHandle:Byte Ptr
		Local jsonWebToken:String
		Local result:EEOSResult = bmx_eos_auth_copy_id_token(_handle, accountId._NativeHandle(), tokenAccountHandle, jsonWebToken)
		If result <> EEOSResult.Success Then Return result

		token = New TEOSAuthIdToken
		token.AccountId = TEOSEpicAccountId._Create(tokenAccountHandle)
		token.JsonWebToken = jsonWebToken
		Return result
	End Method
End Type

Rem
bbdoc: EOS game-services identity login for one platform.
End Rem
Type TEOSConnect
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSConnect(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local connect:TEOSConnect = New TEOSConnect
		connect._owner = owner
		connect._handle = handle
		Return connect
	End Function

	Rem
	bbdoc: Starts an asynchronous game-services identity login.
	about: A terminal InvalidUser result supplies a Connect continuance token
	that may be passed to #CreateUser after explicit user consent.
	End Rem
	Method Login:TEOSConnectLoginRequest(options:TEOSConnectLoginOptions, listener:IEOSConnectLoginListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not options.Credentials Or Not listener Then Return Null
		Local request:TEOSConnectLoginRequest = TEOSConnectLoginRequest._Create(_owner, listener)
		Local useUserLoginInfo:Int = options.UserLoginInfo <> Null
		Local displayName:String, nsaIdToken:String
		If options.UserLoginInfo Then
			displayName = options.UserLoginInfo.DisplayName
			nsaIdToken = options.UserLoginInfo.NsaIdToken
		End If
		bmx_eos_connect_login(_owner._NativeHandle(), _handle, request, options.Credentials.Token, options.Credentials.Type, displayName, nsaIdToken, useUserLoginInfo)
		Return request
	End Method

	Rem
	bbdoc: Creates a Product User from a Connect InvalidUser continuance token.
	End Rem
	Method CreateUser:TEOSConnectCreateUserRequest(continuanceToken:TEOSConnectContinuanceToken, listener:IEOSConnectCreateUserListener)
		If Not _owner Or Not _owner.IsValid() Or Not continuanceToken Or Not continuanceToken.IsValid() Or Not listener Then Return Null
		Local request:TEOSConnectCreateUserRequest = TEOSConnectCreateUserRequest._Create(_owner, listener)
		bmx_eos_connect_create_user(_owner._NativeHandle(), _handle, request, continuanceToken._NativeHandle())
		Return request
	End Method

	Rem
	bbdoc: Logs out one Product User asynchronously.
	End Rem
	Method Logout:TEOSConnectLogoutRequest(localUserId:TEOSProductUserId, listener:IEOSConnectLogoutListener)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId._NativeHandle() Or Not listener Then Return Null
		Local request:TEOSConnectLogoutRequest = TEOSConnectLogoutRequest._Create(_owner, listener)
		bmx_eos_connect_logout(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle())
		Return request
	End Method

	Method LoggedInUsersCount:Int()
		If Not _owner Or Not _owner.IsValid() Then Return 0
		Return bmx_eos_connect_get_logged_in_users_count(_handle)
	End Method

	Method LoggedInUserByIndex:TEOSProductUserId(index:Int)
		If Not _owner Or Not _owner.IsValid() Or index < 0 Then Return Null
		Return TEOSProductUserId._Create(bmx_eos_connect_get_logged_in_user_by_index(_handle, index))
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
	Function bmx_eos_platform_get_auth_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_connect_interface:Byte Ptr(handle:Byte Ptr)

	Function bmx_eos_auth_login(platformHandle:Byte Ptr, authHandle:Byte Ptr, request:TEOSAuthLoginRequest, id:String, token:String, credentialType:EEOSLoginCredentialType, externalType:EEOSExternalCredentialType, scopeFlags:EEOSAuthScopeFlags, loginFlags:EEOSAuthLoginFlags)
	Function bmx_eos_auth_logout(platformHandle:Byte Ptr, authHandle:Byte Ptr, request:TEOSAuthLogoutRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_auth_get_logged_in_accounts_count:Int(authHandle:Byte Ptr)
	Function bmx_eos_auth_get_logged_in_account_by_index:Byte Ptr(authHandle:Byte Ptr, index:Int)
	Function bmx_eos_auth_copy_user_auth_token:EEOSResult(authHandle:Byte Ptr, localUserHandle:Byte Ptr, app:String Var, clientId:String Var, accountHandle:Byte Ptr Var, accessToken:String Var, expiresIn:Double Var, expiresAt:String Var, authType:EEOSAuthTokenType Var, refreshToken:String Var, refreshExpiresIn:Double Var, refreshExpiresAt:String Var)
	Function bmx_eos_auth_copy_id_token:EEOSResult(authHandle:Byte Ptr, accountHandle:Byte Ptr, tokenAccountHandle:Byte Ptr Var, jsonWebToken:String Var)

	Function bmx_eos_connect_login(platformHandle:Byte Ptr, connectHandle:Byte Ptr, request:TEOSConnectLoginRequest, token:String, credentialType:EEOSExternalCredentialType, displayName:String, nsaIdToken:String, useUserLoginInfo:Int)
	Function bmx_eos_connect_create_user(platformHandle:Byte Ptr, connectHandle:Byte Ptr, request:TEOSConnectCreateUserRequest, continuanceHandle:Byte Ptr)
	Function bmx_eos_connect_logout(platformHandle:Byte Ptr, connectHandle:Byte Ptr, request:TEOSConnectLogoutRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_connect_get_logged_in_users_count:Int(connectHandle:Byte Ptr)
	Function bmx_eos_connect_get_logged_in_user_by_index:Byte Ptr(connectHandle:Byte Ptr, index:Int)

	Function bmx_eos_epic_account_id_from_string:Byte Ptr(value:String)
	Function bmx_eos_epic_account_id_is_valid:Int(handle:Byte Ptr)
	Function bmx_eos_epic_account_id_to_string:String(handle:Byte Ptr)
	Function bmx_eos_product_user_id_from_string:Byte Ptr(value:String)
	Function bmx_eos_product_user_id_is_valid:Int(handle:Byte Ptr)
	Function bmx_eos_product_user_id_to_string:String(handle:Byte Ptr)
End Extern
