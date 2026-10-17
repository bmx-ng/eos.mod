' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

SuperStrict

Framework Max2D.SDL3RenderMax2D
Import EOS.SDK
Import BRL.FileSystem
Import BRL.PolledInput
Import BRL.StandardIO
Import BRL.TextStream

Const WINDOW_WIDTH:Int = 820
Const WINDOW_HEIGHT:Int = 460
Const TEST_SOCKET:String = "BmxEosP2PTest"

Global statusTitle:String = "Preparing the two-account P2P test..."
Global statusDetail:String = "Both accounts will sign in through the Developer Authentication Tool."
Global latestLog:String
Global eventSummary:String = "Waiting for both accounts to connect."
Global statusKind:Int
Global done:Int
Global succeeded:Int
Global pendingProductUser:Int

Type TConsoleLogListener Implements IEOSLogListener
	Method OnEOSLog(category:String, message:String, level:EEOSLogLevel)
		latestLog = category + ": " + message
	End Method
End Type

Type TP2PPeer Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSConnectCreateUserListener, IEOSP2PConnectionRequestListener, IEOSP2PConnectionEstablishedListener, IEOSP2PConnectionInterruptedListener, IEOSP2PConnectionClosedListener
	Field Manager:TP2PTest
	Field Number:Int
	Field Credential:String
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field P2P:TEOSP2P
	Field ProductUserId:TEOSProductUserId
	Field CreateMissingProductUser:Int
	Field ContinuanceToken:TEOSConnectContinuanceToken
	Field RequestSubscription:TEOSP2PConnectionRequestSubscription
	Field EstablishedSubscription:TEOSP2PConnectionEstablishedSubscription
	Field InterruptedSubscription:TEOSP2PConnectionInterruptedSubscription
	Field ClosedSubscription:TEOSP2PConnectionClosedSubscription
	Field RequestObserved:Int
	Field EstablishedObserved:Int
	Field ClosedObserved:Int

	Method Start:Int(host:String)
		Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
		credentials.Type = EEOSLoginCredentialType.Developer
		credentials.Id = host
		credentials.Token = Credential
		Local options:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
		options.Credentials = credentials
		' Match the permissions enabled for this EAS application. Requesting
		' basic_profile alone currently produces scope_not_found for a new user.
		options.ScopeFlags = EEOSAuthScopeFlags.BasicProfile | EEOSAuthScopeFlags.FriendsList | EEOSAuthScopeFlags.Presence
		Return Auth.Login(options, Self) <> Null
	End Method

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then
			Manager.Fail("Account " + Number + " Auth login failed", EOSResultString(result))
			Return
		End If

		Local accountId:TEOSEpicAccountId = selectedAccountId
		If Not accountId Then accountId = localUserId
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
		If Not Connect.Login(options, Self) Then Manager.Fail("Account " + Number + " Connect login failed", "EOS rejected the request.")
	End Method

	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			ProductUserId = localUserId
			Manager.PeerReady(Self)
			Return
		End If
		If result = EEOSResult.InvalidUser And continuanceToken And CreateMissingProductUser Then
			If Not Connect.CreateUser(continuanceToken, Self) Then Manager.Fail("Account " + Number + " Product User creation failed", "EOS rejected the request.")
		Else If result = EEOSResult.InvalidUser Then
			Self.ContinuanceToken = continuanceToken
			Manager.AskToCreateProductUser(Self)
		Else
			Manager.Fail("Account " + Number + " Connect login failed", EOSResultString(result))
		End If
	End Method

	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then
			Manager.Fail("Account " + Number + " Product User creation failed", EOSResultString(result))
			Return
		End If
		ProductUserId = localUserId
		ContinuanceToken = Null
		Manager.PeerReady(Self)
	End Method

	Method Subscribe:Int()
		RequestSubscription = P2P.AddNotifyConnectionRequest(ProductUserId, TEST_SOCKET, Self)
		EstablishedSubscription = P2P.AddNotifyConnectionEstablished(ProductUserId, TEST_SOCKET, Self)
		InterruptedSubscription = P2P.AddNotifyConnectionInterrupted(ProductUserId, TEST_SOCKET, Self)
		ClosedSubscription = P2P.AddNotifyConnectionClosed(ProductUserId, TEST_SOCKET, Self)
		Return RequestSubscription And EstablishedSubscription And InterruptedSubscription And ClosedSubscription
	End Method

	Method OnEOSP2PConnectionRequest(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String)
		RequestObserved = True
		If Number = 1 Then
			Local result:EEOSResult = P2P.AcceptConnection(ProductUserId, remoteUserId, TEST_SOCKET)
			If result <> EEOSResult.Success Then Manager.Fail("Could not accept the P2P connection", EOSResultString(result))
		End If
	End Method

	Method OnEOSP2PConnectionEstablished(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String, connectionType:EEOSConnectionEstablishedType, networkType:EEOSNetworkConnectionType)
		EstablishedObserved = True
		eventSummary = "Incoming request accepted; connection established."
	End Method

	Method OnEOSP2PConnectionInterrupted(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String)
		Manager.Fail("The P2P connection was interrupted", "EOS reported an interruption during the local test.")
	End Method

	Method OnEOSP2PConnectionClosed(localUserId:TEOSProductUserId, remoteUserId:TEOSProductUserId, socketName:String, reason:EEOSConnectionClosedReason)
		ClosedObserved = True
		Manager.CheckComplete()
	End Method

	Method RemoveSubscriptions()
		If RequestSubscription Then RequestSubscription.Remove()
		If EstablishedSubscription Then EstablishedSubscription.Remove()
		If InterruptedSubscription Then InterruptedSubscription.Remove()
		If ClosedSubscription Then ClosedSubscription.Remove()
	End Method
End Type

Type TP2PTest
	Field Platform:TEOSPlatform
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field P2P:TEOSP2P
	Field Peers:TP2PPeer[2]
	Field ReadyCount:Int
	Field DevAuthHost:String
	Field PingObserved:Int
	Field PongObserved:Int
	Field CloseStartedAt:Int
	Field PendingPeer:TP2PPeer

	Method AddPeer:TP2PPeer(number:Int, credential:String, createMissing:Int)
		Local peer:TP2PPeer = New TP2PPeer
		peer.Manager = Self
		peer.Number = number
		peer.Credential = credential
		peer.Auth = Auth
		peer.Connect = Connect
		peer.P2P = P2P
		peer.CreateMissingProductUser = createMissing
		Peers[number - 1] = peer
		Return peer
	End Method

	Method PeerReady(peer:TP2PPeer)
		pendingProductUser = False
		PendingPeer = Null
		ReadyCount :+ 1
		statusTitle = "Account " + peer.Number + " connected"
		statusDetail = "Product User: " + peer.ProductUserId.ToString()
		If ReadyCount = 1 Then
			statusTitle = "Account 1 connected; signing in account 2..."
			If Not Peers[1].Start(DevAuthHost) Then Fail("Account 2 login did not start", "Check the second credential name.")
			Return
		End If
		If Peers[0].ProductUserId.ToString() = Peers[1].ProductUserId.ToString() Then
			Fail("Both credentials selected the same account", "Use two different Developer Auth credentials.")
			Return
		End If
		If Not Peers[0].Subscribe() Or Not Peers[1].Subscribe() Then
			Fail("Could not register P2P notifications", "One or more EOS notification registrations failed.")
			Return
		End If
		statusTitle = "Sending a reliable P2P packet..."
		statusDetail = "Account 2 is connecting to account 1 through EOS."
		eventSummary = "Notifications registered for both Product Users."
		Local result:EEOSResult = Send(Peers[1], Peers[0], PacketData("PING"))
		If result <> EEOSResult.Success Then Fail("Could not send the PING packet", EOSResultString(result))
	End Method

	Method AskToCreateProductUser(peer:TP2PPeer)
		PendingPeer = peer
		pendingProductUser = True
		statusKind = 1
		statusTitle = "Account " + peer.Number + " needs a Product User"
		statusDetail = "Press C to create its EOS Product User and continue."
		eventSummary = "Epic login succeeded; EOS Connect needs explicit creation approval."
	End Method

	Method CreateProductUser()
		If Not PendingPeer Or Not PendingPeer.ContinuanceToken Then Return
		statusKind = 0
		statusTitle = "Creating account " + PendingPeer.Number + " Product User..."
		statusDetail = "EOS Connect will assign this account a Product User ID."
		pendingProductUser = False
		If Not PendingPeer.Connect.CreateUser(PendingPeer.ContinuanceToken, PendingPeer) Then
			Fail("Product User creation did not start", "EOS rejected the request.")
		End If
	End Method

	Method Send:EEOSResult(sender:TP2PPeer, receiver:TP2PPeer, data:Byte[])
		Local options:TEOSP2PSendOptions = New TEOSP2PSendOptions
		options.LocalUserId = sender.ProductUserId
		options.RemoteUserId = receiver.ProductUserId
		options.SocketName = TEST_SOCKET
		options.Channel = 0
		options.Data = data
		options.AllowDelayedDelivery = True
		options.Reliability = EEOSPacketReliability.ReliableOrdered
		Return P2P.SendPacket(options)
	End Method

	Method Update()
		If done Or ReadyCount < 2 Then Return
		For Local index:Int = 0 Until 2
			Local peer:TP2PPeer = Peers[index]
			Local packet:TEOSP2PPacket
			While P2P.ReceivePacket(peer.ProductUserId, -1, packet) = EEOSResult.Success
				If packet.SocketName <> TEST_SOCKET Or packet.Channel <> 0 Then Continue
				Local text:String = PacketText(packet.Data)
				If index = 0 And text = "PING" Then
					PingObserved = True
					eventSummary = "Account 1 received PING and sent PONG."
					Local result:EEOSResult = Send(Peers[0], Peers[1], PacketData("PONG"))
					If result <> EEOSResult.Success Then Fail("Could not send the PONG packet", EOSResultString(result))
				Else If index = 1 And text = "PONG" Then
					PongObserved = True
					eventSummary = "Reliable PING/PONG exchange completed; closing connection."
					Local result:EEOSResult = P2P.CloseConnection(Peers[1].ProductUserId, Peers[0].ProductUserId, TEST_SOCKET)
					If result <> EEOSResult.Success Then
						Fail("Could not close the P2P connection", EOSResultString(result))
					Else
						CloseStartedAt = MilliSecs()
					End If
				End If
			Wend
		Next
		CheckComplete()
		If CloseStartedAt And MilliSecs() - CloseStartedAt > 10000 Then Fail("P2P close notification timed out", "PING/PONG succeeded, but the close event did not arrive on both users.")
	End Method

	Method CheckComplete()
		If done Or Not PingObserved Or Not PongObserved Then Return
		If Not Peers[0].RequestObserved Or Not Peers[0].EstablishedObserved Or Not Peers[1].EstablishedObserved Then Return
		If Not Peers[0].ClosedObserved Or Not Peers[1].ClosedObserved Then Return
		statusKind = 2
		statusTitle = "EOS P2P test succeeded"
		statusDetail = "Two accounts exchanged PING/PONG and closed cleanly."
		eventSummary = "Request, established, packet, and closed notifications were observed."
		succeeded = True
		done = True
	End Method

	Method Fail(title:String, detail:String)
		If done Then Return
		statusKind = 3
		statusTitle = title
		statusDetail = detail
		done = True
	End Method
End Type

Function PacketData:Byte[](text:String)
	Local data:Byte[] = New Byte[text.Length]
	For Local index:Int = 0 Until text.Length
		data[index] = text[index]
	Next
	Return data
End Function

Function PacketText:String(data:Byte[])
	If Not data Then Return ""
	Local text:String
	For Local value:Byte = EachIn data
		text :+ Chr(value)
	Next
	Return text
End Function

Function ConfigValue:String(config:String, name:String)
	For Local line:String = EachIn config.Replace(Chr(13), "").Split("~n")
		line = line.Trim()
		If Not line Or line.StartsWith("#") Then Continue
		Local separator:Int = line.Find("=")
		If separator < 0 Then Continue
		If line[..separator].Trim() = name Then Return line[separator + 1..].Trim()
	Next
	Return ""
End Function

Function FindConfig:String()
	If AppArgs.Length > 1 And FileType(AppArgs[1]) = FILETYPE_FILE Then Return RealPath(AppArgs[1])
	Local candidate:String = RealPath(AppDir)
	For Local level:Int = 0 Until 8
		Local configPath:String = candidate + "/sdk.mod/examples/eos.local.conf"
		If FileType(configPath) = FILETYPE_FILE Then Return configPath
		Local parent:String = ExtractDir(candidate)
		If parent = candidate Then Exit
		candidate = parent
	Next
	Return ""
End Function

Function DrawScreen()
	Cls
	SetColor 22, 27, 38
	DrawRect 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT
	Select statusKind
		Case 2 SetColor 75, 201, 126
		Case 3 SetColor 235, 91, 91
		Default SetColor 75, 155, 235
	End Select
	DrawRect 0, 0, WINDOW_WIDTH, 9
	SetColor 245, 247, 250
	SetScale 1.45, 1.45
	DrawText statusTitle, 44, 65
	SetScale 1.0, 1.0
	SetColor 178, 187, 205
	DrawText statusDetail, 46, 120
	SetColor 49, 58, 76
	DrawRect 46, 168, WINDOW_WIDTH - 92, 150
	SetColor 212, 220, 234
	DrawText eventSummary, 70, 205
	If succeeded Then
		DrawText "Reliable ordered packets: PING -> PONG", 70, 242
		DrawText "Connection request, establishment, and closure: verified", 70, 279
	Else If done Then
		DrawText "Check both credential names and the latest EOS log message.", 70, 242
	Else
		DrawText "The test runs entirely within this app; no IDs need to be copied.", 70, 242
	End If
	SetColor 130, 141, 160
	If latestLog Then DrawText latestLog[..Min(latestLog.Length, 105)], 46, 355
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
Local test:TP2PTest
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
	If AppArgs.Length > 2 Then secondCredential = AppArgs[2]
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
		options.ProductName = "EOS P2P Integration Test"
		options.ProductVersion = "0.17.0"
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
				test = New TP2PTest
				test.Platform = platform
				test.Auth = platform.Auth()
				test.Connect = platform.Connect()
				test.P2P = platform.P2P()
				test.DevAuthHost = ConfigValue(config, "DEV_AUTH_HOST")
				If Not test.Auth Or Not test.Connect Or Not test.P2P Then
					test.Fail("Required EOS interfaces are unavailable", "Auth, Connect, and P2P are required.")
				Else
					Local createMissing:Int = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
					Local first:TP2PPeer = test.AddPeer(1, firstCredential, createMissing)
					Local second:TP2PPeer = test.AddPeer(2, secondCredential, createMissing)
					statusTitle = "Signing in both test accounts..."
					statusDetail = "Connecting account 1 first; account 2 will follow automatically."
					If Not first.Start(ConfigValue(config, "DEV_AUTH_HOST")) Then test.Fail("Account 1 login did not start", "Check the first credential name.")
				End If
			End If
		End If
	End If
End If

Local startedAt:Int = MilliSecs()
While Not KeyHit(KEY_ESCAPE) And Not AppTerminate()
	If platform Then platform.Tick()
	If test Then test.Update()
	If pendingProductUser And KeyHit(KEY_C) Then test.CreateProductUser()
	If Not done And MilliSecs() - startedAt > 120000 Then test.Fail("The P2P test timed out", "Check the Developer Authentication Tool and both accounts.")
	DrawScreen()
Wend

If test Then
	For Local peer:TP2PPeer = EachIn test.Peers
		If peer Then peer.RemoveSubscriptions()
	Next
End If
If platform Then platform.Release()
If initialized Then
	Local result:EEOSResult = EOSShutdown()
	If result <> EEOSResult.Success Then Print "EOS shutdown: " + EOSResultString(result)
End If
EndGraphics
