SuperStrict

Framework Max2D.SDL3RenderMax2D
Import EOS.SDK
Import BRL.FileSystem
Import BRL.PolledInput
Import BRL.StandardIO
Import BRL.TextStream

Global sessionStatus:String = "Starting EOS session..."

Function SessionStateName:String(state:EEOSSessionState)
	Select state
		Case EEOSSessionState.Stopped
			Return "Stopped"
		Case EEOSSessionState.Authenticating
			Return "Authenticating"
		Case EEOSSessionState.Connecting
			Return "Connecting"
		Case EEOSSessionState.AwaitingProductUserCreation
			Return "Awaiting Product User creation"
		Case EEOSSessionState.Ready
			Return "Ready"
		Case EEOSSessionState.Refreshing
			Return "Refreshing"
		Case EEOSSessionState.SigningOut
			Return "Signing out"
		Case EEOSSessionState.WaitingToRetry
			Return "Waiting to retry"
		Case EEOSSessionState.Failed
			Return "Failed"
	End Select
	Return "Unknown"
End Function

Type TConsoleLogListener Implements IEOSLogListener
	Method OnEOSLog(category:String, message:String, level:EEOSLogLevel)
		Print "[" + category + "] " + message
	End Method
End Type

Type TSessionFlow Extends TEOSSessionListener
	Field Session:TEOSSessionCoordinator
	Field CreateMissingProductUser:Int
	Field Done:Int
	Field Success:Int

	Method OnEOSSessionStateChanged(state:EEOSSessionState) Override
		sessionStatus = "Session state: " + SessionStateName(state)
		Print sessionStatus
	End Method

	Method OnEOSSessionAuthActionRequired(pinGrantInfo:TEOSAuthPinGrantInfo) Override
		sessionStatus = "Complete sign-in in the browser."
		Print "Complete sign-in at: " + pinGrantInfo.VerificationURIComplete
		If pinGrantInfo.UserCode Then
			Print "User code: " + pinGrantInfo.UserCode
		End If
	End Method

	Method OnEOSSessionProductUserCreationRequired() Override
		If CreateMissingProductUser Then
			sessionStatus = "Creating the missing Product User..."
			Print "Creating the missing Product User..."
			If Not Session.CreateProductUser() Then
				sessionStatus = "Could not start Product User creation."
				Print "Could not start Product User creation."
				Done = True
			End If
		Else
			sessionStatus = "Product User creation requires approval in the configuration."
			Print "No Product User is linked. Set CREATE_MISSING_PRODUCT_USER=1 to approve creation."
			Session.CancelProductUserCreation()
		End If
	End Method

	Method OnEOSSessionReady(accountId:TEOSEpicAccountId, userId:TEOSProductUserId) Override
		sessionStatus = "Ready - the EOS session is active."
		Print "Epic Account ID: " + accountId.ToString()
		Print "Product User ID: " + userId.ToString()
		Success = True
	End Method

	Method OnEOSSessionError(result:EEOSResult, recoverable:Int) Override
		sessionStatus = "Session error: " + EOSResultString(result)
		Print "Session error: " + EOSResultString(result)
		If Not recoverable Then
			Done = True
		End If
	End Method
End Type

Function ConfigValue:String(config:String, name:String)
	For Local line:String = EachIn config.Replace(Chr(13), "").Split("~n")
		line = line.Trim()
		If Not line Or line.StartsWith("#") Then
			Continue
		End If
		Local separator:Int = line.Find("=")
		If separator < 0 Then
			Continue
		End If
		If line[..separator].Trim() = name Then
			Return line[separator + 1..].Trim()
		End If
	Next
	Return ""
End Function

AppTitle = "EOS Managed Session"
Graphics 760, 180, 0, 60, GRAPHICS_BACKBUFFER
SetClsColor 22, 27, 38

Function LoginOptions:TEOSAuthLoginOptions(kind:EEOSLoginCredentialType, id:String = "", token:String = "")
	Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
	credentials.Type = kind
	credentials.Id = id
	credentials.Token = token
	Local options:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
	options.Credentials = credentials
	Return options
End Function

Local configPath:String = "eos.local.conf"
If AppArgs.Length > 1 Then
	configPath = AppArgs[1]
End If
Local loginMode:String = "developer"
If AppArgs.Length > 2 Then
	loginMode = AppArgs[2].ToLower()
End If
If FileType(configPath) <> FILETYPE_FILE Then
	RuntimeError "Copy eos.local.conf.example to eos.local.conf and fill in your EOS values."
End If
Local config:String = LoadText(configPath)

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS Auth and Connect example"
initializeOptions.ProductVersion = "0.19.0"
Local result:EEOSResult = EOSInitialize(initializeOptions)
If result <> EEOSResult.Success Then
	RuntimeError "EOS initialization failed: " + EOSResultString(result)
End If
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
	RuntimeError "EOS platform creation failed. Check eos.local.conf."
End If

Local flow:TSessionFlow = New TSessionFlow
flow.CreateMissingProductUser = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
Local session:TEOSSessionCoordinator = TEOSSessionCoordinator.Create(platform, flow)
If Not session Then
	RuntimeError "Could not create the EOS session coordinator."
End If
flow.Session = session

Local sessionOptions:TEOSSessionOptions = New TEOSSessionOptions
Select loginMode
	Case "developer"
		sessionOptions.LoginOptions = LoginOptions( ..
			EEOSLoginCredentialType.Developer, ..
			ConfigValue(config, "DEV_AUTH_HOST"), ..
			ConfigValue(config, "DEV_AUTH_CREDENTIAL"))
		Print "Starting Developer Authentication Tool login."
	Case "account-portal", "portal"
		sessionOptions.LoginOptions = LoginOptions(EEOSLoginCredentialType.AccountPortal)
		Print "Starting Account Portal login. Complete the browser flow when it opens."
	Case "persistent"
		sessionOptions.LoginOptions = LoginOptions(EEOSLoginCredentialType.PersistentAuth)
		sessionOptions.FallbackLoginOptions = LoginOptions(EEOSLoginCredentialType.AccountPortal)
		Print "Trying persistent login, with Account Portal as the fallback."
	Default
		RuntimeError "Login mode must be developer, account-portal, or persistent."
End Select

If Not session.Start(sessionOptions) Then
	RuntimeError "Could not start the EOS session."
End If

Local started:Int = MilliSecs()
Local timeout:Int = 120000
If loginMode = "account-portal" Or loginMode = "portal" Or loginMode = "persistent" Then
	timeout = 300000
End If
While Not AppTerminate() And Not KeyHit(KEY_ESCAPE)
	If Not flow.Done Then
		session.Tick()
	End If
	If Not flow.Success And Not flow.Done And MilliSecs() - started >= timeout Then
		sessionStatus = "Login timed out."
		Print sessionStatus
		flow.Done = True
	End If

	Cls
	SetColor 238, 242, 255
	DrawText "EOS managed session example", 24, 28
	SetColor 170, 184, 210
	DrawText sessionStatus, 24, 72
	DrawText "Press Escape or close the window to exit.", 24, 108
	Flip
Wend

If session.IsUsable() Then
	session.Logout()
	Local logoutStarted:Int = MilliSecs()
	While session.State() <> EEOSSessionState.Stopped And MilliSecs() - logoutStarted < 5000
		session.Tick()
		Delay 16
	Wend
End If

session.Release()
platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then
	RuntimeError "EOS shutdown failed: " + EOSResultString(result)
End If
If flow.Success Then
	Print "EOS session is ready."
End If
EndGraphics
