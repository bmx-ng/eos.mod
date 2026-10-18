' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

SuperStrict

Framework Max2D.SDL3RenderMax2D
Import EOS.SDK
Import BRL.FileSystem
Import BRL.PolledInput
Import BRL.StandardIO
Import BRL.TextStream

Const WINDOW_WIDTH:Int = 860
Const WINDOW_HEIGHT:Int = 470
Const HOST_SESSION_NAME:String = "EOS Sessions Host Test"
Const CLIENT_SESSION_NAME:String = "EOS Sessions Client Test"
Const TEST_BUCKET:String = "eos-sdk-two-user-sessions-test"

Global statusTitle:String = "Preparing the two-account Sessions test..."
Global statusDetail:String = "Both accounts will sign in through the Developer Authentication Tool."
Global eventSummary:String = "Waiting for both accounts to connect."
Global latestLog:String
Global statusKind:Int
Global done:Int
Global succeeded:Int
Global pendingProductUser:Int

Type TConsoleLogListener Implements IEOSLogListener
	Method OnEOSLog(category:String, message:String, level:EEOSLogLevel)
		latestLog = category + ": " + message
	End Method
End Type

Type TSessionsPeer Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSConnectCreateUserListener
	Field Manager:TTwoUserSessionsTest
	Field Number:Int
	Field Credential:String
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field ProductUserId:TEOSProductUserId
	Field CreateMissingProductUser:Int
	Field ContinuanceToken:TEOSConnectContinuanceToken

	Method Start:Int(host:String)
		Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
		credentials.Type = EEOSLoginCredentialType.Developer
		credentials.Id = host
		credentials.Token = Credential
		Local options:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
		options.Credentials = credentials
		options.ScopeFlags = EEOSAuthScopeFlags.BasicProfile | ..
			EEOSAuthScopeFlags.FriendsList | EEOSAuthScopeFlags.Presence
		Return Auth.Login(options, Self) <> Null
	End Method

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId) Override
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Manager.Fail("Account " + Number + " Auth login failed", EOSResultString(result))
			Return
		End If

		Local accountId:TEOSEpicAccountId = selectedAccountId
		If Not accountId Then
			accountId = localUserId
		End If
		Local idToken:TEOSAuthIdToken
		result = Auth.CopyIdToken(accountId, idToken)
		If result <> EEOSResult.Success Then
			Manager.Fail("Account " + Number + " ID token failed", EOSResultString(result))
			Return
		End If

		Local credentials:TEOSConnectCredentials = New TEOSConnectCredentials
		credentials.Type = EEOSExternalCredentialType.EpicIdToken
		credentials.Token = idToken.JsonWebToken
		Local options:TEOSConnectLoginOptions = New TEOSConnectLoginOptions
		options.Credentials = credentials
		If Not Connect.Login(options, Self) Then
			Manager.Fail("Account " + Number + " Connect login failed", "EOS rejected the request.")
		End If
	End Method

	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken) Override
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result = EEOSResult.Success Then
			ProductUserId = localUserId
			Manager.PeerReady(Self)
			Return
		End If
		If result = EEOSResult.InvalidUser And continuanceToken And CreateMissingProductUser Then
			If Not Connect.CreateUser(continuanceToken, Self) Then
				Manager.Fail("Account " + Number + " Product User creation failed", "EOS rejected the request.")
			End If
		Else If result = EEOSResult.InvalidUser Then
			Self.ContinuanceToken = continuanceToken
			Manager.AskToCreateProductUser(Self)
		Else
			Manager.Fail("Account " + Number + " Connect login failed", EOSResultString(result))
		End If
	End Method

	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId) Override
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Manager.Fail("Account " + Number + " Product User creation failed", EOSResultString(result))
			Return
		End If
		ProductUserId = localUserId
		ContinuanceToken = Null
		Manager.PeerReady(Self)
	End Method
End Type

Type TTwoUserSessionsTest Implements IEOSSessionUpdateListener, IEOSSessionOperationListener, IEOSSessionPlayersListener, IEOSSessionInviteReceivedListener
	Field Platform:TEOSPlatform
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field Sessions:TEOSSessions
	Field Peers:TSessionsPeer[2]
	Field ReadyCount:Int
	Field DevAuthHost:String
	Field PendingPeer:TSessionsPeer
	Field InviteSubscription:TEOSSessionInviteReceivedSubscription
	Field InviteId:String
	Field InviteReceived:Int
	Field SendCompleted:Int
	Field SendCompletedAt:Int
	Field InviteFlowStarted:Int
	Field CleanupStage:Int

	Method AddPeer:TSessionsPeer(number:Int, credential:String, createMissing:Int)
		Local peer:TSessionsPeer = New TSessionsPeer
		peer.Manager = Self
		peer.Number = number
		peer.Credential = credential
		peer.Auth = Auth
		peer.Connect = Connect
		peer.CreateMissingProductUser = createMissing
		Peers[number - 1] = peer
		Return peer
	End Method

	Method PeerReady(peer:TSessionsPeer)
		pendingProductUser = False
		ReadyCount :+ 1
		Print "Account " + peer.Number + " Product User: " + peer.ProductUserId.ToString()
		If ReadyCount = 1 Then
			statusTitle = "Account 1 connected; signing in account 2..."
			If Not Peers[1].Start(DevAuthHost) Then
				Fail("Account 2 login did not start", "Check the second credential name.")
			End If
			Return
		End If
		If ReadyCount = 2 Then
			BeginSessionTest()
		End If
	End Method

	Method AskToCreateProductUser(peer:TSessionsPeer)
		PendingPeer = peer
		pendingProductUser = True
		statusTitle = "Account " + peer.Number + " needs a Product User"
		statusDetail = "Press C to create it, or Escape to cancel."
	End Method

	Method CreateProductUser()
		If Not PendingPeer Or Not PendingPeer.ContinuanceToken Then
			Return
		End If
		pendingProductUser = False
		statusTitle = "Creating account " + PendingPeer.Number + " Product User..."
		If Not Connect.CreateUser(PendingPeer.ContinuanceToken, PendingPeer) Then
			Fail("Product User creation did not start", "EOS rejected the request.")
		End If
	End Method

	Method BeginSessionTest()
		InviteSubscription = Sessions.AddNotifyInviteReceived(Self)
		If Not InviteSubscription Then
			Fail("Invite notification setup failed", "The Sessions notification could not be registered.")
			Return
		End If

		statusTitle = "Publishing the host session..."
		statusDetail = "Account 1 will invite account 2 after publication."
		Local options:TEOSSessionCreateOptions = New TEOSSessionCreateOptions
		options.SessionName = HOST_SESSION_NAME
		options.BucketId = TEST_BUCKET
		options.MaxPlayers = 2
		options.LocalUserId = Peers[0].ProductUserId
		options.SanctionsEnabled = True

		Local modification:TEOSSessionModification
		Local result:EEOSResult = Sessions.CreateSessionModification(options, modification)
		If result <> EEOSResult.Success Then
			Fail("Host session setup failed", EOSResultString(result))
			Return
		End If
		result = modification.SetPermissionLevel(EEOSOnlineSessionPermissionLevel.PublicAdvertised)
		If result = EEOSResult.Success Then
			result = modification.SetInvitesAllowed(True)
		End If
		If result = EEOSResult.Success Then
			result = modification.SetHostAddress("eos-p2p")
		End If
		If result = EEOSResult.Success Then
			result = modification.AddStringAttribute("test", "two-user-join")
		End If
		If result <> EEOSResult.Success Or Not Sessions.UpdateSession(modification, Self) Then
			modification.Release()
			Fail("Host session publication failed", EOSResultString(result))
			Return
		End If
		modification.Release()
	End Method

	Method OnEOSSessionUpdated(result:EEOSResult, sessionName:String, sessionId:String) Override
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Fail("Host session publication failed", EOSResultString(result))
			Return
		End If
		Print "Published session ID: " + sessionId
		statusTitle = "Host session published; sending invitation..."
		eventSummary = "Session published. Waiting for account 2 invitation."
		If Not Sessions.SendInvite( ..
			HOST_SESSION_NAME, Peers[0].ProductUserId, Peers[1].ProductUserId, Self) Then
			Fail("Session invitation did not start", "EOS rejected the request.")
		End If
	End Method

	Method OnEOSSessionInviteReceived(receivedInviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId) Override
		If localUserId.ToString() <> Peers[1].ProductUserId.ToString() Then
			Return
		End If
		InviteId = receivedInviteId
		InviteReceived = True
		Print "Invite received: " + InviteId
		eventSummary = "Account 2 received the session invitation."
		TryBeginInviteQuery()
	End Method

	Method OnEOSSessionOperation(result:EEOSResult, operation:EEOSSessionOperation) Override
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Fail("Session operation " + Int(operation) + " failed", EOSResultString(result))
			Return
		End If

		Select operation
			Case EEOSSessionOperation.SendInvite
				SendCompleted = True
				SendCompletedAt = MilliSecs()
				TryBeginInviteQuery()
			Case EEOSSessionOperation.QueryInvites
				JoinFromInviteCache()
			Case EEOSSessionOperation.JoinSession
				RegisterJoinedPlayer()
			Case EEOSSessionOperation.DestroySession
				If CleanupStage = 1 Then
					CleanupStage = 2
					If Not Sessions.DestroySession(HOST_SESSION_NAME, Self) Then
						Fail("Host session cleanup did not start", "EOS rejected the request.")
					End If
				Else If CleanupStage = 2 Then
					statusKind = 2
					statusTitle = "Two-account EOS Sessions test succeeded"
					statusDetail = "Published, invited, joined, registered, left, and destroyed."
					eventSummary = "Invite cache and two local active-session views were verified."
					succeeded = True
					done = True
				End If
		End Select
	End Method

	Method Tick()
		If SendCompleted And Not InviteFlowStarted And MilliSecs() - SendCompletedAt >= 2000 Then
			BeginInviteQuery(False)
		End If
	End Method

	Method TryBeginInviteQuery()
		If Not SendCompleted Or Not InviteReceived Or InviteFlowStarted Then
			Return
		End If
		BeginInviteQuery(True)
	End Method

	Method BeginInviteQuery(notificationReceived:Int)
		InviteFlowStarted = True
		If notificationReceived Then
			statusTitle = "Invitation received; querying account 2's invite cache..."
		Else
			statusTitle = "Invitation sent; querying account 2's invite cache..."
			eventSummary = "EOS did not emit the local notification; checking the authoritative cache."
		End If
		If Not Sessions.QueryInvites(Peers[1].ProductUserId, Self) Then
			Fail("Invite query did not start", "EOS rejected the request.")
		End If
	End Method

	Method JoinFromInviteCache()
		Local count:UInt = Sessions.InviteCount(Peers[1].ProductUserId)
		Print "Invite cache count: " + count
		If count = 0 Then
			Fail("The invitation cache is empty", "The received invite was not returned by QueryInvites.")
			Return
		End If

		Local cachedInviteId:String
		Local result:EEOSResult = Sessions.GetInviteIdByIndex( ..
			Peers[1].ProductUserId, 0, cachedInviteId)
		If result <> EEOSResult.Success Then
			Fail("Could not copy the invitation ID", EOSResultString(result))
			Return
		End If
		Print "Cached invite ID: " + cachedInviteId

		Local details:TEOSSessionDetails
		result = Sessions.CopySessionDetailsByInviteId(cachedInviteId, details)
		If result <> EEOSResult.Success Then
			Fail("Could not copy invited session details", EOSResultString(result))
			Return
		End If
		Local info:TEOSSessionInfo
		result = details.CopyInfo(info)
		If result = EEOSResult.Success Then
			Print "Invited session ID: " + info.SessionId
			Print "Invited session bucket: " + info.BucketId
		End If
		If result <> EEOSResult.Success Then
			details.Release()
			Fail("Could not inspect invited session", EOSResultString(result))
			Return
		End If

		statusTitle = "Account 2 is joining the invited session..."
		Local joinOptions:TEOSSessionJoinOptions = New TEOSSessionJoinOptions
		joinOptions.SessionName = CLIENT_SESSION_NAME
		joinOptions.SessionDetails = details
		joinOptions.LocalUserId = Peers[1].ProductUserId
		If Not Sessions.JoinSession(joinOptions, Self) Then
			details.Release()
			Fail("Joining the invited session did not start", "EOS rejected the request.")
			Return
		End If
		details.Release()
	End Method

	Method RegisterJoinedPlayer()
		statusTitle = "Account 2 joined; registering it with the host..."
		eventSummary = "Both users now have local active-session views."
		Local players:TEOSProductUserId[] = [Peers[1].ProductUserId]
		If Not Sessions.RegisterPlayers(HOST_SESSION_NAME, players, Self) Then
			Fail("Player registration did not start", "EOS rejected the request.")
		End If
	End Method

	Method OnEOSSessionPlayersChanged(result:EEOSResult, operation:EEOSSessionOperation, changedCount:Int, sanctionedCount:Int) Override
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Fail("Session membership update failed", EOSResultString(result))
			Return
		End If

		If operation = EEOSSessionOperation.RegisterPlayers Then
			Local active:TEOSActiveSession
			result = Sessions.CopyActiveSession(HOST_SESSION_NAME, active)
			If result <> EEOSResult.Success Then
				Fail("Could not inspect the host session", EOSResultString(result))
				Return
			End If
			Local playerCount:UInt = active.RegisteredPlayerCount()
			active.Release()
			Print "Host registered players: " + playerCount
			If Sessions.IsUserInSession(HOST_SESSION_NAME, Peers[1].ProductUserId) <> EEOSResult.Success Then
				Fail("Account 2 was not found in the host session", "Registration completed without visible membership.")
				Return
			End If
			statusTitle = "Membership verified; unregistering account 2..."
			Local players:TEOSProductUserId[] = [Peers[1].ProductUserId]
			If Not Sessions.UnregisterPlayers(HOST_SESSION_NAME, players, Self) Then
				Fail("Player unregistration did not start", "EOS rejected the request.")
			End If
		Else If operation = EEOSSessionOperation.UnregisterPlayers Then
			statusTitle = "Account 2 left; cleaning up both local sessions..."
			CleanupStage = 1
			If Not Sessions.DestroySession(CLIENT_SESSION_NAME, Self) Then
				Fail("Client session cleanup did not start", "EOS rejected the request.")
			End If
		End If
	End Method

	Method RemoveSubscriptions()
		If InviteSubscription Then
			InviteSubscription.Remove()
		End If
	End Method

	Method Fail(title:String, detail:String)
		If done Then
			Return
		End If
		Print title + ": " + detail
		statusKind = 3
		statusTitle = title
		statusDetail = detail
		done = True
	End Method
End Type

Function ConfigValue:String(config:String, name:String)
	For Local line:String = EachIn config.Replace(Chr(13), "").Split("~n")
		line = line.Trim()
		If Not line Or line.StartsWith("#") Then
			Continue
		End If
		Local separator:Int = line.Find("=")
		If separator >= 0 And line[..separator].Trim() = name Then
			Return line[separator + 1..].Trim()
		End If
	Next
	Return ""
End Function

Function FindConfig:String()
	If AppArgs.Length > 1 And FileType(AppArgs[1]) = FILETYPE_FILE Then
		Return AppArgs[1]
	End If
	Local candidate:String = AppDir
	For Local depth:Int = 0 Until 8
		Local configPath:String = candidate + "/sdk.mod/examples/eos.local.conf"
		If FileType(configPath) = FILETYPE_FILE Then
			Return configPath
		End If
		Local parent:String = ExtractDir(candidate)
		If parent = candidate Then
			Exit
		End If
		candidate = parent
	Next
	Return ""
End Function

Function DrawScreen()
	Cls
	SetColor 22, 27, 38
	DrawRect 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT
	Select statusKind
		Case 2
			SetColor 75, 201, 126
		Case 3
			SetColor 235, 91, 91
		Default
			SetColor 75, 155, 235
	End Select
	DrawRect 0, 0, WINDOW_WIDTH, 9
	SetColor 245, 247, 250
	SetScale 1.35, 1.35
	DrawText statusTitle, 44, 62
	SetScale 1.0, 1.0
	SetColor 178, 187, 205
	DrawText statusDetail, 46, 116
	SetColor 49, 58, 76
	DrawRect 46, 164, WINDOW_WIDTH - 92, 150
	SetColor 212, 220, 234
	DrawText eventSummary, 70, 202
	If succeeded Then
		DrawText "Invitation delivery and cache lookup: verified", 70, 239
		DrawText "Join, registration, unregistration, and cleanup: verified", 70, 276
	Else If done Then
		DrawText "Check both credential names and the latest EOS log message.", 70, 239
	Else
		DrawText "The test runs entirely within this app; no IDs need to be copied.", 70, 239
	End If
	SetColor 130, 141, 160
	If latestLog Then
		DrawText latestLog[..Min(latestLog.Length, 110)], 46, 351
	End If
	If done Then
		DrawText "Press Escape to close.", 46, 405
	Else If pendingProductUser Then
		DrawText "Press C to create the Product User, or Escape to cancel.", 46, 405
	Else
		DrawText "Keep the Developer Authentication Tool open.", 46, 405
	End If
	Flip
End Function

Graphics WINDOW_WIDTH, WINDOW_HEIGHT, 0, 60, GRAPHICS_BACKBUFFER
SetClsColor 22, 27, 38

Local initialized:Int
Local platform:TEOSPlatform
Local test:TTwoUserSessionsTest
Local configPath:String = FindConfig()
If Not configPath Then
	statusKind = 3
	statusTitle = "eos.local.conf was not found"
	statusDetail = "Pass its full path as the first command-line argument."
	done = True
Else
	Local config:String = LoadText(configPath)
	Local firstCredential:String = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
	Local secondCredential:String = ConfigValue(config, "DEV_AUTH_CREDENTIAL_2")
	If AppArgs.Length > 2 Then
		secondCredential = AppArgs[2]
	End If
	If Not firstCredential Or Not secondCredential Then
		statusKind = 3
		statusTitle = "Two Developer Auth credentials are required"
		statusDetail = "Add DEV_AUTH_CREDENTIAL_2 to the local config, or pass it as argument 2."
		done = True
	Else If firstCredential = secondCredential Then
		statusKind = 3
		statusTitle = "The two credential names are identical"
		statusDetail = "Select two different accounts in the Developer Authentication Tool."
		done = True
	Else
		Local options:TEOSInitializeOptions = New TEOSInitializeOptions
		options.ProductName = "EOS Sessions Integration Test"
		options.ProductVersion = "0.22.0"
		Local result:EEOSResult = EOSInitialize(options)
		If result <> EEOSResult.Success Then
			statusKind = 3
			statusTitle = "EOS initialization failed"
			statusDetail = EOSResultString(result)
			done = True
		Else
			initialized = True
			TEOSLogging.SetListener(New TConsoleLogListener)
			TEOSLogging.SetLevel(EEOSLogCategory.AllCategories, EEOSLogLevel.Info)
			Local platformOptions:TEOSPlatformOptions = New TEOSPlatformOptions
			platformOptions.ProductId = ConfigValue(config, "PRODUCT_ID")
			platformOptions.SandboxId = ConfigValue(config, "SANDBOX_ID")
			platformOptions.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID")
			platformOptions.ClientId = ConfigValue(config, "CLIENT_ID")
			platformOptions.ClientSecret = ConfigValue(config, "CLIENT_SECRET")
			platformOptions.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")
			platform = TEOSPlatform.Create(platformOptions)
			If Not platform Then
				statusKind = 3
				statusTitle = "EOS platform creation failed"
				statusDetail = "Check the local product configuration."
				done = True
			Else
				test = New TTwoUserSessionsTest
				test.Platform = platform
				test.Auth = platform.Auth()
				test.Connect = platform.Connect()
				test.Sessions = platform.Sessions()
				test.DevAuthHost = ConfigValue(config, "DEV_AUTH_HOST")
				If Not test.Auth Or Not test.Connect Or Not test.Sessions Then
					test.Fail("Required EOS interfaces are unavailable", "Auth, Connect, and Sessions are required.")
				Else
					Local createMissing:Int = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
					Local first:TSessionsPeer = test.AddPeer(1, firstCredential, createMissing)
					test.AddPeer(2, secondCredential, createMissing)
					statusTitle = "Signing in both test accounts..."
					statusDetail = "Connecting account 1 first; account 2 will follow automatically."
					If Not first.Start(test.DevAuthHost) Then
						test.Fail("Account 1 login did not start", "Check the first credential name.")
					End If
				End If
			End If
		End If
	End If
End If

Local startedAt:Int = MilliSecs()
While Not KeyHit(KEY_ESCAPE) And Not AppTerminate()
	If platform Then
		platform.Tick()
	End If
	If test And Not done Then
		test.Tick()
	End If
	If pendingProductUser And KeyHit(KEY_C) Then
		test.CreateProductUser()
	End If
	If Not done And MilliSecs() - startedAt > 120000 Then
		test.Fail("The Sessions test timed out", "Check the Developer Authentication Tool and both accounts.")
	End If
	DrawScreen()
Wend

If test Then
	test.RemoveSubscriptions()
End If
If platform Then
	platform.Release()
End If
If initialized Then
	Local result:EEOSResult = EOSShutdown()
	If result <> EEOSResult.Success Then
		Print "EOS shutdown: " + EOSResultString(result)
	End If
End If
EndGraphics
