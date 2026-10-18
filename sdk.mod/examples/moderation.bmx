SuperStrict

Framework Max2D.SDL3RenderMax2D
Import EOS.SDK
Import BRL.FileSystem
Import BRL.PolledInput
Import BRL.StandardIO
Import BRL.TextStream

Global moderationStatus:String = "Starting the managed EOS session..."
Global moderationDetail:String = "Waiting for a Product User."
Global moderationDone:Int

Type TModerationFlow Extends TEOSSessionListener Implements IEOSSanctionsQueryListener
	Field Platform:TEOSPlatform
	Field Session:TEOSSessionCoordinator
	Field Sanctions:TEOSSanctions
	Field Reports:TEOSReports
	Field CreateMissingProductUser:Int

	Method OnEOSSessionStateChanged(state:EEOSSessionState) Override
		Print "Session state: " + Int(state)
	End Method

	Method OnEOSSessionProductUserCreationRequired() Override
		If CreateMissingProductUser Then
			moderationStatus = "Creating the missing Product User..."
			If Not Session.CreateProductUser() Then
				moderationStatus = "Product User creation could not start."
				moderationDone = True
			End If
		Else
			moderationStatus = "Product User creation requires approval."
			moderationDetail = "Set CREATE_MISSING_PRODUCT_USER=1 to approve it."
			Session.CancelProductUserCreation()
		End If
	End Method

	Method OnEOSSessionReady(accountId:TEOSEpicAccountId, userId:TEOSProductUserId) Override
		Sanctions = Platform.Sanctions()
		Reports = Platform.Reports()
		If Not Sanctions Or Not Reports Then
			moderationStatus = "Moderation interfaces are unavailable."
			moderationDetail = "Check the EOS SDK and platform configuration."
			moderationDone = True
			Return
		End If

		moderationStatus = "Querying active sanctions for the signed-in user..."
		moderationDetail = "The reports interface is also available; no report will be submitted."
		Local options:TEOSSanctionsQueryOptions = New TEOSSanctionsQueryOptions
		options.LocalUserId = userId
		options.TargetUserId = userId
		If Not Sanctions.QueryActivePlayerSanctions(options, Self) Then
			moderationStatus = "The sanctions query could not start."
			moderationDone = True
		End If
	End Method

	Method OnEOSSessionError(result:EEOSResult, recoverable:Int) Override
		moderationStatus = "Session error: " + EOSResultString(result)
		If Not recoverable Then
			moderationDone = True
		End If
	End Method

	Method OnEOSSanctionsQuery(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId) Override
		If result <> EEOSResult.Success Then
			moderationStatus = "Sanctions query failed: " + EOSResultString(result)
			moderationDetail = "Enable the Sanctions action in the client policy and try again."
			moderationDone = True
			Return
		End If

		Local count:Int = Sanctions.PlayerSanctionCount(targetUserId)
		moderationStatus = "Sanctions query succeeded: " + count + " active."
		moderationDetail = "Reports are available but this diagnostic never submits one."
		For Local index:Int = 0 Until count
			Local sanction:TEOSPlayerSanction
			If Sanctions.CopyPlayerSanctionByIndex(targetUserId, index, sanction) = EEOSResult.Success Then
				Print "Sanction " + index + ": " + sanction.Action
				Print "Reference: " + sanction.ReferenceId
				Print "Placed: " + sanction.TimePlaced + ", expires: " + sanction.TimeExpires
			End If
		Next
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

AppTitle = "EOS Sanctions and Reports"
Graphics 800, 220, 0, 60, GRAPHICS_BACKBUFFER
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
initializeOptions.ProductName = "EOS Sanctions and Reports example"
initializeOptions.ProductVersion = "0.20.0"
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

Local flow:TModerationFlow = New TModerationFlow
flow.Platform = platform
flow.CreateMissingProductUser = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
Local session:TEOSSessionCoordinator = TEOSSessionCoordinator.Create(platform, flow)
If Not session Then
	RuntimeError "Could not create the managed EOS session."
End If
flow.Session = session

Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
credentials.Type = EEOSLoginCredentialType.Developer
credentials.Id = ConfigValue(config, "DEV_AUTH_HOST")
credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
Local login:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
login.Credentials = credentials
Local sessionOptions:TEOSSessionOptions = New TEOSSessionOptions
sessionOptions.LoginOptions = login
If Not session.Start(sessionOptions) Then
	RuntimeError "Could not start the managed EOS session."
End If

Local started:Int = MilliSecs()
While Not AppTerminate() And Not KeyHit(KEY_ESCAPE)
	If Not moderationDone Then
		session.Tick()
	End If
	If Not moderationDone And MilliSecs() - started >= 120000 Then
		moderationStatus = "The moderation test timed out."
		moderationDone = True
	End If

	Cls
	SetColor 238, 242, 255
	DrawText "EOS sanctions and reports", 24, 28
	SetColor 170, 184, 210
	DrawText moderationStatus, 24, 78
	DrawText moderationDetail, 24, 114
	DrawText "Press Escape or close the window to exit.", 24, 166
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
EndGraphics
