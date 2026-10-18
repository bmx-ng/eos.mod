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

ModuleInfo "Version: 0.25.0"
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
ModuleInfo "History: 0.8.0"
ModuleInfo "History: Added User Info account queries and cached profile copies."
ModuleInfo "History: 0.9.0"
ModuleInfo "History: Added User Info display-name and external-account lookups."
ModuleInfo "History: 0.10.0"
ModuleInfo "History: Added Friends list, blocklist, and relationship-status queries."
ModuleInfo "History: 0.11.0"
ModuleInfo "History: Added Presence queries and cached presence copies."
ModuleInfo "History: 0.12.0"
ModuleInfo "History: Added Presence status, rich-text, and join-info publishing."
ModuleInfo "History: 0.13.0"
ModuleInfo "History: Added friend-status and blocklist-update notifications."
ModuleInfo "History: 0.14.0"
ModuleInfo "History: Added presence-change notifications."
ModuleInfo "History: 0.15.0"
ModuleInfo "History: Added Auth and Connect login-lifecycle notifications."
ModuleInfo "History: 0.16.0"
ModuleInfo "History: Added Lobby creation, destruction, leaving, and detail snapshots."
ModuleInfo "History: 0.17.0"
ModuleInfo "History: Added P2P packet transport and connection-control foundation."
ModuleInfo "History: Added P2P NAT, relay, port-range, and packet-queue controls."
ModuleInfo "History: 0.18.0"
ModuleInfo "History: Added streaming Title Storage and Player Data Storage APIs."
ModuleInfo "History: 0.19.0"
ModuleInfo "History: Added managed Auth-to-Connect sessions, refresh, retry, and persistent sign-out."
ModuleInfo "History: 0.20.0"
ModuleInfo "History: Added player sanctions queries, appeals, and behavior reports."
ModuleInfo "History: 0.21.0"
ModuleInfo "History: Added searchable game-session creation, joining, lifecycle, and membership."
ModuleInfo "History: 0.22.0"
ModuleInfo "History: Added session invitations, invite caches, overlay events, and leave requests."
ModuleInfo "History: 0.23.0"
ModuleInfo "History: Completed Sessions with keyed attributes, state diagnostics, and update validation."
ModuleInfo "History: 0.24.0"
ModuleInfo "History: Added Social Overlay control, display notifications, and UI event acknowledgement."
ModuleInfo "History: 0.25.0"
ModuleInfo "History: Added Steam Integrated Platform setup, identity state, and logout coordination."

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
Import BRL.Stream
Import "glue/glue.cpp"
Import "glue/storage_glue.cpp"
Import "glue/sanctions_reports_glue.cpp"
Import "glue/sessions_glue.cpp"
Import "glue/ui_glue.cpp"
Import "glue/integrated_platform_glue.cpp"

Const EOS_EPIC_ACCOUNT_ID_MAX_LENGTH:Int = 32
Const EOS_PRODUCT_USER_ID_MAX_LENGTH:Int = 32
Const EOS_STATS_MAX_INGEST_STATS:Int = 3000
Const EOS_STATS_MAX_QUERY_STATS:Int = 1000
Const EOS_STATS_TIME_UNDEFINED:Long = -1
Const EOS_ACHIEVEMENTS_UNLOCKTIME_UNDEFINED:Long = -1
Const EOS_LEADERBOARDS_TIME_UNDEFINED:Long = -1
Const EOS_P2P_MAX_PACKET_SIZE:Int = 1170
Const EOS_P2P_MAX_CONNECTIONS:Int = 32
Const EOS_P2P_MAX_QUEUE_SIZE_UNLIMITED:ULong = 0

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
	SessionsSessionInProgress = 5000
	SessionsTooManyPlayers = 5001
	SessionsNoPermission = 5002
	SessionsSessionAlreadyExists = 5003
	SessionsInvalidLock = 5004
	SessionsInvalidSession = 5005
	SessionsSandboxNotAllowed = 5006
	SessionsInviteFailed = 5007
	SessionsInviteNotFound = 5008
	SessionsUpsertNotAllowed = 5009
	SessionsAggregationFailed = 5010
	SessionsHostAtCapacity = 5011
	SessionsSandboxAtCapacity = 5012
	SessionsSessionNotAnonymous = 5013
	SessionsOutOfSync = 5014
	SessionsTooManyInvites = 5015
	SessionsPresenceSessionExists = 5016
	SessionsDeploymentAtCapacity = 5017
	SessionsNotAllowed = 5018
	SessionsPlayerSanctioned = 5019
	PlayerDataStorageFilenameInvalid = 6000
	PlayerDataStorageFilenameLengthInvalid = 6001
	PlayerDataStorageFilenameInvalidChars = 6002
	PlayerDataStorageFileSizeTooLarge = 6003
	PlayerDataStorageFileSizeInvalid = 6004
	PlayerDataStorageFileHandleInvalid = 6005
	PlayerDataStorageDataInvalid = 6006
	PlayerDataStorageDataLengthInvalid = 6007
	PlayerDataStorageStartIndexInvalid = 6008
	PlayerDataStorageRequestInProgress = 6009
	PlayerDataStorageUserThrottled = 6010
	PlayerDataStorageEncryptionKeyNotSet = 6011
	PlayerDataStorageUserErrorFromDataCallback = 6012
	PlayerDataStorageFileHeaderHasNewerVersion = 6013
	PlayerDataStorageFileCorrupted = 6014
	TitleStorageUserErrorFromDataCallback = 10000
	TitleStorageEncryptionKeyNotSet = 10001
	TitleStorageFileCorrupted = 10002
	TitleStorageFileHeaderHasNewerVersion = 10003
	UnexpectedError = $7fffffff
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

Enum EEOSExternalAccountType
	Epic = 0
	Steam = 1
	PSN = 2
	XBL = 3
	Discord = 4
	GOG = 5
	Nintendo = 6
	Uplay = 7
	OpenID = 8
	Apple = 9
	Google = 10
	Oculus = 11
	Itchio = 12
	Amazon = 13
	Viveport = 14
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

Enum EEOSFriendsStatus
	NotFriends = 0
	InviteSent = 1
	InviteReceived = 2
	Friends = 3
End Enum

Enum EEOSPresenceStatus
	Offline = 0
	Online = 1
	Away = 2
	ExtendedAway = 3
	DoNotDisturb = 4
End Enum

Enum EEOSLoginStatus
	NotLoggedIn = 0
	UsingLocalProfile = 1
	LoggedIn = 2
End Enum

Enum EEOSLeaderboardAggregation
	Minimum = 0
	Maximum = 1
	Sum = 2
	Latest = 3
End Enum

Enum EEOSLobbyPermissionLevel
	PublicAdvertised = 0
	JoinViaPresence = 1
	InviteOnly = 2
End Enum

Enum EEOSComparisonOp
	Equal = 0
	NotEqual = 1
	GreaterThan = 2
	GreaterThanOrEqual = 3
	LessThan = 4
	LessThanOrEqual = 5
	Distance = 6
	AnyOf = 7
	NotAnyOf = 8
	OneOf = 9
	NotOneOf = 10
	Contains = 11
	RegexMatch = 12
	Size = 13
End Enum

Enum EEOSLobbyAttributeType
	Boolean = 0
	Int64 = 1
	DoubleValue = 2
	StringValue = 3
End Enum

Enum EEOSLobbyAttributeVisibility
	Public = 0
	PrivateValue = 1
End Enum

Enum EEOSLobbyMemberStatus
	Joined = 0
	Left = 1
	Disconnected = 2
	Kicked = 3
	Promoted = 4
	Closed = 5
End Enum

Enum EEOSPacketReliability
	UnreliableUnordered = 0
	ReliableUnordered = 1
	ReliableOrdered = 2
End Enum

Enum EEOSConnectionEstablishedType
	NewConnection = 0
	Reconnection = 1
End Enum

Enum EEOSNetworkConnectionType
	NoConnection = 0
	DirectConnection = 1
	RelayedConnection = 2
End Enum

Enum EEOSConnectionClosedReason
	Unknown = 0
	ClosedByLocalUser = 1
	ClosedByPeer = 2
	TimedOut = 3
	TooManyConnections = 4
	InvalidMessage = 5
	InvalidData = 6
	ConnectionFailed = 7
	ConnectionClosed = 8
	NegotiationFailed = 9
	UnexpectedError = 10
	ConnectionIgnored = 11
End Enum

Enum EEOSNATType
	Unknown = 0
	Open = 1
	Moderate = 2
	Strict = 3
End Enum

Enum EEOSRelayControl
	NoRelays = 0
	AllowRelays = 1
	ForceRelays = 2
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
	Field IntegratedPlatformOptions:TEOSIntegratedPlatformOptionsContainer
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

Rem
bbdoc: Values used to create a lobby.
about: BucketId is the lobby's primary search partition and must be non-empty.
End Rem
Type TEOSLobbyCreateOptions
	Field LocalUserId:TEOSProductUserId
	Field MaxMembers:UInt = 4
	Field PermissionLevel:EEOSLobbyPermissionLevel = EEOSLobbyPermissionLevel.InviteOnly
	Field PresenceEnabled:Int
	Field AllowInvites:Int = True
	Field BucketId:String
	Field DisableHostMigration:Int
	Field EnableRTCRoom:Int
	Field EnableJoinById:Int
	Field RejoinAfterKickRequiresInvite:Int
	Field CrossplayOptOut:Int
End Type

Type TEOSLobbyJoinOptions
	Field LocalUserId:TEOSProductUserId
	Field Details:TEOSLobbyDetails
	Field PresenceEnabled:Int
	Field CrossplayOptOut:Int
End Type

Rem
bbdoc: General information copied from a lobby-details handle.
End Rem
Type TEOSLobbyInfo
	Field LobbyId:String
	Field OwnerUserId:TEOSProductUserId
	Field PermissionLevel:EEOSLobbyPermissionLevel
	Field AvailableSlots:UInt
	Field MaxMembers:UInt
	Field AllowInvites:Int
	Field BucketId:String
	Field AllowHostMigration:Int
	Field RTCRoomEnabled:Int
	Field AllowJoinById:Int
	Field RejoinAfterKickRequiresInvite:Int
	Field PresenceEnabled:Int
	Field AllowedPlatformIds:Int[]
End Type

Type TEOSLobbyAttribute
	Field Key:String
	Field ValueType:EEOSLobbyAttributeType
	Field IntValue:Long
	Field DoubleValue:Double
	Field BoolValue:Int
	Field StringValue:String
	Field Visibility:EEOSLobbyAttributeVisibility
End Type

Type TEOSP2PSendOptions
	Field LocalUserId:TEOSProductUserId
	Field RemoteUserId:TEOSProductUserId
	Field SocketName:String
	Field Channel:Int
	Field Data:Byte[]
	Field AllowDelayedDelivery:Int
	Field Reliability:EEOSPacketReliability = EEOSPacketReliability.ReliableOrdered
	Field DisableAutoAcceptConnection:Int
End Type

Type TEOSP2PPacket
	Field RemoteUserId:TEOSProductUserId
	Field SocketName:String
	Field Channel:Int
	Field Data:Byte[]
End Type

Type TEOSP2PPacketQueueInfo
	Field IncomingMaxSizeBytes:ULong
	Field IncomingCurrentSizeBytes:ULong
	Field IncomingCurrentPacketCount:ULong
	Field OutgoingMaxSizeBytes:ULong
	Field OutgoingCurrentSizeBytes:ULong
	Field OutgoingCurrentPacketCount:ULong
End Type

Rem
bbdoc: User profile information copied from the local EOS cache.
about: Fields other than UserId may be empty when the account has not supplied
them or the application is not permitted to receive them.
End Rem
Type TEOSUserInfoData
	Field UserId:TEOSEpicAccountId
	Field Country:String
	Field DisplayName:String
	Field PreferredLanguage:String
	Field Nickname:String
	Field DisplayNameSanitized:String
End Type

Rem
bbdoc: One linked external account copied from the local User Info cache.
End Rem
Type TEOSExternalUserInfo
	Field AccountType:EEOSExternalAccountType
	Field AccountId:String
	Field DisplayName:String
	Field DisplayNameSanitized:String
End Type

Type TEOSPresenceDataRecord
	Field Key:String
	Field Value:String
End Type

Rem
bbdoc: Presence information copied from the local EOS cache.
End Rem
Type TEOSPresenceInfo
	Field Status:EEOSPresenceStatus
	Field UserId:TEOSEpicAccountId
	Field ProductId:String
	Field ProductVersion:String
	Field Platform:String
	Field RichText:String
	Field ProductName:String
	Field IntegratedPlatform:String
	Field Records:TEOSPresenceDataRecord[]
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

Interface IEOSAuthDeletePersistentAuthListener
	Method OnEOSAuthDeletePersistentAuth(result:EEOSResult)
End Interface

Interface IEOSAuthLoginStatusListener
	Method OnEOSAuthLoginStatusChanged(localUserId:TEOSEpicAccountId, previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus)
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

Interface IEOSConnectAuthExpirationListener
	Method OnEOSConnectAuthExpiration(localUserId:TEOSProductUserId)
End Interface

Interface IEOSConnectLoginStatusListener
	Method OnEOSConnectLoginStatusChanged(localUserId:TEOSProductUserId, previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus)
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

Interface IEOSUserInfoQueryListener
	Method OnEOSUserInfoQuery(result:EEOSResult, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
End Interface

Interface IEOSUserInfoQueryByDisplayNameListener
	Method OnEOSUserInfoQueryByDisplayName(result:EEOSResult, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, displayName:String)
End Interface

Interface IEOSUserInfoQueryByExternalAccountListener
	Method OnEOSUserInfoQueryByExternalAccount(result:EEOSResult, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, externalAccountId:String, accountType:EEOSExternalAccountType)
End Interface

Interface IEOSFriendsQueryListener
	Method OnEOSFriendsQuery(result:EEOSResult, localUserId:TEOSEpicAccountId)
End Interface

Interface IEOSFriendsUpdateListener
	Method OnEOSFriendsUpdate(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, previousStatus:EEOSFriendsStatus, currentStatus:EEOSFriendsStatus)
End Interface

Interface IEOSBlockedUsersUpdateListener
	Method OnEOSBlockedUsersUpdate(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, blocked:Int)
End Interface

Interface IEOSPresenceQueryListener
	Method OnEOSPresenceQuery(result:EEOSResult, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
End Interface

Interface IEOSPresenceSetListener
	Method OnEOSPresenceSet(result:EEOSResult, localUserId:TEOSEpicAccountId, richPresenceResult:EEOSResult)
End Interface

Interface IEOSPresenceChangedListener
	Method OnEOSPresenceChanged(localUserId:TEOSEpicAccountId, presenceUserId:TEOSEpicAccountId)
End Interface

Interface IEOSLobbyCreateListener
	Method OnEOSLobbyCreate(result:EEOSResult, lobbyId:String)
End Interface

Interface IEOSLobbyDestroyListener
	Method OnEOSLobbyDestroy(result:EEOSResult, lobbyId:String)
End Interface

Interface IEOSLobbyLeaveListener
	Method OnEOSLobbyLeave(result:EEOSResult, lobbyId:String)
End Interface

Interface IEOSLobbyJoinListener
	Method OnEOSLobbyJoin(result:EEOSResult, lobbyId:String)
End Interface

Interface IEOSLobbySearchFindListener
	Method OnEOSLobbySearchFind(result:EEOSResult)
End Interface

Interface IEOSLobbyUpdateListener
	Method OnEOSLobbyUpdate(result:EEOSResult, lobbyId:String)
End Interface

Interface IEOSLobbySendInviteListener
	Method OnEOSLobbySendInvite(result:EEOSResult, lobbyId:String)
End Interface

Interface IEOSLobbyRejectInviteListener
	Method OnEOSLobbyRejectInvite(result:EEOSResult, inviteId:String)
End Interface

Interface IEOSLobbyQueryInvitesListener
	Method OnEOSLobbyQueryInvites(result:EEOSResult, localUserId:TEOSProductUserId)
End Interface

Interface IEOSLobbyUpdateReceivedListener
	Method OnEOSLobbyUpdateReceived(lobbyId:String)
End Interface

Interface IEOSLobbyMemberUpdateReceivedListener
	Method OnEOSLobbyMemberUpdateReceived(lobbyId:String, targetUserId:TEOSProductUserId)
End Interface

Interface IEOSLobbyMemberStatusReceivedListener
	Method OnEOSLobbyMemberStatusReceived(lobbyId:String, targetUserId:TEOSProductUserId, status:EEOSLobbyMemberStatus)
End Interface

Interface IEOSLobbyInviteReceivedListener
	Method OnEOSLobbyInviteReceived(inviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId)
End Interface

Interface IEOSLobbyInviteAcceptedListener
	Method OnEOSLobbyInviteAccepted(inviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId, lobbyId:String)
End Interface

Interface IEOSP2PConnectionRequestListener
	Method OnEOSP2PConnectionRequest(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String)
End Interface

Interface IEOSP2PConnectionEstablishedListener
	Method OnEOSP2PConnectionEstablished(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String, connectionType:EEOSConnectionEstablishedType, networkType:EEOSNetworkConnectionType)
End Interface

Interface IEOSP2PConnectionInterruptedListener
	Method OnEOSP2PConnectionInterrupted(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String)
End Interface

Interface IEOSP2PConnectionClosedListener
	Method OnEOSP2PConnectionClosed(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String, reason:EEOSConnectionClosedReason)
End Interface

Interface IEOSP2PQueryNATTypeListener
	Method OnEOSP2PQueryNATType(result:EEOSResult, natType:EEOSNATType)
End Interface

Interface IEOSP2PIncomingPacketQueueFullListener
	Method OnEOSP2PIncomingPacketQueueFull(maxSizeBytes:ULong, currentSizeBytes:ULong, localUserId:TEOSProductUserId, channel:Int, packetSizeBytes:UInt)
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
		If Not EOSIsInitialized() Or Not options Then
			Return Null
		End If
		Local integratedPlatformOptionsHandle:Byte Ptr
		If options.IntegratedPlatformOptions Then
			integratedPlatformOptionsHandle = ..
				options.IntegratedPlatformOptions._NativeHandle()
			If Not integratedPlatformOptionsHandle Then
				Return Null
			End If
		End If
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
			options.TaskNetworkTimeoutSeconds,
			integratedPlatformOptionsHandle))
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
	bbdoc: Returns the Epic Account Services User Info interface.
	End Rem
	Method UserInfo:TEOSUserInfoInterface()
		If Not _handle Then Return Null
		Return TEOSUserInfoInterface._Create(Self, bmx_eos_platform_get_user_info_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the Epic Account Services Friends interface.
	End Rem
	Method Friends:TEOSFriends()
		If Not _handle Then Return Null
		Return TEOSFriends._Create(Self, bmx_eos_platform_get_friends_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the Epic Account Services Presence interface.
	End Rem
	Method Presence:TEOSPresence()
		If Not _handle Then Return Null
		Return TEOSPresence._Create(Self, bmx_eos_platform_get_presence_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS game-services Lobby interface.
	End Rem
	Method Lobby:TEOSLobby()
		If Not _handle Then Return Null
		Return TEOSLobby._Create(Self, bmx_eos_platform_get_lobby_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS searchable game-sessions interface.
	End Rem
	Method Sessions:TEOSSessions()
		If Not _handle Then
			Return Null
		End If
		Return TEOSSessions._Create(Self, bmx_eos_platform_get_sessions_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the Epic Social Overlay interface.
	End Rem
	Method UI:TEOSUI()
		If Not _handle Then
			Return Null
		End If
		Return TEOSUI._Create(Self, bmx_eos_platform_get_ui_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the native-service Integrated Platform interface.
	End Rem
	Method IntegratedPlatform:TEOSIntegratedPlatform()
		If Not _handle Then
			Return Null
		End If
		Return TEOSIntegratedPlatform._Create( ..
			Self, bmx_eos_platform_get_integrated_platform_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS game-services peer-to-peer networking interface.
	End Rem
	Method P2P:TEOSP2P()
		If Not _handle Then Return Null
		Return TEOSP2P._Create(Self, bmx_eos_platform_get_p2p_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS read-only Title Storage interface.
	End Rem
	Method TitleStorage:TEOSTitleStorage()
		If Not _handle Then Return Null
		Return TEOSTitleStorage._Create(Self, bmx_eos_platform_get_title_storage_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS per-user Player Data Storage interface.
	End Rem
	Method PlayerDataStorage:TEOSPlayerDataStorage()
		If Not _handle Then Return Null
		Return TEOSPlayerDataStorage._Create(Self, bmx_eos_platform_get_player_storage_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS player-sanctions interface.
	End Rem
	Method Sanctions:TEOSSanctions()
		If Not _handle Then
			Return Null
		End If
		Return TEOSSanctions._Create(Self, bmx_eos_platform_get_sanctions_interface(_handle))
	End Method

	Rem
	bbdoc: Returns the EOS player behavior reports interface.
	End Rem
	Method Reports:TEOSReports()
		If Not _handle Then
			Return Null
		End If
		Return TEOSReports._Create(Self, bmx_eos_platform_get_reports_interface(_handle))
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

Rem
bbdoc: One pending request to revoke the locally persisted Auth credential.
End Rem
Type TEOSAuthDeletePersistentAuthRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSAuthDeletePersistentAuthListener
	Field _complete:Int

	Public
	Function _Create:TEOSAuthDeletePersistentAuthRequest(owner:TEOSPlatform, listener:IEOSAuthDeletePersistentAuthListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSAuthDeletePersistentAuthRequest = New TEOSAuthDeletePersistentAuthRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSAuthDeletePersistentAuthRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSAuthDeletePersistentAuthListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSAuthDeletePersistentAuth(result)
		End If
	End Function

	Function _Cancel(request:TEOSAuthDeletePersistentAuthRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
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

Type TEOSAuthLoginStatusSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSAuthLoginStatusListener
	Field _id:ULong
	Public
	Function _Create:TEOSAuthLoginStatusSubscription(owner:TEOSPlatform, listener:IEOSAuthLoginStatusListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSAuthLoginStatusSubscription = New TEOSAuthLoginStatusSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function
	Function _Notify(subscription:TEOSAuthLoginStatusSubscription, localUserHandle:Byte Ptr, previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSAuthLoginStatusChanged(TEOSEpicAccountId._Create(localUserHandle), previousStatus, currentStatus)
	End Function
	Function _Cancel(subscription:TEOSAuthLoginStatusSubscription) { nomangle }
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
		bmx_eos_login_remove_notify(id)
	End Method
	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method
	Method Delete()
		Remove()
	End Method
End Type

Type TEOSConnectAuthExpirationSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSConnectAuthExpirationListener
	Field _id:ULong
	Public
	Function _Create:TEOSConnectAuthExpirationSubscription(owner:TEOSPlatform, listener:IEOSConnectAuthExpirationListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSConnectAuthExpirationSubscription = New TEOSConnectAuthExpirationSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function
	Function _Notify(subscription:TEOSConnectAuthExpirationSubscription, localUserHandle:Byte Ptr) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSConnectAuthExpiration(TEOSProductUserId._Create(localUserHandle))
	End Function
	Function _Cancel(subscription:TEOSConnectAuthExpirationSubscription) { nomangle }
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
		bmx_eos_login_remove_notify(id)
	End Method
	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method
	Method Delete()
		Remove()
	End Method
End Type

Type TEOSConnectLoginStatusSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSConnectLoginStatusListener
	Field _id:ULong
	Public
	Function _Create:TEOSConnectLoginStatusSubscription(owner:TEOSPlatform, listener:IEOSConnectLoginStatusListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSConnectLoginStatusSubscription = New TEOSConnectLoginStatusSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function
	Function _Notify(subscription:TEOSConnectLoginStatusSubscription, localUserHandle:Byte Ptr, previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSConnectLoginStatusChanged(TEOSProductUserId._Create(localUserHandle), previousStatus, currentStatus)
	End Function
	Function _Cancel(subscription:TEOSConnectLoginStatusSubscription) { nomangle }
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
		bmx_eos_login_remove_notify(id)
	End Method
	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method
	Method Delete()
		Remove()
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
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
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
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
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
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
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
		request._owner = owner
		request._listener = listener
		Return request
	End Function
	Function _Complete(request:TEOSLeaderboardsQueryDefinitionsRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLeaderboardsQueryDefinitionsListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
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
		request._owner = owner
		request._listener = listener
		Return request
	End Function
	Function _Complete(request:TEOSLeaderboardsQueryRanksRequest, result:EEOSResult, leaderboardId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLeaderboardsQueryRanksListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
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
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSLeaderboardsQueryUserScores(result)
	End Function
	Function _Cancel(request:TEOSLeaderboardsQueryUserScoresRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
	End Function
	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSUserInfoQueryRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSUserInfoQueryListener
	Field _complete:Int

	Public
	Function _Create:TEOSUserInfoQueryRequest(owner:TEOSPlatform, listener:IEOSUserInfoQueryListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSUserInfoQueryRequest = New TEOSUserInfoQueryRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSUserInfoQueryRequest, result:EEOSResult, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSUserInfoQueryListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSUserInfoQuery(result, TEOSEpicAccountId._Create(localUserHandle), TEOSEpicAccountId._Create(targetUserHandle))
	End Function

	Function _Cancel(request:TEOSUserInfoQueryRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSUserInfoQueryByDisplayNameRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSUserInfoQueryByDisplayNameListener
	Field _complete:Int

	Public
	Function _Create:TEOSUserInfoQueryByDisplayNameRequest(owner:TEOSPlatform, listener:IEOSUserInfoQueryByDisplayNameListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSUserInfoQueryByDisplayNameRequest = New TEOSUserInfoQueryByDisplayNameRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSUserInfoQueryByDisplayNameRequest, result:EEOSResult, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, displayName:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSUserInfoQueryByDisplayNameListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSUserInfoQueryByDisplayName(result, TEOSEpicAccountId._Create(localUserHandle), TEOSEpicAccountId._Create(targetUserHandle), displayName)
	End Function

	Function _Cancel(request:TEOSUserInfoQueryByDisplayNameRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null, "")
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSUserInfoQueryByExternalAccountRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSUserInfoQueryByExternalAccountListener
	Field _complete:Int

	Public
	Function _Create:TEOSUserInfoQueryByExternalAccountRequest(owner:TEOSPlatform, listener:IEOSUserInfoQueryByExternalAccountListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSUserInfoQueryByExternalAccountRequest = New TEOSUserInfoQueryByExternalAccountRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSUserInfoQueryByExternalAccountRequest, result:EEOSResult, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, externalAccountId:String, accountType:EEOSExternalAccountType) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSUserInfoQueryByExternalAccountListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSUserInfoQueryByExternalAccount(result, TEOSEpicAccountId._Create(localUserHandle), TEOSEpicAccountId._Create(targetUserHandle), externalAccountId, accountType)
	End Function

	Function _Cancel(request:TEOSUserInfoQueryByExternalAccountRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null, "", EEOSExternalAccountType.Epic)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSFriendsQueryRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSFriendsQueryListener
	Field _complete:Int

	Public
	Function _Create:TEOSFriendsQueryRequest(owner:TEOSPlatform, listener:IEOSFriendsQueryListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSFriendsQueryRequest = New TEOSFriendsQueryRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSFriendsQueryRequest, result:EEOSResult, localUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSFriendsQueryListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSFriendsQuery(result, TEOSEpicAccountId._Create(localUserHandle))
	End Function

	Function _Cancel(request:TEOSFriendsQueryRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSFriendsUpdateSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSFriendsUpdateListener
	Field _id:ULong

	Public
	Function _Create:TEOSFriendsUpdateSubscription(owner:TEOSPlatform, listener:IEOSFriendsUpdateListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSFriendsUpdateSubscription = New TEOSFriendsUpdateSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSFriendsUpdateSubscription, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, previousStatus:EEOSFriendsStatus, currentStatus:EEOSFriendsStatus) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSFriendsUpdate(TEOSEpicAccountId._Create(localUserHandle), TEOSEpicAccountId._Create(targetUserHandle), previousStatus, currentStatus)
	End Function

	Function _Cancel(subscription:TEOSFriendsUpdateSubscription) { nomangle }
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
		bmx_eos_friends_remove_notify(id)
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSBlockedUsersUpdateSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSBlockedUsersUpdateListener
	Field _id:ULong

	Public
	Function _Create:TEOSBlockedUsersUpdateSubscription(owner:TEOSPlatform, listener:IEOSBlockedUsersUpdateListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSBlockedUsersUpdateSubscription = New TEOSBlockedUsersUpdateSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSBlockedUsersUpdateSubscription, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, blocked:Int) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSBlockedUsersUpdate(TEOSEpicAccountId._Create(localUserHandle), TEOSEpicAccountId._Create(targetUserHandle), blocked)
	End Function

	Function _Cancel(subscription:TEOSBlockedUsersUpdateSubscription) { nomangle }
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
		bmx_eos_friends_remove_notify(id)
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSPresenceQueryRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSPresenceQueryListener
	Field _complete:Int

	Public
	Function _Create:TEOSPresenceQueryRequest(owner:TEOSPlatform, listener:IEOSPresenceQueryListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSPresenceQueryRequest = New TEOSPresenceQueryRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSPresenceQueryRequest, result:EEOSResult, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSPresenceQueryListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSPresenceQuery(result, TEOSEpicAccountId._Create(localUserHandle), TEOSEpicAccountId._Create(targetUserHandle))
	End Function

	Function _Cancel(request:TEOSPresenceQueryRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSPresenceSetRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSPresenceSetListener
	Field _complete:Int

	Public
	Function _Create:TEOSPresenceSetRequest(owner:TEOSPlatform, listener:IEOSPresenceSetListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSPresenceSetRequest = New TEOSPresenceSetRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSPresenceSetRequest, result:EEOSResult, localUserHandle:Byte Ptr, richPresenceResult:EEOSResult) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSPresenceSetListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSPresenceSet(result, TEOSEpicAccountId._Create(localUserHandle), richPresenceResult)
	End Function

	Function _Cancel(request:TEOSPresenceSetRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, EEOSResult.Canceled)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbyCreateRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyCreateListener
	Field _complete:Int

	Public
	Function _Create:TEOSLobbyCreateRequest(owner:TEOSPlatform, listener:IEOSLobbyCreateListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLobbyCreateRequest = New TEOSLobbyCreateRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSLobbyCreateRequest, result:EEOSResult, lobbyId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbyCreateListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSLobbyCreate(result, lobbyId)
	End Function

	Function _Cancel(request:TEOSLobbyCreateRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbyDestroyRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyDestroyListener
	Field _complete:Int

	Public
	Function _Create:TEOSLobbyDestroyRequest(owner:TEOSPlatform, listener:IEOSLobbyDestroyListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLobbyDestroyRequest = New TEOSLobbyDestroyRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSLobbyDestroyRequest, result:EEOSResult, lobbyId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbyDestroyListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSLobbyDestroy(result, lobbyId)
	End Function

	Function _Cancel(request:TEOSLobbyDestroyRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbyLeaveRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyLeaveListener
	Field _complete:Int

	Public
	Function _Create:TEOSLobbyLeaveRequest(owner:TEOSPlatform, listener:IEOSLobbyLeaveListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLobbyLeaveRequest = New TEOSLobbyLeaveRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSLobbyLeaveRequest, result:EEOSResult, lobbyId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbyLeaveListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSLobbyLeave(result, lobbyId)
	End Function

	Function _Cancel(request:TEOSLobbyLeaveRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbyJoinRequest
	Private
	Field _owner:TEOSPlatform
	Field _details:TEOSLobbyDetails
	Field _listener:IEOSLobbyJoinListener
	Field _complete:Int

	Public
	Function _Create:TEOSLobbyJoinRequest(owner:TEOSPlatform, details:TEOSLobbyDetails, listener:IEOSLobbyJoinListener)
		If Not owner Or Not details Or Not listener Then Return Null
		Local request:TEOSLobbyJoinRequest = New TEOSLobbyJoinRequest
		request._owner = owner
		request._details = details
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSLobbyJoinRequest, result:EEOSResult, lobbyId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbyJoinListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
			request._details = Null
		End If
		If listener Then listener.OnEOSLobbyJoin(result, lobbyId)
	End Function

	Function _Cancel(request:TEOSLobbyJoinRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbySearchFindRequest
	Private
	Field _owner:TEOSPlatform
	Field _search:TEOSLobbySearch
	Field _listener:IEOSLobbySearchFindListener
	Field _complete:Int

	Public
	Function _Create:TEOSLobbySearchFindRequest(owner:TEOSPlatform, search:TEOSLobbySearch, listener:IEOSLobbySearchFindListener)
		If Not owner Or Not search Or Not listener Then Return Null
		Local request:TEOSLobbySearchFindRequest = New TEOSLobbySearchFindRequest
		request._owner = owner
		request._search = search
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSLobbySearchFindRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbySearchFindListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
			request._search = Null
		End If
		If listener Then listener.OnEOSLobbySearchFind(result)
	End Function

	Function _Cancel(request:TEOSLobbySearchFindRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbyUpdateRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyUpdateListener
	Field _complete:Int

	Public
	Function _Create:TEOSLobbyUpdateRequest(owner:TEOSPlatform, listener:IEOSLobbyUpdateListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLobbyUpdateRequest = New TEOSLobbyUpdateRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSLobbyUpdateRequest, result:EEOSResult, lobbyId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbyUpdateListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSLobbyUpdate(result, lobbyId)
	End Function

	Function _Cancel(request:TEOSLobbyUpdateRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbySendInviteRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbySendInviteListener
	Field _complete:Int
	Public
	Function _Create:TEOSLobbySendInviteRequest(owner:TEOSPlatform, listener:IEOSLobbySendInviteListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLobbySendInviteRequest = New TEOSLobbySendInviteRequest
		request._owner = owner; request._listener = listener
		Return request
	End Function
	Function _Complete(request:TEOSLobbySendInviteRequest, result:EEOSResult, lobbyId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbySendInviteListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSLobbySendInvite(result, lobbyId)
	End Function
	Function _Cancel(request:TEOSLobbySendInviteRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function
	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbyRejectInviteRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyRejectInviteListener
	Field _complete:Int
	Public
	Function _Create:TEOSLobbyRejectInviteRequest(owner:TEOSPlatform, listener:IEOSLobbyRejectInviteListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLobbyRejectInviteRequest = New TEOSLobbyRejectInviteRequest
		request._owner = owner; request._listener = listener
		Return request
	End Function
	Function _Complete(request:TEOSLobbyRejectInviteRequest, result:EEOSResult, inviteId:String) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbyRejectInviteListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSLobbyRejectInvite(result, inviteId)
	End Function
	Function _Cancel(request:TEOSLobbyRejectInviteRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function
	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbyQueryInvitesRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyQueryInvitesListener
	Field _complete:Int
	Public
	Function _Create:TEOSLobbyQueryInvitesRequest(owner:TEOSPlatform, listener:IEOSLobbyQueryInvitesListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSLobbyQueryInvitesRequest = New TEOSLobbyQueryInvitesRequest
		request._owner = owner; request._listener = listener
		Return request
	End Function
	Function _Complete(request:TEOSLobbyQueryInvitesRequest, result:EEOSResult, localUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSLobbyQueryInvitesListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSLobbyQueryInvites(result, TEOSProductUserId._Create(localUserHandle))
	End Function
	Function _Cancel(request:TEOSLobbyQueryInvitesRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null)
	End Function
	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSLobbyUpdateReceivedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyUpdateReceivedListener
	Field _id:ULong
	Public
	Function _Create:TEOSLobbyUpdateReceivedSubscription(owner:TEOSPlatform, listener:IEOSLobbyUpdateReceivedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSLobbyUpdateReceivedSubscription = New TEOSLobbyUpdateReceivedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSLobbyUpdateReceivedSubscription, lobbyId:String) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSLobbyUpdateReceived(lobbyId)
		End If
	End Function

	Function _Cancel(subscription:TEOSLobbyUpdateReceivedSubscription) { nomangle }
		If subscription Then
			subscription._id = 0
			subscription._listener = Null
		End If
	End Function

	Method _SetId(id:ULong)
		_id = id
	End Method

	Method Remove()
		If _id Then
			Local id:ULong = _id
			_id = 0
			_listener = Null
			bmx_eos_lobby_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSLobbyMemberUpdateReceivedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyMemberUpdateReceivedListener
	Field _id:ULong
	Public
	Function _Create:TEOSLobbyMemberUpdateReceivedSubscription(owner:TEOSPlatform, listener:IEOSLobbyMemberUpdateReceivedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSLobbyMemberUpdateReceivedSubscription = New TEOSLobbyMemberUpdateReceivedSubscription
		subscription._owner = owner; subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSLobbyMemberUpdateReceivedSubscription, lobbyId:String, targetHandle:Byte Ptr) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSLobbyMemberUpdateReceived(lobbyId, TEOSProductUserId._Create(targetHandle))
	End Function

	Function _Cancel(subscription:TEOSLobbyMemberUpdateReceivedSubscription) { nomangle }
		If subscription Then subscription._id = 0; subscription._listener = Null
	End Function

	Method _SetId(id:ULong)
		_id = id
	End Method

	Method Remove()
		If _id Then
			Local id:ULong = _id
			_id = 0
			_listener = Null
			bmx_eos_lobby_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSLobbyMemberStatusReceivedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyMemberStatusReceivedListener
	Field _id:ULong
	Public
	Function _Create:TEOSLobbyMemberStatusReceivedSubscription(owner:TEOSPlatform, listener:IEOSLobbyMemberStatusReceivedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSLobbyMemberStatusReceivedSubscription = New TEOSLobbyMemberStatusReceivedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSLobbyMemberStatusReceivedSubscription, lobbyId:String, targetHandle:Byte Ptr, status:EEOSLobbyMemberStatus) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSLobbyMemberStatusReceived(lobbyId, TEOSProductUserId._Create(targetHandle), status)
		End If
	End Function

	Function _Cancel(subscription:TEOSLobbyMemberStatusReceivedSubscription) { nomangle }
		If subscription Then
			subscription._id = 0
			subscription._listener = Null
		End If
	End Function

	Method _SetId(id:ULong)
		_id = id
	End Method

	Method Remove()
		If _id Then
			Local id:ULong = _id
			_id = 0
			_listener = Null
			bmx_eos_lobby_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSLobbyInviteReceivedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyInviteReceivedListener
	Field _id:ULong
	Public
	Function _Create:TEOSLobbyInviteReceivedSubscription(owner:TEOSPlatform, listener:IEOSLobbyInviteReceivedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSLobbyInviteReceivedSubscription = New TEOSLobbyInviteReceivedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSLobbyInviteReceivedSubscription, inviteId:String, localHandle:Byte Ptr, senderHandle:Byte Ptr) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSLobbyInviteReceived(inviteId, TEOSProductUserId._Create(localHandle), TEOSProductUserId._Create(senderHandle))
		End If
	End Function

	Function _Cancel(subscription:TEOSLobbyInviteReceivedSubscription) { nomangle }
		If subscription Then
			subscription._id = 0
			subscription._listener = Null
		End If
	End Function

	Method _SetId(id:ULong)
		_id = id
	End Method

	Method Remove()
		If _id Then
			Local id:ULong = _id
			_id = 0
			_listener = Null
			bmx_eos_lobby_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSLobbyInviteAcceptedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLobbyInviteAcceptedListener
	Field _id:ULong
	Public
	Function _Create:TEOSLobbyInviteAcceptedSubscription(owner:TEOSPlatform, listener:IEOSLobbyInviteAcceptedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSLobbyInviteAcceptedSubscription = New TEOSLobbyInviteAcceptedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSLobbyInviteAcceptedSubscription, inviteId:String, localHandle:Byte Ptr, senderHandle:Byte Ptr, lobbyId:String) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSLobbyInviteAccepted(inviteId, TEOSProductUserId._Create(localHandle), TEOSProductUserId._Create(senderHandle), lobbyId)
		End If
	End Function

	Function _Cancel(subscription:TEOSLobbyInviteAcceptedSubscription) { nomangle }
		If subscription Then
			subscription._id = 0
			subscription._listener = Null
		End If
	End Function

	Method _SetId(id:ULong)
		_id = id
	End Method

	Method Remove()
		If _id Then
			Local id:ULong = _id
			_id = 0
			_listener = Null
			bmx_eos_lobby_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSPresenceChangedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSPresenceChangedListener
	Field _id:ULong

	Public
	Function _Create:TEOSPresenceChangedSubscription(owner:TEOSPlatform, listener:IEOSPresenceChangedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSPresenceChangedSubscription = New TEOSPresenceChangedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSPresenceChangedSubscription, localUserHandle:Byte Ptr, presenceUserHandle:Byte Ptr) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSPresenceChanged(TEOSEpicAccountId._Create(localUserHandle), TEOSEpicAccountId._Create(presenceUserHandle))
	End Function

	Function _Cancel(subscription:TEOSPresenceChangedSubscription) { nomangle }
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
		bmx_eos_presence_remove_notify_changed(id)
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
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

	Rem
	bbdoc: Revokes and removes the credential used by PersistentAuth login.
	about: RefreshToken is normally empty on desktop and mobile. Console callers
	pass the long-lived refresh token stored by the title.
	End Rem
	Method DeletePersistentAuth:TEOSAuthDeletePersistentAuthRequest(listener:IEOSAuthDeletePersistentAuthListener, refreshToken:String = "")
		If Not _owner Or Not _owner.IsValid() Or Not listener Then
			Return Null
		End If
		Local request:TEOSAuthDeletePersistentAuthRequest = TEOSAuthDeletePersistentAuthRequest._Create(_owner, listener)
		bmx_eos_auth_delete_persistent(_owner._NativeHandle(), _handle, request, refreshToken)
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

	Method LoginStatus:EEOSLoginStatus(localUserId:TEOSEpicAccountId)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Then Return EEOSLoginStatus.NotLoggedIn
		Return EEOSLoginStatus(bmx_eos_auth_get_login_status(_handle, localUserId._NativeHandle()))
	End Method

	Method AddNotifyLoginStatusChanged:TEOSAuthLoginStatusSubscription(listener:IEOSAuthLoginStatusListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSAuthLoginStatusSubscription = TEOSAuthLoginStatusSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_auth_add_notify_login_status(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
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

	Method LoginStatus:EEOSLoginStatus(localUserId:TEOSProductUserId)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Then Return EEOSLoginStatus.NotLoggedIn
		Return EEOSLoginStatus(bmx_eos_connect_get_login_status(_handle, localUserId._NativeHandle()))
	End Method

	Method AddNotifyAuthExpiration:TEOSConnectAuthExpirationSubscription(listener:IEOSConnectAuthExpirationListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSConnectAuthExpirationSubscription = TEOSConnectAuthExpirationSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_connect_add_notify_auth_expiration(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyLoginStatusChanged:TEOSConnectLoginStatusSubscription(listener:IEOSConnectLoginStatusListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSConnectLoginStatusSubscription = TEOSConnectLoginStatusSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_connect_add_notify_login_status(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
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
		definition.LeaderboardId = id
		definition.StatName = statName
		definition.Aggregation = aggregation
		definition.StartTime = startTime
		definition.EndTime = endTime
		Return definition
	End Function
	Function _Record:TEOSLeaderboardRecord(userHandle:Byte Ptr, rank:UInt, score:Int, displayName:String)
		Local record:TEOSLeaderboardRecord = New TEOSLeaderboardRecord
		record.UserId = TEOSProductUserId._Create(userHandle)
		record.Rank = rank
		record.Score = score
		record.UserDisplayName = displayName
		Return record
	End Function
	Public
	Function _Create:TEOSLeaderboards(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local leaderboards:TEOSLeaderboards = New TEOSLeaderboards
		leaderboards._owner = owner
		leaderboards._handle = handle
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
			userScore.UserId = TEOSProductUserId._Create(userHandle)
			userScore.Score = score
		End If
		Return result
	End Method
End Type

Rem
bbdoc: Epic Account Services profile queries for one platform.
End Rem
Type TEOSUserInfoInterface
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSUserInfoInterface(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local userInfo:TEOSUserInfoInterface = New TEOSUserInfoInterface
		userInfo._owner = owner
		userInfo._handle = handle
		Return userInfo
	End Function

	Rem
	bbdoc: Queries profile information for an Epic Account and places it in the local EOS cache.
	End Rem
	Method Query:TEOSUserInfoQueryRequest(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, listener:IEOSUserInfoQueryListener)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Or Not listener Then Return Null
		Local request:TEOSUserInfoQueryRequest = TEOSUserInfoQueryRequest._Create(_owner, listener)
		bmx_eos_user_info_query(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), targetUserId._NativeHandle())
		Return request
	End Method

	Rem
	bbdoc: Finds an Epic Account by its raw display name and caches its profile.
	End Rem
	Method QueryByDisplayName:TEOSUserInfoQueryByDisplayNameRequest(localUserId:TEOSEpicAccountId, displayName:String, listener:IEOSUserInfoQueryByDisplayNameListener)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Or Not displayName Or Not listener Then Return Null
		Local request:TEOSUserInfoQueryByDisplayNameRequest = TEOSUserInfoQueryByDisplayNameRequest._Create(_owner, listener)
		bmx_eos_user_info_query_by_display_name(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), displayName)
		Return request
	End Method

	Rem
	bbdoc: Finds an Epic Account by a linked external account and caches its profile.
	End Rem
	Method QueryByExternalAccount:TEOSUserInfoQueryByExternalAccountRequest(localUserId:TEOSEpicAccountId, externalAccountId:String, accountType:EEOSExternalAccountType, listener:IEOSUserInfoQueryByExternalAccountListener)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Or Not externalAccountId Or Not listener Then Return Null
		Local request:TEOSUserInfoQueryByExternalAccountRequest = TEOSUserInfoQueryByExternalAccountRequest._Create(_owner, listener)
		bmx_eos_user_info_query_by_external_account(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), externalAccountId, accountType)
		Return request
	End Method

	Rem
	bbdoc: Copies cached profile information populated by a successful Query call.
	End Rem
	Method CopyUserInfo:EEOSResult(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, info:TEOSUserInfoData Var)
		info = Null
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Then Return EEOSResult.InvalidParameters
		Local userHandle:Byte Ptr
		Local country:String, displayName:String, preferredLanguage:String, nickname:String, displayNameSanitized:String
		Local result:EEOSResult = bmx_eos_user_info_copy(_handle, localUserId._NativeHandle(), targetUserId._NativeHandle(), userHandle, country, displayName, preferredLanguage, nickname, displayNameSanitized)
		If result = EEOSResult.Success Then
			info = New TEOSUserInfoData
			info.UserId = TEOSEpicAccountId._Create(userHandle)
			info.Country = country
			info.DisplayName = displayName
			info.PreferredLanguage = preferredLanguage
			info.Nickname = nickname
			info.DisplayNameSanitized = displayNameSanitized
		End If
		Return result
	End Method

	Method ExternalUserInfoCount:Int(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Then Return 0
		Return Int(bmx_eos_user_info_get_external_count(_handle, localUserId._NativeHandle(), targetUserId._NativeHandle()))
	End Method

	Method CopyExternalUserInfoByIndex:EEOSResult(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, index:Int, info:TEOSExternalUserInfo Var)
		info = Null
		If Not _ValidIds(localUserId, targetUserId) Or index < 0 Then Return EEOSResult.InvalidParameters
		Local accountType:EEOSExternalAccountType, accountId:String, displayName:String, displayNameSanitized:String
		Local result:EEOSResult = bmx_eos_user_info_copy_external_by_index(_handle, localUserId._NativeHandle(), targetUserId._NativeHandle(), UInt(index), accountType, accountId, displayName, displayNameSanitized)
		If result = EEOSResult.Success Then info = _ExternalInfo(accountType, accountId, displayName, displayNameSanitized)
		Return result
	End Method

	Method CopyExternalUserInfoByAccountType:EEOSResult(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, requestedType:EEOSExternalAccountType, info:TEOSExternalUserInfo Var)
		info = Null
		If Not _ValidIds(localUserId, targetUserId) Then Return EEOSResult.InvalidParameters
		Local accountType:EEOSExternalAccountType, accountId:String, displayName:String, displayNameSanitized:String
		Local result:EEOSResult = bmx_eos_user_info_copy_external_by_type(_handle, localUserId._NativeHandle(), targetUserId._NativeHandle(), requestedType, accountType, accountId, displayName, displayNameSanitized)
		If result = EEOSResult.Success Then info = _ExternalInfo(accountType, accountId, displayName, displayNameSanitized)
		Return result
	End Method

	Method CopyExternalUserInfoByAccountId:EEOSResult(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, requestedAccountId:String, info:TEOSExternalUserInfo Var)
		info = Null
		If Not _ValidIds(localUserId, targetUserId) Or Not requestedAccountId Then Return EEOSResult.InvalidParameters
		Local accountType:EEOSExternalAccountType, accountId:String, displayName:String, displayNameSanitized:String
		Local result:EEOSResult = bmx_eos_user_info_copy_external_by_id(_handle, localUserId._NativeHandle(), targetUserId._NativeHandle(), requestedAccountId, accountType, accountId, displayName, displayNameSanitized)
		If result = EEOSResult.Success Then info = _ExternalInfo(accountType, accountId, displayName, displayNameSanitized)
		Return result
	End Method

	Private
	Method _ValidIds:Int(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
		Return _owner And _owner.IsValid() And localUserId And localUserId.IsValid() And targetUserId And targetUserId.IsValid()
	End Method

	Function _ExternalInfo:TEOSExternalUserInfo(accountType:EEOSExternalAccountType, accountId:String, displayName:String, displayNameSanitized:String)
		Local info:TEOSExternalUserInfo = New TEOSExternalUserInfo
		info.AccountType = accountType
		info.AccountId = accountId
		info.DisplayName = displayName
		info.DisplayNameSanitized = displayNameSanitized
		Return info
	End Function
End Type

Rem
bbdoc: Epic Account Services friends and blocklist access for one platform.
End Rem
Type TEOSFriends
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSFriends(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local friends:TEOSFriends = New TEOSFriends
		friends._owner = owner
		friends._handle = handle
		Return friends
	End Function

	Rem
	bbdoc: Queries the signed-in Epic account's friends list and blocklist into the local cache.
	End Rem
	Method Query:TEOSFriendsQueryRequest(localUserId:TEOSEpicAccountId, listener:IEOSFriendsQueryListener)
		If Not _ValidUser(localUserId) Or Not listener Then Return Null
		Local request:TEOSFriendsQueryRequest = TEOSFriendsQueryRequest._Create(_owner, listener)
		bmx_eos_friends_query(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle())
		Return request
	End Method

	Method FriendCount:Int(localUserId:TEOSEpicAccountId)
		If Not _ValidUser(localUserId) Then Return 0
		Return bmx_eos_friends_get_count(_handle, localUserId._NativeHandle())
	End Method

	Method FriendAtIndex:TEOSEpicAccountId(localUserId:TEOSEpicAccountId, index:Int)
		If Not _ValidUser(localUserId) Or index < 0 Then Return Null
		Return TEOSEpicAccountId._Create(bmx_eos_friends_get_by_index(_handle, localUserId._NativeHandle(), index))
	End Method

	Method Status:EEOSFriendsStatus(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
		If Not _ValidUser(localUserId) Or Not targetUserId Or Not targetUserId.IsValid() Then Return EEOSFriendsStatus.NotFriends
		Return bmx_eos_friends_get_status(_handle, localUserId._NativeHandle(), targetUserId._NativeHandle())
	End Method

	Method BlockedUserCount:Int(localUserId:TEOSEpicAccountId)
		If Not _ValidUser(localUserId) Then Return 0
		Return bmx_eos_friends_get_blocked_count(_handle, localUserId._NativeHandle())
	End Method

	Method BlockedUserAtIndex:TEOSEpicAccountId(localUserId:TEOSEpicAccountId, index:Int)
		If Not _ValidUser(localUserId) Or index < 0 Then Return Null
		Return TEOSEpicAccountId._Create(bmx_eos_friends_get_blocked_by_index(_handle, localUserId._NativeHandle(), index))
	End Method

	Method AddNotifyFriendsUpdate:TEOSFriendsUpdateSubscription(listener:IEOSFriendsUpdateListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSFriendsUpdateSubscription = TEOSFriendsUpdateSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_friends_add_notify_update(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyBlockedUsersUpdate:TEOSBlockedUsersUpdateSubscription(listener:IEOSBlockedUsersUpdateListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSBlockedUsersUpdateSubscription = TEOSBlockedUsersUpdateSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_friends_add_notify_blocked(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Private
	Method _ValidUser:Int(localUserId:TEOSEpicAccountId)
		Return _owner And _owner.IsValid() And localUserId And localUserId.IsValid()
	End Method
End Type

Rem
bbdoc: Epic Account Services presence access for one platform.
End Rem
Type TEOSPresence
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSPresence(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local presence:TEOSPresence = New TEOSPresence
		presence._owner = owner
		presence._handle = handle
		Return presence
	End Function

	Rem
	bbdoc: Queries presence for the local user or one of their Epic friends.
	End Rem
	Method Query:TEOSPresenceQueryRequest(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, listener:IEOSPresenceQueryListener)
		If Not _ValidIds(localUserId, targetUserId) Or Not listener Then Return Null
		Local request:TEOSPresenceQueryRequest = TEOSPresenceQueryRequest._Create(_owner, listener)
		bmx_eos_presence_query(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), targetUserId._NativeHandle())
		Return request
	End Method

	Method HasPresence:Int(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
		If Not _ValidIds(localUserId, targetUserId) Then Return False
		Return bmx_eos_presence_has(_handle, localUserId._NativeHandle(), targetUserId._NativeHandle())
	End Method

	Method CopyPresence:EEOSResult(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, info:TEOSPresenceInfo Var)
		info = Null
		If Not _ValidIds(localUserId, targetUserId) Then Return EEOSResult.InvalidParameters
		Local status:EEOSPresenceStatus, userHandle:Byte Ptr
		Local productId:String, productVersion:String, platform:String, richText:String, productName:String, integratedPlatform:String
		Local keys:String[], values:String[]
		Local result:EEOSResult = bmx_eos_presence_copy(_handle, localUserId._NativeHandle(), targetUserId._NativeHandle(), status, userHandle, productId, productVersion, platform, richText, productName, integratedPlatform, keys, values)
		If result = EEOSResult.Success Then
			info = New TEOSPresenceInfo
			info.Status = status
			info.UserId = TEOSEpicAccountId._Create(userHandle)
			info.ProductId = productId
			info.ProductVersion = productVersion
			info.Platform = platform
			info.RichText = richText
			info.ProductName = productName
			info.IntegratedPlatform = integratedPlatform
			info.Records = New TEOSPresenceDataRecord[keys.Length]
			For Local index:Int = 0 Until keys.Length
				Local record:TEOSPresenceDataRecord = New TEOSPresenceDataRecord
				record.Key = keys[index]
				If index < values.Length Then record.Value = values[index]
				info.Records[index] = record
			Next
		End If
		Return result
	End Method

	Rem
	bbdoc: Creates an owned modification used to compose a presence update.
	End Rem
	Method CreateModification:EEOSResult(localUserId:TEOSEpicAccountId, modification:TEOSPresenceModification Var)
		modification = Null
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Then Return EEOSResult.InvalidParameters
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_presence_create_modification(_handle, localUserId._NativeHandle(), handle)
		If result = EEOSResult.Success Then modification = TEOSPresenceModification._Create(_owner, handle)
		Return result
	End Method

	Rem
	bbdoc: Publishes the composed presence update asynchronously.
	about: The modification may be released immediately after this method returns.
	End Rem
	Method SetPresence:TEOSPresenceSetRequest(localUserId:TEOSEpicAccountId, modification:TEOSPresenceModification, listener:IEOSPresenceSetListener)
		If Not _owner Or Not _owner.IsValid() Or Not localUserId Or Not localUserId.IsValid() Or Not modification Or Not modification.IsValid() Or Not listener Then Return Null
		Local request:TEOSPresenceSetRequest = TEOSPresenceSetRequest._Create(_owner, listener)
		bmx_eos_presence_set(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), modification._NativeHandle())
		Return request
	End Method

	Method AddNotifyPresenceChanged:TEOSPresenceChangedSubscription(listener:IEOSPresenceChangedListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSPresenceChangedSubscription = TEOSPresenceChangedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_presence_add_notify_changed(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Private
	Method _ValidIds:Int(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
		Return _owner And _owner.IsValid() And localUserId And localUserId.IsValid() And targetUserId And targetUserId.IsValid()
	End Method
End Type

Rem
bbdoc: An owned collection of changes to publish through the Presence interface.
End Rem
Type TEOSPresenceModification
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSPresenceModification(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local modification:TEOSPresenceModification = New TEOSPresenceModification
		modification._owner = owner
		modification._handle = handle
		Return modification
	End Function

	Method SetStatus:EEOSResult(status:EEOSPresenceStatus)
		If Not IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_presence_modification_set_status(_handle, status)
	End Method

	Method SetRawRichText:EEOSResult(richText:String)
		If Not IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_presence_modification_set_rich_text(_handle, richText)
	End Method

	Method SetJoinInfo:EEOSResult(joinInfo:String)
		If Not IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_presence_modification_set_join_info(_handle, joinInfo)
	End Method

	Method IsValid:Int()
		Return _handle And _owner And _owner.IsValid()
	End Method

	Method _NativeHandle:Byte Ptr()
		If Not IsValid() Then Return Null
		Return _handle
	End Method

	Method Release()
		If Not _handle Then Return
		Local handle:Byte Ptr = _handle
		_handle = Null
		bmx_eos_presence_modification_release(handle)
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type

Rem
bbdoc: EOS game-services lobby access for one platform.
End Rem
Type TEOSLobby
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSLobby(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local lobby:TEOSLobby = New TEOSLobby
		lobby._owner = owner
		lobby._handle = handle
		Return lobby
	End Function

	Rem
	bbdoc: Creates a lobby and joins the local Product User as its owner.
	End Rem
	Method Create:TEOSLobbyCreateRequest(options:TEOSLobbyCreateOptions, listener:IEOSLobbyCreateListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not options.LocalUserId Or Not options.LocalUserId.IsValid() Or Not listener Then Return Null
		If options.MaxMembers < 1 Or options.MaxMembers > 64 Or Not options.BucketId Then Return Null
		Local request:TEOSLobbyCreateRequest = TEOSLobbyCreateRequest._Create(_owner, listener)
		bmx_eos_lobby_create(_owner._NativeHandle(), _handle, request, options.LocalUserId._NativeHandle(), options.MaxMembers, options.PermissionLevel, options.PresenceEnabled, options.AllowInvites, options.BucketId, options.DisableHostMigration, options.EnableRTCRoom, options.EnableJoinById, options.RejoinAfterKickRequiresInvite, options.CrossplayOptOut)
		Return request
	End Method

	Rem
	bbdoc: Destroys a lobby owned by the local Product User.
	End Rem
	Method Destroy:TEOSLobbyDestroyRequest(localUserId:TEOSProductUserId, lobbyId:String, listener:IEOSLobbyDestroyListener)
		If Not _ValidUser(localUserId) Or Not lobbyId Or Not listener Then Return Null
		Local request:TEOSLobbyDestroyRequest = TEOSLobbyDestroyRequest._Create(_owner, listener)
		bmx_eos_lobby_destroy(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), lobbyId)
		Return request
	End Method

	Rem
	bbdoc: Leaves a lobby as a non-owner. Owners should destroy the lobby or transfer ownership first.
	End Rem
	Method Leave:TEOSLobbyLeaveRequest(localUserId:TEOSProductUserId, lobbyId:String, listener:IEOSLobbyLeaveListener)
		If Not _ValidUser(localUserId) Or Not lobbyId Or Not listener Then Return Null
		Local request:TEOSLobbyLeaveRequest = TEOSLobbyLeaveRequest._Create(_owner, listener)
		bmx_eos_lobby_leave(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), lobbyId)
		Return request
	End Method

	Rem
	bbdoc: Joins the lobby represented by a details handle copied from a completed search.
	End Rem
	Method Join:TEOSLobbyJoinRequest(options:TEOSLobbyJoinOptions, listener:IEOSLobbyJoinListener)
		If Not _owner Or Not _owner.IsValid() Or Not options Or Not options.LocalUserId Or Not options.LocalUserId.IsValid() Or Not options.Details Or Not options.Details.IsValid() Or Not listener Then Return Null
		Local request:TEOSLobbyJoinRequest = TEOSLobbyJoinRequest._Create(_owner, options.Details, listener)
		bmx_eos_lobby_join(_owner._NativeHandle(), _handle, request, options.Details._NativeHandle(), options.LocalUserId._NativeHandle(), options.PresenceEnabled, options.CrossplayOptOut)
		Return request
	End Method

	Rem
	bbdoc: Creates an owned lobby search with room for up to maxResults results.
	End Rem
	Method CreateSearch:EEOSResult(maxResults:UInt, search:TEOSLobbySearch Var)
		search = Null
		If Not _owner Or Not _owner.IsValid() Or maxResults < 1 Or maxResults > 200 Then Return EEOSResult.InvalidParameters
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_lobby_create_search(_handle, maxResults, handle)
		If result = EEOSResult.Success Then search = TEOSLobbySearch._Create(_owner, handle)
		Return result
	End Method

	Method CreateModification:EEOSResult(localUserId:TEOSProductUserId, lobbyId:String, modification:TEOSLobbyModification Var)
		modification = Null
		If Not _ValidUser(localUserId) Or Not lobbyId Then Return EEOSResult.InvalidParameters
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_lobby_create_modification(_handle, localUserId._NativeHandle(), lobbyId, handle)
		If result = EEOSResult.Success Then modification = TEOSLobbyModification._Create(_owner, handle)
		Return result
	End Method

	Rem
	bbdoc: Publishes a composed lobby or member update asynchronously.
	about: The modification may be released immediately after this method returns.
	End Rem
	Method Update:TEOSLobbyUpdateRequest(modification:TEOSLobbyModification, listener:IEOSLobbyUpdateListener)
		If Not _owner Or Not _owner.IsValid() Or Not modification Or Not modification.IsValid() Or Not listener Then Return Null
		Local request:TEOSLobbyUpdateRequest = TEOSLobbyUpdateRequest._Create(_owner, listener)
		bmx_eos_lobby_update(_owner._NativeHandle(), _handle, request, modification._NativeHandle())
		Return request
	End Method

	Method SendInvite:TEOSLobbySendInviteRequest(lobbyId:String, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId, listener:IEOSLobbySendInviteListener)
		If Not _ValidUser(localUserId) Or Not targetUserId Or Not targetUserId.IsValid() Or Not lobbyId Or Not listener Then Return Null
		Local request:TEOSLobbySendInviteRequest = TEOSLobbySendInviteRequest._Create(_owner, listener)
		bmx_eos_lobby_send_invite(_owner._NativeHandle(), _handle, request, lobbyId, localUserId._NativeHandle(), targetUserId._NativeHandle())
		Return request
	End Method

	Method RejectInvite:TEOSLobbyRejectInviteRequest(inviteId:String, localUserId:TEOSProductUserId, listener:IEOSLobbyRejectInviteListener)
		If Not _ValidUser(localUserId) Or Not inviteId Or Not listener Then Return Null
		Local request:TEOSLobbyRejectInviteRequest = TEOSLobbyRejectInviteRequest._Create(_owner, listener)
		bmx_eos_lobby_reject_invite(_owner._NativeHandle(), _handle, request, inviteId, localUserId._NativeHandle())
		Return request
	End Method

	Method QueryInvites:TEOSLobbyQueryInvitesRequest(localUserId:TEOSProductUserId, listener:IEOSLobbyQueryInvitesListener)
		If Not _ValidUser(localUserId) Or Not listener Then Return Null
		Local request:TEOSLobbyQueryInvitesRequest = TEOSLobbyQueryInvitesRequest._Create(_owner, listener)
		bmx_eos_lobby_query_invites(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle())
		Return request
	End Method

	Method InviteCount:UInt(localUserId:TEOSProductUserId)
		If Not _ValidUser(localUserId) Then Return 0
		Return bmx_eos_lobby_get_invite_count(_handle, localUserId._NativeHandle())
	End Method

	Method InviteIdByIndex:EEOSResult(localUserId:TEOSProductUserId, index:UInt, inviteId:String Var)
		inviteId = ""
		If Not _ValidUser(localUserId) Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_get_invite_id_by_index(_handle, localUserId._NativeHandle(), index, inviteId)
	End Method

	Method CopyDetailsByInviteId:EEOSResult(inviteId:String, details:TEOSLobbyDetails Var)
		details = Null
		If Not _owner Or Not _owner.IsValid() Or Not inviteId Then Return EEOSResult.InvalidParameters
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_lobby_copy_details_by_invite(_handle, inviteId, handle)
		If result = EEOSResult.Success Then details = TEOSLobbyDetails._Create(_owner, handle)
		Return result
	End Method

	Method AddNotifyLobbyUpdateReceived:TEOSLobbyUpdateReceivedSubscription(listener:IEOSLobbyUpdateReceivedListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSLobbyUpdateReceivedSubscription = TEOSLobbyUpdateReceivedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_lobby_add_notify_update(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyMemberUpdateReceived:TEOSLobbyMemberUpdateReceivedSubscription(listener:IEOSLobbyMemberUpdateReceivedListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSLobbyMemberUpdateReceivedSubscription = TEOSLobbyMemberUpdateReceivedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_lobby_add_notify_member_update(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyMemberStatusReceived:TEOSLobbyMemberStatusReceivedSubscription(listener:IEOSLobbyMemberStatusReceivedListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSLobbyMemberStatusReceivedSubscription = TEOSLobbyMemberStatusReceivedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_lobby_add_notify_member_status(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyInviteReceived:TEOSLobbyInviteReceivedSubscription(listener:IEOSLobbyInviteReceivedListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSLobbyInviteReceivedSubscription = TEOSLobbyInviteReceivedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_lobby_add_notify_invite_received(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyInviteAccepted:TEOSLobbyInviteAcceptedSubscription(listener:IEOSLobbyInviteAcceptedListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSLobbyInviteAcceptedSubscription = TEOSLobbyInviteAcceptedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_lobby_add_notify_invite_accepted(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Rem
	bbdoc: Copies an owned details handle for a lobby the local Product User has joined.
	End Rem
	Method CopyDetails:EEOSResult(localUserId:TEOSProductUserId, lobbyId:String, details:TEOSLobbyDetails Var)
		details = Null
		If Not _ValidUser(localUserId) Or Not lobbyId Then Return EEOSResult.InvalidParameters
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_lobby_copy_details(_handle, localUserId._NativeHandle(), lobbyId, handle)
		If result = EEOSResult.Success Then details = TEOSLobbyDetails._Create(_owner, handle)
		Return result
	End Method

	Private
	Method _ValidUser:Int(localUserId:TEOSProductUserId)
		Return _owner And _owner.IsValid() And localUserId And localUserId.IsValid()
	End Method
End Type

Rem
bbdoc: An owned collection of lobby and local-member changes.
End Rem
Type TEOSLobbyModification
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSLobbyModification(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local modification:TEOSLobbyModification = New TEOSLobbyModification
		modification._owner = owner
		modification._handle = handle
		Return modification
	End Function

	Method SetBucketId:EEOSResult(bucketId:String)
		If Not IsValid() Or Not bucketId Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_modification_set_bucket(_handle, bucketId)
	End Method

	Method SetPermissionLevel:EEOSResult(permissionLevel:EEOSLobbyPermissionLevel)
		If Not IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_lobby_modification_set_permission(_handle, permissionLevel)
	End Method

	Method SetMaxMembers:EEOSResult(maxMembers:UInt)
		If Not IsValid() Or maxMembers < 1 Or maxMembers > 64 Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_modification_set_max_members(_handle, maxMembers)
	End Method

	Method SetInvitesAllowed:EEOSResult(allowInvites:Int)
		If Not IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_lobby_modification_set_invites(_handle, allowInvites)
	End Method

	Method AddStringAttribute:EEOSResult(key:String, value:String, visibility:EEOSLobbyAttributeVisibility = EEOSLobbyAttributeVisibility.Public)
		If Not IsValid() Or Not key Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_modification_add_string_attribute(_handle, key, value, visibility)
	End Method

	Method RemoveAttribute:EEOSResult(key:String)
		If Not IsValid() Or Not key Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_modification_remove_attribute(_handle, key, False)
	End Method

	Method AddStringMemberAttribute:EEOSResult(key:String, value:String, visibility:EEOSLobbyAttributeVisibility = EEOSLobbyAttributeVisibility.Public)
		If Not IsValid() Or Not key Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_modification_add_string_member_attribute(_handle, key, value, visibility)
	End Method

	Method RemoveMemberAttribute:EEOSResult(key:String)
		If Not IsValid() Or Not key Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_modification_remove_attribute(_handle, key, True)
	End Method

	Method IsValid:Int()
		Return _handle And _owner And _owner.IsValid()
	End Method

	Method _NativeHandle:Byte Ptr()
		If Not IsValid() Then Return Null
		Return _handle
	End Method

	Method Release()
		If Not _handle Then Return
		Local handle:Byte Ptr = _handle
		_handle = Null
		bmx_eos_lobby_modification_release(handle)
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type

Rem
bbdoc: An owned configurable lobby search and its most recent results.
about: Set exactly one search mode: a lobby ID, target Product User, or one or
more parameters. Release the search before releasing its platform.
End Rem
Type TEOSLobbySearch
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSLobbySearch(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local search:TEOSLobbySearch = New TEOSLobbySearch
		search._owner = owner
		search._handle = handle
		Return search
	End Function

	Method SetLobbyId:EEOSResult(lobbyId:String)
		If Not IsValid() Or Not lobbyId Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_search_set_lobby_id(_handle, lobbyId)
	End Method

	Method SetTargetUserId:EEOSResult(targetUserId:TEOSProductUserId)
		If Not IsValid() Or Not targetUserId Or Not targetUserId.IsValid() Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_search_set_target_user(_handle, targetUserId._NativeHandle())
	End Method

	Rem
	bbdoc: Adds a string-valued search parameter, such as key "bucket".
	End Rem
	Method SetStringParameter:EEOSResult(key:String, value:String, comparison:EEOSComparisonOp = EEOSComparisonOp.Equal)
		If Not IsValid() Or Not key Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_search_set_string_parameter(_handle, key, value, comparison)
	End Method

	Method SetMaxResults:EEOSResult(maxResults:UInt)
		If Not IsValid() Or maxResults < 1 Or maxResults > 200 Then Return EEOSResult.InvalidParameters
		Return bmx_eos_lobby_search_set_max_results(_handle, maxResults)
	End Method

	Method Find:TEOSLobbySearchFindRequest(localUserId:TEOSProductUserId, listener:IEOSLobbySearchFindListener)
		If Not IsValid() Or Not localUserId Or Not localUserId.IsValid() Or Not listener Then Return Null
		Local request:TEOSLobbySearchFindRequest = TEOSLobbySearchFindRequest._Create(_owner, Self, listener)
		bmx_eos_lobby_search_find(_owner._NativeHandle(), _handle, request, localUserId._NativeHandle())
		Return request
	End Method

	Method ResultCount:UInt()
		If Not IsValid() Then Return 0
		Return bmx_eos_lobby_search_get_result_count(_handle)
	End Method

	Method CopyResultByIndex:EEOSResult(index:UInt, details:TEOSLobbyDetails Var)
		details = Null
		If Not IsValid() Then Return EEOSResult.InvalidState
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_lobby_search_copy_result(_handle, index, handle)
		If result = EEOSResult.Success Then details = TEOSLobbyDetails._Create(_owner, handle)
		Return result
	End Method

	Method IsValid:Int()
		Return _handle And _owner And _owner.IsValid()
	End Method

	Method Release()
		If Not _handle Then Return
		Local handle:Byte Ptr = _handle
		_handle = Null
		bmx_eos_lobby_search_release(handle)
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type

Rem
bbdoc: An owned snapshot handle for one lobby.
about: Release it before releasing its platform. Search and join support also use this handle.
End Rem
Type TEOSLobbyDetails
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSLobbyDetails(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local details:TEOSLobbyDetails = New TEOSLobbyDetails
		details._owner = owner
		details._handle = handle
		Return details
	End Function

	Method CopyInfo:EEOSResult(info:TEOSLobbyInfo Var)
		info = Null
		If Not IsValid() Then Return EEOSResult.InvalidState
		Local lobbyId:String, ownerHandle:Byte Ptr, permissionLevel:EEOSLobbyPermissionLevel
		Local availableSlots:UInt, maxMembers:UInt, allowInvites:Int, bucketId:String
		Local allowHostMigration:Int, rtcRoomEnabled:Int, allowJoinById:Int
		Local rejoinAfterKickRequiresInvite:Int, presenceEnabled:Int, allowedPlatformIds:Int[]
		Local result:EEOSResult = bmx_eos_lobby_details_copy_info(_handle, lobbyId, ownerHandle, permissionLevel, availableSlots, maxMembers, allowInvites, bucketId, allowHostMigration, rtcRoomEnabled, allowJoinById, rejoinAfterKickRequiresInvite, presenceEnabled, allowedPlatformIds)
		If result = EEOSResult.Success Then
			info = New TEOSLobbyInfo
			info.LobbyId = lobbyId
			info.OwnerUserId = TEOSProductUserId._Create(ownerHandle)
			info.PermissionLevel = permissionLevel
			info.AvailableSlots = availableSlots
			info.MaxMembers = maxMembers
			info.AllowInvites = allowInvites
			info.BucketId = bucketId
			info.AllowHostMigration = allowHostMigration
			info.RTCRoomEnabled = rtcRoomEnabled
			info.AllowJoinById = allowJoinById
			info.RejoinAfterKickRequiresInvite = rejoinAfterKickRequiresInvite
			info.PresenceEnabled = presenceEnabled
			info.AllowedPlatformIds = allowedPlatformIds
		End If
		Return result
	End Method

	Method MemberCount:UInt()
		If Not IsValid() Then Return 0
		Return bmx_eos_lobby_details_get_member_count(_handle)
	End Method

	Method MemberByIndex:TEOSProductUserId(index:UInt)
		If Not IsValid() Then Return Null
		Return TEOSProductUserId._Create(bmx_eos_lobby_details_get_member_by_index(_handle, index))
	End Method

	Method AttributeCount:UInt()
		If Not IsValid() Then Return 0
		Return bmx_eos_lobby_details_get_attribute_count(_handle)
	End Method

	Method CopyAttributeByIndex:EEOSResult(index:UInt, attribute:TEOSLobbyAttribute Var)
		attribute = Null
		If Not IsValid() Then Return EEOSResult.InvalidState
		Local key:String, valueType:EEOSLobbyAttributeType, intValue:Long, doubleValue:Double
		Local boolValue:Int, stringValue:String, visibility:EEOSLobbyAttributeVisibility
		Local result:EEOSResult = bmx_eos_lobby_details_copy_attribute_by_index(_handle, index, key, valueType, intValue, doubleValue, boolValue, stringValue, visibility)
		If result = EEOSResult.Success Then
			attribute = New TEOSLobbyAttribute
			attribute.Key = key
			attribute.ValueType = valueType
			attribute.IntValue = intValue
			attribute.DoubleValue = doubleValue
			attribute.BoolValue = boolValue
			attribute.StringValue = stringValue
			attribute.Visibility = visibility
		End If
		Return result
	End Method

	Method IsValid:Int()
		Return _handle And _owner And _owner.IsValid()
	End Method

	Method _NativeHandle:Byte Ptr()
		If Not IsValid() Then Return Null
		Return _handle
	End Method

	Method Release()
		If Not _handle Then Return
		Local handle:Byte Ptr = _handle
		_handle = Null
		bmx_eos_lobby_details_release(handle)
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type

Rem
bbdoc: EOS peer-to-peer packet transport for one platform.
about: Socket names are application-defined identifiers of 1 to 32 permitted
characters. Packet payloads are limited to #EOS_P2P_MAX_PACKET_SIZE bytes.
End Rem
Type TEOSP2PQueryNATTypeRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSP2PQueryNATTypeListener
	Field _complete:Int

	Public
	Function _Create:TEOSP2PQueryNATTypeRequest(owner:TEOSPlatform, listener:IEOSP2PQueryNATTypeListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSP2PQueryNATTypeRequest = New TEOSP2PQueryNATTypeRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSP2PQueryNATTypeRequest, result:EEOSResult, natType:EEOSNATType) { nomangle }
		If Not request Or request._complete Then Return
		Local listener:IEOSP2PQueryNATTypeListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then listener.OnEOSP2PQueryNATType(result, natType)
	End Function

	Function _Cancel(request:TEOSP2PQueryNATTypeRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, EEOSNATType.Unknown)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSP2PConnectionRequestSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSP2PConnectionRequestListener
	Field _id:ULong
	Public
	Function _Create:TEOSP2PConnectionRequestSubscription(owner:TEOSPlatform, listener:IEOSP2PConnectionRequestListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSP2PConnectionRequestSubscription = New TEOSP2PConnectionRequestSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSP2PConnectionRequestSubscription, localHandle:Byte Ptr, remoteHandle:Byte Ptr, socketName:String) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSP2PConnectionRequest(TEOSProductUserId._Create(localHandle), TEOSProductUserId._Create(remoteHandle), socketName)
	End Function

	Function _Cancel(subscription:TEOSP2PConnectionRequestSubscription) { nomangle }
		If subscription Then
			subscription._id = 0
			subscription._listener = Null
		End If
	End Function

	Method _SetId(id:ULong)
		_id = id
	End Method

	Method Remove()
		If _id Then
			Local id:ULong = _id
			_id = 0
			_listener = Null
			bmx_eos_p2p_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSP2PConnectionEstablishedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSP2PConnectionEstablishedListener
	Field _id:ULong
	Public
	Function _Create:TEOSP2PConnectionEstablishedSubscription(owner:TEOSPlatform, listener:IEOSP2PConnectionEstablishedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSP2PConnectionEstablishedSubscription = New TEOSP2PConnectionEstablishedSubscription
		subscription._owner = owner; subscription._listener = listener
		Return subscription
	End Function
	Function _Notify(subscription:TEOSP2PConnectionEstablishedSubscription, localHandle:Byte Ptr, remoteHandle:Byte Ptr, socketName:String, connectionType:EEOSConnectionEstablishedType, networkType:EEOSNetworkConnectionType) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSP2PConnectionEstablished(TEOSProductUserId._Create(localHandle), TEOSProductUserId._Create(remoteHandle), socketName, connectionType, networkType)
	End Function
	Function _Cancel(subscription:TEOSP2PConnectionEstablishedSubscription) { nomangle }
		If subscription Then subscription._id = 0; subscription._listener = Null
	End Function
	Method _SetId(id:ULong)
		_id = id
	End Method
	Method Remove()
		If Not _id Then
			Return
		End If
		Local id:ULong = _id
		_id = 0
		_listener = Null
		bmx_eos_p2p_remove_notify(id)
	End Method
	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method
	Method Delete()
		Remove()
	End Method
End Type

Type TEOSP2PConnectionInterruptedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSP2PConnectionInterruptedListener
	Field _id:ULong
	Public
	Function _Create:TEOSP2PConnectionInterruptedSubscription(owner:TEOSPlatform, listener:IEOSP2PConnectionInterruptedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSP2PConnectionInterruptedSubscription = New TEOSP2PConnectionInterruptedSubscription
		subscription._owner = owner; subscription._listener = listener
		Return subscription
	End Function
	Function _Notify(subscription:TEOSP2PConnectionInterruptedSubscription, localHandle:Byte Ptr, remoteHandle:Byte Ptr, socketName:String) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSP2PConnectionInterrupted(TEOSProductUserId._Create(localHandle), TEOSProductUserId._Create(remoteHandle), socketName)
	End Function
	Function _Cancel(subscription:TEOSP2PConnectionInterruptedSubscription) { nomangle }
		If subscription Then subscription._id = 0; subscription._listener = Null
	End Function
	Method _SetId(id:ULong)
		_id = id
	End Method
	Method Remove()
		If Not _id Then
			Return
		End If
		Local id:ULong = _id
		_id = 0
		_listener = Null
		bmx_eos_p2p_remove_notify(id)
	End Method
	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method
	Method Delete()
		Remove()
	End Method
End Type

Type TEOSP2PConnectionClosedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSP2PConnectionClosedListener
	Field _id:ULong
	Public
	Function _Create:TEOSP2PConnectionClosedSubscription(owner:TEOSPlatform, listener:IEOSP2PConnectionClosedListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSP2PConnectionClosedSubscription = New TEOSP2PConnectionClosedSubscription
		subscription._owner = owner; subscription._listener = listener
		Return subscription
	End Function
	Function _Notify(subscription:TEOSP2PConnectionClosedSubscription, localHandle:Byte Ptr, remoteHandle:Byte Ptr, socketName:String, reason:EEOSConnectionClosedReason) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSP2PConnectionClosed(TEOSProductUserId._Create(localHandle), TEOSProductUserId._Create(remoteHandle), socketName, reason)
	End Function
	Function _Cancel(subscription:TEOSP2PConnectionClosedSubscription) { nomangle }
		If subscription Then subscription._id = 0; subscription._listener = Null
	End Function
	Method _SetId(id:ULong)
		_id = id
	End Method
	Method Remove()
		If Not _id Then
			Return
		End If
		Local id:ULong = _id
		_id = 0
		_listener = Null
		bmx_eos_p2p_remove_notify(id)
	End Method
	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method
	Method Delete()
		Remove()
	End Method
End Type

Type TEOSP2PIncomingPacketQueueFullSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSP2PIncomingPacketQueueFullListener
	Field _id:ULong
	Public
	Function _Create:TEOSP2PIncomingPacketQueueFullSubscription(owner:TEOSPlatform, listener:IEOSP2PIncomingPacketQueueFullListener)
		If Not owner Or Not listener Then Return Null
		Local subscription:TEOSP2PIncomingPacketQueueFullSubscription = New TEOSP2PIncomingPacketQueueFullSubscription
		subscription._owner = owner; subscription._listener = listener
		Return subscription
	End Function
	Function _Notify(subscription:TEOSP2PIncomingPacketQueueFullSubscription, maxSizeBytes:ULong, currentSizeBytes:ULong, localUserHandle:Byte Ptr, channel:Int, packetSizeBytes:UInt) { nomangle }
		If subscription And subscription._listener Then subscription._listener.OnEOSP2PIncomingPacketQueueFull(maxSizeBytes, currentSizeBytes, TEOSProductUserId._Create(localUserHandle), channel, packetSizeBytes)
	End Function
	Function _Cancel(subscription:TEOSP2PIncomingPacketQueueFullSubscription) { nomangle }
		If subscription Then subscription._id = 0; subscription._listener = Null
	End Function
	Method _SetId(id:ULong)
		_id = id
	End Method
	Method Remove()
		If Not _id Then
			Return
		End If
		Local id:ULong = _id
		_id = 0
		_listener = Null
		bmx_eos_p2p_remove_notify(id)
	End Method
	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method
	Method Delete()
		Remove()
	End Method
End Type

Type TEOSP2P
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSP2P(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local p2p:TEOSP2P = New TEOSP2P
		p2p._owner = owner
		p2p._handle = handle
		Return p2p
	End Function

	Method SendPacket:EEOSResult(options:TEOSP2PSendOptions)
		If Not options Or Not _ValidUsers(options.LocalUserId, options.RemoteUserId) Then Return EEOSResult.InvalidParameters
		If Not _ValidSocket(options.SocketName) Or options.Channel < 0 Or options.Channel > 255 Then Return EEOSResult.InvalidParameters
		If options.Data And options.Data.Length > EOS_P2P_MAX_PACKET_SIZE Then Return EEOSResult.LimitExceeded
		Return bmx_eos_p2p_send(_handle, options.LocalUserId._NativeHandle(), options.RemoteUserId._NativeHandle(), options.SocketName, options.Channel, options.Data, options.AllowDelayedDelivery, options.Reliability, options.DisableAutoAcceptConnection)
	End Method

	Rem
	bbdoc: Returns the byte size of the next queued packet without removing it.
	about: Pass -1 for requestedChannel to inspect the next packet on any channel.
	End Rem
	Method NextReceivedPacketSize:EEOSResult(localUserId:TEOSProductUserId, requestedChannel:Int, packetSize:UInt Var)
		packetSize = 0
		If Not _ValidLocalUser(localUserId) Or requestedChannel < -1 Or requestedChannel > 255 Then Return EEOSResult.InvalidParameters
		Return bmx_eos_p2p_next_packet_size(_handle, localUserId._NativeHandle(), requestedChannel, packetSize)
	End Method

	Rem
	bbdoc: Removes and copies the next queued packet on any or one requested channel.
	End Rem
	Method ReceivePacket:EEOSResult(localUserId:TEOSProductUserId, requestedChannel:Int, packet:TEOSP2PPacket Var)
		packet = Null
		If Not _ValidLocalUser(localUserId) Or requestedChannel < -1 Or requestedChannel > 255 Then Return EEOSResult.InvalidParameters
		Local remoteHandle:Byte Ptr, socketName:String, channel:Int, data:Byte[]
		Local result:EEOSResult = bmx_eos_p2p_receive(_handle, localUserId._NativeHandle(), requestedChannel, remoteHandle, socketName, channel, data)
		If result = EEOSResult.Success Then
			packet = New TEOSP2PPacket
			packet.RemoteUserId = TEOSProductUserId._Create(remoteHandle)
			packet.SocketName = socketName
			packet.Channel = channel
			packet.Data = data
		End If
		Return result
	End Method

	Method AcceptConnection:EEOSResult(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String)
		If Not _ValidUsers(localUserId, remoteUserId) Or Not _ValidSocket(socketName) Then Return EEOSResult.InvalidParameters
		Return bmx_eos_p2p_accept(_handle, localUserId._NativeHandle(), remoteUserId._NativeHandle(), socketName)
	End Method

	Method CloseConnection:EEOSResult(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String)
		If Not _ValidUsers(localUserId, remoteUserId) Or Not _ValidSocket(socketName) Then Return EEOSResult.InvalidParameters
		Return bmx_eos_p2p_close(_handle, localUserId._NativeHandle(), remoteUserId._NativeHandle(), socketName)
	End Method

	Method CloseConnections:EEOSResult(localUserId:TEOSProductUserId, socketName:String)
		If Not _ValidLocalUser(localUserId) Or Not _ValidSocket(socketName) Then Return EEOSResult.InvalidParameters
		Return bmx_eos_p2p_close_socket(_handle, localUserId._NativeHandle(), socketName)
	End Method

	Rem
	bbdoc: Starts an asynchronous query of the local network's NAT type.
	End Rem
	Method QueryNATType:TEOSP2PQueryNATTypeRequest(listener:IEOSP2PQueryNATTypeListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local request:TEOSP2PQueryNATTypeRequest = TEOSP2PQueryNATTypeRequest._Create(_owner, listener)
		bmx_eos_p2p_query_nat_type(_owner._NativeHandle(), _handle, request)
		Return request
	End Method

	Rem
	bbdoc: Returns the most recently queried local NAT type.
	End Rem
	Method GetNATType:EEOSResult(natType:EEOSNATType Var)
		natType = EEOSNATType.Unknown
		If Not _owner Or Not _owner.IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_p2p_get_nat_type(_handle, natType)
	End Method

	Method SetRelayControl:EEOSResult(relayControl:EEOSRelayControl)
		If Not _owner Or Not _owner.IsValid() Then Return EEOSResult.InvalidState
		If relayControl < EEOSRelayControl.NoRelays Or relayControl > EEOSRelayControl.ForceRelays Then Return EEOSResult.InvalidParameters
		Return bmx_eos_p2p_set_relay_control(_handle, relayControl)
	End Method

	Method GetRelayControl:EEOSResult(relayControl:EEOSRelayControl Var)
		relayControl = EEOSRelayControl.AllowRelays
		If Not _owner Or Not _owner.IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_p2p_get_relay_control(_handle, relayControl)
	End Method

	Rem
	bbdoc: Sets the preferred UDP port and the number of consecutive fallback ports.
	about: Pass zero for both values to let the operating system select a port.
	End Rem
	Method SetPortRange:EEOSResult(port:Int, maxAdditionalPortsToTry:Int)
		If Not _owner Or Not _owner.IsValid() Then Return EEOSResult.InvalidState
		If port < 0 Or port > 65535 Or maxAdditionalPortsToTry < 0 Or maxAdditionalPortsToTry > 65535 Then Return EEOSResult.InvalidParameters
		If port = 0 And maxAdditionalPortsToTry <> 0 Then Return EEOSResult.InvalidParameters
		If port + maxAdditionalPortsToTry > 65535 Then Return EEOSResult.InvalidParameters
		Return bmx_eos_p2p_set_port_range(_handle, port, maxAdditionalPortsToTry)
	End Method

	Method GetPortRange:EEOSResult(port:Int Var, maxAdditionalPortsToTry:Int Var)
		port = 0
		maxAdditionalPortsToTry = 0
		If Not _owner Or Not _owner.IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_p2p_get_port_range(_handle, port, maxAdditionalPortsToTry)
	End Method

	Rem
	bbdoc: Sets the maximum byte size of the incoming and outgoing packet queues.
	about: A value of #EOS_P2P_MAX_QUEUE_SIZE_UNLIMITED allows that queue to grow without a configured limit.
	End Rem
	Method SetPacketQueueSize:EEOSResult(incomingMaxSizeBytes:ULong, outgoingMaxSizeBytes:ULong)
		If Not _owner Or Not _owner.IsValid() Then Return EEOSResult.InvalidState
		Return bmx_eos_p2p_set_packet_queue_size(_handle, incomingMaxSizeBytes, outgoingMaxSizeBytes)
	End Method

	Method GetPacketQueueInfo:EEOSResult(info:TEOSP2PPacketQueueInfo Var)
		info = Null
		If Not _owner Or Not _owner.IsValid() Then Return EEOSResult.InvalidState
		Local incomingMax:ULong, incomingCurrent:ULong, incomingCount:ULong
		Local outgoingMax:ULong, outgoingCurrent:ULong, outgoingCount:ULong
		Local result:EEOSResult = bmx_eos_p2p_get_packet_queue_info(_handle, incomingMax, incomingCurrent, incomingCount, outgoingMax, outgoingCurrent, outgoingCount)
		If result = EEOSResult.Success Then
			info = New TEOSP2PPacketQueueInfo
			info.IncomingMaxSizeBytes = incomingMax
			info.IncomingCurrentSizeBytes = incomingCurrent
			info.IncomingCurrentPacketCount = incomingCount
			info.OutgoingMaxSizeBytes = outgoingMax
			info.OutgoingCurrentSizeBytes = outgoingCurrent
			info.OutgoingCurrentPacketCount = outgoingCount
		End If
		Return result
	End Method

	Method ClearPacketQueue:EEOSResult(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String)
		If Not _ValidUsers(localUserId, remoteUserId) Or Not _ValidSocket(socketName) Then Return EEOSResult.InvalidParameters
		Return bmx_eos_p2p_clear_packet_queue(_handle, localUserId._NativeHandle(), remoteUserId._NativeHandle(), socketName)
	End Method

	Method AddNotifyIncomingPacketQueueFull:TEOSP2PIncomingPacketQueueFullSubscription(listener:IEOSP2PIncomingPacketQueueFullListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		Local subscription:TEOSP2PIncomingPacketQueueFullSubscription = TEOSP2PIncomingPacketQueueFullSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_p2p_add_notify_incoming_queue_full(_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyConnectionRequest:TEOSP2PConnectionRequestSubscription(localUserId:TEOSProductUserId, socketName:String, listener:IEOSP2PConnectionRequestListener)
		If Not _ValidSubscription(localUserId, socketName, listener <> Null) Then Return Null
		Local subscription:TEOSP2PConnectionRequestSubscription = TEOSP2PConnectionRequestSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_p2p_add_notify_connection_request(_owner._NativeHandle(), _handle, subscription, localUserId._NativeHandle(), socketName))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyConnectionEstablished:TEOSP2PConnectionEstablishedSubscription(localUserId:TEOSProductUserId, socketName:String, listener:IEOSP2PConnectionEstablishedListener)
		If Not _ValidSubscription(localUserId, socketName, listener <> Null) Then Return Null
		Local subscription:TEOSP2PConnectionEstablishedSubscription = TEOSP2PConnectionEstablishedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_p2p_add_notify_connection_established(_owner._NativeHandle(), _handle, subscription, localUserId._NativeHandle(), socketName))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyConnectionInterrupted:TEOSP2PConnectionInterruptedSubscription(localUserId:TEOSProductUserId, socketName:String, listener:IEOSP2PConnectionInterruptedListener)
		If Not _ValidSubscription(localUserId, socketName, listener <> Null) Then Return Null
		Local subscription:TEOSP2PConnectionInterruptedSubscription = TEOSP2PConnectionInterruptedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_p2p_add_notify_connection_interrupted(_owner._NativeHandle(), _handle, subscription, localUserId._NativeHandle(), socketName))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Method AddNotifyConnectionClosed:TEOSP2PConnectionClosedSubscription(localUserId:TEOSProductUserId, socketName:String, listener:IEOSP2PConnectionClosedListener)
		If Not _ValidSubscription(localUserId, socketName, listener <> Null) Then Return Null
		Local subscription:TEOSP2PConnectionClosedSubscription = TEOSP2PConnectionClosedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_p2p_add_notify_connection_closed(_owner._NativeHandle(), _handle, subscription, localUserId._NativeHandle(), socketName))
		If Not subscription.IsActive() Then Return Null
		Return subscription
	End Method

	Private
	Method _ValidLocalUser:Int(localUserId:TEOSProductUserId)
		Return _owner And _owner.IsValid() And localUserId And localUserId.IsValid()
	End Method

	Method _ValidUsers:Int(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId)
		Return _ValidLocalUser(localUserId) And remoteUserId And remoteUserId.IsValid()
	End Method

	Method _ValidSocket:Int(socketName:String)
		Return socketName.Length >= 1 And socketName.Length <= 32
	End Method

	Method _ValidSubscription:Int(localUserId:TEOSProductUserId, socketName:String, hasListener:Int)
		Return _ValidLocalUser(localUserId) And (Not socketName Or _ValidSocket(socketName)) And hasListener
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

	Function bmx_eos_platform_create:Byte Ptr( ..
		productId:String, sandboxId:String, deploymentId:String, ..
		clientId:String, clientSecret:String, encryptionKey:String, ..
		overrideCountryCode:String, overrideLocaleCode:String, ..
		cacheDirectory:String, isServer:Int, flags:EEOSPlatformFlags, ..
		tickBudgetInMilliseconds:UInt, useTaskNetworkTimeout:Int, ..
		taskNetworkTimeoutSeconds:Double, ..
		integratedPlatformOptionsHandle:Byte Ptr)
	Function bmx_eos_platform_tick(handle:Byte Ptr)
	Function bmx_eos_platform_release(handle:Byte Ptr)
	Function bmx_eos_platform_get_auth_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_connect_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_stats_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_achievements_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_leaderboards_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_user_info_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_friends_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_presence_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_lobby_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_sessions_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_p2p_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_title_storage_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_player_storage_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_sanctions_interface:Byte Ptr(handle:Byte Ptr)
	Function bmx_eos_platform_get_reports_interface:Byte Ptr(handle:Byte Ptr)

	Function bmx_eos_auth_login(platformHandle:Byte Ptr, authHandle:Byte Ptr, request:TEOSAuthLoginRequest, id:String, token:String, credentialType:EEOSLoginCredentialType, externalType:EEOSExternalCredentialType, scopeFlags:EEOSAuthScopeFlags, loginFlags:EEOSAuthLoginFlags)
	Function bmx_eos_auth_logout(platformHandle:Byte Ptr, authHandle:Byte Ptr, request:TEOSAuthLogoutRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_auth_delete_persistent(platformHandle:Byte Ptr, authHandle:Byte Ptr, request:TEOSAuthDeletePersistentAuthRequest, refreshToken:String)
	Function bmx_eos_auth_get_logged_in_accounts_count:Int(authHandle:Byte Ptr)
	Function bmx_eos_auth_get_logged_in_account_by_index:Byte Ptr(authHandle:Byte Ptr, index:Int)
	Function bmx_eos_auth_get_login_status:Int(authHandle:Byte Ptr, localUserHandle:Byte Ptr)
	Function bmx_eos_auth_add_notify_login_status:ULong(platformHandle:Byte Ptr, authHandle:Byte Ptr, subscription:TEOSAuthLoginStatusSubscription)
	Function bmx_eos_auth_copy_user_auth_token:EEOSResult(authHandle:Byte Ptr, localUserHandle:Byte Ptr, app:String Var, clientId:String Var, accountHandle:Byte Ptr Var, accessToken:String Var, expiresIn:Double Var, expiresAt:String Var, authType:EEOSAuthTokenType Var, refreshToken:String Var, refreshExpiresIn:Double Var, refreshExpiresAt:String Var)
	Function bmx_eos_auth_copy_id_token:EEOSResult(authHandle:Byte Ptr, accountHandle:Byte Ptr, tokenAccountHandle:Byte Ptr Var, jsonWebToken:String Var)

	Function bmx_eos_connect_login(platformHandle:Byte Ptr, connectHandle:Byte Ptr, request:TEOSConnectLoginRequest, token:String, credentialType:EEOSExternalCredentialType, displayName:String, nsaIdToken:String, useUserLoginInfo:Int)
	Function bmx_eos_connect_create_user(platformHandle:Byte Ptr, connectHandle:Byte Ptr, request:TEOSConnectCreateUserRequest, continuanceHandle:Byte Ptr)
	Function bmx_eos_connect_logout(platformHandle:Byte Ptr, connectHandle:Byte Ptr, request:TEOSConnectLogoutRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_connect_get_logged_in_users_count:Int(connectHandle:Byte Ptr)
	Function bmx_eos_connect_get_logged_in_user_by_index:Byte Ptr(connectHandle:Byte Ptr, index:Int)
	Function bmx_eos_connect_get_login_status:Int(connectHandle:Byte Ptr, localUserHandle:Byte Ptr)
	Function bmx_eos_connect_add_notify_auth_expiration:ULong(platformHandle:Byte Ptr, connectHandle:Byte Ptr, subscription:TEOSConnectAuthExpirationSubscription)
	Function bmx_eos_connect_add_notify_login_status:ULong(platformHandle:Byte Ptr, connectHandle:Byte Ptr, subscription:TEOSConnectLoginStatusSubscription)
	Function bmx_eos_login_remove_notify(id:ULong)

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

	Function bmx_eos_user_info_query(platformHandle:Byte Ptr, userInfoHandle:Byte Ptr, request:TEOSUserInfoQueryRequest, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_user_info_query_by_display_name(platformHandle:Byte Ptr, userInfoHandle:Byte Ptr, request:TEOSUserInfoQueryByDisplayNameRequest, localUserHandle:Byte Ptr, displayName:String)
	Function bmx_eos_user_info_query_by_external_account(platformHandle:Byte Ptr, userInfoHandle:Byte Ptr, request:TEOSUserInfoQueryByExternalAccountRequest, localUserHandle:Byte Ptr, externalAccountId:String, accountType:EEOSExternalAccountType)
	Function bmx_eos_user_info_copy:EEOSResult(userInfoHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, userHandle:Byte Ptr Var, country:String Var, displayName:String Var, preferredLanguage:String Var, nickname:String Var, displayNameSanitized:String Var)
	Function bmx_eos_user_info_get_external_count:UInt(userInfoHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_user_info_copy_external_by_index:EEOSResult(userInfoHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, index:UInt, accountType:EEOSExternalAccountType Var, accountId:String Var, displayName:String Var, displayNameSanitized:String Var)
	Function bmx_eos_user_info_copy_external_by_type:EEOSResult(userInfoHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, requestedType:EEOSExternalAccountType, accountType:EEOSExternalAccountType Var, accountId:String Var, displayName:String Var, displayNameSanitized:String Var)
	Function bmx_eos_user_info_copy_external_by_id:EEOSResult(userInfoHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, requestedAccountId:String, accountType:EEOSExternalAccountType Var, accountId:String Var, displayName:String Var, displayNameSanitized:String Var)

	Function bmx_eos_friends_query(platformHandle:Byte Ptr, friendsHandle:Byte Ptr, request:TEOSFriendsQueryRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_friends_get_count:Int(friendsHandle:Byte Ptr, localUserHandle:Byte Ptr)
	Function bmx_eos_friends_get_by_index:Byte Ptr(friendsHandle:Byte Ptr, localUserHandle:Byte Ptr, index:Int)
	Function bmx_eos_friends_get_status:EEOSFriendsStatus(friendsHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_friends_get_blocked_count:Int(friendsHandle:Byte Ptr, localUserHandle:Byte Ptr)
	Function bmx_eos_friends_get_blocked_by_index:Byte Ptr(friendsHandle:Byte Ptr, localUserHandle:Byte Ptr, index:Int)
	Function bmx_eos_friends_add_notify_update:ULong(platformHandle:Byte Ptr, friendsHandle:Byte Ptr, subscription:TEOSFriendsUpdateSubscription)
	Function bmx_eos_friends_add_notify_blocked:ULong(platformHandle:Byte Ptr, friendsHandle:Byte Ptr, subscription:TEOSBlockedUsersUpdateSubscription)
	Function bmx_eos_friends_remove_notify(id:ULong)

	Function bmx_eos_presence_query(platformHandle:Byte Ptr, presenceHandle:Byte Ptr, request:TEOSPresenceQueryRequest, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_presence_has:Int(presenceHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_presence_copy:EEOSResult(presenceHandle:Byte Ptr, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, status:EEOSPresenceStatus Var, userHandle:Byte Ptr Var, productId:String Var, productVersion:String Var, platform:String Var, richText:String Var, productName:String Var, integratedPlatform:String Var, recordKeys:String[] Var, recordValues:String[] Var)
	Function bmx_eos_presence_create_modification:EEOSResult(presenceHandle:Byte Ptr, localUserHandle:Byte Ptr, modificationHandle:Byte Ptr Var)
	Function bmx_eos_presence_modification_release(modificationHandle:Byte Ptr)
	Function bmx_eos_presence_modification_set_status:EEOSResult(modificationHandle:Byte Ptr, status:EEOSPresenceStatus)
	Function bmx_eos_presence_modification_set_rich_text:EEOSResult(modificationHandle:Byte Ptr, richText:String)
	Function bmx_eos_presence_modification_set_join_info:EEOSResult(modificationHandle:Byte Ptr, joinInfo:String)
	Function bmx_eos_presence_set(platformHandle:Byte Ptr, presenceHandle:Byte Ptr, request:TEOSPresenceSetRequest, localUserHandle:Byte Ptr, modificationHandle:Byte Ptr)
	Function bmx_eos_presence_add_notify_changed:ULong(platformHandle:Byte Ptr, presenceHandle:Byte Ptr, subscription:TEOSPresenceChangedSubscription)
	Function bmx_eos_presence_remove_notify_changed(id:ULong)

	Function bmx_eos_lobby_create(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, request:TEOSLobbyCreateRequest, localUserHandle:Byte Ptr, maxMembers:UInt, permissionLevel:EEOSLobbyPermissionLevel, presenceEnabled:Int, allowInvites:Int, bucketId:String, disableHostMigration:Int, enableRTCRoom:Int, enableJoinById:Int, rejoinAfterKickRequiresInvite:Int, crossplayOptOut:Int)
	Function bmx_eos_lobby_destroy(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, request:TEOSLobbyDestroyRequest, localUserHandle:Byte Ptr, lobbyId:String)
	Function bmx_eos_lobby_leave(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, request:TEOSLobbyLeaveRequest, localUserHandle:Byte Ptr, lobbyId:String)
	Function bmx_eos_lobby_join(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, request:TEOSLobbyJoinRequest, detailsHandle:Byte Ptr, localUserHandle:Byte Ptr, presenceEnabled:Int, crossplayOptOut:Int)
	Function bmx_eos_lobby_create_search:EEOSResult(lobbyHandle:Byte Ptr, maxResults:UInt, searchHandle:Byte Ptr Var)
	Function bmx_eos_lobby_search_release(searchHandle:Byte Ptr)
	Function bmx_eos_lobby_search_set_lobby_id:EEOSResult(searchHandle:Byte Ptr, lobbyId:String)
	Function bmx_eos_lobby_search_set_target_user:EEOSResult(searchHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_lobby_search_set_string_parameter:EEOSResult(searchHandle:Byte Ptr, key:String, value:String, comparison:EEOSComparisonOp)
	Function bmx_eos_lobby_search_set_max_results:EEOSResult(searchHandle:Byte Ptr, maxResults:UInt)
	Function bmx_eos_lobby_search_find(platformHandle:Byte Ptr, searchHandle:Byte Ptr, request:TEOSLobbySearchFindRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_lobby_search_get_result_count:UInt(searchHandle:Byte Ptr)
	Function bmx_eos_lobby_search_copy_result:EEOSResult(searchHandle:Byte Ptr, index:UInt, detailsHandle:Byte Ptr Var)
	Function bmx_eos_lobby_copy_details:EEOSResult(lobbyHandle:Byte Ptr, localUserHandle:Byte Ptr, lobbyId:String, detailsHandle:Byte Ptr Var)
	Function bmx_eos_lobby_details_release(detailsHandle:Byte Ptr)
	Function bmx_eos_lobby_details_copy_info:EEOSResult(detailsHandle:Byte Ptr, lobbyId:String Var, ownerUserHandle:Byte Ptr Var, permissionLevel:EEOSLobbyPermissionLevel Var, availableSlots:UInt Var, maxMembers:UInt Var, allowInvites:Int Var, bucketId:String Var, allowHostMigration:Int Var, rtcRoomEnabled:Int Var, allowJoinById:Int Var, rejoinAfterKickRequiresInvite:Int Var, presenceEnabled:Int Var, allowedPlatformIds:Int[] Var)
	Function bmx_eos_lobby_details_get_member_count:UInt(detailsHandle:Byte Ptr)
	Function bmx_eos_lobby_details_get_member_by_index:Byte Ptr(detailsHandle:Byte Ptr, index:UInt)
	Function bmx_eos_lobby_create_modification:EEOSResult(lobbyHandle:Byte Ptr, localUserHandle:Byte Ptr, lobbyId:String, modificationHandle:Byte Ptr Var)
	Function bmx_eos_lobby_modification_release(modificationHandle:Byte Ptr)
	Function bmx_eos_lobby_modification_set_bucket:EEOSResult(modificationHandle:Byte Ptr, bucketId:String)
	Function bmx_eos_lobby_modification_set_permission:EEOSResult(modificationHandle:Byte Ptr, permissionLevel:EEOSLobbyPermissionLevel)
	Function bmx_eos_lobby_modification_set_max_members:EEOSResult(modificationHandle:Byte Ptr, maxMembers:UInt)
	Function bmx_eos_lobby_modification_set_invites:EEOSResult(modificationHandle:Byte Ptr, allowInvites:Int)
	Function bmx_eos_lobby_modification_add_string_attribute:EEOSResult(modificationHandle:Byte Ptr, key:String, value:String, visibility:EEOSLobbyAttributeVisibility)
	Function bmx_eos_lobby_modification_add_string_member_attribute:EEOSResult(modificationHandle:Byte Ptr, key:String, value:String, visibility:EEOSLobbyAttributeVisibility)
	Function bmx_eos_lobby_modification_remove_attribute:EEOSResult(modificationHandle:Byte Ptr, key:String, member:Int)
	Function bmx_eos_lobby_update(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, request:TEOSLobbyUpdateRequest, modificationHandle:Byte Ptr)
	Function bmx_eos_lobby_details_get_attribute_count:UInt(detailsHandle:Byte Ptr)
	Function bmx_eos_lobby_details_copy_attribute_by_index:EEOSResult(detailsHandle:Byte Ptr, index:UInt, key:String Var, valueType:EEOSLobbyAttributeType Var, intValue:Long Var, doubleValue:Double Var, boolValue:Int Var, stringValue:String Var, visibility:EEOSLobbyAttributeVisibility Var)
	Function bmx_eos_lobby_send_invite(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, request:TEOSLobbySendInviteRequest, lobbyId:String, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_lobby_reject_invite(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, request:TEOSLobbyRejectInviteRequest, inviteId:String, localUserHandle:Byte Ptr)
	Function bmx_eos_lobby_query_invites(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, request:TEOSLobbyQueryInvitesRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_lobby_get_invite_count:UInt(lobbyHandle:Byte Ptr, localUserHandle:Byte Ptr)
	Function bmx_eos_lobby_get_invite_id_by_index:EEOSResult(lobbyHandle:Byte Ptr, localUserHandle:Byte Ptr, index:UInt, inviteId:String Var)
	Function bmx_eos_lobby_copy_details_by_invite:EEOSResult(lobbyHandle:Byte Ptr, inviteId:String, detailsHandle:Byte Ptr Var)
	Function bmx_eos_lobby_add_notify_update:ULong(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, subscription:TEOSLobbyUpdateReceivedSubscription)
	Function bmx_eos_lobby_add_notify_member_update:ULong(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, subscription:TEOSLobbyMemberUpdateReceivedSubscription)
	Function bmx_eos_lobby_add_notify_member_status:ULong(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, subscription:TEOSLobbyMemberStatusReceivedSubscription)
	Function bmx_eos_lobby_add_notify_invite_received:ULong(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, subscription:TEOSLobbyInviteReceivedSubscription)
	Function bmx_eos_lobby_add_notify_invite_accepted:ULong(platformHandle:Byte Ptr, lobbyHandle:Byte Ptr, subscription:TEOSLobbyInviteAcceptedSubscription)
	Function bmx_eos_lobby_remove_notify(id:ULong)

	Function bmx_eos_p2p_send:EEOSResult(p2pHandle:Byte Ptr, localUserHandle:Byte Ptr, remoteUserHandle:Byte Ptr, socketName:String, channel:Int, data:Byte[], allowDelayedDelivery:Int, reliability:EEOSPacketReliability, disableAutoAccept:Int)
	Function bmx_eos_p2p_next_packet_size:EEOSResult(p2pHandle:Byte Ptr, localUserHandle:Byte Ptr, requestedChannel:Int, packetSize:UInt Var)
	Function bmx_eos_p2p_receive:EEOSResult(p2pHandle:Byte Ptr, localUserHandle:Byte Ptr, requestedChannel:Int, remoteUserHandle:Byte Ptr Var, socketName:String Var, channel:Int Var, data:Byte[] Var)
	Function bmx_eos_p2p_accept:EEOSResult(p2pHandle:Byte Ptr, localUserHandle:Byte Ptr, remoteUserHandle:Byte Ptr, socketName:String)
	Function bmx_eos_p2p_close:EEOSResult(p2pHandle:Byte Ptr, localUserHandle:Byte Ptr, remoteUserHandle:Byte Ptr, socketName:String)
	Function bmx_eos_p2p_close_socket:EEOSResult(p2pHandle:Byte Ptr, localUserHandle:Byte Ptr, socketName:String)
	Function bmx_eos_p2p_query_nat_type(platformHandle:Byte Ptr, p2pHandle:Byte Ptr, request:TEOSP2PQueryNATTypeRequest)
	Function bmx_eos_p2p_get_nat_type:EEOSResult(p2pHandle:Byte Ptr, natType:EEOSNATType Var)
	Function bmx_eos_p2p_set_relay_control:EEOSResult(p2pHandle:Byte Ptr, relayControl:EEOSRelayControl)
	Function bmx_eos_p2p_get_relay_control:EEOSResult(p2pHandle:Byte Ptr, relayControl:EEOSRelayControl Var)
	Function bmx_eos_p2p_set_port_range:EEOSResult(p2pHandle:Byte Ptr, port:Int, maxAdditionalPortsToTry:Int)
	Function bmx_eos_p2p_get_port_range:EEOSResult(p2pHandle:Byte Ptr, port:Int Var, maxAdditionalPortsToTry:Int Var)
	Function bmx_eos_p2p_set_packet_queue_size:EEOSResult(p2pHandle:Byte Ptr, incomingMaxSizeBytes:ULong, outgoingMaxSizeBytes:ULong)
	Function bmx_eos_p2p_get_packet_queue_info:EEOSResult(p2pHandle:Byte Ptr, incomingMaxSizeBytes:ULong Var, incomingCurrentSizeBytes:ULong Var, incomingCurrentPacketCount:ULong Var, outgoingMaxSizeBytes:ULong Var, outgoingCurrentSizeBytes:ULong Var, outgoingCurrentPacketCount:ULong Var)
	Function bmx_eos_p2p_clear_packet_queue:EEOSResult(p2pHandle:Byte Ptr, localUserHandle:Byte Ptr, remoteUserHandle:Byte Ptr, socketName:String)
	Function bmx_eos_p2p_add_notify_incoming_queue_full:ULong(platformHandle:Byte Ptr, p2pHandle:Byte Ptr, subscription:TEOSP2PIncomingPacketQueueFullSubscription)
	Function bmx_eos_p2p_add_notify_connection_request:ULong(platformHandle:Byte Ptr, p2pHandle:Byte Ptr, subscription:TEOSP2PConnectionRequestSubscription, localUserHandle:Byte Ptr, socketName:String)
	Function bmx_eos_p2p_add_notify_connection_established:ULong(platformHandle:Byte Ptr, p2pHandle:Byte Ptr, subscription:TEOSP2PConnectionEstablishedSubscription, localUserHandle:Byte Ptr, socketName:String)
	Function bmx_eos_p2p_add_notify_connection_interrupted:ULong(platformHandle:Byte Ptr, p2pHandle:Byte Ptr, subscription:TEOSP2PConnectionInterruptedSubscription, localUserHandle:Byte Ptr, socketName:String)
	Function bmx_eos_p2p_add_notify_connection_closed:ULong(platformHandle:Byte Ptr, p2pHandle:Byte Ptr, subscription:TEOSP2PConnectionClosedSubscription, localUserHandle:Byte Ptr, socketName:String)
	Function bmx_eos_p2p_remove_notify(id:ULong)

	Function bmx_eos_epic_account_id_from_string:Byte Ptr(value:String)
	Function bmx_eos_epic_account_id_is_valid:Int(handle:Byte Ptr)
	Function bmx_eos_epic_account_id_to_string:String(handle:Byte Ptr)
	Function bmx_eos_product_user_id_from_string:Byte Ptr(value:String)
	Function bmx_eos_product_user_id_is_valid:Int(handle:Byte Ptr)
	Function bmx_eos_product_user_id_to_string:String(handle:Byte Ptr)
End Extern

Public
Include "storage.bmx"
Include "sanctions_reports.bmx"
Include "session.bmx"
Include "online_sessions.bmx"
Include "online_ui.bmx"
Include "integrated_platform.bmx"
