SuperStrict

Framework EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TLobbyFlow Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSConnectCreateUserListener, IEOSLobbyCreateListener, IEOSLobbyDestroyListener
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field Lobby:TEOSLobby
	Field CreateMissingProductUser:Int
	Field LocalUserId:TEOSProductUserId
	Field Done:Int
	Field Success:Int

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
		If result = EEOSResult.Success Then CreateLobby(localUserId); Return
		If result = EEOSResult.InvalidUser And continuanceToken And CreateMissingProductUser Then
			If Not Connect.CreateUser(continuanceToken, Self) Then Done = True
		Else
			Done = True
		End If
	End Method

	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId)
		Print "Connect create user: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then CreateLobby(localUserId) Else Done = True
	End Method

	Method CreateLobby(userId:TEOSProductUserId)
		LocalUserId = userId
		Print "Product User ID: " + userId.ToString()
		Local options:TEOSLobbyCreateOptions = New TEOSLobbyCreateOptions
		options.LocalUserId = userId
		options.MaxMembers = 4
		options.PermissionLevel = EEOSLobbyPermissionLevel.InviteOnly
		options.AllowInvites = True
		options.BucketId = "eos-sdk-lobby-test"
		If Not Lobby.Create(options, Self) Then Print "Could not start Lobby creation."; Done = True
	End Method

	Method OnEOSLobbyCreate(result:EEOSResult, lobbyId:String)
		Print "Lobby create: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		Print "Lobby ID: " + lobbyId

		Local details:TEOSLobbyDetails
		result = Lobby.CopyDetails(LocalUserId, lobbyId, details)
		Print "Copy lobby details: " + EOSResultString(result)
		If result = EEOSResult.Success Then
			Local info:TEOSLobbyInfo
			result = details.CopyInfo(info)
			Print "Copy lobby info: " + EOSResultString(result)
			If result = EEOSResult.Success Then
				Print "Bucket: " + info.BucketId
				Print "Members: " + details.MemberCount() + "/" + info.MaxMembers
				Print "Available slots: " + info.AvailableSlots
				Local owner:TEOSProductUserId = info.OwnerUserId
				If owner Then Print "Owner Product User ID: " + owner.ToString()
			End If
			details.Release()
		End If

		If Not Lobby.Destroy(LocalUserId, lobbyId, Self) Then Print "Could not start Lobby destruction."; Done = True
	End Method

	Method OnEOSLobbyDestroy(result:EEOSResult, lobbyId:String)
		Print "Lobby destroy: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		Success = result = EEOSResult.Success
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

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS Lobbies example"
initializeOptions.ProductVersion = "0.16.0"
Local result:EEOSResult = EOSInitialize(initializeOptions)
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

Local flow:TLobbyFlow = New TLobbyFlow
flow.Auth = platform.Auth()
flow.Connect = platform.Connect()
flow.Lobby = platform.Lobby()
flow.CreateMissingProductUser = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
If Not flow.Auth Or Not flow.Connect Or Not flow.Lobby Then RuntimeError "Auth, Connect, or Lobby interface is unavailable."

Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
credentials.Type = EEOSLoginCredentialType.Developer
credentials.Id = ConfigValue(config, "DEV_AUTH_HOST")
credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
Local loginOptions:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
loginOptions.Credentials = credentials
If Not flow.Auth.Login(loginOptions, flow) Then RuntimeError "Could not start Auth login."

Local started:Int = MilliSecs()
While Not flow.Done And MilliSecs() - started < 120000
	platform.Tick()
	Delay 16
Wend
If Not flow.Done Then Print "Lobbies example timed out."

platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError "EOS shutdown failed: " + EOSResultString(result)
If flow.Success Then Print "Lobby lifecycle completed."
