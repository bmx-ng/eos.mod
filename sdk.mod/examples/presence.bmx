SuperStrict

Framework EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TPresenceFlow Implements IEOSAuthLoginListener, IEOSPresenceQueryListener, IEOSPresenceSetListener, IEOSPresenceChangedListener
	Field Presence:TEOSPresence
	Field ChangedSubscription:TEOSPresenceChangedSubscription
	Field Done:Int
	Field Success:Int
	Field WriteTest:Int
	Field WriteStage:Int

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
		Print "Auth login: " + EOSResultString(result)
		If pinGrantInfo Then
			Print "Complete sign-in at: " + pinGrantInfo.VerificationURIComplete
			Print "User code: " + pinGrantInfo.UserCode
		End If
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		Local accountId:TEOSEpicAccountId = selectedAccountId
		If Not accountId Then accountId = localUserId
		ChangedSubscription = Presence.AddNotifyPresenceChanged(Self)
		If Not Presence.Query(accountId, accountId, Self) Then
			Print "Could not start Presence query."
			Done = True
		End If
	End Method

	Method OnEOSPresenceQuery(result:EEOSResult, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
		Print "Presence query: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Print "Presence cached: " + Presence.HasPresence(localUserId, targetUserId)
			Local info:TEOSPresenceInfo
			result = Presence.CopyPresence(localUserId, targetUserId, info)
			Print "Copy Presence: " + EOSResultString(result)
			If result = EEOSResult.Success Then
				Print "Status: " + Int(info.Status)
				Print "Product: " + info.ProductName + " " + info.ProductVersion
				Print "Platform: " + info.Platform
				Print "Rich text: " + info.RichText
				For Local record:TEOSPresenceDataRecord = EachIn info.Records
					Print "  " + record.Key + "=" + record.Value
				Next
				If WriteTest And Not WriteStage Then
					Local modification:TEOSPresenceModification
					result = Presence.CreateModification(localUserId, modification)
					If result <> EEOSResult.Success Then Print "Create modification: " + EOSResultString(result); Done = True; Return
					result = modification.SetStatus(EEOSPresenceStatus.Online)
					If result = EEOSResult.Success Then result = modification.SetRawRichText("Testing EOS from BlitzMax")
					If result <> EEOSResult.Success Then modification.Release(); Print "Prepare presence: " + EOSResultString(result); Done = True; Return
					WriteStage = 1
					If Not Presence.SetPresence(localUserId, modification, Self) Then modification.Release(); Print "Could not publish Presence."; Done = True; Return
					modification.Release()
					Return
				End If
				Success = True
			End If
		End If
		Done = True
	End Method

	Method OnEOSPresenceSet(result:EEOSResult, localUserId:TEOSEpicAccountId, richPresenceResult:EEOSResult)
		Print "Set Presence: " + EOSResultString(result)
		Print "Rich Presence: " + EOSResultString(richPresenceResult)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return
		If Not Presence.Query(localUserId, localUserId, Self) Then Print "Could not verify Presence."; Done = True
	End Method

	Method OnEOSPresenceChanged(localUserId:TEOSEpicAccountId, presenceUserId:TEOSEpicAccountId)
		Print "Presence changed: " + presenceUserId.ToString()
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
Local loginMode:String = "developer"
If AppArgs.Length > 2 Then loginMode = AppArgs[2].ToLower()
Local writeTest:Int
If AppArgs.Length > 3 And AppArgs[3].ToLower() = "write" Then writeTest = True
If FileType(configPath) <> FILETYPE_FILE Then RuntimeError "Copy eos.local.conf.example to eos.local.conf and fill in your EOS values."
Local config:String = LoadText(configPath)

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS Presence example"
initializeOptions.ProductVersion = "0.14.0"
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
If Not platform Then RuntimeError "EOS platform creation failed. Check eos.local.conf."

Local auth:TEOSAuth = platform.Auth()
Local flow:TPresenceFlow = New TPresenceFlow
flow.Presence = platform.Presence()
flow.WriteTest = writeTest
If Not auth Or Not flow.Presence Then RuntimeError "Auth or Presence interface is unavailable."

Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
Select loginMode
	Case "developer"
		credentials.Type = EEOSLoginCredentialType.Developer
		credentials.Id = ConfigValue(config, "DEV_AUTH_HOST")
		credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
	Case "account-portal", "portal"
		credentials.Type = EEOSLoginCredentialType.AccountPortal
	Default
		RuntimeError "Login mode must be developer or account-portal."
End Select
Local loginOptions:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
loginOptions.Credentials = credentials
loginOptions.ScopeFlags = EEOSAuthScopeFlags.BasicProfile | EEOSAuthScopeFlags.Presence
If Not auth.Login(loginOptions, flow) Then RuntimeError "Could not start Auth login."

Local started:Int = MilliSecs()
Local timeout:Int = 120000
If loginMode = "account-portal" Or loginMode = "portal" Then timeout = 300000
While Not flow.Done And MilliSecs() - started < timeout
	platform.Tick()
	Delay 16
Wend
If Not flow.Done Then Print "Presence query timed out."

If flow.ChangedSubscription Then flow.ChangedSubscription.Remove()
platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError "EOS shutdown failed: " + EOSResultString(result)
If flow.Success Then Print "Presence flow completed."
