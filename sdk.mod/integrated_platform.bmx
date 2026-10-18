' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

Const EOS_INTEGRATED_PLATFORM_STEAM:String = "STEAM"
Const EOS_INTEGRATED_PLATFORM_STEAM_MAX_INTERFACE_VERSIONS_SIZE:UInt = 4096

Enum EEOSIntegratedPlatformManagementFlags Flags
	Disabled = $0001
	LibraryManagedByApplication = $0002
	LibraryManagedBySDK = $0004
	DisablePresenceMirroring = $0008
	DisableSDKManagedSessions = $0010
	PreferEOSIdentity = $0020
	PreferIntegratedIdentity = $0040
	ApplicationManagedIdentityLogin = $0080
End Enum

Enum EEOSIntegratedPlatformPreLogoutAction
	ProcessLogoutImmediately
	DeferLogout
End Enum

Rem
bbdoc: Steam-specific initialization values for EOS Integrated Platform support.
about: When the application manages Steam, initialize Steam before creating the
EOS platform and leave OverrideLibraryPath and SteamApiInterfaceVersions empty.
When EOS manages Steam, provide the absolute runtime-library path and the exact
null-separated interface-version block from the matching steam_api.h.
End Rem
Type TEOSIntegratedPlatformSteamOptions
	Field Flags:EEOSIntegratedPlatformManagementFlags = ..
		EEOSIntegratedPlatformManagementFlags.LibraryManagedByApplication
	Field OverrideLibraryPath:String
	Field SteamMajorVersion:UInt
	Field SteamMinorVersion:UInt
	Field SteamApiInterfaceVersions:Byte[]
End Type

Rem
bbdoc: Collects native-platform options used while creating an EOS platform.
about: Release this container after passing it to #TEOSPlatform.Create. EOS
copies the configuration during platform creation.
End Rem
Type TEOSIntegratedPlatformOptionsContainer
	Private
	Field _handle:Byte Ptr

	Public
	Function Create:EEOSResult(container:TEOSIntegratedPlatformOptionsContainer Var)
		container = Null
		If Not EOSIsInitialized() Then
			Return EEOSResult.NotConfigured
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = ..
			bmx_eos_integrated_platform_options_create(handle)
		If result = EEOSResult.Success And handle Then
			container = New TEOSIntegratedPlatformOptionsContainer
			container._handle = handle
		End If
		Return result
	End Function

	Method _NativeHandle:Byte Ptr()
		Return _handle
	End Method

	Method AddSteam:EEOSResult(options:TEOSIntegratedPlatformSteamOptions)
		If Not _handle Then
			Return EEOSResult.InvalidState
		End If
		If Not options Then
			Return EEOSResult.InvalidParameters
		End If
		If options.SteamApiInterfaceVersions And ..
			options.SteamApiInterfaceVersions.Length > ..
			EOS_INTEGRATED_PLATFORM_STEAM_MAX_INTERFACE_VERSIONS_SIZE Then
			Return EEOSResult.LimitExceeded
		End If
		Return bmx_eos_integrated_platform_options_add_steam( ..
			_handle, options.Flags, options.OverrideLibraryPath, ..
			options.SteamMajorVersion, options.SteamMinorVersion, ..
			options.SteamApiInterfaceVersions)
	End Method

	Method IsValid:Int()
		Return _handle <> Null
	End Method

	Method Release()
		If _handle Then
			bmx_eos_integrated_platform_options_release(_handle)
			_handle = Null
		End If
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type

Interface IEOSIntegratedPlatformLoginStatusListener
	Method OnEOSIntegratedPlatformLoginStatusChanged( ..
		platformType:String, localPlatformUserId:String, ..
		accountId:TEOSEpicAccountId, productUserId:TEOSProductUserId, ..
		previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus)
End Interface

Interface IEOSIntegratedPlatformPreLogoutListener
	Method OnEOSIntegratedPlatformPreLogout:EEOSIntegratedPlatformPreLogoutAction( ..
		platformType:String, localPlatformUserId:String, ..
		accountId:TEOSEpicAccountId, productUserId:TEOSProductUserId)
End Interface

Type TEOSIntegratedPlatformLoginStatusSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSIntegratedPlatformLoginStatusListener
	Field _id:ULong

	Public
	Function _Create:TEOSIntegratedPlatformLoginStatusSubscription( ..
		owner:TEOSPlatform, listener:IEOSIntegratedPlatformLoginStatusListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSIntegratedPlatformLoginStatusSubscription = ..
			New TEOSIntegratedPlatformLoginStatusSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify( ..
		subscription:TEOSIntegratedPlatformLoginStatusSubscription, ..
		platformType:String, localPlatformUserId:String, ..
		accountHandle:Byte Ptr, productUserHandle:Byte Ptr, ..
		previousStatus:EEOSLoginStatus, currentStatus:EEOSLoginStatus) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSIntegratedPlatformLoginStatusChanged( ..
				platformType, localPlatformUserId, ..
				TEOSEpicAccountId._Create(accountHandle), ..
				TEOSProductUserId._Create(productUserHandle), ..
				previousStatus, currentStatus)
		End If
	End Function

	Function _Cancel( ..
		subscription:TEOSIntegratedPlatformLoginStatusSubscription) { nomangle }
		If subscription Then
			subscription._id = 0
			subscription._listener = Null
		End If
	End Function

	Method _SetId(id:ULong)
		_id = id
	End Method

	Method Remove()
		If _id Then
			Local id:ULong = _id
			_id = 0
			_listener = Null
			bmx_eos_integrated_platform_remove_login_status_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSIntegratedPlatformPreLogoutRegistration
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSIntegratedPlatformPreLogoutListener
	Field _active:Int

	Public
	Function _Create:TEOSIntegratedPlatformPreLogoutRegistration( ..
		owner:TEOSPlatform, listener:IEOSIntegratedPlatformPreLogoutListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local registration:TEOSIntegratedPlatformPreLogoutRegistration = ..
			New TEOSIntegratedPlatformPreLogoutRegistration
		registration._owner = owner
		registration._listener = listener
		Return registration
	End Function

	Function _Notify:EEOSIntegratedPlatformPreLogoutAction( ..
		registration:TEOSIntegratedPlatformPreLogoutRegistration, ..
		platformType:String, localPlatformUserId:String, ..
		accountHandle:Byte Ptr, productUserHandle:Byte Ptr) { nomangle }
		If registration And registration._listener Then
			Return registration._listener.OnEOSIntegratedPlatformPreLogout( ..
				platformType, localPlatformUserId, ..
				TEOSEpicAccountId._Create(accountHandle), ..
				TEOSProductUserId._Create(productUserHandle))
		End If
		Return EEOSIntegratedPlatformPreLogoutAction.ProcessLogoutImmediately
	End Function

	Function _Cancel( ..
		registration:TEOSIntegratedPlatformPreLogoutRegistration) { nomangle }
		If registration Then
			registration._active = False
			registration._listener = Null
		End If
	End Function

	Method _Activate()
		_active = True
	End Method

	Method Remove()
		If _active Then
			_active = False
			_listener = Null
			bmx_eos_integrated_platform_clear_pre_logout(Self)
		End If
	End Method

	Method IsActive:Int()
		Return _active And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Rem
bbdoc: Coordinates local native-service users with EOS.
End Rem
Type TEOSIntegratedPlatform
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSIntegratedPlatform(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local integrated:TEOSIntegratedPlatform = New TEOSIntegratedPlatform
		integrated._owner = owner
		integrated._handle = handle
		Return integrated
	End Function

	Method SetUserLoginStatus:EEOSResult( ..
		platformType:String, localPlatformUserId:String, status:EEOSLoginStatus)
		If Not _Valid() Then
			Return EEOSResult.InvalidState
		End If
		If Not platformType Or Not localPlatformUserId Then
			Return EEOSResult.InvalidParameters
		End If
		Return bmx_eos_integrated_platform_set_user_login_status( ..
			_handle, platformType, localPlatformUserId, status)
	End Method

	Method AddNotifyUserLoginStatusChanged:TEOSIntegratedPlatformLoginStatusSubscription( ..
		listener:IEOSIntegratedPlatformLoginStatusListener)
		If Not _Valid() Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSIntegratedPlatformLoginStatusSubscription = ..
			TEOSIntegratedPlatformLoginStatusSubscription._Create(_owner, listener)
		subscription._SetId( ..
			bmx_eos_integrated_platform_add_login_status_notify( ..
				_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then
			Return Null
		End If
		Return subscription
	End Method

	Method SetPreLogoutHandler:EEOSResult( ..
		listener:IEOSIntegratedPlatformPreLogoutListener, ..
		registration:TEOSIntegratedPlatformPreLogoutRegistration Var)
		registration = Null
		If Not _Valid() Then
			Return EEOSResult.InvalidState
		End If
		If Not listener Then
			Return EEOSResult.InvalidParameters
		End If
		Local newRegistration:TEOSIntegratedPlatformPreLogoutRegistration = ..
			TEOSIntegratedPlatformPreLogoutRegistration._Create(_owner, listener)
		Local result:EEOSResult = ..
			bmx_eos_integrated_platform_set_pre_logout( ..
				_owner._NativeHandle(), _handle, newRegistration)
		If result = EEOSResult.Success Then
			newRegistration._Activate()
			registration = newRegistration
		End If
		Return result
	End Method

	Method FinalizeDeferredUserLogout:EEOSResult( ..
		platformType:String, localPlatformUserId:String, ..
		expectedStatus:EEOSLoginStatus)
		If Not _Valid() Then
			Return EEOSResult.InvalidState
		End If
		If Not platformType Or Not localPlatformUserId Or ..
			(expectedStatus <> EEOSLoginStatus.LoggedIn And ..
			expectedStatus <> EEOSLoginStatus.NotLoggedIn) Then
			Return EEOSResult.InvalidParameters
		End If
		Return bmx_eos_integrated_platform_finalize_logout( ..
			_handle, platformType, localPlatformUserId, expectedStatus)
	End Method

	Private
	Method _Valid:Int()
		Return _owner <> Null And _owner.IsValid() And _handle <> Null
	End Method
End Type

Private

Extern
	Function bmx_eos_integrated_platform_options_create:EEOSResult(handle:Byte Ptr Var)
	Function bmx_eos_integrated_platform_options_add_steam:EEOSResult(handle:Byte Ptr, flags:EEOSIntegratedPlatformManagementFlags, overrideLibraryPath:String, steamMajorVersion:UInt, steamMinorVersion:UInt, interfaceVersions:Byte[])
	Function bmx_eos_integrated_platform_options_release(handle:Byte Ptr)
	Function bmx_eos_platform_get_integrated_platform_interface:Byte Ptr(platformHandle:Byte Ptr)
	Function bmx_eos_integrated_platform_set_user_login_status:EEOSResult(handle:Byte Ptr, platformType:String, localPlatformUserId:String, status:EEOSLoginStatus)
	Function bmx_eos_integrated_platform_add_login_status_notify:ULong(platformHandle:Byte Ptr, handle:Byte Ptr, subscription:TEOSIntegratedPlatformLoginStatusSubscription)
	Function bmx_eos_integrated_platform_remove_login_status_notify(id:ULong)
	Function bmx_eos_integrated_platform_set_pre_logout:EEOSResult(platformHandle:Byte Ptr, handle:Byte Ptr, registration:TEOSIntegratedPlatformPreLogoutRegistration)
	Function bmx_eos_integrated_platform_clear_pre_logout(registration:TEOSIntegratedPlatformPreLogoutRegistration)
	Function bmx_eos_integrated_platform_finalize_logout:EEOSResult(handle:Byte Ptr, platformType:String, localPlatformUserId:String, expectedStatus:EEOSLoginStatus)
End Extern

Public
