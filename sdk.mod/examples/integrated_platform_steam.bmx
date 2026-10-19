' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../../LICENSE.

SuperStrict

Framework Steam.SteamSDK
Import EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TIntegratedPlatformEvents Implements ..
	IEOSIntegratedPlatformLoginStatusListener, ..
	IEOSIntegratedPlatformPreLogoutListener
	Method OnEOSIntegratedPlatformLoginStatusChanged( ..
		platformType:String, localPlatformUserId:String, ..
		accountId:TEOSEpicAccountId, productUserId:TEOSProductUserId, ..
		previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus) Override
		Print platformType + " user " + localPlatformUserId + ..
			" changed from " + Int(previousStatus) + " to " + Int(currentStatus)
		If accountId Then
			Print "Epic account: " + accountId.ToString()
		End If
		If productUserId Then
			Print "Product user: " + productUserId.ToString()
		End If
	End Method

	Method OnEOSIntegratedPlatformPreLogout:EEOSIntegratedPlatformPreLogoutAction( ..
		platformType:String, localPlatformUserId:String, ..
		accountId:TEOSEpicAccountId, productUserId:TEOSProductUserId) Override
		Print platformType + " user " + localPlatformUserId + ..
			" is signing out."
		Return EEOSIntegratedPlatformPreLogoutAction.ProcessLogoutImmediately
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

Local configPath:String = "eos.local.conf"
If AppArgs.Length > 1 Then
	configPath = AppArgs[1]
End If
If FileType(configPath) <> FILETYPE_FILE Then
	RuntimeError "Copy eos.local.conf.example to eos.local.conf and fill in your EOS values."
End If
Local config:String = LoadText(configPath)

' The application owns Steam in this example, so it must initialize Steam first.
If Not SteamInit(False) Then
	RuntimeError "Steam initialization failed. Launch through Steam or provide steam_appid.txt."
End If

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS Integrated Platform example"
initializeOptions.ProductVersion = "0.25.0"
Local result:EEOSResult = EOSInitialize(initializeOptions)
If result <> EEOSResult.Success Then
	SteamShutdown()
	RuntimeError "EOS initialization failed: " + EOSResultString(result)
End If

Local integratedOptions:TEOSIntegratedPlatformOptionsContainer
result = TEOSIntegratedPlatformOptionsContainer.Create(integratedOptions)
If result <> EEOSResult.Success Then
	EOSShutdown()
	SteamShutdown()
	RuntimeError "Integrated Platform options creation failed: " + ..
		EOSResultString(result)
End If

Local steamOptions:TEOSIntegratedPlatformSteamOptions = ..
	New TEOSIntegratedPlatformSteamOptions
steamOptions.Flags = ..
	EEOSIntegratedPlatformManagementFlags.LibraryManagedByApplication
' Match these values to the Steamworks SDK used by the application.
steamOptions.SteamMajorVersion = 1
steamOptions.SteamMinorVersion = 65
result = integratedOptions.AddSteam(steamOptions)
If result <> EEOSResult.Success Then
	integratedOptions.Release()
	EOSShutdown()
	SteamShutdown()
	RuntimeError "Adding Steam integration failed: " + EOSResultString(result)
End If

Local platformOptions:TEOSPlatformOptions = New TEOSPlatformOptions
platformOptions.ProductId = ConfigValue(config, "PRODUCT_ID")
platformOptions.SandboxId = ConfigValue(config, "SANDBOX_ID")
platformOptions.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID")
platformOptions.ClientId = ConfigValue(config, "CLIENT_ID")
platformOptions.ClientSecret = ConfigValue(config, "CLIENT_SECRET")
platformOptions.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")
platformOptions.IntegratedPlatformOptions = integratedOptions

Local platform:TEOSPlatform = TEOSPlatform.Create(platformOptions)
' EOS copies the options during Create, so the temporary container is done.
integratedOptions.Release()
If Not platform Then
	EOSShutdown()
	SteamShutdown()
	RuntimeError "EOS platform creation failed."
End If

Local integrated:TEOSIntegratedPlatform = platform.IntegratedPlatform()
If Not integrated Then
	platform.Release()
	EOSShutdown()
	SteamShutdown()
	RuntimeError "The EOS Integrated Platform interface is unavailable."
End If

Local events:TIntegratedPlatformEvents = New TIntegratedPlatformEvents
Local statusSubscription:TEOSIntegratedPlatformLoginStatusSubscription = ..
	integrated.AddNotifyUserLoginStatusChanged(events)
If Not statusSubscription Then
	platform.Release()
	EOSShutdown()
	SteamShutdown()
	RuntimeError "Could not subscribe to native-user login changes."
End If

Local preLogoutRegistration:TEOSIntegratedPlatformPreLogoutRegistration
result = integrated.SetPreLogoutHandler(events, preLogoutRegistration)
If result <> EEOSResult.Success Then
	statusSubscription.Remove()
	platform.Release()
	EOSShutdown()
	SteamShutdown()
	RuntimeError "Could not install the pre-logout handler: " + ..
		EOSResultString(result)
End If

Print "Steam is attached to EOS Integrated Platform. Ticking for 10 seconds..."
Local started:Int = MilliSecs()
While MilliSecs() - started < 10000
	SteamRunCallbacks()
	platform.Tick()
	Delay 16
Wend

preLogoutRegistration.Remove()
statusSubscription.Remove()
platform.Release()
result = EOSShutdown()
SteamShutdown()
If result <> EEOSResult.Success Then
	RuntimeError "EOS shutdown failed: " + EOSResultString(result)
End If
