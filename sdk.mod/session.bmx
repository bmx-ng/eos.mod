' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

Rem
bbdoc: Stages in the lifecycle of a single local EOS user session.
End Rem
Enum EEOSSessionState
	Stopped
	Authenticating
	Connecting
	AwaitingProductUserCreation
	Ready
	Refreshing
	SigningOut
	WaitingToRetry
	Failed
End Enum

Enum EEOSSessionRetryAction
	None
	Authenticate
	Connect
End Enum

Rem
bbdoc: Configures one Auth-to-Connect login flow.
about: LoginOptions is attempted first. FallbackLoginOptions is useful when
trying PersistentAuth before AccountPortal. Product User creation always waits
for an explicit call to #CreateProductUser.
End Rem
Type TEOSSessionOptions
	Field LoginOptions:TEOSAuthLoginOptions
	Field FallbackLoginOptions:TEOSAuthLoginOptions
	Field RetryConnection:Int = True
	Field MaximumRetryAttempts:Int = 5
	Field InitialRetryDelay:Int = 1000
	Field MaximumRetryDelay:Int = 30000
End Type

Rem
bbdoc: Receives high-level session lifecycle events.
End Rem
Interface IEOSSessionListener
	Method OnEOSSessionStateChanged(state:EEOSSessionState)
	Method OnEOSSessionAuthActionRequired(pinGrantInfo:TEOSAuthPinGrantInfo)
	Method OnEOSSessionProductUserCreationRequired()
	Method OnEOSSessionReady(accountId:TEOSEpicAccountId, userId:TEOSProductUserId)
	Method OnEOSSessionError(result:EEOSResult, recoverable:Int)
	Method OnEOSSessionEnded()
End Interface

Rem
bbdoc: Optional no-op base listener for applications interested in only some events.
End Rem
Type TEOSSessionListener Implements IEOSSessionListener
	Method OnEOSSessionStateChanged(state:EEOSSessionState)
	End Method

	Method OnEOSSessionAuthActionRequired(pinGrantInfo:TEOSAuthPinGrantInfo)
	End Method

	Method OnEOSSessionProductUserCreationRequired()
	End Method

	Method OnEOSSessionReady(accountId:TEOSEpicAccountId, userId:TEOSProductUserId)
	End Method

	Method OnEOSSessionError(result:EEOSResult, recoverable:Int)
	End Method

	Method OnEOSSessionEnded()
	End Method
End Type

Rem
bbdoc: Operations used by #TEOSSessionCoordinator.
about: Applications normally use the native backend created from a
#TEOSPlatform. This interface permits deterministic coordinator tests.
End Rem
Interface IEOSSessionBackend
	Method Initialize:Int(authStatusListener:IEOSAuthLoginStatusListener, authExpirationListener:IEOSConnectAuthExpirationListener, connectStatusListener:IEOSConnectLoginStatusListener)
	Method LoginAuth:Int(options:TEOSAuthLoginOptions, listener:IEOSAuthLoginListener)
	Method CopyIdToken:EEOSResult(accountId:TEOSEpicAccountId, token:TEOSAuthIdToken Var)
	Method LoginConnect:Int(options:TEOSConnectLoginOptions, listener:IEOSConnectLoginListener)
	Method CreateProductUser:Int(continuanceToken:TEOSConnectContinuanceToken, listener:IEOSConnectCreateUserListener)
	Method LogoutConnect:Int(userId:TEOSProductUserId, listener:IEOSConnectLogoutListener)
	Method LogoutAuth:Int(accountId:TEOSEpicAccountId, listener:IEOSAuthLogoutListener)
	Method DeletePersistentAuth:Int(listener:IEOSAuthDeletePersistentAuthListener, refreshToken:String)
	Method Shutdown()
End Interface

Type TNativeEOSSessionBackend Implements IEOSSessionBackend
	Private
	Field _platform:TEOSPlatform
	Field _auth:TEOSAuth
	Field _connect:TEOSConnect
	Field _authStatus:TEOSAuthLoginStatusSubscription
	Field _authExpiration:TEOSConnectAuthExpirationSubscription
	Field _connectStatus:TEOSConnectLoginStatusSubscription
	Field _authLogin:TEOSAuthLoginRequest
	Field _authLogout:TEOSAuthLogoutRequest
	Field _deletePersistent:TEOSAuthDeletePersistentAuthRequest
	Field _connectLogin:TEOSConnectLoginRequest
	Field _connectCreate:TEOSConnectCreateUserRequest
	Field _connectLogout:TEOSConnectLogoutRequest

	Public
	Method New(platform:TEOSPlatform)
		_platform = platform
	End Method

	Method Initialize:Int(authStatusListener:IEOSAuthLoginStatusListener, authExpirationListener:IEOSConnectAuthExpirationListener, connectStatusListener:IEOSConnectLoginStatusListener) Override
		If Not _platform Or Not _platform.IsValid() Then
			Return False
		End If
		_auth = _platform.Auth()
		_connect = _platform.Connect()
		If Not _auth Or Not _connect Then
			Return False
		End If
		_authStatus = _auth.AddNotifyLoginStatusChanged(authStatusListener)
		_authExpiration = _connect.AddNotifyAuthExpiration(authExpirationListener)
		_connectStatus = _connect.AddNotifyLoginStatusChanged(connectStatusListener)
		If Not _authStatus Or Not _authExpiration Or Not _connectStatus Then
			Shutdown()
			Return False
		End If
		Return True
	End Method

	Method LoginAuth:Int(options:TEOSAuthLoginOptions, listener:IEOSAuthLoginListener) Override
		_authLogin = _auth.Login(options, listener)
		Return _authLogin <> Null
	End Method

	Method CopyIdToken:EEOSResult(accountId:TEOSEpicAccountId, token:TEOSAuthIdToken Var) Override
		Return _auth.CopyIdToken(accountId, token)
	End Method

	Method LoginConnect:Int(options:TEOSConnectLoginOptions, listener:IEOSConnectLoginListener) Override
		_connectLogin = _connect.Login(options, listener)
		Return _connectLogin <> Null
	End Method

	Method CreateProductUser:Int(continuanceToken:TEOSConnectContinuanceToken, listener:IEOSConnectCreateUserListener) Override
		_connectCreate = _connect.CreateUser(continuanceToken, listener)
		Return _connectCreate <> Null
	End Method

	Method LogoutConnect:Int(userId:TEOSProductUserId, listener:IEOSConnectLogoutListener) Override
		_connectLogout = _connect.Logout(userId, listener)
		Return _connectLogout <> Null
	End Method

	Method LogoutAuth:Int(accountId:TEOSEpicAccountId, listener:IEOSAuthLogoutListener) Override
		_authLogout = _auth.Logout(accountId, listener)
		Return _authLogout <> Null
	End Method

	Method DeletePersistentAuth:Int(listener:IEOSAuthDeletePersistentAuthListener, refreshToken:String) Override
		_deletePersistent = _auth.DeletePersistentAuth(listener, refreshToken)
		Return _deletePersistent <> Null
	End Method

	Method Shutdown() Override
		If _authStatus Then
			_authStatus.Remove()
		End If
		If _authExpiration Then
			_authExpiration.Remove()
		End If
		If _connectStatus Then
			_connectStatus.Remove()
		End If
		_authStatus = Null
		_authExpiration = Null
		_connectStatus = Null
		_authLogin = Null
		_authLogout = Null
		_deletePersistent = Null
		_connectLogin = Null
		_connectCreate = Null
		_connectLogout = Null
		_auth = Null
		_connect = Null
	End Method
End Type

Rem
bbdoc: Coordinates Auth, Connect, Product User creation, refresh, retry, and logout for one local player.
about: Call #Tick once per main-loop iteration. Once #IsReady returns True,
#ProductUserId can be supplied to all EOS Game Services and GameNet.EOSOnline.
End Rem
Type TEOSSessionCoordinator Implements IEOSAuthLoginListener, IEOSAuthLogoutListener, IEOSAuthDeletePersistentAuthListener, IEOSConnectLoginListener, IEOSConnectCreateUserListener, IEOSConnectLogoutListener, IEOSAuthLoginStatusListener, IEOSConnectAuthExpirationListener, IEOSConnectLoginStatusListener
	Private
	Field _platform:TEOSPlatform
	Field _backend:IEOSSessionBackend
	Field _listener:IEOSSessionListener
	Field _options:TEOSSessionOptions
	Field _state:EEOSSessionState = EEOSSessionState.Stopped
	Field _lastResult:EEOSResult = EEOSResult.Success
	Field _accountId:TEOSEpicAccountId
	Field _userId:TEOSProductUserId
	Field _continuanceToken:TEOSConnectContinuanceToken
	Field _usingFallback:Int
	Field _refreshing:Int
	Field _forgetPersistent:Int
	Field _retryAction:EEOSSessionRetryAction
	Field _retryAt:Int
	Field _retryCount:Int
	Field _initialized:Int

	Method ChangeState(state:EEOSSessionState)
		If _state = state Then
			Return
		End If
		_state = state
		If _listener Then
			_listener.OnEOSSessionStateChanged(state)
		End If
	End Method

	Method CurrentLoginOptions:TEOSAuthLoginOptions()
		If _usingFallback Then
			Return _options.FallbackLoginOptions
		End If
		Return _options.LoginOptions
	End Method

	Method IsTransient:Int(result:EEOSResult)
		Select result
			Case EEOSResult.NoConnection, EEOSResult.TooManyRequests, EEOSResult.TimedOut
				Return True
			Case EEOSResult.ServiceFailure, EEOSResult.NetworkDisconnected, EEOSResult.OperationWillRetry
				Return True
			Case EEOSResult.AuthExpired
				Return True
		End Select
		Return False
	End Method

	Method CanUseFallback:Int(result:EEOSResult)
		If _usingFallback Or Not _options Or Not _options.FallbackLoginOptions Then
			Return False
		End If
		Select result
			Case EEOSResult.InvalidCredentials, EEOSResult.NotFound
				Return True
			Case EEOSResult.AuthInvalidRefreshToken, EEOSResult.AuthInvalidToken, EEOSResult.AuthExpired
				Return True
		End Select
		Return False
	End Method

	Method ReportError(result:EEOSResult, recoverable:Int)
		_lastResult = result
		If _listener Then
			_listener.OnEOSSessionError(result, recoverable)
		End If
	End Method

	Method Fail(result:EEOSResult)
		_retryAction = EEOSSessionRetryAction.None
		_lastResult = result
		ChangeState(EEOSSessionState.Failed)
		If _listener Then
			_listener.OnEOSSessionError(result, False)
		End If
	End Method

	Method ScheduleRetry(result:EEOSResult, action:EEOSSessionRetryAction)
		If Not _options Or Not _options.RetryConnection Or Not IsTransient(result) Then
			Fail(result)
			Return
		End If
		If _options.MaximumRetryAttempts >= 0 And _retryCount >= _options.MaximumRetryAttempts Then
			Fail(result)
			Return
		End If
		Local delay:Int = _options.InitialRetryDelay
		If delay < 0 Then
			delay = 0
		End If
		For Local index:Int = 0 Until _retryCount
			If delay >= _options.MaximumRetryDelay Then
				Exit
			End If
			delay :* 2
		Next
		If _options.MaximumRetryDelay >= 0 And delay > _options.MaximumRetryDelay Then
			delay = _options.MaximumRetryDelay
		End If
		_retryCount :+ 1
		_retryAction = action
		_retryAt = MilliSecs() + delay
		_lastResult = result
		ChangeState(EEOSSessionState.WaitingToRetry)
		If _listener Then
			_listener.OnEOSSessionError(result, True)
		End If
	End Method

	Method BeginAuthentication:Int()
		Local loginOptions:TEOSAuthLoginOptions = CurrentLoginOptions()
		If Not loginOptions Or Not loginOptions.Credentials Then
			Fail(EEOSResult.InvalidParameters)
			Return False
		End If
		_refreshing = False
		ChangeState(EEOSSessionState.Authenticating)
		If Not _backend.LoginAuth(loginOptions, Self) Then
			Fail(EEOSResult.InvalidState)
			Return False
		End If
		Return True
	End Method

	Method BeginConnect:Int(refreshing:Int)
		If Not _accountId Then
			Fail(EEOSResult.InvalidUser)
			Return False
		End If
		Local token:TEOSAuthIdToken
		Local result:EEOSResult = _backend.CopyIdToken(_accountId, token)
		If result <> EEOSResult.Success Or Not token Or Not token.JsonWebToken Then
			If result = EEOSResult.Success Then
				result = EEOSResult.UnexpectedError
			End If
			ScheduleRetry(result, EEOSSessionRetryAction.Connect)
			Return False
		End If
		Local credentials:TEOSConnectCredentials = New TEOSConnectCredentials
		credentials.Type = EEOSExternalCredentialType.EpicIdToken
		credentials.Token = token.JsonWebToken
		Local options:TEOSConnectLoginOptions = New TEOSConnectLoginOptions
		options.Credentials = credentials
		_refreshing = refreshing
		If refreshing Then
			ChangeState(EEOSSessionState.Refreshing)
		Else
			ChangeState(EEOSSessionState.Connecting)
		End If
		If Not _backend.LoginConnect(options, Self) Then
			Fail(EEOSResult.InvalidState)
			Return False
		End If
		Return True
	End Method

	Method BecomeReady(userId:TEOSProductUserId)
		If Not userId Then
			Fail(EEOSResult.InvalidUser)
			Return
		End If
		Local reportReady:Int = Not _refreshing Or Not _userId
		If _refreshing And _userId And _userId._NativeHandle() <> userId._NativeHandle() Then
			Fail(EEOSResult.InvalidUser)
			Return
		End If
		_userId = userId
		_continuanceToken = Null
		_refreshing = False
		_retryAction = EEOSSessionRetryAction.None
		_retryCount = 0
		_lastResult = EEOSResult.Success
		ChangeState(EEOSSessionState.Ready)
		If reportReady And _listener Then
			_listener.OnEOSSessionReady(_accountId, _userId)
		End If
	End Method

	Method BeginAuthLogout()
		If _accountId Then
			If Not _backend.LogoutAuth(_accountId, Self) Then
				ReportError(EEOSResult.InvalidState, False)
				BeginDeletePersistent()
			End If
		Else
			BeginDeletePersistent()
		End If
	End Method

	Method BeginDeletePersistent()
		If _forgetPersistent Then
			If Not _backend.DeletePersistentAuth(Self, "") Then
				ReportError(EEOSResult.InvalidState, False)
				FinishStopped()
			End If
		Else
			FinishStopped()
		End If
	End Method

	Method FinishStopped()
		_accountId = Null
		_userId = Null
		_continuanceToken = Null
		_retryAction = EEOSSessionRetryAction.None
		_refreshing = False
		_forgetPersistent = False
		ChangeState(EEOSSessionState.Stopped)
		If _listener Then
			_listener.OnEOSSessionEnded()
		End If
	End Method

	Public
	Function Create:TEOSSessionCoordinator(platform:TEOSPlatform, listener:IEOSSessionListener = Null)
		If Not platform Or Not platform.IsValid() Then
			Return Null
		End If
		Local session:TEOSSessionCoordinator = New TEOSSessionCoordinator
		session._platform = platform
		session._backend = New TNativeEOSSessionBackend(platform)
		session._listener = listener
		Return session
	End Function

	Function CreateForBackend:TEOSSessionCoordinator(backend:IEOSSessionBackend, listener:IEOSSessionListener = Null)
		If Not backend Then
			Return Null
		End If
		Local session:TEOSSessionCoordinator = New TEOSSessionCoordinator
		session._backend = backend
		session._listener = listener
		Return session
	End Function

	Method Start:Int(options:TEOSSessionOptions)
		If Not options Or Not options.LoginOptions Or Not options.LoginOptions.Credentials Then
			Return False
		End If
		If _state <> EEOSSessionState.Stopped And _state <> EEOSSessionState.Failed Then
			Return False
		End If
		If Not _initialized Then
			_initialized = _backend.Initialize(Self, Self, Self)
			If Not _initialized Then
				Fail(EEOSResult.InvalidState)
				Return False
			End If
		End If
		_options = options
		_accountId = Null
		_userId = Null
		_continuanceToken = Null
		_usingFallback = False
		_retryCount = 0
		_retryAction = EEOSSessionRetryAction.None
		_lastResult = EEOSResult.Success
		Return BeginAuthentication()
	End Method

	Method CreateProductUser:Int()
		If _state <> EEOSSessionState.AwaitingProductUserCreation Or Not _continuanceToken Then
			Return False
		End If
		ChangeState(EEOSSessionState.Connecting)
		If Not _backend.CreateProductUser(_continuanceToken, Self) Then
			Fail(EEOSResult.InvalidState)
			Return False
		End If
		Return True
	End Method

	Method CancelProductUserCreation()
		If _state = EEOSSessionState.AwaitingProductUserCreation Then
			_continuanceToken = Null
			Fail(EEOSResult.Canceled)
		End If
	End Method

	Method RetryNow:Int()
		If _state <> EEOSSessionState.WaitingToRetry Then
			Return False
		End If
		_retryAt = 0
		Update()
		Return True
	End Method

	Method Update()
		If _state <> EEOSSessionState.WaitingToRetry Or MilliSecs() < _retryAt Then
			Return
		End If
		Local action:EEOSSessionRetryAction = _retryAction
		_retryAction = EEOSSessionRetryAction.None
		If action = EEOSSessionRetryAction.Connect And _accountId Then
			BeginConnect(_userId <> Null)
		Else
			BeginAuthentication()
		End If
	End Method

	Method Tick()
		If _platform And _platform.IsValid() Then
			_platform.Tick()
		End If
		Update()
	End Method

	Method Logout:Int(forgetPersistent:Int = False)
		If _state = EEOSSessionState.Stopped Or _state = EEOSSessionState.SigningOut Then
			Return False
		End If
		Local previousState:EEOSSessionState = _state
		_forgetPersistent = forgetPersistent
		_retryAction = EEOSSessionRetryAction.None
		_continuanceToken = Null
		ChangeState(EEOSSessionState.SigningOut)
		If previousState = EEOSSessionState.Authenticating Or previousState = EEOSSessionState.Connecting Or previousState = EEOSSessionState.Refreshing Then
			Return True
		End If
		If _userId Then
			If Not _backend.LogoutConnect(_userId, Self) Then
				ReportError(EEOSResult.InvalidState, False)
				BeginAuthLogout()
			End If
		Else
			BeginAuthLogout()
		End If
		Return True
	End Method

	Method Release()
		If _initialized Then
			_backend.Shutdown()
		End If
		_initialized = False
		_options = Null
		_accountId = Null
		_userId = Null
		_continuanceToken = Null
		_listener = Null
		_state = EEOSSessionState.Stopped
	End Method

	Method State:EEOSSessionState()
		Return _state
	End Method

	Method IsReady:Int()
		Return _state = EEOSSessionState.Ready And _userId <> Null
	End Method

	Rem
	bbdoc: Returns True while the established Product User can still be used.
	about: A session remains usable during a proactive Connect refresh or a
	transient retry that has not invalidated the Product User.
	End Rem
	Method IsUsable:Int()
		If Not _userId Then
			Return False
		End If
		Select _state
			Case EEOSSessionState.Ready, EEOSSessionState.Refreshing, EEOSSessionState.WaitingToRetry
				Return True
		End Select
		Return False
	End Method

	Method LastResult:EEOSResult()
		Return _lastResult
	End Method

	Method AccountId:TEOSEpicAccountId()
		Return _accountId
	End Method

	Method ProductUserId:TEOSProductUserId()
		Return _userId
	End Method

	Method Platform:TEOSPlatform()
		Return _platform
	End Method

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId) Override
		If _state = EEOSSessionState.SigningOut Then
			If Not EOSResultIsOperationComplete(result) Then
				Return
			End If
			If result = EEOSResult.Success Then
				_accountId = selectedAccountId
				If Not _accountId Then
					_accountId = localUserId
				End If
			End If
			BeginAuthLogout()
			Return
		End If
		If _state <> EEOSSessionState.Authenticating Then
			Return
		End If
		If pinGrantInfo And _listener Then
			_listener.OnEOSSessionAuthActionRequired(pinGrantInfo)
		End If
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			If CanUseFallback(result) Then
				_usingFallback = True
				_retryCount = 0
				BeginAuthentication()
			Else
				ScheduleRetry(result, EEOSSessionRetryAction.Authenticate)
			End If
			Return
		End If
		_accountId = selectedAccountId
		If Not _accountId Then
			_accountId = localUserId
		End If
		_retryCount = 0
		BeginConnect(False)
	End Method

	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken) Override
		If _state = EEOSSessionState.SigningOut Then
			If Not EOSResultIsOperationComplete(result) Then
				Return
			End If
			If result = EEOSResult.Success And localUserId Then
				_userId = localUserId
				If Not _backend.LogoutConnect(_userId, Self) Then
					BeginAuthLogout()
				End If
			Else
				BeginAuthLogout()
			End If
			Return
		End If
		If _state <> EEOSSessionState.Connecting And _state <> EEOSSessionState.Refreshing Then
			Return
		End If
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result = EEOSResult.Success Then
			BecomeReady(localUserId)
			Return
		End If
		If result = EEOSResult.InvalidUser And continuanceToken And Not _refreshing Then
			_continuanceToken = continuanceToken
			ChangeState(EEOSSessionState.AwaitingProductUserCreation)
			If _listener Then
				_listener.OnEOSSessionProductUserCreationRequired()
			End If
			Return
		End If
		ScheduleRetry(result, EEOSSessionRetryAction.Connect)
	End Method

	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId) Override
		If _state = EEOSSessionState.SigningOut Then
			If Not EOSResultIsOperationComplete(result) Then
				Return
			End If
			If result = EEOSResult.Success And localUserId Then
				_userId = localUserId
				If Not _backend.LogoutConnect(_userId, Self) Then
					BeginAuthLogout()
				End If
			Else
				BeginAuthLogout()
			End If
			Return
		End If
		If _state <> EEOSSessionState.Connecting Then
			Return
		End If
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result = EEOSResult.Success Then
			BecomeReady(localUserId)
		Else
			ScheduleRetry(result, EEOSSessionRetryAction.Connect)
		End If
	End Method

	Method OnEOSConnectAuthExpiration(localUserId:TEOSProductUserId) Override
		If _state <> EEOSSessionState.Ready Or Not _userId Or Not localUserId Then
			Return
		End If
		If _userId._NativeHandle() = localUserId._NativeHandle() Then
			BeginConnect(True)
		End If
	End Method

	Method OnEOSAuthLoginStatusChanged(localUserId:TEOSEpicAccountId, previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus) Override
		If currentStatus <> EEOSLoginStatus.NotLoggedIn Then
			Return
		End If
		If _state <> EEOSSessionState.Ready And _state <> EEOSSessionState.Refreshing And _state <> EEOSSessionState.WaitingToRetry Then
			Return
		End If
		If _accountId And localUserId And _accountId._NativeHandle() <> localUserId._NativeHandle() Then
			Return
		End If
		_accountId = Null
		_userId = Null
		ScheduleRetry(EEOSResult.AuthExpired, EEOSSessionRetryAction.Authenticate)
	End Method

	Method OnEOSConnectLoginStatusChanged(localUserId:TEOSProductUserId, previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus) Override
		If currentStatus <> EEOSLoginStatus.NotLoggedIn Then
			Return
		End If
		If _state <> EEOSSessionState.Ready And _state <> EEOSSessionState.Refreshing Then
			Return
		End If
		If _userId And localUserId And _userId._NativeHandle() <> localUserId._NativeHandle() Then
			Return
		End If
		_userId = Null
		ScheduleRetry(EEOSResult.AuthExpired, EEOSSessionRetryAction.Connect)
	End Method

	Method OnEOSConnectLogout(result:EEOSResult, localUserId:TEOSProductUserId) Override
		If _state <> EEOSSessionState.SigningOut Or Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			ReportError(result, False)
		End If
		_userId = Null
		BeginAuthLogout()
	End Method

	Method OnEOSAuthLogout(result:EEOSResult, localUserId:TEOSEpicAccountId) Override
		If _state <> EEOSSessionState.SigningOut Or Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			ReportError(result, False)
		End If
		_accountId = Null
		BeginDeletePersistent()
	End Method

	Method OnEOSAuthDeletePersistentAuth(result:EEOSResult) Override
		If _state <> EEOSSessionState.SigningOut Or Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			ReportError(result, False)
		End If
		FinishStopped()
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type
