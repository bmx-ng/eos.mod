SuperStrict

Framework Max2D.SDL3RenderMax2D
Import EOS.SDK
Import BRL.FileSystem
Import BRL.PolledInput
Import BRL.StandardIO
Import BRL.TextStream

Const SESSION_NAME:String = "EOS SDK Sessions Test"
Const SESSION_BUCKET:String = "eos-sdk-sessions-test"

Global sessionStatus:String = "Starting the managed EOS login..."
Global sessionDetail:String = "Waiting for a Product User."
Global sessionDone:Int
Global sessionSuccess:Int

Type TSessionsFlow Extends TEOSSessionListener Implements IEOSSessionUpdateListener, IEOSSessionOperationListener, IEOSSessionSearchListener
	Field Platform:TEOSPlatform
	Field LoginSession:TEOSSessionCoordinator
	Field Sessions:TEOSSessions
	Field LocalUserId:TEOSProductUserId
	Field Search:TEOSSessionSearch
	Field CreateMissingProductUser:Int
	Field SearchAt:Int
	Field SearchAttempts:Int
	Field UpdateStage:Int

	Method OnEOSSessionStateChanged(state:EEOSSessionState) Override
		Print "Login state: " + Int(state)
	End Method

	Method OnEOSSessionProductUserCreationRequired() Override
		If CreateMissingProductUser Then
			sessionStatus = "Creating the missing Product User..."
			If Not LoginSession.CreateProductUser() Then
				Fail("Product User creation could not start.")
			End If
		Else
			sessionStatus = "Product User creation requires approval."
			sessionDetail = "Set CREATE_MISSING_PRODUCT_USER=1 to approve it."
			LoginSession.CancelProductUserCreation()
		End If
	End Method

	Method OnEOSSessionReady(accountId:TEOSEpicAccountId, userId:TEOSProductUserId) Override
		LocalUserId = userId
		Sessions = Platform.Sessions()
		If Not Sessions Then
			Fail("The EOS Sessions interface is unavailable.")
			Return
		End If
		CreateAdvertisedSession()
	End Method

	Method OnEOSSessionError(result:EEOSResult, recoverable:Int) Override
		If Not recoverable Then
			Fail("Login failed: " + EOSResultString(result))
		End If
	End Method

	Method CreateAdvertisedSession()
		sessionStatus = "Creating a public searchable session..."
		sessionDetail = "Publishing bucket, game mode, build, and host information."
		Local options:TEOSSessionCreateOptions = New TEOSSessionCreateOptions
		options.SessionName = SESSION_NAME
		options.BucketId = SESSION_BUCKET
		options.MaxPlayers = 4
		options.LocalUserId = LocalUserId
		options.SanctionsEnabled = True

		Local modification:TEOSSessionModification
		Local result:EEOSResult = Sessions.CreateSessionModification(options, modification)
		If result <> EEOSResult.Success Then
			Fail("Create modification failed: " + EOSResultString(result))
			Return
		End If

		result = modification.SetPermissionLevel(EEOSOnlineSessionPermissionLevel.PublicAdvertised)
		If result = EEOSResult.Success Then
			result = modification.SetJoinInProgressAllowed(True)
		End If
		If result = EEOSResult.Success Then
			result = modification.SetInvitesAllowed(True)
		End If
		If result = EEOSResult.Success Then
			result = modification.SetHostAddress("eos-p2p")
		End If
		If result = EEOSResult.Success Then
			result = modification.AddStringAttribute("game_mode", "example")
		End If
		If result = EEOSResult.Success Then
			result = modification.AddIntAttribute("build", 1)
		End If
		If result <> EEOSResult.Success Then
			modification.Release()
			Fail("Configure session failed: " + EOSResultString(result))
			Return
		End If

		If Not Sessions.UpdateSession(modification, Self) Then
			modification.Release()
			Fail("The session update could not start.")
			Return
		End If
		modification.Release()
	End Method

	Method OnEOSSessionUpdated(result:EEOSResult, sessionName:String, sessionId:String) Override
		Print "Update session: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Fail("Publish failed: " + EOSResultString(result))
			Return
		End If

		If UpdateStage = 0 Then
			Print "Session ID: " + sessionId
			InspectActiveSession()
			UpdateStage = 1
			UpdatePublishedSession()
			Return
		End If

		Print "Published session update succeeded."
		InspectActiveSession()
		Local dumpResult:EEOSResult = Sessions.DumpSessionState(SESSION_NAME)
		Print "Dump session state: " + EOSResultString(dumpResult)
		If dumpResult <> EEOSResult.Success Then
			Fail("Session state dump failed: " + EOSResultString(dumpResult))
			Return
		End If
		sessionStatus = "Session published; waiting for search indexing..."
		sessionDetail = "The updated capacity and attributes will be verified through search."
		SearchAt = MilliSecs() + 5000
	End Method

	Method UpdatePublishedSession()
		sessionStatus = "Updating the published session..."
		sessionDetail = "Changing its capacity and adding a searchable map attribute."
		Local modification:TEOSSessionModification
		Local result:EEOSResult = Sessions.UpdateSessionModification(SESSION_NAME, modification)
		If result <> EEOSResult.Success Then
			Fail("Create update modification failed: " + EOSResultString(result))
			Return
		End If

		result = modification.SetMaxPlayers(6)
		If result = EEOSResult.Success Then
			result = modification.AddIntAttribute("build", 2)
		End If
		If result = EEOSResult.Success Then
			result = modification.AddStringAttribute("map", "test-map")
		End If
		If result <> EEOSResult.Success Then
			modification.Release()
			Fail("Configure published session update failed: " + EOSResultString(result))
			Return
		End If

		If Not Sessions.UpdateSession(modification, Self) Then
			modification.Release()
			Fail("The published session update could not start.")
			Return
		End If
		modification.Release()
	End Method

	Method Tick()
		If SearchAt And MilliSecs() >= SearchAt Then
			SearchAt = 0
			FindPublishedSession()
		End If
	End Method

	Method FindPublishedSession()
		SearchAttempts :+ 1
		sessionStatus = "Searching for the published session..."
		sessionDetail = "Search attempt " + SearchAttempts + " of 5."
		If Search Then
			Search.Release()
			Search = Null
		End If
		Local result:EEOSResult = Sessions.CreateSearch(20, Search)
		If result <> EEOSResult.Success Then
			Fail("Create search failed: " + EOSResultString(result))
			Return
		End If
		result = Search.SetStringParameter(EOS_SESSIONS_SEARCH_BUCKET_ID, SESSION_BUCKET)
		If result <> EEOSResult.Success Then
			Fail("Set bucket filter failed: " + EOSResultString(result))
			Return
		End If
		result = Search.SetStringParameter("game_mode", "example")
		If result <> EEOSResult.Success Then
			Fail("Set game-mode filter failed: " + EOSResultString(result))
			Return
		End If
		If Not Search.Find(LocalUserId, Self) Then
			Fail("The session search could not start.")
		End If
	End Method

	Method OnEOSSessionSearch(result:EEOSResult) Override
		Print "Session search: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Fail("Search failed: " + EOSResultString(result))
			Return
		End If

		Local count:UInt = Search.ResultCount()
		Print "Search results: " + count
		If count = 0 Then
			If SearchAttempts < 5 Then
				sessionStatus = "The session is still being indexed..."
				sessionDetail = "EOS returned no matches; retrying in three seconds."
				SearchAt = MilliSecs() + 3000
				Return
			End If
			Fail("The new session was not found after five searches.")
			Return
		End If

		Local details:TEOSSessionDetails
		result = Search.CopyResultByIndex(0, details)
		If result <> EEOSResult.Success Then
			Fail("Copy search result failed: " + EOSResultString(result))
			Return
		End If
		Local info:TEOSSessionInfo
		result = details.CopyInfo(info)
		If result = EEOSResult.Success Then
			Print "Found session: " + info.SessionId
			Print "Bucket: " + info.BucketId
			Print "Host address: " + info.HostAddress
			Print "Open slots: " + info.OpenPublicConnections + "/" + info.MaxPlayers
			For Local index:UInt = 0 Until details.AttributeCount()
				Local attribute:TEOSSessionAttribute
				If details.CopyAttributeByIndex(index, attribute) = EEOSResult.Success Then
					PrintAttribute(attribute)
				End If
			Next
			If info.MaxPlayers <> 6 Then
				result = EEOSResult.UnexpectedError
			Else
				Local buildAttribute:TEOSSessionAttribute
				result = details.CopyAttributeByKey("build", buildAttribute)
				If result = EEOSResult.Success And ..
					(buildAttribute.ValueType <> EEOSSessionAttributeType.Int64 Or ..
					buildAttribute.IntValue <> 2) Then
					result = EEOSResult.UnexpectedError
				End If
			End If
			If result = EEOSResult.Success Then
				Local mapAttribute:TEOSSessionAttribute
				result = details.CopyAttributeByKey("map", mapAttribute)
				If result = EEOSResult.Success And ..
					(mapAttribute.ValueType <> EEOSSessionAttributeType.StringValue Or ..
					mapAttribute.StringValue <> "test-map") Then
					result = EEOSResult.UnexpectedError
				End If
			End If
		End If
		details.Release()
		If result <> EEOSResult.Success Then
			Fail("Copy session info failed: " + EOSResultString(result))
			Return
		End If

		sessionStatus = "Session found; starting the match..."
		sessionDetail = "The same session will then be ended and removed."
		If Not Sessions.StartSession(SESSION_NAME, Self) Then
			Fail("The session start could not begin.")
		End If
	End Method

	Method OnEOSSessionOperation(result:EEOSResult, operation:EEOSSessionOperation) Override
		Print "Session operation " + Int(operation) + ": " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Fail("Session operation failed: " + EOSResultString(result))
			Return
		End If

		Select operation
			Case EEOSSessionOperation.StartSession
				sessionStatus = "Session started; ending the match..."
				InspectActiveSession()
				If Not Sessions.EndSession(SESSION_NAME, Self) Then
					Fail("The session end could not begin.")
				End If
			Case EEOSSessionOperation.EndSession
				sessionStatus = "Session ended; destroying it..."
				If Not Sessions.DestroySession(SESSION_NAME, Self) Then
					Fail("The session destruction could not begin.")
				End If
			Case EEOSSessionOperation.DestroySession
				sessionStatus = "EOS Sessions lifecycle succeeded."
				sessionDetail = "Published, updated, searched, inspected, started, ended, and destroyed."
				sessionSuccess = True
				sessionDone = True
		End Select
	End Method

	Method InspectActiveSession()
		Local active:TEOSActiveSession
		Local result:EEOSResult = Sessions.CopyActiveSession(SESSION_NAME, active)
		Print "Copy active session: " + EOSResultString(result)
		If result <> EEOSResult.Success Then
			Return
		End If
		Local info:TEOSActiveSessionInfo
		result = active.CopyInfo(info)
		If result = EEOSResult.Success Then
			Print "Active state: " + Int(info.State)
			Print "Registered players: " + active.RegisteredPlayerCount()
		End If
		active.Release()
	End Method

	Method Fail(message:String)
		Print message
		sessionStatus = message
		sessionDetail = "Enable the Sessions action in the client policy if permission was denied."
		sessionDone = True
	End Method
End Type

Function PrintAttribute(attribute:TEOSSessionAttribute)
	Select attribute.ValueType
		Case EEOSSessionAttributeType.Boolean
			Print "Attribute: " + attribute.Key + " = " + attribute.BoolValue
		Case EEOSSessionAttributeType.Int64
			Print "Attribute: " + attribute.Key + " = " + attribute.IntValue
		Case EEOSSessionAttributeType.DoubleValue
			Print "Attribute: " + attribute.Key + " = " + attribute.DoubleValue
		Case EEOSSessionAttributeType.StringValue
			Print "Attribute: " + attribute.Key + " = " + attribute.StringValue
	End Select
End Function

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

AppTitle = "EOS Sessions"
Graphics 860, 240, 0, 60, GRAPHICS_BACKBUFFER
SetClsColor 22, 27, 38

Local configPath:String = "eos.local.conf"
If AppArgs.Length > 1 Then
	configPath = AppArgs[1]
End If
If FileType(configPath) <> FILETYPE_FILE Then
	RuntimeError "Copy eos.local.conf.example to eos.local.conf and fill in your EOS values."
End If
Local config:String = LoadText(configPath)

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS Sessions example"
initializeOptions.ProductVersion = "0.23.0"
Local result:EEOSResult = EOSInitialize(initializeOptions)
If result <> EEOSResult.Success Then
	RuntimeError "EOS initialization failed: " + EOSResultString(result)
End If

Local platformOptions:TEOSPlatformOptions = New TEOSPlatformOptions
platformOptions.ProductId = ConfigValue(config, "PRODUCT_ID")
platformOptions.SandboxId = ConfigValue(config, "SANDBOX_ID")
platformOptions.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID")
platformOptions.ClientId = ConfigValue(config, "CLIENT_ID")
platformOptions.ClientSecret = ConfigValue(config, "CLIENT_SECRET")
platformOptions.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")
Local platform:TEOSPlatform = TEOSPlatform.Create(platformOptions)
If Not platform Then
	RuntimeError "EOS platform creation failed."
End If

Local flow:TSessionsFlow = New TSessionsFlow
flow.Platform = platform
flow.CreateMissingProductUser = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
Local loginSession:TEOSSessionCoordinator = TEOSSessionCoordinator.Create(platform, flow)
If Not loginSession Then
	RuntimeError "Could not create the managed EOS login session."
End If
flow.LoginSession = loginSession

Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
credentials.Type = EEOSLoginCredentialType.Developer
credentials.Id = ConfigValue(config, "DEV_AUTH_HOST")
credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
Local login:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
login.Credentials = credentials
Local sessionOptions:TEOSSessionOptions = New TEOSSessionOptions
sessionOptions.LoginOptions = login
If Not loginSession.Start(sessionOptions) Then
	RuntimeError "Could not start the managed EOS login session."
End If

Local started:Int = MilliSecs()
While Not AppTerminate() And Not KeyHit(KEY_ESCAPE)
	loginSession.Tick()
	flow.Tick()
	If Not sessionDone And MilliSecs() - started >= 120000 Then
		flow.Fail("The EOS Sessions test timed out.")
	End If

	Cls
	SetColor 238, 242, 255
	DrawText "EOS searchable game sessions", 24, 28
	SetColor 170, 184, 210
	DrawText sessionStatus, 24, 78
	DrawText sessionDetail, 24, 114
	DrawText "Press Escape or close the window to exit.", 24, 184
	Flip
Wend

If flow.Search Then
	flow.Search.Release()
End If
If loginSession.IsUsable() Then
	loginSession.Logout()
	Local logoutStarted:Int = MilliSecs()
	While loginSession.State() <> EEOSSessionState.Stopped And MilliSecs() - logoutStarted < 5000
		loginSession.Tick()
		Delay 16
	Wend
End If

loginSession.Release()
platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then
	RuntimeError "EOS shutdown failed: " + EOSResultString(result)
End If
EndGraphics
