SuperStrict

Framework EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TFriendsFlow Implements IEOSAuthLoginListener, IEOSFriendsQueryListener, IEOSFriendsUpdateListener, IEOSBlockedUsersUpdateListener
	Field Friends:TEOSFriends
	Field FriendsSubscription:TEOSFriendsUpdateSubscription
	Field BlockedSubscription:TEOSBlockedUsersUpdateSubscription
	Field Done:Int
	Field Success:Int

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
		FriendsSubscription = Friends.AddNotifyFriendsUpdate(Self)
		BlockedSubscription = Friends.AddNotifyBlockedUsersUpdate(Self)
		If Not Friends.Query(accountId, Self) Then
			Print "Could not start Friends query."
			Done = True
		End If
	End Method

	Method OnEOSFriendsQuery(result:EEOSResult, localUserId:TEOSEpicAccountId)
		Print "Friends query: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then
			Local count:Int = Friends.FriendCount(localUserId)
			Print "Friends and pending invitations: " + count
			For Local index:Int = 0 Until count
				Local friendId:TEOSEpicAccountId = Friends.FriendAtIndex(localUserId, index)
				If friendId Then Print "  " + friendId.ToString() + " | status " + Int(Friends.Status(localUserId, friendId))
			Next
			Local blockedCount:Int = Friends.BlockedUserCount(localUserId)
			Print "Blocked users: " + blockedCount
			For Local index:Int = 0 Until blockedCount
				Local blockedId:TEOSEpicAccountId = Friends.BlockedUserAtIndex(localUserId, index)
				If blockedId Then Print "  " + blockedId.ToString()
			Next
			Success = True
		End If
		Done = True
	End Method

	Method OnEOSFriendsUpdate(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, previousStatus:EEOSFriendsStatus, currentStatus:EEOSFriendsStatus)
		Print "Friend status changed: " + targetUserId.ToString() + " | " + Int(previousStatus) + " -> " + Int(currentStatus)
	End Method

	Method OnEOSBlockedUsersUpdate(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, blocked:Int)
		Print "Blocked status changed: " + targetUserId.ToString() + " | blocked " + blocked
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
If FileType(configPath) <> FILETYPE_FILE Then RuntimeError "Copy eos.local.conf.example to eos.local.conf and fill in your EOS values."
Local config:String = LoadText(configPath)

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS Friends example"
initializeOptions.ProductVersion = "0.13.0"
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
Local flow:TFriendsFlow = New TFriendsFlow
flow.Friends = platform.Friends()
If Not auth Or Not flow.Friends Then RuntimeError "Auth or Friends interface is unavailable."

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
loginOptions.ScopeFlags = EEOSAuthScopeFlags.BasicProfile | EEOSAuthScopeFlags.FriendsList
If Not auth.Login(loginOptions, flow) Then RuntimeError "Could not start Auth login."

Local started:Int = MilliSecs()
Local timeout:Int = 120000
If loginMode = "account-portal" Or loginMode = "portal" Then timeout = 300000
While Not flow.Done And MilliSecs() - started < timeout
	platform.Tick()
	Delay 16
Wend
If Not flow.Done Then Print "Friends query timed out."

If flow.FriendsSubscription Then flow.FriendsSubscription.Remove()
If flow.BlockedSubscription Then flow.BlockedSubscription.Remove()
platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError "EOS shutdown failed: " + EOSResultString(result)
If flow.Success Then Print "Friends flow completed."
