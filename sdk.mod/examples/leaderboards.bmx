SuperStrict

Framework EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TLeaderboardsFlow Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSLeaderboardsQueryDefinitionsListener, IEOSLeaderboardsQueryRanksListener, IEOSLeaderboardsQueryUserScoresListener
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field Leaderboards:TEOSLeaderboards
	Field UserId:TEOSProductUserId
	Field StatName:String
	Field Aggregation:EEOSLeaderboardAggregation
	Field Done:Int
	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
		Print "Auth login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		Local accountId:TEOSEpicAccountId = selectedAccountId
		If Not accountId Then accountId = localUserId
		Local token:TEOSAuthIdToken
		result = Auth.CopyIdToken(accountId, token)
		If result <> EEOSResult.Success Then Done = True; Return
		Local credentials:TEOSConnectCredentials = New TEOSConnectCredentials
		credentials.Type = EEOSExternalCredentialType.EpicIdToken; credentials.Token = token.JsonWebToken
		Local options:TEOSConnectLoginOptions = New TEOSConnectLoginOptions
		options.Credentials = credentials
		If Not Connect.Login(options, Self) Then Done = True
	End Method
	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken)
		Print "Connect login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		UserId = localUserId
		Local options:TEOSLeaderboardsQueryDefinitionsOptions = New TEOSLeaderboardsQueryDefinitionsOptions
		options.LocalUserId = UserId
		If Not Leaderboards.QueryDefinitions(options, Self) Then Done = True
	End Method
	Method OnEOSLeaderboardsQueryDefinitions(result:EEOSResult)
		Print "Leaderboard definitions: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		Local count:Int = Leaderboards.DefinitionCount()
		Print "Definitions cached: " + count
		Local first:TEOSLeaderboardDefinition
		For Local index:Int = 0 Until count
			Local definition:TEOSLeaderboardDefinition
			If Leaderboards.CopyDefinitionByIndex(index, definition) = EEOSResult.Success Then
				Print definition.LeaderboardId + " (" + definition.StatName + ")"
				If Not first Then first = definition
			End If
		Next
		If first Then
			StatName = first.StatName
			Aggregation = first.Aggregation
			If Not Leaderboards.QueryRanks(UserId, first.LeaderboardId, Self) Then Done = True
		Else
			Done = True
		End If
	End Method
	Method OnEOSLeaderboardsQueryRanks(result:EEOSResult, leaderboardId:String)
		Print "Leaderboard ranks " + leaderboardId + ": " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Local count:Int = Leaderboards.RecordCount()
			Print "Records cached: " + count
			For Local index:Int = 0 Until count
				Local record:TEOSLeaderboardRecord
				If Leaderboards.CopyRecordByIndex(index, record) = EEOSResult.Success Then Print record.Rank + ". " + record.UserDisplayName + " = " + record.Score
			Next
		End If
		If result = EEOSResult.Success And StatName Then
			Local statInfo:TEOSLeaderboardUserScoresQueryStatInfo = New TEOSLeaderboardUserScoresQueryStatInfo
			statInfo.StatName = StatName
			statInfo.Aggregation = Aggregation
			Local options:TEOSLeaderboardsQueryUserScoresOptions = New TEOSLeaderboardsQueryUserScoresOptions
			options.LocalUserId = UserId; options.UserIds = [UserId]; options.StatInfo = [statInfo]
			If Not Leaderboards.QueryUserScores(options, Self) Then Done = True
		Else
			Done = True
		End If
	End Method
	Method OnEOSLeaderboardsQueryUserScores(result:EEOSResult)
		Print "User scores for " + StatName + ": " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			For Local index:Int = 0 Until Leaderboards.UserScoreCount(StatName)
				Local userScore:TEOSLeaderboardUserScore
				If Leaderboards.CopyUserScoreByIndex(index, StatName, userScore) = EEOSResult.Success Then Print userScore.UserId.ToString() + " = " + userScore.Score
			Next
		End If
		Done = True
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
init.ProductName = "EOS Leaderboards example"; init.ProductVersion = "0.7.0"
Local result:EEOSResult = EOSInitialize(init)
If result <> EEOSResult.Success Then RuntimeError EOSResultString(result)
Local options:TEOSPlatformOptions = New TEOSPlatformOptions
options.ProductId = ConfigValue(config, "PRODUCT_ID"); options.SandboxId = ConfigValue(config, "SANDBOX_ID")
options.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID"); options.ClientId = ConfigValue(config, "CLIENT_ID")
options.ClientSecret = ConfigValue(config, "CLIENT_SECRET"); options.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")
Local platform:TEOSPlatform = TEOSPlatform.Create(options)
If Not platform Then RuntimeError "EOS platform creation failed."
Local flow:TLeaderboardsFlow = New TLeaderboardsFlow
flow.Auth = platform.Auth(); flow.Connect = platform.Connect(); flow.Leaderboards = platform.Leaderboards()
Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
credentials.Type = EEOSLoginCredentialType.Developer
credentials.Id = ConfigValue(config, "DEV_AUTH_HOST"); credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
Local login:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
login.Credentials = credentials
If Not flow.Auth.Login(login, flow) Then RuntimeError "Could not start Auth login."
Local started:Int = MilliSecs()
While Not flow.Done And MilliSecs() - started < 120000
	platform.Tick(); Delay 16
Wend
If Not flow.Done Then Print "Leaderboards example timed out."
platform.Release(); result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError EOSResultString(result)
