SuperStrict

Framework EOS.SDK
Import BRL.StandardIO

Type TMockSessionBackend Implements IEOSSessionBackend
	Field authStatusListener:IEOSAuthLoginStatusListener
	Field authExpirationListener:IEOSConnectAuthExpirationListener
	Field connectStatusListener:IEOSConnectLoginStatusListener
	Field authLoginCount:Int
	Field connectLoginCount:Int
	Field createUserCount:Int
	Field connectLogoutCount:Int
	Field authLogoutCount:Int
	Field deletePersistentCount:Int
	Field shutdownCount:Int
	Field lastAuthOptions:TEOSAuthLoginOptions
	Field copiedToken:String = "mock-id-token"

	Method Initialize:Int(authStatus:IEOSAuthLoginStatusListener, authExpiration:IEOSConnectAuthExpirationListener, connectStatus:IEOSConnectLoginStatusListener) Override
		authStatusListener = authStatus
		authExpirationListener = authExpiration
		connectStatusListener = connectStatus
		Return True
	End Method

	Method LoginAuth:Int(options:TEOSAuthLoginOptions, listener:IEOSAuthLoginListener) Override
		authLoginCount :+ 1
		lastAuthOptions = options
		Return True
	End Method

	Method CopyIdToken:EEOSResult(accountId:TEOSEpicAccountId, token:TEOSAuthIdToken Var) Override
		token = New TEOSAuthIdToken
		token.AccountId = accountId
		token.JsonWebToken = copiedToken
		Return EEOSResult.Success
	End Method

	Method LoginConnect:Int(options:TEOSConnectLoginOptions, listener:IEOSConnectLoginListener) Override
		connectLoginCount :+ 1
		Return options And options.Credentials And options.Credentials.Token = copiedToken
	End Method

	Method CreateProductUser:Int(continuanceToken:TEOSConnectContinuanceToken, listener:IEOSConnectCreateUserListener) Override
		createUserCount :+ 1
		Return continuanceToken <> Null
	End Method

	Method LogoutConnect:Int(userId:TEOSProductUserId, listener:IEOSConnectLogoutListener) Override
		connectLogoutCount :+ 1
		Return True
	End Method

	Method LogoutAuth:Int(accountId:TEOSEpicAccountId, listener:IEOSAuthLogoutListener) Override
		authLogoutCount :+ 1
		Return True
	End Method

	Method DeletePersistentAuth:Int(listener:IEOSAuthDeletePersistentAuthListener, refreshToken:String) Override
		deletePersistentCount :+ 1
		Return True
	End Method

	Method Shutdown() Override
		shutdownCount :+ 1
	End Method
End Type

Type TSessionEvents Extends TEOSSessionListener
	Field readyCount:Int
	Field creationCount:Int
	Field errorCount:Int
	Field endedCount:Int
	Field lastRecoverable:Int

	Method OnEOSSessionProductUserCreationRequired() Override
		creationCount :+ 1
	End Method

	Method OnEOSSessionReady(accountId:TEOSEpicAccountId, userId:TEOSProductUserId) Override
		readyCount :+ 1
	End Method

	Method OnEOSSessionError(result:EEOSResult, recoverable:Int) Override
		errorCount :+ 1
		lastRecoverable = recoverable
	End Method

	Method OnEOSSessionEnded() Override
		endedCount :+ 1
	End Method
End Type

Function Check(value:Int, message:String)
	If Not value Then
		RuntimeError message
	End If
End Function

Function LoginOptions:TEOSAuthLoginOptions(kind:EEOSLoginCredentialType)
	Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
	credentials.Type = kind
	Local options:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
	options.Credentials = credentials
	Return options
End Function

Function SessionOptions:TEOSSessionOptions()
	Local options:TEOSSessionOptions = New TEOSSessionOptions
	options.LoginOptions = LoginOptions(EEOSLoginCredentialType.PersistentAuth)
	options.FallbackLoginOptions = LoginOptions(EEOSLoginCredentialType.AccountPortal)
	options.InitialRetryDelay = 0
	Return options
End Function

Local accountId:TEOSEpicAccountId = TEOSEpicAccountId._Create(Byte Ptr(1))
Local userId:TEOSProductUserId = TEOSProductUserId._Create(Byte Ptr(2))

' Successful login and token refresh.
Local backend:TMockSessionBackend = New TMockSessionBackend
Local events:TSessionEvents = New TSessionEvents
Local session:TEOSSessionCoordinator = TEOSSessionCoordinator.CreateForBackend(backend, events)
Check(session.Start(SessionOptions()), "session should start")
Check(session.State() = EEOSSessionState.Authenticating, "session should authenticate first")
Check(backend.authLoginCount = 1, "Auth login should start once")
session.OnEOSAuthLogin(EEOSResult.Success, accountId, Null, Null, Null)
Check(session.State() = EEOSSessionState.Connecting, "successful Auth should start Connect")
Check(backend.connectLoginCount = 1, "Connect login should start once")
session.OnEOSConnectLogin(EEOSResult.Success, userId, Null)
Check(session.IsReady(), "successful Connect should make the session ready")
Check(events.readyCount = 1, "ready should be reported")
session.OnEOSConnectAuthExpiration(userId)
Check(session.State() = EEOSSessionState.Refreshing, "expiration should refresh Connect")
Check(backend.connectLoginCount = 2, "refresh should repeat Connect login")
session.OnEOSConnectLogin(EEOSResult.Success, userId, Null)
Check(session.IsReady(), "successful refresh should restore ready state")
Check(events.readyCount = 1, "proactive refresh should not duplicate the initial ready event")

' Missing Product User requires explicit approval.
Local createBackend:TMockSessionBackend = New TMockSessionBackend
Local createEvents:TSessionEvents = New TSessionEvents
Local createSession:TEOSSessionCoordinator = TEOSSessionCoordinator.CreateForBackend(createBackend, createEvents)
Check(createSession.Start(SessionOptions()), "creation session should start")
createSession.OnEOSAuthLogin(EEOSResult.Success, accountId, Null, Null, Null)
Local continuanceToken:TEOSConnectContinuanceToken = New TEOSConnectContinuanceToken
createSession.OnEOSConnectLogin(EEOSResult.InvalidUser, Null, continuanceToken)
Check(createSession.State() = EEOSSessionState.AwaitingProductUserCreation, "missing Product User should pause")
Check(createEvents.creationCount = 1, "creation approval should be requested")
Check(createSession.CreateProductUser(), "approved Product User creation should start")
Check(createBackend.createUserCount = 1, "CreateUser should be called")
createSession.OnEOSConnectCreateUser(EEOSResult.Success, userId)
Check(createSession.IsReady(), "created Product User should make the session ready")

' Invalid persistent credentials use the configured interactive fallback.
Local fallbackBackend:TMockSessionBackend = New TMockSessionBackend
Local fallbackSession:TEOSSessionCoordinator = TEOSSessionCoordinator.CreateForBackend(fallbackBackend)
Local fallbackOptions:TEOSSessionOptions = SessionOptions()
Check(fallbackSession.Start(fallbackOptions), "fallback session should start")
fallbackSession.OnEOSAuthLogin(EEOSResult.AuthInvalidRefreshToken, Null, Null, Null, Null)
Check(fallbackBackend.authLoginCount = 2, "failed PersistentAuth should start fallback login")
Check(fallbackBackend.lastAuthOptions = fallbackOptions.FallbackLoginOptions, "fallback options should be used")

' Transient failures enter a retry state and can be retried immediately.
Local retryBackend:TMockSessionBackend = New TMockSessionBackend
Local retryEvents:TSessionEvents = New TSessionEvents
Local retrySession:TEOSSessionCoordinator = TEOSSessionCoordinator.CreateForBackend(retryBackend, retryEvents)
Check(retrySession.Start(SessionOptions()), "retry session should start")
retrySession.OnEOSAuthLogin(EEOSResult.NoConnection, Null, Null, Null, Null)
Check(retrySession.State() = EEOSSessionState.WaitingToRetry, "network failure should wait to retry")
Check(retryEvents.lastRecoverable, "network failure should be recoverable")
Check(retrySession.RetryNow(), "manual retry should be accepted")
Check(retryBackend.authLoginCount = 2, "manual retry should repeat Auth login")

' Logout waits for in-flight identity operations and then unwinds them.
Local pendingBackend:TMockSessionBackend = New TMockSessionBackend
Local pendingSession:TEOSSessionCoordinator = TEOSSessionCoordinator.CreateForBackend(pendingBackend)
Check(pendingSession.Start(SessionOptions()), "pending session should start")
Check(pendingSession.Logout(), "logout during Auth should be accepted")
Check(pendingBackend.authLogoutCount = 0, "Auth cannot log out before its login completes")
pendingSession.OnEOSAuthLogin(EEOSResult.Success, accountId, Null, Null, Null)
Check(pendingBackend.authLogoutCount = 1, "completed in-flight Auth should immediately log out")

Local pendingConnectBackend:TMockSessionBackend = New TMockSessionBackend
Local pendingConnectSession:TEOSSessionCoordinator = TEOSSessionCoordinator.CreateForBackend(pendingConnectBackend)
Check(pendingConnectSession.Start(SessionOptions()), "pending Connect session should start")
pendingConnectSession.OnEOSAuthLogin(EEOSResult.Success, accountId, Null, Null, Null)
Check(pendingConnectSession.Logout(), "logout during Connect should be accepted")
pendingConnectSession.OnEOSConnectLogin(EEOSResult.Success, userId, Null)
Check(pendingConnectBackend.connectLogoutCount = 1, "completed in-flight Connect should immediately log out")

' Logout is Connect, Auth, and optional persistent credential deletion in order.
Check(session.Logout(True), "ready session should begin logout")
Check(backend.connectLogoutCount = 1, "Connect should log out first")
session.OnEOSConnectLogout(EEOSResult.Success, userId)
Check(backend.authLogoutCount = 1, "Auth should log out second")
session.OnEOSAuthLogout(EEOSResult.Success, accountId)
Check(backend.deletePersistentCount = 1, "persistent credential should be removed last")
session.OnEOSAuthDeletePersistentAuth(EEOSResult.Success)
Check(session.State() = EEOSSessionState.Stopped, "logout should stop the session")
Check(events.endedCount = 1, "session end should be reported")

session.Release()
Check(backend.shutdownCount = 1, "release should remove backend notifications")

Print "EOS session coordinator tests passed."
