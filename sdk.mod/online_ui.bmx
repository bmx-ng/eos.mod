' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

Const EOS_UI_EVENT_ID_INVALID:ULong = 0

Rem
bbdoc: Returns whether Epic supports the Social Overlay on the current target platform.
about: This reports platform support, not whether the overlay is installed or
configured for a particular application. The current desktop EOS SDK supports
the Social Overlay on Windows x64.
End Rem
Function EOSSocialOverlaySupportedOnPlatform:Int()
	Local supported:Int
?win32x64
	supported = True
?
	Return supported
End Function

Enum EEOSUIOperation
	ShowFriends
	HideFriends
	ShowBlockPlayer
	ShowReportPlayer
End Enum

Enum EEOSUINotificationLocation
	TopLeft
	TopRight
	BottomLeft
	BottomRight
End Enum

Interface IEOSUIOperationListener
	Method OnEOSUIOperation(result:EEOSResult, operation:EEOSUIOperation, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId)
End Interface

Interface IEOSUIDisplaySettingsListener
	Method OnEOSUIDisplaySettingsUpdated(isVisible:Int, isExclusiveInput:Int)
End Interface

Type TEOSUIOperationRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSUIOperationListener
	Field _operation:EEOSUIOperation
	Field _complete:Int

	Public
	Function _Create:TEOSUIOperationRequest(owner:TEOSPlatform, listener:IEOSUIOperationListener, operation:EEOSUIOperation)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSUIOperationRequest = New TEOSUIOperationRequest
		request._owner = owner
		request._listener = listener
		request._operation = operation
		Return request
	End Function

	Function _Complete(request:TEOSUIOperationRequest, result:EEOSResult, localHandle:Byte Ptr, targetHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSUIOperationListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSUIOperation( ..
				result, request._operation, TEOSEpicAccountId._Create(localHandle), ..
				TEOSEpicAccountId._Create(targetHandle))
		End If
	End Function

	Function _Cancel(request:TEOSUIOperationRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSUIDisplaySettingsSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSUIDisplaySettingsListener
	Field _id:ULong

	Public
	Function _Create:TEOSUIDisplaySettingsSubscription(owner:TEOSPlatform, listener:IEOSUIDisplaySettingsListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSUIDisplaySettingsSubscription = New TEOSUIDisplaySettingsSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSUIDisplaySettingsSubscription, isVisible:Int, isExclusiveInput:Int) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSUIDisplaySettingsUpdated(isVisible, isExclusiveInput)
		End If
	End Function

	Function _Cancel(subscription:TEOSUIDisplaySettingsSubscription) { nomangle }
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
			bmx_eos_ui_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Rem
bbdoc: Controls the Epic Social Overlay and acknowledges UI events.
End Rem
Type TEOSUI
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSUI(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local ui:TEOSUI = New TEOSUI
		ui._owner = owner
		ui._handle = handle
		Return ui
	End Function

	Method ShowFriends:TEOSUIOperationRequest(localUserId:TEOSEpicAccountId, listener:IEOSUIOperationListener)
		Return _FriendsOperation(localUserId, listener, EEOSUIOperation.ShowFriends)
	End Method

	Method HideFriends:TEOSUIOperationRequest(localUserId:TEOSEpicAccountId, listener:IEOSUIOperationListener)
		Return _FriendsOperation(localUserId, listener, EEOSUIOperation.HideFriends)
	End Method

	Method FriendsVisible:Int(localUserId:TEOSEpicAccountId)
		If Not _ValidUser(localUserId) Then
			Return False
		End If
		Return bmx_eos_ui_friends_visible(_handle, localUserId._NativeHandle())
	End Method

	Method FriendsExclusiveInput:Int(localUserId:TEOSEpicAccountId)
		If Not _ValidUser(localUserId) Then
			Return False
		End If
		Return bmx_eos_ui_friends_exclusive_input(_handle, localUserId._NativeHandle())
	End Method

	Method SetDisplayPreference:EEOSResult(location:EEOSUINotificationLocation)
		If Not _Valid() Then
			Return EEOSResult.InvalidState
		End If
		If location < EEOSUINotificationLocation.TopLeft Or ..
			location > EEOSUINotificationLocation.BottomRight Then
			Return EEOSResult.InvalidParameters
		End If
		Return bmx_eos_ui_set_display_preference(_handle, location)
	End Method

	Method DisplayPreference:EEOSUINotificationLocation()
		If Not _Valid() Then
			Return EEOSUINotificationLocation.TopRight
		End If
		Return bmx_eos_ui_get_display_preference(_handle)
	End Method

	Method AcknowledgeEvent:EEOSResult(uiEventId:ULong, result:EEOSResult)
		If Not _Valid() Then
			Return EEOSResult.InvalidState
		End If
		If uiEventId = EOS_UI_EVENT_ID_INVALID Then
			Return EEOSResult.InvalidParameters
		End If
		Return bmx_eos_ui_acknowledge_event(_handle, uiEventId, result)
	End Method

	Method ShowBlockPlayer:TEOSUIOperationRequest(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, listener:IEOSUIOperationListener)
		Return _PlayerOperation( ..
			localUserId, targetUserId, listener, EEOSUIOperation.ShowBlockPlayer)
	End Method

	Method ShowReportPlayer:TEOSUIOperationRequest(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, listener:IEOSUIOperationListener)
		Return _PlayerOperation( ..
			localUserId, targetUserId, listener, EEOSUIOperation.ShowReportPlayer)
	End Method

	Method PauseSocialOverlay:EEOSResult(paused:Int)
		If Not _Valid() Then
			Return EEOSResult.InvalidState
		End If
		Return bmx_eos_ui_pause_social_overlay(_handle, paused)
	End Method

	Method IsSocialOverlayPaused:Int()
		If Not _Valid() Then
			Return False
		End If
		Return bmx_eos_ui_is_social_overlay_paused(_handle)
	End Method

	Method AddNotifyDisplaySettingsUpdated:TEOSUIDisplaySettingsSubscription(listener:IEOSUIDisplaySettingsListener)
		If Not _Valid() Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSUIDisplaySettingsSubscription = ..
			TEOSUIDisplaySettingsSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_ui_add_notify_display_settings( ..
			_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then
			Return Null
		End If
		Return subscription
	End Method

	Private
	Method _Valid:Int()
		Return _owner <> Null And _owner.IsValid() And _handle <> Null
	End Method

	Method _ValidUser:Int(userId:TEOSEpicAccountId)
		Return _Valid() And userId <> Null And userId.IsValid()
	End Method

	Method _FriendsOperation:TEOSUIOperationRequest(localUserId:TEOSEpicAccountId, listener:IEOSUIOperationListener, operation:EEOSUIOperation)
		If Not _ValidUser(localUserId) Or Not listener Then
			Return Null
		End If
		Local request:TEOSUIOperationRequest = TEOSUIOperationRequest._Create( ..
			_owner, listener, operation)
		bmx_eos_ui_friends_operation( ..
			_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), operation)
		Return request
	End Method

	Method _PlayerOperation:TEOSUIOperationRequest(localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId, listener:IEOSUIOperationListener, operation:EEOSUIOperation)
		If Not _ValidUser(localUserId) Or Not targetUserId Or ..
			Not targetUserId.IsValid() Or Not listener Then
			Return Null
		End If
		Local request:TEOSUIOperationRequest = TEOSUIOperationRequest._Create( ..
			_owner, listener, operation)
		bmx_eos_ui_player_operation( ..
			_owner._NativeHandle(), _handle, request, localUserId._NativeHandle(), ..
			targetUserId._NativeHandle(), operation)
		Return request
	End Method
End Type

Private

Extern
	Function bmx_eos_platform_get_ui_interface:Byte Ptr(platformHandle:Byte Ptr)
	Function bmx_eos_ui_friends_operation(platformHandle:Byte Ptr, uiHandle:Byte Ptr, request:TEOSUIOperationRequest, localUserHandle:Byte Ptr, operation:EEOSUIOperation)
	Function bmx_eos_ui_player_operation(platformHandle:Byte Ptr, uiHandle:Byte Ptr, request:TEOSUIOperationRequest, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr, operation:EEOSUIOperation)
	Function bmx_eos_ui_friends_visible:Int(uiHandle:Byte Ptr, localUserHandle:Byte Ptr)
	Function bmx_eos_ui_friends_exclusive_input:Int(uiHandle:Byte Ptr, localUserHandle:Byte Ptr)
	Function bmx_eos_ui_set_display_preference:EEOSResult(uiHandle:Byte Ptr, location:EEOSUINotificationLocation)
	Function bmx_eos_ui_get_display_preference:EEOSUINotificationLocation(uiHandle:Byte Ptr)
	Function bmx_eos_ui_acknowledge_event:EEOSResult(uiHandle:Byte Ptr, uiEventId:ULong, result:EEOSResult)
	Function bmx_eos_ui_pause_social_overlay:EEOSResult(uiHandle:Byte Ptr, paused:Int)
	Function bmx_eos_ui_is_social_overlay_paused:Int(uiHandle:Byte Ptr)
	Function bmx_eos_ui_add_notify_display_settings:ULong(platformHandle:Byte Ptr, uiHandle:Byte Ptr, subscription:TEOSUIDisplaySettingsSubscription)
	Function bmx_eos_ui_remove_notify(id:ULong)
End Extern

Public
