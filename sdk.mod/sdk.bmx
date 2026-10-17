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

ModuleInfo "Version: 0.7.0"
ModuleInfo "License: zlib/libpng"
ModuleInfo "Copyright: Epic Online Services SDK - Epic Games, Inc."
ModuleInfo "Copyright: Wrapper - 2026 Bruce A Henderson"
ModuleInfo "History: 0.1.0"
ModuleInfo "History: Initial lifecycle, platform, logging, result, and identity foundation."
ModuleInfo "History: 0.2.0"
ModuleInfo "History: Added Auth and Connect login, logout, token, enumeration, and user creation foundations."
ModuleInfo "History: 0.3.0"
ModuleInfo "History: Added Stats ingest, query, and cached-result access."
ModuleInfo "History: 0.4.0"
ModuleInfo "History: Added Achievement definition and player-progress queries."
ModuleInfo "History: 0.5.0"
ModuleInfo "History: Added achievement unlocking and unlock notifications."
ModuleInfo "History: 0.6.0"
ModuleInfo "History: Added leaderboard definition and rank queries."
ModuleInfo "History: 0.7.0"
ModuleInfo "History: Added leaderboard multi-user score queries."

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
Const EOS_STATS_MAX_INGEST_STATS:Int = 3000
Const EOS_STATS_MAX_QUERY_STATS:Int = 1000
Const EOS_STATS_TIME_UNDEFINED:Long = -1
Const EOS_ACHIEVEMENTS_UNLOCKTIME_UNDEFINED:Long = -1
Const EOS_LEADERBOARDS_TIME_UNDEFINED:Long = -1

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

Enum EEOSLeaderboardAggregation
	Minimum = 0
	Maximum = 1
	Sum = 2
	Latest = 3
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

Type TEOSStatsIngestData
	Field Name:String
	Field IngestAmount:Int
End Type

Type TEOSStatsIngestOptions
	Field LocalUserId:TEOSProductUserId
	Field TargetUserId:TEOSProductUserId
	Field Stats:TEOSStatsIngestData[]
End Type

Type TEOSStatsQueryOptions
	Field LocalUserId:TEOSProductUserId
	Field TargetUserId:TEOSProductUserId
	Field StartTime:Long = EOS_STATS_TIME_UNDEFINED
	Field EndTime:Long = EOS_STATS_TIME_UNDEFINED
	Field StatNames:String[]
End Type

Rem
bbdoc: One stat copied from the local EOS query cache.
End Rem
Type TEOSStat
	Field Name:String
	Field StartTime:Long
	Field EndTime:Long
	Field Value:Int
End Type

Type TEOSAchievementsQueryDefinitionsOptions
	Field LocalUserId:TEOSProductUserId
End Type

Type TEOSAchievementsQueryPlayerOptions
	Field LocalUserId:TEOSProductUserId
	Field TargetUserId:TEOSProductUserId
End Type

Type TEOSAchievementStatThreshold
	Field Name:String
	Field Threshold:Int
End Type

Type TEOSAchievementDefinition
	Field AchievementId:String
	Field UnlockedDisplayName:String
	Field UnlockedDescription:String
	Field LockedDisplayName:String
	Field LockedDescription:String
	Field FlavorText:String
	Field UnlockedIconURL:String
	Field LockedIconURL:String
	Field IsHidden:Int
	Field StatThresholds:TEOSAchievementStatThreshold[]
End Type

Type TEOSPlayerAchievementStatInfo
	Field Name:String
	Field CurrentValue:Int
	Field ThresholdValue:Int
End Type

Type TEOSPlayerAchievement
	Field AchievementId:String
	' Normalized progress in the range 0.0 (locked) through 1.0 (unlocked).
	Field Progress:Double
	Field UnlockTime:Long = EOS_ACHIEVEMENTS_UNLOCKTIME_UNDEFINED
	Field DisplayName:String
	Field Description:String
	Field IconURL:String
	Field FlavorText:String
	Field StatInfo:TEOSPlayerAchievementStatInfo[]
End Type

Type TEOSLeaderboardsQueryDefinitionsOptions
	Field LocalUserId:TEOSProductUserId
	Field StartTime:Long = EOS_LEADERBOARDS_TIME_UNDEFINED
	Field EndTime:Long = EOS_LEADERBOARDS_TIME_UNDEFINED
End Type

Type TEOSLeaderboardDefinition
	Field LeaderboardId:String
	Field StatName:String
	Field Aggregation:EEOSLeaderboardAggregation
	Field StartTime:Long
	Field EndTime:Long
End Type

Type TEOSLeaderboardRecord
	Field UserId:TEOSProductUserId
	Field Rank:UInt
	Field Score:Int
	Field UserDisplayName:String
End Type

Type TEOSLeaderboardUserScoresQueryStatInfo
	Field StatName:String
	Field Aggregation:EEOSLeaderboardAggregation
End Type

Type TEOSLeaderboardsQueryUserScoresOptions
	Field LocalUserId:TEOSProductUserId
	Field UserIds:TEOSProductUserId[]
	Field StatInfo:TEOSLeaderboardUserScoresQueryStatInfo[]
	Field StartTime:Long = EOS_LEADERBOARDS_TIME_UNDEFINED
	Field EndTime:Long = EOS_LEADERBOARDS_TIME_UNDEFINED
End Type

Type TEOSLeaderboardUserScore
	Field UserId:TEOSProductUserId
	Field Score:Int
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

Interface IEOSStatsIngestListener
	Method OnEOSStatsIngest(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
End Interface

Interface IEOSStatsQueryListener
	Method OnEOSStatsQuery(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
End Interface

Interface IEOSAchievementsQueryDefinitionsListener
	Method OnEOSAchievementsQueryDefinitions(result:EEOSResult)
End Interface

Interface IEOSAchievementsQueryPlayerListener
	Method OnEOSAchievementsQueryPlayer(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
End Interface

Interface IEOSAchievementsUnlockListener
	Method OnEOSAchievementsUnlock(result:EEOSResult, userId:TEOSProductUserId, achievementsCount:UInt)
End Interface

Interface IEOSAchievementsUnlockedListener
	Method OnEOSAchievementUnlocked(userId:TEOSProductUserId, achievementId:String, unlockTime:Long)
End Interface

Interface IEOSLeaderboardsQueryDefinitionsListener
	Method OnEOSLeaderboardsQueryDefinitions(result:EEOSResult)
End Interface

Interface IEOSLeaderboardsQueryRanksListener
	Method OnEOSLeaderboardsQueryRanks(result:EEOSResult, leaderboardId:String)
End Interface

Interface IEOSLeaderboardsQueryUserScoresListener
	Method OnEOSLeaderboardsQueryUserScores(result:EEOSResult)
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
	bbdoc: Returns the EOS game-services Stats interface.
	End Rem
	Method Stats:TEOSStats()
		If Not _handle Then Return Null
		Return TEOSStats._Create(Self, bmx_eos_platform_get_stats_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS game-services Achievements interface.
	End Rem
	Method Achievements:TEOSAchievements()
		If Not _handle Then Return Null
		Return TEOSAchievements._Create(Self, bmx_eos_platform_get_achievements_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS game-services Leaderboards interface.
	End Rem
	Method Leaderboards:TEOSLeaderboards()
		If Not _handle Then Return Null
		Return TEOSLeaderboards._Create(Self, bmx_eos_platform_get_leaderboards_interface(_handle))
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

Type TEOSStatsIngestRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSStatsIngestListener
	Field _complete:Int

	Public
	Function _Create:TEOSStatsIngestRequest(owner:TEOSPlatform, listener:IEOSStatsIngestListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSStatsIngestRequest = New TEOSStatsIngestRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSStatsIngestRequest, result:EEOSResult, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSStatsIngestListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSStatsIngest(result, TEOSProductUserId._Create(localUserHandle), TEOSProductUserId._Create(targetUserHandle))
	End Function

	Function _Cancel(request:TEOSStatsIngestRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSStatsQueryRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSStatsQueryListener
	Field _complete:Int

	Public
	Function _Create:TEOSStatsQueryRequest(owner:TEOSPlatform, listener:IEOSStatsQueryListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSStatsQueryRequest = New TEOSStatsQueryRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSStatsQueryRequest, result:EEOSResult, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSStatsQueryListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSStatsQuery(result, TEOSProductUserId._Create(localUserHandle), TEOSProductUserId._Create(targetUserHandle))
	End Function

	Function _Cancel(request:TEOSStatsQueryRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSAchievementsQueryDefinitionsRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSAchievementsQueryDefinitionsListener
	Field _complete:Int

	Public
	Function _Create:TEOSAchievementsQueryDefinitionsRequest(owner:TEOSPlatform, listener:IEOSAchievementsQueryDefinitionsListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSAchievementsQueryDefinitionsRequest = New TEOSAchievementsQueryDefinitionsRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSAchievementsQueryDefinitionsRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSAchievementsQueryDefinitionsListener = request._listener
		If EOSResultIsOperationComplete(result) Then request._complete = True; request._listener = Null
		If listener Then listener.OnEOSAchievementsQueryDefinitions(result)
	End Function

	Function _Cancel(request:TEOSAchievementsQueryDefinitionsRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSAchievementsQueryPlayerRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSAchievementsQueryPlayerListener
	Field _complete:Int

	Public
	Function _Create:TEOSAchievementsQueryPlayerRequest(owner:TEOSPlatform, listener:IEOSAchievementsQueryPlayerListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSAchievementsQueryPlayerRequest = New TEOSAchievementsQueryPlayerRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSAchievementsQueryPlayerRequest, result:EEOSResult, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSAchievementsQueryPlayerListener = request._listener
		If EOSResultIsOperationComplete(result) Then request._complete = True; request._listener = Null
		If listener Then listener.OnEOSAchievementsQueryPlayer(result, TEOSProductUserId._Create(localUserHandle), TEOSProductUserId._Create(targetUserHandle))
	End Function

	Function _Cancel(request:TEOSAchievementsQueryPlayerRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSAchievementsUnlockRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSAchievementsUnlockListener
	Field _complete:Int

	Public
	Function _Create:TEOSAchievementsUnlockRequest(owner:TEOSPlatform, listener:IEOSAchievementsUnlockListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSAchievementsUnlockRequest = New TEOSAchievementsUnlockRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSAchievementsUnlockRequest, result:EEOSResult, userHandle:Byte Ptr, achievementsCount:UInt) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSAchievementsUnlockListener = request._listener
		If EOSResultIsOperationComplete(result) Then request._complete = True; request._listener = Null
		If listener Then listener.OnEOSAchievementsUnlock(result, TEOSProductUserId._Create(userHandle), achievementsCount)
	End Function

	Function _Cancel(request:TEOSAchievementsUnlockRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, 0)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Rem
bbdoc: A removable achievement-unlocked notification registration.
End Rem
Type TEOSAchievementsUnlockedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSAchievementsUnlockedListener
	Field _id:ULong

	Public
	Function _Create:TEOSAchievementsUnlockedSubscription(owner:TEOSPlatform, listener:IEOSAchievementsUnlockedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSAchievementsUnlockedSubscription = New TEOSAchievementsUnlockedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSAchievementsUnlockedSubscription, userHandle:Byte Ptr, achievementId:String, unlockTime:Long) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSAchievementUnlocked(TEOSProductUserId._Create(userHandle), achievementId, unlockTime)
	End Function

	Function _Cancel(subscription:TEOSAchievementsUnlockedSubscription) { nomangle }
		If Not subscription Then Return
		subscription._id = 0
		subscription._listener = Null
	End Function

	Method _SetId(id:ULong)
		_id = id
	End Method

	Method Remove()
		If Not _id Then Return
		Local id:ULong = _id
		_id = 0
		_listener = Null
		bmx_eos_achievements_remove_notify_unlocked(id)
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSLeaderboardsQueryDefinitionsRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLeaderboardsQueryDefinitionsListener
	Field _complete:Int
	Public
	Function _Create:TEOSLeaderboardsQueryDefinitionsRequest(owner:TEOSPlatform, listener:IEOSLeaderboardsQueryDefinitionsListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLeaderboardsQueryDefinitionsRequest = New TEOSLeaderboardsQueryDefinitionsRequest
		request._owner = owner; request._listener = listener
		Return request
	End Function
	Function _Complete(request:TEOSLeaderboardsQueryDefinitionsRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLeaderboardsQueryDefinitionsListener = request._listener
		If EOSResultIsOperationComplete(result) Then request._complete = True; request._listener = Null
		If listener Then listener.OnEOSLeaderboardsQueryDefinitions(result)
	End Function
	Function _Cancel(request:TEOSLeaderboardsQueryDefinitionsRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
	End Function
	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLeaderboardsQueryRanksRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLeaderboardsQueryRanksListener
	Field _complete:Int
	Public
	Function _Create:TEOSLeaderboardsQueryRanksRequest(owner:TEOSPlatform, listener:IEOSLeaderboardsQueryRanksListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLeaderboardsQueryRanksRequest = New TEOSLeaderboardsQueryRanksRequest
		request._owner = owner; request._listener = listener
		Return request
	End Function
	Function _Complete(request:TEOSLeaderboardsQueryRanksRequest, result:EEOSResult, leaderboardId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLeaderboardsQueryRanksListener = request._listener
		If EOSResultIsOperationComplete(result) Then request._complete = True; request._listener = Null
		If listener Then listener.OnEOSLeaderboardsQueryRanks(result, leaderboardId)
	End Function
	Function _Cancel(request:TEOSLeaderboardsQueryRanksRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function
	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLeaderboardsQueryUserScoresRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLeaderboardsQueryUserScoresListener
	Field _complete:Int
	Public
	Function _Create:TEOSLeaderboardsQueryUserScoresRequest(owner:TEOSPlatform, listener:IEOSLeaderboardsQueryUserScoresListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLeaderboardsQueryUserScoresRequest = New TEOSLeaderboardsQueryUserScoresRequest
		request._owner = owner; request._listener = listener
		Return request
	End Function
	Function _Complete(request:TEOSLeaderboardsQueryUserScoresRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLeaderboardsQueryUserScoresListener = request._listener
		If EOSResultIsOperationComplete(result) Then request._complete = True; request._listener = Null
		If listener Then listener.OnEOSLeaderboardsQueryUserScores(result)
	End Function
	Function _Cancel(request:TEOSLeaderboardsQueryUserScoresRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
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

Rem
bbdoc: EOS game-services Stats interface for one platform.
about: Query operations populate an EOS-managed local cache. Use #StatsCount,
#CopyStatByIndex, or #CopyStatByName after a successful query.
End Rem
Type TEOSStats
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSStats(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local stats:TEOSStats = New TEOSStats
		stats._owner = owner
		stats._handle = handle
		Return stats
	End Function

	Rem
	bbdoc: Adds one or more values to the target user's configured stats.
	about: A successful callback confirms that the request reached the service;
	backend processing and related achievement unlocks may occur later.
	End Rem
	Method Ingest:TEOSStatsIngestRequest(options:TEOSStatsIngestOptions, listener:IEOSStatsIngestListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not listener Then Return Null
		If Not options.TargetUserId Or Not options.TargetUserId.IsValid() Then Return Null
		If Not options.Stats Or options.Stats.Length = 0 Or options.Stats.Length > EOS_STATS_MAX_INGEST_STATS Then Return Null

		Local names:String[options.Stats.Length]
		Local amounts:Int[options.Stats.Length]
		For Local index:Int = 0 Until options.Stats.Length
			If Not options.Stats[index] Or Not options.Stats[index].Name Then Return Null
			names[index] = options.Stats[index].Name
			amounts[index] = options.Stats[index].IngestAmount
		Next

		Local localUserHandle:Byte Ptr
		If options.LocalUserId Then localUserHandle = options.LocalUserId._NativeHandle()
		Local request:TEOSStatsIngestRequest = TEOSStatsIngestRequest._Create(_owner, listener)
		bmx_eos_stats_ingest(_owner._NativeHandle(), _handle, request, localUserHandle, options.TargetUserId._NativeHandle(), names, amounts)
		Return request
	End Method

	Rem
	bbdoc: Queries stats for a Product User and updates the local Stats cache.
	about: Leave StatNames empty to query all available stats. StartTime and
	EndTime default to #EOS_STATS_TIME_UNDEFINED.
	End Rem
	Method Query:TEOSStatsQueryRequest(options:TEOSStatsQueryOptions, listener:IEOSStatsQueryListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not listener Then Return Null
		If Not options.TargetUserId Or Not options.TargetUserId.IsValid() Then Return Null
		If options.StatNames And options.StatNames.Length > EOS_STATS_MAX_QUERY_STATS Then Return Null
		If options.StatNames Then
			For Local name:String = EachIn options.StatNames
				If Not name Then Return Null
			Next
		End If

		Local localUserHandle:Byte Ptr
		If options.LocalUserId Then localUserHandle = options.LocalUserId._NativeHandle()
		Local request:TEOSStatsQueryRequest = TEOSStatsQueryRequest._Create(_owner, listener)
		bmx_eos_stats_query(_owner._NativeHandle(), _handle, request, localUserHandle, options.TargetUserId._NativeHandle(), options.StartTime, options.EndTime, options.StatNames)
		Return request
	End Method

	Method StatsCount:Int(targetUserId:TEOSProductUserId)
		If Not _owner Or Not _owner.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Then Return 0
		Return bmx_eos_stats_get_count(_handle, targetUserId._NativeHandle())
	End Method

	Method CopyStatByIndex:EEOSResult(targetUserId:TEOSProductUserId, index:Int, stat:TEOSStat Var)
		stat = Null
		If Not _owner Or Not _owner.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Or index < 0 Then Return EEOSResult.InvalidParameters
		Local name:String, startTime:Long, endTime:Long, value:Int
		Local result:EEOSResult = bmx_eos_stats_copy_by_index(_handle, targetUserId._NativeHandle(), UInt(index), name, startTime, endTime, value)
		If result <> EEOSResult.Success Then Return result
		stat = New TEOSStat
		stat.Name = name
		stat.StartTime = startTime
		stat.EndTime = endTime
		stat.Value = value
		Return result
	End Method

	Method CopyStatByName:EEOSResult(targetUserId:TEOSProductUserId, statName:String, stat:TEOSStat Var)
		stat = Null
		If Not _owner Or Not _owner.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Or Not statName Then Return EEOSResult.InvalidParameters
		Local name:String, startTime:Long, endTime:Long, value:Int
		Local result:EEOSResult = bmx_eos_stats_copy_by_name(_handle, targetUserId._NativeHandle(), statName, name, startTime, endTime, value)
		If result <> EEOSResult.Success Then Return result
		stat = New TEOSStat
		stat.Name = name
		stat.StartTime = startTime
		stat.EndTime = endTime
		stat.Value = value
		Return result
	End Method
End Type

Rem
bbdoc: EOS game-services Achievements interface for one platform.
End Rem
Type TEOSAchievements
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Function _Definition:TEOSAchievementDefinition(achievementId:String, unlockedName:String, unlockedDescription:String, lockedName:String, lockedDescription:String, flavorText:String, unlockedIcon:String, lockedIcon:String, isHidden:Int, statNames:String[], thresholds:Int[])
		Local definition:TEOSAchievementDefinition = New TEOSAchievementDefinition
		definition.AchievementId = achievementId
		definition.UnlockedDisplayName = unlockedName
		definition.UnlockedDescription = unlockedDescription
		definition.LockedDisplayName = lockedName
		definition.LockedDescription = lockedDescription
		definition.FlavorText = flavorText
		definition.UnlockedIconURL = unlockedIcon
		definition.LockedIconURL = lockedIcon
		definition.IsHidden = isHidden
		definition.StatThresholds = New TEOSAchievementStatThreshold[statNames.Length]
		For Local index:Int = 0 Until statNames.Length
			definition.StatThresholds[index] = New TEOSAchievementStatThreshold
			definition.StatThresholds[index].Name = statNames[index]
			definition.StatThresholds[index].Threshold = thresholds[index]
		Next
		Return definition
	End Function

	Function _Player:TEOSPlayerAchievement(achievementId:String, progress:Double, unlockTime:Long, displayName:String, description:String, iconUrl:String, flavorText:String, statNames:String[], currentValues:Int[], thresholdValues:Int[])
		Local achievement:TEOSPlayerAchievement = New TEOSPlayerAchievement
		achievement.AchievementId = achievementId
		achievement.Progress = progress
		achievement.UnlockTime = unlockTime
		achievement.DisplayName = displayName
		achievement.Description = description
		achievement.IconURL = iconUrl
		achievement.FlavorText = flavorText
		achievement.StatInfo = New TEOSPlayerAchievementStatInfo[statNames.Length]
		For Local index:Int = 0 Until statNames.Length
			achievement.StatInfo[index] = New TEOSPlayerAchievementStatInfo
			achievement.StatInfo[index].Name = statNames[index]
			achievement.StatInfo[index].CurrentValue = currentValues[index]
			achievement.StatInfo[index].ThresholdValue = thresholdValues[index]
		Next
		Return achievement
	End Function

	Public
	Function _Create:TEOSAchievements(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local achievements:TEOSAchievements = New TEOSAchievements
		achievements._owner = owner
		achievements._handle = handle
		Return achievements
	End Function

	Method QueryDefinitions:TEOSAchievementsQueryDefinitionsRequest(options:TEOSAchievementsQueryDefinitionsOptions, listener:IEOSAchievementsQueryDefinitionsListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not listener Then Return Null
		Local localUserHandle:Byte Ptr
		If options.LocalUserId Then localUserHandle = options.LocalUserId._NativeHandle()
		Local request:TEOSAchievementsQueryDefinitionsRequest = TEOSAchievementsQueryDefinitionsRequest._Create(_owner, listener)
		bmx_eos_achievements_query_definitions(_owner._NativeHandle(), _handle, request, localUserHandle)
		Return request
	End Method

	Method QueryPlayerAchievements:TEOSAchievementsQueryPlayerRequest(options:TEOSAchievementsQueryPlayerOptions, listener:IEOSAchievementsQueryPlayerListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not listener Then Return Null
		If Not options.TargetUserId Or Not options.TargetUserId.IsValid() Then Return Null
		Local localUserHandle:Byte Ptr
		If options.LocalUserId Then localUserHandle = options.LocalUserId._NativeHandle()
		Local request:TEOSAchievementsQueryPlayerRequest = TEOSAchievementsQueryPlayerRequest._Create(_owner, listener)
		bmx_eos_achievements_query_player(_owner._NativeHandle(), _handle, request, localUserHandle, options.TargetUserId._NativeHandle())
		Return request
	End Method

	Method DefinitionCount:Int()
		If Not _owner Or Not _owner.IsValid() Then Return 0
		Return bmx_eos_achievements_definition_count(_handle)
	End Method

	Method CopyDefinitionByIndex:EEOSResult(index:Int, definition:TEOSAchievementDefinition Var)
		definition = Null
		If Not _owner Or Not _owner.IsValid() Or index < 0 Then Return EEOSResult.InvalidParameters
		Local id:String, un:String, ud:String, ln:String, ld:String, flavor:String, ui:String, li:String, hidden:Int, names:String[], values:Int[]
		Local result:EEOSResult = bmx_eos_achievements_copy_definition_by_index(_handle, UInt(index), id, un, ud, ln, ld, flavor, ui, li, hidden, names, values)
		If result = EEOSResult.Success Then definition = _Definition(id, un, ud, ln, ld, flavor, ui, li, hidden, names, values)
		Return result
	End Method

	Method CopyDefinitionById:EEOSResult(achievementId:String, definition:TEOSAchievementDefinition Var)
		definition = Null
		If Not _owner Or Not _owner.IsValid() Or Not achievementId Then Return EEOSResult.InvalidParameters
		Local id:String, un:String, ud:String, ln:String, ld:String, flavor:String, ui:String, li:String, hidden:Int, names:String[], values:Int[]
		Local result:EEOSResult = bmx_eos_achievements_copy_definition_by_id(_handle, achievementId, id, un, ud, ln, ld, flavor, ui, li, hidden, names, values)
		If result = EEOSResult.Success Then definition = _Definition(id, un, ud, ln, ld, flavor, ui, li, hidden, names, values)
		Return result
	End Method

	Method PlayerAchievementCount:Int(targetUserId:TEOSProductUserId)
		If Not _owner Or Not _owner.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Then Return 0
		Return bmx_eos_achievements_player_count(_handle, targetUserId._NativeHandle())
	End Method

	Method CopyPlayerAchievementByIndex:EEOSResult(localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId, index:Int, achievement:TEOSPlayerAchievement Var)
		achievement = Null
		If Not _owner Or Not _owner.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Or index < 0 Then Return EEOSResult.InvalidParameters
		Local localHandle:Byte Ptr
		If localUserId Then localHandle = localUserId._NativeHandle()
		Local id:String, progress:Double, unlockTime:Long, displayName:String, description:String, icon:String, flavor:String, names:String[], current:Int[], thresholds:Int[]
		Local result:EEOSResult = bmx_eos_achievements_copy_player_by_index(_handle, localHandle, targetUserId._NativeHandle(), UInt(index), id, progress, unlockTime, displayName, description, icon, flavor, names, current, thresholds)
		If result = EEOSResult.Success Then achievement = _Player(id, progress, unlockTime, displayName, description, icon, flavor, names, current, thresholds)
		Return result
	End Method

	Method CopyPlayerAchievementById:EEOSResult(localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId, achievementId:String, achievement:TEOSPlayerAchievement Var)
		achievement = Null
		If Not _owner Or Not _owner.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Or Not achievementId Then Return EEOSResult.InvalidParameters
		Local localHandle:Byte Ptr
		If localUserId Then localHandle = localUserId._NativeHandle()
		Local id:String, progress:Double, unlockTime:Long, displayName:String, description:String, icon:String, flavor:String, names:String[], current:Int[], thresholds:Int[]
		Local result:EEOSResult = bmx_eos_achievements_copy_player_by_id(_handle, localHandle, targetUserId._NativeHandle(), achievementId, id, progress, unlockTime, displayName, description, icon, flavor, names, current, thresholds)
		If result = EEOSResult.Success Then achievement = _Player(id, progress, unlockTime, displayName, description, icon, flavor, names, current, thresholds)
		Return result
	End Method

	Rem
	bbdoc: Explicitly unlocks one or more achievements for a Product User.
	End Rem
	Method UnlockAchievements:TEOSAchievementsUnlockRequest(userId:TEOSProductUserId, achievementIds:String[], listener:IEOSAchievementsUnlockListener)
		If Not _owner Or Not _owner.IsValid() Or Not userId Or Not userId.IsValid() Or Not listener Then Return Null
		If Not achievementIds Or achievementIds.Length = 0 Then Return Null
		For Local achievementId:String = EachIn achievementIds
			If Not achievementId Then Return Null
		Next
		Local request:TEOSAchievementsUnlockRequest = TEOSAchievementsUnlockRequest._Create(_owner, listener)
		bmx_eos_achievements_unlock(_owner._NativeHandle(), _handle, request, userId._NativeHandle(), achievementIds)
		Return request
	End Method

	Rem
	bbdoc: Registers for achievement-unlocked notifications.
	about: Call Remove on the returned subscription when it is no longer needed.
	Platform release also removes it safely.
	End Rem
	Method AddNotifyAchievementsUnlocked:TEOSAchievementsUnlockedSubscription(listener:IEOSAchievementsUnlockedListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSAchievementsUnlockedSubscription = TEOSAchievementsUnlockedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_achievements_add_notify_unlocked(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method
End Type

Type TEOSLeaderboards
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr
	Function _Definition:TEOSLeaderboardDefinition(id:String, statName:String, aggregation:EEOSLeaderboardAggregation, startTime:Long, endTime:Long)
		Local definition:TEOSLeaderboardDefinition = New TEOSLeaderboardDefinition
		definition.LeaderboardId = id; definition.StatName = statName; definition.Aggregation = aggregation
		definition.StartTime = startTime; definition.EndTime = endTime
		Return definition
	End Function
	Function _Record:TEOSLeaderboardRecord(userHandle:Byte Ptr, rank:UInt, score:Int, displayName:String)
		Local record:TEOSLeaderboardRecord = New TEOSLeaderboardRecord
		record.UserId = TEOSProductUserId._Create(userHandle); record.Rank = rank
		record.Score = score; record.UserDisplayName = displayName
		Return record
	End Function
	Public
	Function _Create:TEOSLeaderboards(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local leaderboards:TEOSLeaderboards = New TEOSLeaderboards
		leaderboards._owner = owner; leaderboards._handle = handle
		Return leaderboards
	End Function
	Method QueryDefinitions:TEOSLeaderboardsQueryDefinitionsRequest(options:TEOSLeaderboardsQueryDefinitionsOptions, listener:IEOSLeaderboardsQueryDefinitionsListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not listener Then Return Null
		Local localHandle:Byte Ptr
		If options.LocalUserId Then localHandle = options.LocalUserId._NativeHandle()
		Local request:TEOSLeaderboardsQueryDefinitionsRequest = TEOSLeaderboardsQueryDefinitionsRequest._Create(_owner, listener)
		bmx_eos_leaderboards_query_definitions(_owner._NativeHandle(), _handle, request, localHandle, options.StartTime, options.EndTime)
		Return request
	End Method
	Method QueryRanks:TEOSLeaderboardsQueryRanksRequest(localUserId:TEOSProductUserId, leaderboardId:String, listener:IEOSLeaderboardsQueryRanksListener)
		If Not _owner Or Not _owner.IsValid() Or Not leaderboardId Or Not listener Then Return Null
		Local localHandle:Byte Ptr
		If localUserId Then localHandle = localUserId._NativeHandle()
		Local request:TEOSLeaderboardsQueryRanksRequest = TEOSLeaderboardsQueryRanksRequest._Create(_owner, listener)
		bmx_eos_leaderboards_query_ranks(_owner._NativeHandle(), _handle, request, localHandle, leaderboardId)
		Return request
	End Method
	Method DefinitionCount:Int()
		If Not _owner Or Not _owner.IsValid() Then Return 0
		Return bmx_eos_leaderboards_definition_count(_handle)
	End Method
	Method CopyDefinitionByIndex:EEOSResult(index:Int, definition:TEOSLeaderboardDefinition Var)
		definition = Null
		If Not _owner Or Not _owner.IsValid() Or index < 0 Then Return EEOSResult.InvalidParameters
		Local id:String, statName:String, aggregation:EEOSLeaderboardAggregation, startTime:Long, endTime:Long
		Local result:EEOSResult = bmx_eos_leaderboards_copy_definition_by_index(_handle, UInt(index), id, statName, aggregation, startTime, endTime)
		If result = EEOSResult.Success Then definition = _Definition(id, statName, aggregation, startTime, endTime)
		Return result
	End Method
	Method CopyDefinitionById:EEOSResult(leaderboardId:String, definition:TEOSLeaderboardDefinition Var)
		definition = Null
		If Not _owner Or Not _owner.IsValid() Or Not leaderboardId Then Return EEOSResult.InvalidParameters
		Local id:String, statName:String, aggregation:EEOSLeaderboardAggregation, startTime:Long, endTime:Long
		Local result:EEOSResult = bmx_eos_leaderboards_copy_definition_by_id(_handle, leaderboardId, id, statName, aggregation, startTime, endTime)
		If result = EEOSResult.Success Then definition = _Definition(id, statName, aggregation, startTime, endTime)
		Return result
	End Method
	Method RecordCount:Int()
		If Not _owner Or Not _owner.IsValid() Then Return 0
		Return bmx_eos_leaderboards_record_count(_handle)
	End Method
	Method CopyRecordByIndex:EEOSResult(index:Int, record:TEOSLeaderboardRecord Var)
		record = Null
		If Not _owner Or Not _owner.IsValid() Or index < 0 Then Return EEOSResult.InvalidParameters
		Local userHandle:Byte Ptr, rank:UInt, score:Int, displayName:String
		Local result:EEOSResult = bmx_eos_leaderboards_copy_record_by_index(_handle, UInt(index), userHandle, rank, score, displayName)
		If result = EEOSResult.Success Then record = _Record(userHandle, rank, score, displayName)
		Return result
	End Method
	Method CopyRecordByUserId:EEOSResult(userId:TEOSProductUserId, record:TEOSLeaderboardRecord Var)
		record = Null
		If Not _owner Or Not _owner.IsValid() Or Not userId Or Not userId.IsValid() Then Return EEOSResult.InvalidParameters
		Local userHandle:Byte Ptr, rank:UInt, score:Int, displayName:String
		Local result:EEOSResult = bmx_eos_leaderboards_copy_record_by_user(_handle, userId._NativeHandle(), userHandle, rank, score, displayName)
		If result = EEOSResult.Success Then record = _Record(userHandle, rank, score, displayName)
		Return result
	End Method
	Method QueryUserScores:TEOSLeaderboardsQueryUserScoresRequest(options:TEOSLeaderboardsQueryUserScoresOptions, listener:IEOSLeaderboardsQueryUserScoresListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not listener Then Return Null
		If Not options.UserIds Or options.UserIds.Length = 0 Or Not options.StatInfo Or options.StatInfo.Length = 0 Then Return Null
		Local userHandles:Byte Ptr[options.UserIds.Length]
		For Local index:Int = 0 Until options.UserIds.Length
			If Not options.UserIds[index] Or Not options.UserIds[index].IsValid() Then Return Null
			userHandles[index] = options.UserIds[index]._NativeHandle()
		Next
		Local statNames:String[options.StatInfo.Length]
		Local aggregations:Int[options.StatInfo.Length]
		For Local index:Int = 0 Until options.StatInfo.Length
			If Not options.StatInfo[index] Or Not options.StatInfo[index].StatName Then Return Null
			statNames[index] = options.StatInfo[index].StatName
			aggregations[index] = Int(options.StatInfo[index].Aggregation)
		Next
		Local localHandle:Byte Ptr
		If options.LocalUserId Then localHandle = options.LocalUserId._NativeHandle()
		Local request:TEOSLeaderboardsQueryUserScoresRequest = TEOSLeaderboardsQueryUserScoresRequest._Create(_owner, listener)
		bmx_eos_leaderboards_query_user_scores(_owner._NativeHandle(), _handle, request, localHandle, userHandles, statNames, aggregations, options.StartTime, options.EndTime)
		Return request
	End Method
	Method UserScoreCount:Int(statName:String)
		If Not _owner Or Not _owner.IsValid() Or Not statName Then Return 0
		Return bmx_eos_leaderboards_user_score_count(_handle, statName)
	End Method
	Method CopyUserScoreByIndex:EEOSResult(index:Int, statName:String, userScore:TEOSLeaderboardUserScore Var)
		userScore = Null
		If Not _owner Or Not _owner.IsValid() Or index < 0 Or Not statName Then Return EEOSResult.InvalidParameters
		Local userHandle:Byte Ptr, score:Int
		Local result:EEOSResult = bmx_eos_leaderboards_copy_user_score_by_index(_handle, UInt(index), statName, userHandle, score)
		If result = EEOSResult.Success Then
			userScore = New TEOSLeaderboardUserScore
			userScore.UserId = TEOSProductUserId._Create(userHandle); userScore.Score = score
		End If
		Return result
	End Method
	Method CopyUserScoreByUserId:EEOSResult(userId:TEOSProductUserId, statName:String, userScore:TEOSLeaderboardUserScore Var)
		userScore = Null
		If Not _owner Or Not _owner.IsValid() Or Not userId Or Not userId.IsValid() Or Not statName Then Return EEOSResult.InvalidParameters
		Local userHandle:Byte Ptr, score:Int
		Local result:EEOSResult = bmx_eos_leaderboards_copy_user_score_by_user(_handle, userId._NativeHandle(), statName, userHandle, score)
		If result = EEOSResult.Success Then
			userScore = New TEOSLeaderboardUserScore
			userScore.UserId = TEOSProductUserId._Create(userHandle); userScore.Score = score
		End If
		Return result
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
	Function bmx_eos_platform_get_stats_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_achievements_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_leaderboards_interface:Byte Ptr(handle:Byte Ptr)

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

	Function bmx_eos_stats_ingest(platformHandle:Byte Ptr, statsHandle:Byte Ptr, request:TEOSStatsIngestRequest, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, names:String[], amounts:Int[])
	Function bmx_eos_stats_query(platformHandle:Byte Ptr, statsHandle:Byte Ptr, request:TEOSStatsQueryRequest, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, startTime:Long, endTime:Long, names:String[])
	Function bmx_eos_stats_get_count:Int(statsHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_stats_copy_by_index:EEOSResult(statsHandle:Byte Ptr, targetUserHandle:Byte Ptr, index:UInt, name:String Var, startTime:Long Var, endTime:Long Var, value:Int Var)
	Function bmx_eos_stats_copy_by_name:EEOSResult(statsHandle:Byte Ptr, targetUserHandle:Byte Ptr, statName:String, name:String Var, startTime:Long Var, endTime:Long Var, value:Int Var)

	Function bmx_eos_achievements_query_definitions(platformHandle:Byte Ptr, achievementsHandle:Byte Ptr, request:TEOSAchievementsQueryDefinitionsRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_achievements_query_player(platformHandle:Byte Ptr, achievementsHandle:Byte Ptr, request:TEOSAchievementsQueryPlayerRequest, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_achievements_definition_count:Int(achievementsHandle:Byte Ptr)
	Function bmx_eos_achievements_copy_definition_by_index:EEOSResult(achievementsHandle:Byte Ptr, index:UInt, achievementId:String Var, unlockedName:String Var, unlockedDescription:String Var, lockedName:String Var, lockedDescription:String Var, flavorText:String Var, unlockedIcon:String Var, lockedIcon:String Var, isHidden:Int Var, statNames:String[] Var, thresholds:Int[] Var)
	Function bmx_eos_achievements_copy_definition_by_id:EEOSResult(achievementsHandle:Byte Ptr, requestedId:String, achievementId:String Var, unlockedName:String Var, unlockedDescription:String Var, lockedName:String Var, lockedDescription:String Var, flavorText:String Var, unlockedIcon:String Var, lockedIcon:String Var, isHidden:Int Var, statNames:String[] Var, thresholds:Int[] Var)
	Function bmx_eos_achievements_player_count:Int(achievementsHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_achievements_copy_player_by_index:EEOSResult(achievementsHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, index:UInt, achievementId:String Var, progress:Double Var, unlockTime:Long Var, displayName:String Var, description:String Var, iconUrl:String Var, flavorText:String Var, statNames:String[] Var, currentValues:Int[] Var, thresholdValues:Int[] Var)
	Function bmx_eos_achievements_copy_player_by_id:EEOSResult(achievementsHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, requestedId:String, achievementId:String Var, progress:Double Var, unlockTime:Long Var, displayName:String Var, description:String Var, iconUrl:String Var, flavorText:String Var, statNames:String[] Var, currentValues:Int[] Var, thresholdValues:Int[] Var)
	Function bmx_eos_achievements_unlock(platformHandle:Byte Ptr, achievementsHandle:Byte Ptr, request:TEOSAchievementsUnlockRequest, userHandle:Byte Ptr, achievementIds:String[])
	Function bmx_eos_achievements_add_notify_unlocked:ULong(platformHandle:Byte Ptr, achievementsHandle:Byte Ptr, subscription:TEOSAchievementsUnlockedSubscription)
	Function bmx_eos_achievements_remove_notify_unlocked(id:ULong)

	Function bmx_eos_leaderboards_query_definitions(platformHandle:Byte Ptr, leaderboardsHandle:Byte Ptr, request:TEOSLeaderboardsQueryDefinitionsRequest, localUserHandle:Byte Ptr, startTime:Long, endTime:Long)
	Function bmx_eos_leaderboards_query_ranks(platformHandle:Byte Ptr, leaderboardsHandle:Byte Ptr, request:TEOSLeaderboardsQueryRanksRequest, localUserHandle:Byte Ptr, leaderboardId:String)
	Function bmx_eos_leaderboards_definition_count:Int(leaderboardsHandle:Byte Ptr)
	Function bmx_eos_leaderboards_copy_definition_by_index:EEOSResult(leaderboardsHandle:Byte Ptr, index:UInt, leaderboardId:String Var, statName:String Var, aggregation:EEOSLeaderboardAggregation Var, startTime:Long Var, endTime:Long Var)
	Function bmx_eos_leaderboards_copy_definition_by_id:EEOSResult(leaderboardsHandle:Byte Ptr, requestedId:String, leaderboardId:String Var, statName:String Var, aggregation:EEOSLeaderboardAggregation Var, startTime:Long Var, endTime:Long Var)
	Function bmx_eos_leaderboards_record_count:Int(leaderboardsHandle:Byte Ptr)
	Function bmx_eos_leaderboards_copy_record_by_index:EEOSResult(leaderboardsHandle:Byte Ptr, index:UInt, userHandle:Byte Ptr Var, rank:UInt Var, score:Int Var, displayName:String Var)
	Function bmx_eos_leaderboards_copy_record_by_user:EEOSResult(leaderboardsHandle:Byte Ptr, requestedUserHandle:Byte Ptr, userHandle:Byte Ptr Var, rank:UInt Var, score:Int Var, displayName:String Var)
	Function bmx_eos_leaderboards_query_user_scores(platformHandle:Byte Ptr, leaderboardsHandle:Byte Ptr, request:TEOSLeaderboardsQueryUserScoresRequest, localUserHandle:Byte Ptr, userHandles:Byte Ptr[], statNames:String[], aggregations:Int[], startTime:Long, endTime:Long)
	Function bmx_eos_leaderboards_user_score_count:Int(leaderboardsHandle:Byte Ptr, statName:String)
	Function bmx_eos_leaderboards_copy_user_score_by_index:EEOSResult(leaderboardsHandle:Byte Ptr, index:UInt, statName:String, userHandle:Byte Ptr Var, score:Int Var)
	Function bmx_eos_leaderboards_copy_user_score_by_user:EEOSResult(leaderboardsHandle:Byte Ptr, requestedUserHandle:Byte Ptr, statName:String, userHandle:Byte Ptr Var, score:Int Var)

	Function bmx_eos_epic_account_id_from_string:Byte Ptr(value:String)
	Function bmx_eos_epic_account_id_is_valid:Int(handle:Byte Ptr)
	Function bmx_eos_epic_account_id_to_string:String(handle:Byte Ptr)
	Function bmx_eos_product_user_id_from_string:Byte Ptr(value:String)
	Function bmx_eos_product_user_id_is_valid:Int(handle:Byte Ptr)
	Function bmx_eos_product_user_id_to_string:String(handle:Byte Ptr)
End Extern
