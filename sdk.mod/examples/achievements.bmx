SuperStrict

Framework EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TAchievementsFlow Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSAchievementsQueryDefinitionsListener, IEOSAchievementsQueryPlayerListener, IEOSAchievementsUnlockListener, IEOSAchievementsUnlockedListener
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field Achievements:TEOSAchievements
	Field UserId:TEOSProductUserId
	Field UnlockAchievementId:String
	Field UnlockRequested:Int
	Field UnlockedSubscription:TEOSAchievementsUnlockedSubscription
	Field Done:Int

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
		Print "Auth login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		Local accountId:TEOSEpicAccountId = selectedAccountId
		If Not accountId Then accountId = localUserId
		Local idToken:TEOSAuthIdToken
		result = Auth.CopyIdToken(accountId, idToken)
		If result <> EEOSResult.Success Then Done = True; Return
		Local credentials:TEOSConnectCredentials = New TEOSConnectCredentials
		credentials.Type = EEOSExternalCredentialType.EpicIdToken
		credentials.Token = idToken.JsonWebToken
		Local options:TEOSConnectLoginOptions = New TEOSConnectLoginOptions
		options.Credentials = credentials
		If Not Connect.Login(options, Self) Then Done = True
	End Method

	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken)
		Print "Connect login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		UserId = localUserId
		UnlockedSubscription = Achievements.AddNotifyAchievementsUnlocked(Self)
		Local options:TEOSAchievementsQueryDefinitionsOptions = New TEOSAchievementsQueryDefinitionsOptions
		options.LocalUserId = UserId
		If Not Achievements.QueryDefinitions(options, Self) Then Done = True
	End Method

	Method OnEOSAchievementsQueryDefinitions(result:EEOSResult)
		Print "Achievement definitions: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		Local count:Int = Achievements.DefinitionCount()
		Print "Definitions cached: " + count
		For Local index:Int = 0 Until count
			Local definition:TEOSAchievementDefinition
			If Achievements.CopyDefinitionByIndex(index, definition) = EEOSResult.Success Then Print definition.AchievementId + ": " + definition.UnlockedDisplayName
		Next
		Local options:TEOSAchievementsQueryPlayerOptions = New TEOSAchievementsQueryPlayerOptions
		options.LocalUserId = UserId
		options.TargetUserId = UserId
		If Not Achievements.QueryPlayerAchievements(options, Self) Then Done = True
	End Method

	Method OnEOSAchievementsQueryPlayer(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
		Print "Player achievements: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Local count:Int = Achievements.PlayerAchievementCount(targetUserId)
			Print "Player achievements cached: " + count
			For Local index:Int = 0 Until count
				Local achievement:TEOSPlayerAchievement
				If Achievements.CopyPlayerAchievementByIndex(localUserId, targetUserId, index, achievement) = EEOSResult.Success Then Print achievement.AchievementId + ": " + (achievement.Progress * 100.0) + "%"
			Next
		End If
		If result = EEOSResult.Success And UnlockRequested And UnlockAchievementId Then
			If Not Achievements.UnlockAchievements(targetUserId, [UnlockAchievementId], Self) Then Done = True
		Else
			Done = True
		End If
	End Method

	Method OnEOSAchievementsUnlock(result:EEOSResult, userId:TEOSProductUserId, achievementsCount:UInt)
		Print "Unlock achievements: " + EOSResultString(result) + " (" + achievementsCount + ")"
		If EOSResultIsOperationComplete(result) Then Done = True
	End Method

	Method OnEOSAchievementUnlocked(userId:TEOSProductUserId, achievementId:String, unlockTime:Long)
		Print "Achievement unlocked: " + achievementId + " at " + unlockTime
	End Method
End Type

Function ConfigValue:String(config:String, name:String)
	For Local line:String = EachIn config.Replace(Chr(13), "").Split("~n")
		line = line.Trim()
		If Not line Or line.StartsWith("#") Then Continue
		Local separator:Int = line.Find("=")
		If separator >= 0 And line[..separator].Trim() = name Then Return line[separator + 1..].Trim()
	Next
	Return ""
End Function

Local configPath:String = "eos.local.conf"
If AppArgs.Length > 1 Then configPath = AppArgs[1]
If FileType(configPath) <> FILETYPE_FILE Then RuntimeError "Copy eos.local.conf.example to eos.local.conf and fill in your EOS values."
Local config:String = LoadText(configPath)
Local init:TEOSInitializeOptions = New TEOSInitializeOptions
init.ProductName = "EOS Achievements example"
init.ProductVersion = "0.5.0"
Local result:EEOSResult = EOSInitialize(init)
If result <> EEOSResult.Success Then RuntimeError EOSResultString(result)
Local platformOptions:TEOSPlatformOptions = New TEOSPlatformOptions
platformOptions.ProductId = ConfigValue(config, "PRODUCT_ID")
platformOptions.SandboxId = ConfigValue(config, "SANDBOX_ID")
platformOptions.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID")
platformOptions.ClientId = ConfigValue(config, "CLIENT_ID")
platformOptions.ClientSecret = ConfigValue(config, "CLIENT_SECRET")
platformOptions.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")
Local platform:TEOSPlatform = TEOSPlatform.Create(platformOptions)
If Not platform Then RuntimeError "EOS platform creation failed."
Local flow:TAchievementsFlow = New TAchievementsFlow
flow.Auth = platform.Auth()
flow.Connect = platform.Connect()
flow.Achievements = platform.Achievements()
flow.UnlockAchievementId = ConfigValue(config, "ACHIEVEMENT_ID")
flow.UnlockRequested = Int(ConfigValue(config, "UNLOCK_ACHIEVEMENT"))
Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
credentials.Type = EEOSLoginCredentialType.Developer
credentials.Id = ConfigValue(config, "DEV_AUTH_HOST")
credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
Local login:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
login.Credentials = credentials
If Not flow.Auth.Login(login, flow) Then RuntimeError "Could not start Auth login."
Local started:Int = MilliSecs()
While Not flow.Done And MilliSecs() - started < 120000
	platform.Tick()
	Delay 16
Wend
If Not flow.Done Then Print "Achievements example timed out."
If flow.UnlockedSubscription Then flow.UnlockedSubscription.Remove()
platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError EOSResultString(result)
