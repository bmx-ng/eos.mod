SuperStrict

Framework EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TConsoleLogListener Implements IEOSLogListener
	Method OnEOSLog(category:String, message:String, level:EEOSLogLevel)
		Print "[" + category + "] " + message
	End Method
End Type

Type TAuthConnectFlow Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSConnectCreateUserListener
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field CreateMissingProductUser:Int
	Field Done:Int
	Field Success:Int

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
		Print "Auth login: " + EOSResultString(result)
		If pinGrantInfo Then
			Print "Complete sign-in at: " + pinGrantInfo.VerificationURIComplete
			Print "User code: " + pinGrantInfo.UserCode
		End If
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then
			Done = True
			Return
		End If

		Local accountId:TEOSEpicAccountId = selectedAccountId
		If Not accountId Then accountId = localUserId
		Local idToken:TEOSAuthIdToken
		result = Auth.CopyIdToken(accountId, idToken)
		If result <> EEOSResult.Success Then
			Print "Copy ID token: " + EOSResultString(result)
			Done = True
			Return
		End If

		Local credentials:TEOSConnectCredentials = New TEOSConnectCredentials
		credentials.Type = EEOSExternalCredentialType.EpicIdToken
		credentials.Token = idToken.JsonWebToken
		Local options:TEOSConnectLoginOptions = New TEOSConnectLoginOptions
		options.Credentials = credentials
		If Not Connect.Login(options, Self) Then
			Print "Could not start Connect login."
			Done = True
		End If
	End Method

	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken)
		Print "Connect login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Print "Product User ID: " + localUserId.ToString()
			Success = True
			Done = True
			Return
		End If

		If result = EEOSResult.InvalidUser And continuanceToken Then
			If CreateMissingProductUser Then
				Print "Creating the missing Product User..."
				If Not Connect.CreateUser(continuanceToken, Self) Then Done = True
			Else
				Print "No Product User is linked. Set CREATE_MISSING_PRODUCT_USER=1 to create one."
				Done = True
			End If
		Else
			Done = True
		End If
	End Method

	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId)
		Print "Connect create user: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Print "Product User ID: " + localUserId.ToString()
			Success = True
		End If
		Done = True
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

Local configPath:String = "eos.local.conf"
If AppArgs.Length > 1 Then configPath = AppArgs[1]
Local loginMode:String = "developer"
If AppArgs.Length > 2 Then loginMode = AppArgs[2].ToLower()
If FileType(configPath) <> FILETYPE_FILE Then
	RuntimeError "Copy eos.local.conf.example to eos.local.conf and fill in your EOS values."
End If
Local config:String = LoadText(configPath)

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS Auth and Connect example"
initializeOptions.ProductVersion = "0.2.0"
Local result:EEOSResult = EOSInitialize(initializeOptions)
If result <> EEOSResult.Success Then RuntimeError "EOS initialization failed: " + EOSResultString(result)
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
If Not platform Then RuntimeError "EOS platform creation failed. Check eos.local.conf."

Local flow:TAuthConnectFlow = New TAuthConnectFlow
flow.Auth = platform.Auth()
flow.Connect = platform.Connect()
flow.CreateMissingProductUser = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
If Not flow.Auth Or Not flow.Connect Then RuntimeError "Auth or Connect interface is unavailable."

Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
Select loginMode
	Case "developer"
		credentials.Type = EEOSLoginCredentialType.Developer
		credentials.Id = ConfigValue(config, "DEV_AUTH_HOST")
		credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
		Print "Starting Developer Authentication Tool login."
	Case "account-portal", "portal"
		credentials.Type = EEOSLoginCredentialType.AccountPortal
		Print "Starting Account Portal login. Complete the browser flow when it opens."
	Default
		RuntimeError "Login mode must be developer or account-portal."
End Select
Local loginOptions:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
loginOptions.Credentials = credentials

If Not flow.Auth.Login(loginOptions, flow) Then RuntimeError "Could not start Auth login."

Local started:Int = MilliSecs()
Local timeout:Int = 120000
If loginMode = "account-portal" Or loginMode = "portal" Then timeout = 300000
While Not flow.Done And MilliSecs() - started < timeout
	platform.Tick()
	Delay 16
Wend
If Not flow.Done Then Print "Login timed out."

platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError "EOS shutdown failed: " + EOSResultString(result)
If flow.Success Then Print "Auth and Connect flow completed."
