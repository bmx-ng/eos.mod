' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../../LICENSE.

SuperStrict

Framework Max2D.SDL3RenderMax2D
Import EOS.SDK
Import BRL.FileSystem
Import BRL.PolledInput
Import BRL.StandardIO
Import BRL.TextStream

Global uiStatus:String = "Starting the managed EOS login..."
Global uiDetail:String = "The Friends overlay will open after login."
Global uiEvent:String = "Waiting for the EOS UI interface."
Global uiDone:Int
Global uiSuccess:Int
Global uiSkipped:Int

Function SocialOverlayPlatformName:String()
?win32x64
	Return "Windows x64"
?
?win32arm64
	Return "Windows ARM64"
?
?linux
	Return "Linux"
?
?macos
	Return "macOS"
?
End Function

Type TUIFlow Extends TEOSSessionListener Implements IEOSUIOperationListener, IEOSUIDisplaySettingsListener
	Field Platform:TEOSPlatform
	Field LoginSession:TEOSSessionCoordinator
	Field UI:TEOSUI
	Field AccountId:TEOSEpicAccountId
	Field DisplaySubscription:TEOSUIDisplaySettingsSubscription
	Field CreateMissingProductUser:Int
	Field HideAt:Int
	Field ShowCompleted:Int
	Field SawVisible:Int
	Field SawExclusiveInput:Int
	Field SawHidden:Int

	Method OnEOSSessionProductUserCreationRequired() Override
		If CreateMissingProductUser Then
			uiStatus = "Creating the missing Product User..."
			If Not LoginSession.CreateProductUser() Then
				Fail("Product User creation could not start.")
			End If
		Else
			uiStatus = "Product User creation requires approval."
			uiDetail = "Set CREATE_MISSING_PRODUCT_USER=1 to approve it."
			LoginSession.CancelProductUserCreation()
		End If
	End Method

	Method OnEOSSessionReady(accountId:TEOSEpicAccountId, userId:TEOSProductUserId) Override
		Self.AccountId = accountId
		UI = Platform.UI()
		If Not UI Then
			Fail("The EOS UI interface is unavailable.")
			Return
		End If
		If Not EOSSocialOverlaySupportedOnPlatform() Then
			SkipUnsupportedPlatform(SocialOverlayPlatformName())
			Return
		End If

		DisplaySubscription = UI.AddNotifyDisplaySettingsUpdated(Self)
		If Not DisplaySubscription Then
			Fail("The Social Overlay display notification could not be registered.")
			Return
		End If

		Local result:EEOSResult = UI.SetDisplayPreference( ..
			EEOSUINotificationLocation.BottomRight)
		If result <> EEOSResult.Success Then
			Fail("Setting the notification location failed: " + EOSResultString(result))
			Return
		End If
		If UI.DisplayPreference() <> EEOSUINotificationLocation.BottomRight Then
			Fail("The notification location was not preserved.")
			Return
		End If

		result = UI.PauseSocialOverlay(True)
		If result <> EEOSResult.Success Or Not UI.IsSocialOverlayPaused() Then
			Fail("Pausing the Social Overlay failed: " + EOSResultString(result))
			Return
		End If
		result = UI.PauseSocialOverlay(False)
		If result <> EEOSResult.Success Or UI.IsSocialOverlayPaused() Then
			Fail("Resuming the Social Overlay failed: " + EOSResultString(result))
			Return
		End If

		uiStatus = "Opening the Epic Friends overlay..."
		uiDetail = "It will close automatically after its display event is observed."
		If Not UI.ShowFriends(AccountId, Self) Then
			Fail("The Friends overlay request could not start.")
		End If
	End Method

	Method OnEOSSessionError(result:EEOSResult, recoverable:Int) Override
		If Not recoverable Then
			Fail("Login failed: " + EOSResultString(result))
		End If
	End Method

	Method OnEOSUIOperation(result:EEOSResult, operation:EEOSUIOperation, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId) Override
		Print "UI operation " + Int(operation) + ": " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then
			Return
		End If
		If result <> EEOSResult.Success Then
			Fail("UI operation failed: " + EOSResultString(result))
			Return
		End If

		Select operation
			Case EEOSUIOperation.ShowFriends
				ShowCompleted = True
				uiStatus = "Friends overlay opened."
				If SawVisible Then
					HideAt = MilliSecs() + 2500
				End If
			Case EEOSUIOperation.HideFriends
				CheckComplete()
		End Select
	End Method

	Method OnEOSUIDisplaySettingsUpdated(isVisible:Int, isExclusiveInput:Int) Override
		Print "Overlay display: visible=" + isVisible + ", exclusive=" + isExclusiveInput
		If isVisible Then
			SawVisible = True
			If isExclusiveInput Then
				SawExclusiveInput = True
			End If
			uiEvent = "Visible and exclusive-input display state observed."
			If ShowCompleted And Not HideAt Then
				HideAt = MilliSecs() + 2500
			End If
		Else If SawVisible Then
			SawHidden = True
			uiEvent = "Hidden display state observed after closing the overlay."
			CheckComplete()
		End If
	End Method

	Method Tick()
		If HideAt And MilliSecs() >= HideAt Then
			HideAt = 0
			uiStatus = "Closing the Epic Friends overlay..."
			If Not UI.HideFriends(AccountId, Self) Then
				Fail("The Friends overlay close request could not start.")
			End If
		End If
	End Method

	Method CheckComplete()
		If uiDone Or Not ShowCompleted Or Not SawVisible Or Not SawHidden Then
			Return
		End If
		uiSuccess = True
		uiDone = True
		uiStatus = "EOS UI overlay test succeeded."
		If SawExclusiveInput Then
			uiDetail = "Show, hide, display state, exclusive input, pause, and placement verified."
		Else
			uiDetail = "Show, hide, display state, pause, and placement verified."
		End If
	End Method

	Method Fail(message:String)
		If uiDone Then
			Return
		End If
		Print message
		uiStatus = message
		uiDetail = "Check that the Epic Social Overlay is installed and configured."
		uiDone = True
	End Method

	Method SkipUnsupportedPlatform(platformName:String)
		Print "EOS Social Overlay is not supported on " + platformName + "."
		uiStatus = "EOS UI is available; the Social Overlay test was skipped."
		uiDetail = "Epic does not support the Social Overlay on " + platformName + "."
		uiEvent = "Use the game's own social UI on this platform."
		uiSkipped = True
		uiDone = True
	End Method

	Method RemoveSubscriptions()
		If DisplaySubscription Then
			DisplaySubscription.Remove()
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
		If separator >= 0 And line[..separator].Trim() = name Then
			Return line[separator + 1..].Trim()
		End If
	Next
	Return ""
End Function

AppTitle = "EOS UI Overlay"
Graphics 900, 280, 0, 60, GRAPHICS_BACKBUFFER
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
initializeOptions.ProductName = "EOS UI Overlay example"
initializeOptions.ProductVersion = "0.24.0"
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

Local flow:TUIFlow = New TUIFlow
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
login.ScopeFlags = EEOSAuthScopeFlags.BasicProfile | ..
	EEOSAuthScopeFlags.FriendsList | EEOSAuthScopeFlags.Presence
Local sessionOptions:TEOSSessionOptions = New TEOSSessionOptions
sessionOptions.LoginOptions = login
If Not loginSession.Start(sessionOptions) Then
	RuntimeError "Could not start the managed EOS login session."
End If

Local started:Int = MilliSecs()
While Not AppTerminate() And Not KeyHit(KEY_ESCAPE)
	loginSession.Tick()
	flow.Tick()
	If Not uiDone And MilliSecs() - started >= 120000 Then
		flow.Fail("The EOS UI test timed out.")
	End If

	Cls
	If uiSuccess Then
		SetColor 75, 201, 126
	Else If uiSkipped Then
		SetColor 235, 183, 75
	Else If uiDone Then
		SetColor 235, 91, 91
	Else
		SetColor 75, 155, 235
	End If
	DrawRect 0, 0, 900, 8
	SetColor 238, 242, 255
	DrawText "EOS Social Overlay", 34, 34
	SetColor 170, 184, 210
	DrawText uiStatus, 34, 90
	DrawText uiDetail, 34, 128
	DrawText uiEvent, 34, 174
	DrawText "Press Escape or close the window to exit.", 34, 232
	Flip
Wend

flow.RemoveSubscriptions()
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
