SuperStrict

Framework EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TStatsFlow Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSConnectCreateUserListener, IEOSStatsIngestListener, IEOSStatsQueryListener
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field Stats:TEOSStats
	Field StatName:String
	Field IngestAmount:Int
	Field CreateMissingProductUser:Int
	Field Done:Int

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
		Print "Auth login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return

		Local accountId:TEOSEpicAccountId = selectedAccountId
		If Not accountId Then accountId = localUserId
		Local idToken:TEOSAuthIdToken
		result = Auth.CopyIdToken(accountId, idToken)
		If result <> EEOSResult.Success Then Print "Copy ID token: " + EOSResultString(result); Done = True; Return

		Local credentials:TEOSConnectCredentials = New TEOSConnectCredentials
		credentials.Type = EEOSExternalCredentialType.EpicIdToken
		credentials.Token = idToken.JsonWebToken
		Local options:TEOSConnectLoginOptions = New TEOSConnectLoginOptions
		options.Credentials = credentials
		If Not Connect.Login(options, Self) Then Print "Could not start Connect login."; Done = True
	End Method

	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken)
		Print "Connect login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then StartIngest(localUserId); Return
		If result = EEOSResult.InvalidUser And continuanceToken And CreateMissingProductUser Then
			If Not Connect.CreateUser(continuanceToken, Self) Then Done = True
		Else
			Done = True
		End If
	End Method

	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId)
		Print "Connect create user: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then StartIngest(localUserId) Else Done = True
	End Method

	Method StartIngest(userId:TEOSProductUserId)
		Print "Product User ID: " + userId.ToString()
		Local data:TEOSStatsIngestData = New TEOSStatsIngestData
		data.Name = StatName
		data.IngestAmount = IngestAmount
		Local options:TEOSStatsIngestOptions = New TEOSStatsIngestOptions
		options.LocalUserId = userId
		options.TargetUserId = userId
		options.Stats = [data]
		If Not Stats.Ingest(options, Self) Then Print "Could not start Stats ingest."; Done = True
	End Method

	Method OnEOSStatsIngest(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
		Print "Stats ingest: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return

		Local options:TEOSStatsQueryOptions = New TEOSStatsQueryOptions
		options.LocalUserId = localUserId
		options.TargetUserId = targetUserId
		options.StatNames = [StatName]
		If Not Stats.Query(options, Self) Then Print "Could not start Stats query."; Done = True
	End Method

	Method OnEOSStatsQuery(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
		Print "Stats query: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Print "Cached stats: " + Stats.StatsCount(targetUserId)
			Local stat:TEOSStat
			result = Stats.CopyStatByName(targetUserId, StatName, stat)
			If result = EEOSResult.Success Then
				Print stat.Name + " = " + stat.Value
			Else
				Print "Copy stat: " + EOSResultString(result)
			End If
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
Local configuredStatName:String = ConfigValue(config, "STAT_NAME")
If Not configuredStatName Then RuntimeError "Set STAT_NAME to a stat configured in the Developer Portal."

Local init:TEOSInitializeOptions = New TEOSInitializeOptions
init.ProductName = "EOS Stats example"
init.ProductVersion = "0.3.0"
Local result:EEOSResult = EOSInitialize(init)
If result <> EEOSResult.Success Then RuntimeError "EOS initialization failed: " + EOSResultString(result)

Local platformOptions:TEOSPlatformOptions = New TEOSPlatformOptions
platformOptions.ProductId = ConfigValue(config, "PRODUCT_ID")
platformOptions.SandboxId = ConfigValue(config, "SANDBOX_ID")
platformOptions.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID")
platformOptions.ClientId = ConfigValue(config, "CLIENT_ID")
platformOptions.ClientSecret = ConfigValue(config, "CLIENT_SECRET")
platformOptions.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")
Local platform:TEOSPlatform = TEOSPlatform.Create(platformOptions)
If Not platform Then RuntimeError "EOS platform creation failed."

Local flow:TStatsFlow = New TStatsFlow
flow.Auth = platform.Auth()
flow.Connect = platform.Connect()
flow.Stats = platform.Stats()
flow.StatName = configuredStatName
flow.IngestAmount = Int(ConfigValue(config, "STAT_INGEST_AMOUNT"))
flow.CreateMissingProductUser = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))

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
If Not flow.Done Then Print "Stats example timed out."

platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError "EOS shutdown failed: " + EOSResultString(result)
