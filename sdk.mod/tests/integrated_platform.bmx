SuperStrict

Framework EOS.SDK
Import BRL.StandardIO

Type TIntegratedPlatformEvents Implements ..
	IEOSIntegratedPlatformLoginStatusListener, ..
	IEOSIntegratedPlatformPreLogoutListener
	Field loginStatusCount:Int
	Field preLogoutCount:Int
	Field platformType:String
	Field platformUserId:String
	Field previousStatus:EEOSLoginStatus
	Field currentStatus:EEOSLoginStatus

	Method OnEOSIntegratedPlatformLoginStatusChanged( ..
		platformType:String, localPlatformUserId:String, ..
		accountId:TEOSEpicAccountId, productUserId:TEOSProductUserId, ..
		previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus) Override
		loginStatusCount :+ 1
		Self.platformType = platformType
		platformUserId = localPlatformUserId
		Self.previousStatus = previousStatus
		Self.currentStatus = currentStatus
	End Method

	Method OnEOSIntegratedPlatformPreLogout:EEOSIntegratedPlatformPreLogoutAction( ..
		platformType:String, localPlatformUserId:String, ..
		accountId:TEOSEpicAccountId, productUserId:TEOSProductUserId) Override
		preLogoutCount :+ 1
		Self.platformType = platformType
		platformUserId = localPlatformUserId
		Return EEOSIntegratedPlatformPreLogoutAction.DeferLogout
	End Method
End Type

Function Check(value:Int, message:String)
	If Not value Then
		RuntimeError message
	End If
End Function

Local owner:TEOSPlatform = New TEOSPlatform
Local events:TIntegratedPlatformEvents = New TIntegratedPlatformEvents
Local subscription:TEOSIntegratedPlatformLoginStatusSubscription = ..
	TEOSIntegratedPlatformLoginStatusSubscription._Create(owner, events)
Check(subscription <> Null, "login-status subscription should be created")
TEOSIntegratedPlatformLoginStatusSubscription._Notify( ..
	subscription, EOS_INTEGRATED_PLATFORM_STEAM, "76561190000000000", ..
	Null, Null, EEOSLoginStatus.NotLoggedIn, EEOSLoginStatus.LoggedIn)
Check(events.loginStatusCount = 1, "login-status listener should run")
Check(events.platformType = EOS_INTEGRATED_PLATFORM_STEAM, ..
	"integrated platform type should be preserved")
Check(events.platformUserId = "76561190000000000", ..
	"platform user id should be preserved")
Check(events.previousStatus = EEOSLoginStatus.NotLoggedIn, ..
	"previous login state should be preserved")
Check(events.currentStatus = EEOSLoginStatus.LoggedIn, ..
	"current login state should be preserved")
TEOSIntegratedPlatformLoginStatusSubscription._Cancel(subscription)
Check(Not subscription.IsActive(), ..
	"canceled login-status subscription should be inactive")

Local registration:TEOSIntegratedPlatformPreLogoutRegistration = ..
	TEOSIntegratedPlatformPreLogoutRegistration._Create(owner, events)
Check(registration <> Null, "pre-logout registration should be created")
Local action:EEOSIntegratedPlatformPreLogoutAction = ..
	TEOSIntegratedPlatformPreLogoutRegistration._Notify( ..
		registration, EOS_INTEGRATED_PLATFORM_STEAM, ..
		"76561190000000000", Null, Null)
Check(events.preLogoutCount = 1, "pre-logout listener should run")
Check(action = EEOSIntegratedPlatformPreLogoutAction.DeferLogout, ..
	"pre-logout action should be preserved")
TEOSIntegratedPlatformPreLogoutRegistration._Cancel(registration)
Check(Not registration.IsActive(), ..
	"canceled pre-logout registration should be inactive")

Local invalidIntegrated:TEOSIntegratedPlatform = ..
	TEOSIntegratedPlatform._Create(owner, Byte Ptr(1))
Check(invalidIntegrated.SetUserLoginStatus( ..
	EOS_INTEGRATED_PLATFORM_STEAM, "1", EEOSLoginStatus.LoggedIn) = ..
	EEOSResult.InvalidState, ..
	"login-state update should reject an invalid platform")
Check(invalidIntegrated.FinalizeDeferredUserLogout( ..
	EOS_INTEGRATED_PLATFORM_STEAM, "1", EEOSLoginStatus.UsingLocalProfile) = ..
	EEOSResult.InvalidState, ..
	"deferred logout should reject an invalid platform")

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS Integrated Platform tests"
initializeOptions.ProductVersion = "0.25.0"
Local result:EEOSResult = EOSInitialize(initializeOptions)
Check(result = EEOSResult.Success, "EOS initialization should succeed")

Local container:TEOSIntegratedPlatformOptionsContainer
result = TEOSIntegratedPlatformOptionsContainer.Create(container)
Check(result = EEOSResult.Success And container <> Null, ..
	"integrated platform options container should be created")
Local steamOptions:TEOSIntegratedPlatformSteamOptions = ..
	New TEOSIntegratedPlatformSteamOptions
steamOptions.SteamMajorVersion = 1
steamOptions.SteamMinorVersion = 58
result = container.AddSteam(steamOptions)
Check(result = EEOSResult.Success, ..
	"application-managed Steam options should be accepted")
steamOptions.SteamApiInterfaceVersions = New Byte[4097]
result = container.AddSteam(steamOptions)
Check(result = EEOSResult.LimitExceeded, ..
	"oversized Steam interface-version data should be rejected")
container.Release()
Check(Not container.IsValid(), "released options container should be invalid")
result = container.AddSteam(steamOptions)
Check(result = EEOSResult.InvalidState, ..
	"released options container should reject changes")

result = EOSShutdown()
Check(result = EEOSResult.Success, "EOS shutdown should succeed")
Check(EOS_INTEGRATED_PLATFORM_STEAM_MAX_INTERFACE_VERSIONS_SIZE = 4096, ..
	"Steam interface-version size limit should match EOS")
Check(EEOSIntegratedPlatformManagementFlags.ApplicationManagedIdentityLogin = $80, ..
	"identity-login management flag should match EOS")

Print "EOS Integrated Platform tests passed."
