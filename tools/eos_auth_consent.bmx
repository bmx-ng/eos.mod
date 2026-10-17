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

Global statusTitle:String = "Preparing Epic Account Portal..."
Global statusDetail:String = "EOS will present the sign-in and consent flow."
Global verificationURI:String
Global userCode:String
Global statusKind:Int
Global done:Int
Global succeeded:Int
Global latestLog:String
Global pendingProductUser:Int
Global writeMode:Int
Global displayedFriendCount:Int
Global displayedBlockedUserCount:Int

Type TConsoleLogListener Implements IEOSLogListener
	Method OnEOSLog(category:String, message:String, level:EEOSLogLevel)
		latestLog = category + ": " + message
	End Method
End Type

Type TAuthConnectListener Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSConnectCreateUserListener, IEOSStatsQueryListener, IEOSStatsIngestListener, IEOSAchievementsQueryDefinitionsListener, IEOSAchievementsQueryPlayerListener, IEOSAchievementsUnlockedListener, IEOSLeaderboardsQueryDefinitionsListener, IEOSLeaderboardsQueryRanksListener, IEOSUserInfoQueryListener, IEOSFriendsQueryListener
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field UserInfo:TEOSUserInfoInterface
	Field Friends:TEOSFriends
	Field Stats:TEOSStats
	Field Achievements:TEOSAchievements
	Field Leaderboards:TEOSLeaderboards
	Field CreateMissingProductUser:Int
	Field ContinuanceToken:TEOSConnectContinuanceToken
	Field ProductUserId:TEOSProductUserId
	Field StatsCount:Int
	Field DefinitionCount:Int
	Field PlayerAchievementCount:Int
	Field LeaderboardCount:Int
	Field RecordCount:Int
	Field EpicAccountId:TEOSEpicAccountId
	Field ProfileDisplayName:String
	Field FriendCount:Int
	Field BlockedUserCount:Int
	Field WriteTest:Int
	Field RefreshStage:Int
	Field RefreshAt:Int
	Field RefreshAttempts:Int
	Field TestStatName:String
	Field TestAchievementId:String
	Field TestThreshold:Int
	Field TestCurrentValue:Int
	Field TestProgress:Double
	Field TestLeaderboardId:String
	Field TestAggregation:EEOSLeaderboardAggregation
	Field StatObserved:Int
	Field UnlockObserved:Int
	Field UnlockedSubscription:TEOSAchievementsUnlockedSubscription

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
		If pinGrantInfo Then
			statusKind = 1
			statusTitle = "Complete sign-in in your browser"
			verificationURI = pinGrantInfo.VerificationURIComplete
			If Not verificationURI Then verificationURI = pinGrantInfo.VerificationURI
			userCode = pinGrantInfo.UserCode
			statusDetail = "EOS supplied a browser verification step."
		End If

		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			statusKind = 1
			statusTitle = "Epic account authenticated"
			statusDetail = "Checking the permitted Basic Profile fields..."
			EpicAccountId = selectedAccountId
			If Not EpicAccountId Then EpicAccountId = localUserId
			If Not UserInfo.Query(EpicAccountId, EpicAccountId, Self) Then Fail("Could not start User Info query", EEOSResult.InvalidState)
		Else
			Fail("Epic account sign-in did not complete", result)
		End If
	End Method

	Method OnEOSUserInfoQuery(result:EEOSResult, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Fail("User Info query failed", result); Return
		Local info:TEOSUserInfoData
		result = UserInfo.CopyUserInfo(localUserId, targetUserId, info)
		If result <> EEOSResult.Success Then Fail("Could not copy User Info", result); Return
		ProfileDisplayName = info.DisplayName
		statusTitle = "Epic profile retrieved"
		statusDetail = ProfileDisplayName + " | Checking friends and blocked users..."
		If Not Friends.Query(EpicAccountId, Self) Then Fail("Could not start Friends query", EEOSResult.InvalidState)
	End Method

	Method OnEOSFriendsQuery(result:EEOSResult, localUserId:TEOSEpicAccountId)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Fail("Friends query failed", result); Return
		FriendCount = Friends.FriendCount(localUserId)
		BlockedUserCount = Friends.BlockedUserCount(localUserId)
		displayedFriendCount = FriendCount
		displayedBlockedUserCount = BlockedUserCount
		statusTitle = "Epic friends retrieved"
		statusDetail = "Friends " + FriendCount + " | Blocked " + BlockedUserCount + " | Continuing to EOS Connect..."
		BeginConnect()
	End Method

	Method BeginConnect()
		Local idToken:TEOSAuthIdToken
		Local result:EEOSResult = Auth.CopyIdToken(EpicAccountId, idToken)
		If result <> EEOSResult.Success Then Fail("Could not copy Epic ID token", result); Return
		Local credentials:TEOSConnectCredentials = New TEOSConnectCredentials
		credentials.Type = EEOSExternalCredentialType.EpicIdToken
		credentials.Token = idToken.JsonWebToken
		Local options:TEOSConnectLoginOptions = New TEOSConnectLoginOptions
		options.Credentials = credentials
		If Not Connect.Login(options, Self) Then Fail("Could not start Connect login", EEOSResult.InvalidState)
	End Method

	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Complete(localUserId)
			Return
		End If

		If result = EEOSResult.InvalidUser And continuanceToken Then
			Self.ContinuanceToken = continuanceToken
			If CreateMissingProductUser Then
				CreateProductUser()
			Else
				pendingProductUser = True
				statusKind = 1
				statusTitle = "Connect needs a Product User"
				statusDetail = "Press C to create it, or Escape to leave it unchanged."
			End If
		Else
			Fail("EOS Connect login failed", result)
		End If
	End Method

	Method CreateProductUser()
		If Not ContinuanceToken Then Return
		pendingProductUser = False
		statusKind = 1
		statusTitle = "Creating Product User..."
		statusDetail = "This links the Epic account to this EOS product."
		If Not Connect.CreateUser(ContinuanceToken, Self) Then
			statusKind = 3
			statusTitle = "Could not start Product User creation"
			statusDetail = "The EOS Connect interface rejected the request."
			done = True
		End If
	End Method

	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Complete(localUserId)
		Else
			Fail("Product User creation failed", result)
		End If
	End Method

	Method Complete(localUserId:TEOSProductUserId)
		ProductUserId = localUserId
		If WriteTest Then UnlockedSubscription = Achievements.AddNotifyAchievementsUnlocked(Self)
		statusKind = 1
		statusTitle = "Checking Stats..."
		statusDetail = "Querying all configured stats without changing them."
		Local options:TEOSStatsQueryOptions = New TEOSStatsQueryOptions
		options.LocalUserId = localUserId
		options.TargetUserId = localUserId
		If Not Stats.Query(options, Self) Then Fail("Could not start Stats query", EEOSResult.InvalidState)
	End Method

	Method OnEOSStatsQuery(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Fail("Stats query failed", result); Return
		StatsCount = Stats.StatsCount(targetUserId)
		If RefreshStage Then
			Local stat:TEOSStat
			If Stats.CopyStatByName(targetUserId, TestStatName, stat) = EEOSResult.Success Then
				StatObserved = True
				TestCurrentValue = stat.Value
			End If
			Local playerOptions:TEOSAchievementsQueryPlayerOptions = New TEOSAchievementsQueryPlayerOptions
			playerOptions.LocalUserId = ProductUserId
			playerOptions.TargetUserId = ProductUserId
			If Not Achievements.QueryPlayerAchievements(playerOptions, Self) Then Fail("Could not refresh player achievements", EEOSResult.InvalidState)
			Return
		End If
		statusTitle = "Checking Achievements..."
		statusDetail = "Stats succeeded; querying achievement definitions."
		Local options:TEOSAchievementsQueryDefinitionsOptions = New TEOSAchievementsQueryDefinitionsOptions
		options.LocalUserId = ProductUserId
		If Not Achievements.QueryDefinitions(options, Self) Then Fail("Could not query Achievements", EEOSResult.InvalidState)
	End Method

	Method OnEOSAchievementsQueryDefinitions(result:EEOSResult)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Fail("Achievement definitions failed", result); Return
		DefinitionCount = Achievements.DefinitionCount()
		If DefinitionCount > 0 Then
			Local definition:TEOSAchievementDefinition
			If Achievements.CopyDefinitionByIndex(0, definition) = EEOSResult.Success Then
				TestAchievementId = definition.AchievementId
				If definition.StatThresholds And definition.StatThresholds.Length > 0 Then
					TestStatName = definition.StatThresholds[0].Name
					TestThreshold = definition.StatThresholds[0].Threshold
				End If
			End If
		End If
		Local options:TEOSAchievementsQueryPlayerOptions = New TEOSAchievementsQueryPlayerOptions
		options.LocalUserId = ProductUserId
		options.TargetUserId = ProductUserId
		If Not Achievements.QueryPlayerAchievements(options, Self) Then Fail("Could not query player achievements", EEOSResult.InvalidState)
	End Method

	Method OnEOSAchievementsQueryPlayer(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Fail("Player achievements failed", result); Return
		PlayerAchievementCount = Achievements.PlayerAchievementCount(targetUserId)
		If TestAchievementId Then
			Local achievement:TEOSPlayerAchievement
			If Achievements.CopyPlayerAchievementById(localUserId, targetUserId, TestAchievementId, achievement) = EEOSResult.Success Then
				TestProgress = achievement.Progress
				If achievement.UnlockTime <> EOS_ACHIEVEMENTS_UNLOCKTIME_UNDEFINED Then UnlockObserved = True
				For Local statInfo:TEOSPlayerAchievementStatInfo = EachIn achievement.StatInfo
					If statInfo.Name = TestStatName Then TestCurrentValue = statInfo.CurrentValue
				Next
			End If
		End If
		If RefreshStage Then
			If TestLeaderboardId Then
				If Not Leaderboards.QueryRanks(ProductUserId, TestLeaderboardId, Self) Then Fail("Could not refresh leaderboard ranks", EEOSResult.InvalidState)
			Else
				EvaluateWriteTest()
			End If
			Return
		End If
		statusTitle = "Checking Leaderboards..."
		statusDetail = "Achievements succeeded; querying leaderboard definitions."
		Local options:TEOSLeaderboardsQueryDefinitionsOptions = New TEOSLeaderboardsQueryDefinitionsOptions
		options.LocalUserId = ProductUserId
		If Not Leaderboards.QueryDefinitions(options, Self) Then Fail("Could not query Leaderboards", EEOSResult.InvalidState)
	End Method

	Method OnEOSLeaderboardsQueryDefinitions(result:EEOSResult)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Fail("Leaderboard definitions failed", result); Return
		LeaderboardCount = Leaderboards.DefinitionCount()
		If LeaderboardCount > 0 Then
			For Local index:Int = 0 Until LeaderboardCount
				Local definition:TEOSLeaderboardDefinition
				result = Leaderboards.CopyDefinitionByIndex(index, definition)
				If result <> EEOSResult.Success Then Fail("Could not copy leaderboard definition", result); Return
				If Not TestLeaderboardId Or definition.StatName = TestStatName Then
					TestLeaderboardId = definition.LeaderboardId
					TestAggregation = definition.Aggregation
				End If
			Next
			If Not Leaderboards.QueryRanks(ProductUserId, TestLeaderboardId, Self) Then Fail("Could not query leaderboard ranks", EEOSResult.InvalidState)
		Else
			FinishServiceChecks()
		End If
	End Method

	Method OnEOSLeaderboardsQueryRanks(result:EEOSResult, leaderboardId:String)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Fail("Leaderboard ranks failed", result); Return
		RecordCount = Leaderboards.RecordCount()
		If RefreshStage Then EvaluateWriteTest() Else FinishServiceChecks()
	End Method

	Method FinishServiceChecks()
		If WriteTest Then
			If Not TestStatName Or TestThreshold <= 0 Then Fail("No achievement stat threshold found", EEOSResult.NotFound); Return
			Local amount:Int = TestThreshold
			If TestAggregation = EEOSLeaderboardAggregation.Sum Then amount = TestThreshold - TestCurrentValue
			If amount <= 0 Then amount = 1
			Local data:TEOSStatsIngestData = New TEOSStatsIngestData
			data.Name = TestStatName
			data.IngestAmount = amount
			Local options:TEOSStatsIngestOptions = New TEOSStatsIngestOptions
			options.LocalUserId = ProductUserId
			options.TargetUserId = ProductUserId
			options.Stats = [data]
			statusKind = 1
			statusTitle = "Ingesting test stat..."
			statusDetail = TestStatName + " +" + amount + " toward " + TestAchievementId
			If Not Stats.Ingest(options, Self) Then Fail("Could not start stat ingest", EEOSResult.InvalidState)
			Return
		End If
		succeeded = True
		done = True
		statusKind = 2
		statusTitle = "EOS service checks completed"
		statusDetail = ProfileDisplayName + " | Friends " + FriendCount + " | Stats " + StatsCount + " | Achievements " + PlayerAchievementCount + "/" + DefinitionCount + " | Leaderboards " + RecordCount + "/" + LeaderboardCount
	End Method

	Method OnEOSStatsIngest(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Fail("Stat ingest failed", result); Return
		RefreshStage = True
		RefreshAttempts = 0
		ScheduleRefresh()
	End Method

	Method OnEOSAchievementUnlocked(userId:TEOSProductUserId, achievementId:String, unlockTime:Long)
		If achievementId = TestAchievementId Then UnlockObserved = True
	End Method

	Method ScheduleRefresh()
		RefreshAt = MilliSecs() + 3000
		statusKind = 1
		statusTitle = "Waiting for EOS processing..."
		statusDetail = "Attempt " + (RefreshAttempts + 1) + ": stat, achievement, and rank will be queried again."
	End Method

	Method Update()
		If Not RefreshAt Or MilliSecs() < RefreshAt Then Return
		RefreshAt = 0
		RefreshAttempts :+ 1
		Local options:TEOSStatsQueryOptions = New TEOSStatsQueryOptions
		options.LocalUserId = ProductUserId
		options.TargetUserId = ProductUserId
		options.StatNames = [TestStatName]
		If Not Stats.Query(options, Self) Then Fail("Could not refresh Stats", EEOSResult.InvalidState)
	End Method

	Method EvaluateWriteTest()
		If StatObserved And (UnlockObserved Or TestProgress >= 1.0) And (Not TestLeaderboardId Or RecordCount > 0) Then
			succeeded = True
			done = True
			statusKind = 2
			statusTitle = "EOS write pipeline completed"
			statusDetail = TestStatName + "=" + TestCurrentValue + " | Achievement " + (TestProgress * 100.0) + "% | Rank records " + RecordCount
			Return
		End If
		If RefreshAttempts >= 20 Then
			done = True
			statusKind = 3
			statusTitle = "EOS backend processing is still pending"
			statusDetail = TestStatName + "=" + TestCurrentValue + " | Achievement " + (TestProgress * 100.0) + "% | Rank records " + RecordCount
		Else
			ScheduleRefresh()
		End If
	End Method

	Method Fail(title:String, result:EEOSResult)
		done = True
		statusKind = 3
		statusTitle = title
		statusDetail = EOSResultString(result)
	End Method
End Type

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
	For Local level:Int = 0 Until 9
		Local configPath:String = candidate + "/sdk.mod/examples/eos.local.conf"
		If FileType(configPath) = FILETYPE_FILE Then Return configPath
		Local parent:String = ExtractDir(candidate)
		If parent = candidate Then Exit
		candidate = parent
	Next

	candidate = RealPath(CurrentDir())
	For Local level:Int = 0 Until 5
		Local configPath:String = candidate + "/sdk.mod/examples/eos.local.conf"
		If FileType(configPath) = FILETYPE_FILE Then Return configPath
		Local parent:String = ExtractDir(candidate)
		If parent = candidate Then Exit
		candidate = parent
	Next
	Return ""
End Function

Function StartLogin:Int(auth:TEOSAuth, listener:TAuthConnectListener, config:String, loginMode:String)
	Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
	Select loginMode
		Case "developer"
			credentials.Type = EEOSLoginCredentialType.Developer
			credentials.Id = ConfigValue(config, "DEV_AUTH_HOST")
			credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
			statusTitle = "Starting Developer Auth login..."
			statusDetail = "The Developer Authentication Tool must remain open."
		Case "account-portal", "portal"
			credentials.Type = EEOSLoginCredentialType.AccountPortal
			statusTitle = "Starting Epic Account Portal..."
			statusDetail = "Complete the sign-in and consent flow when it opens."
		Default
			statusKind = 3
			statusTitle = "Unknown login mode"
			statusDetail = "Use developer or account-portal."
			Return False
	End Select

	Local loginOptions:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
	loginOptions.Credentials = credentials
	loginOptions.ScopeFlags = EEOSAuthScopeFlags.BasicProfile | EEOSAuthScopeFlags.FriendsList
	If Not auth Or Not auth.Login(loginOptions, listener) Then
		statusKind = 3
		statusTitle = "Could not start EOS login"
		statusDetail = "The EOS Auth interface rejected the request."
		Return False
	End If
	Return True
End Function

Function DrawScreen()
	Cls
	SetColor 22, 27, 38
	DrawRect 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	Select statusKind
		Case 1
			SetColor 245, 181, 66
		Case 2
			SetColor 75, 201, 126
		Case 3
			SetColor 235, 91, 91
		Default
			SetColor 75, 155, 235
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
	If verificationURI Then
		DrawText "Verification address:", 70, 194
		DrawText verificationURI, 70, 226
		If userCode Then DrawText "Code: " + userCode, 70, 263
	Else
		If done And succeeded Then
			If writeMode Then
				DrawText "Stat ingestion, achievement progress, and ranking succeeded.", 70, 205
				DrawText "Friends: " + displayedFriendCount + "  |  Blocked users: " + displayedBlockedUserCount, 70, 242
				DrawText "The test achievement may now be permanently unlocked.", 70, 279
			Else
				DrawText "Profile and all read-only EOS service queries succeeded.", 70, 205
				DrawText "Friends: " + displayedFriendCount + "  |  Blocked users: " + displayedBlockedUserCount, 70, 242
				DrawText "Zero values are valid when this test account has no data.", 70, 279
			End If
		Else If done Then
			DrawText "The test stopped at the service named above.", 70, 205
			DrawText "Check the client policy and latest EOS log message.", 70, 242
		Else If statusTitle = "Choose a login method" Then
			DrawText "Press A  -  Account Portal and consent", 70, 205
			DrawText "Press D  -  Developer Authentication Tool", 70, 242
		Else
			DrawText "Waiting for EOS authentication, Connect, and service checks...", 70, 205
			DrawText "If a browser or Epic window opens, sign in and click Allow.", 70, 242
		End If
	End If

	SetColor 130, 141, 160
	If latestLog Then DrawText latestLog[..Min(latestLog.Length, 105)], 46, 355
	If done Then
		DrawText "Press Escape to close.", 46, 405
	Else If pendingProductUser Then
		DrawText "Press C to create the Product User, or Escape to close.", 46, 405
	Else
		DrawText "Keep this window open while the login flow completes.", 46, 405
	End If
	Flip
End Function

Graphics WINDOW_WIDTH, WINDOW_HEIGHT, 0, 60, GRAPHICS_BACKBUFFER
SetClsColor 22, 27, 38

Local completedMainLoop:Int
Local configPath:String = FindConfig()
Local loginMode:String
If AppArgs.Length > 2 Then loginMode = AppArgs[2].ToLower()
If AppArgs.Length > 3 And AppArgs[3].ToLower() = "write" Then writeMode = True
If Not configPath Then
	statusKind = 3
	statusTitle = "eos.local.conf was not found"
	statusDetail = "Pass its full path as the first command-line argument."
	done = True
Else
	Local config:String = LoadText(configPath)
	Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
	initializeOptions.ProductName = "EOS Integration Test"
	initializeOptions.ProductVersion = "0.10.0"
	Local result:EEOSResult = EOSInitialize(initializeOptions)
	If result <> EEOSResult.Success Then
		statusKind = 3
		statusTitle = "EOS initialization failed"
		statusDetail = EOSResultString(result)
		done = True
	Else
		TEOSLogging.SetListener(New TConsoleLogListener)
		TEOSLogging.SetLevel(EEOSLogCategory.AllCategories, EEOSLogLevel.Info)

		Local platformOptions:TEOSPlatformOptions = New TEOSPlatformOptions
		platformOptions.ProductId = ConfigValue(config, "PRODUCT_ID")
		platformOptions.SandboxId = ConfigValue(config, "SANDBOX_ID")
		platformOptions.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID")
		platformOptions.ClientId = ConfigValue(config, "CLIENT_ID")
		platformOptions.ClientSecret = ConfigValue(config, "CLIENT_SECRET")
		platformOptions.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")

		Local platform:TEOSPlatform = TEOSPlatform.Create(platformOptions)
		If Not platform Then
			statusKind = 3
			statusTitle = "EOS platform creation failed"
			statusDetail = "Check the local product configuration."
			done = True
		Else
			Local auth:TEOSAuth = platform.Auth()
			Local connect:TEOSConnect = platform.Connect()
			Local stats:TEOSStats = platform.Stats()
			Local achievements:TEOSAchievements = platform.Achievements()
			Local leaderboards:TEOSLeaderboards = platform.Leaderboards()
			Local userInfo:TEOSUserInfoInterface = platform.UserInfo()
			Local friends:TEOSFriends = platform.Friends()
			Local listener:TAuthConnectListener = New TAuthConnectListener
			listener.Auth = auth
			listener.Connect = connect
			listener.UserInfo = userInfo
			listener.Friends = friends
			listener.Stats = stats
			listener.Achievements = achievements
			listener.Leaderboards = leaderboards
			listener.WriteTest = writeMode
			listener.CreateMissingProductUser = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
			If Not auth Or Not connect Or Not stats Or Not achievements Or Not leaderboards Or Not userInfo Or Not friends Then
				statusKind = 3
				statusTitle = "EOS interfaces are unavailable"
				statusDetail = "The platform did not provide Auth and Connect."
				done = True
			Else If loginMode Then
				If Not StartLogin(auth, listener, config, loginMode) Then done = True
			Else
				statusTitle = "Choose a login method"
				statusDetail = "Account Portal grants consent; Developer Auth is faster afterward."
			End If

			While Not KeyHit(KEY_ESCAPE) And Not AppTerminate()
				platform.Tick()
				listener.Update()
				If Not done And Not loginMode Then
					If KeyHit(KEY_A) Then
						loginMode = "account-portal"
						If Not StartLogin(auth, listener, config, loginMode) Then done = True
					Else If KeyHit(KEY_D) Then
						loginMode = "developer"
						If Not StartLogin(auth, listener, config, loginMode) Then done = True
					End If
				End If
				If pendingProductUser And KeyHit(KEY_C) Then listener.CreateProductUser()
				DrawScreen()
			Wend
			completedMainLoop = True
			If listener.UnlockedSubscription Then listener.UnlockedSubscription.Remove()
			platform.Release()
		End If

		result = EOSShutdown()
		If result <> EEOSResult.Success Then Print "EOS shutdown: " + EOSResultString(result)
	End If
End If

While done And Not completedMainLoop And Not KeyHit(KEY_ESCAPE) And Not AppTerminate()
	DrawScreen()
Wend

EndGraphics
