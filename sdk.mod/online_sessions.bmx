' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

Const EOS_SESSIONS_MAX_REGISTERED_PLAYERS:Int = 1000
Const EOS_SESSIONS_MAX_SEARCH_RESULTS:Int = 200
Const EOS_SESSIONMODIFICATION_MAX_ATTRIBUTES:Int = 64
Const EOS_SESSIONMODIFICATION_MAX_ATTRIBUTE_LENGTH:Int = 64
Const EOS_SESSIONS_SEARCH_BUCKET_ID:String = "bucket"
Const EOS_SESSIONS_SEARCH_EMPTY_SERVERS_ONLY:String = "emptyonly"
Const EOS_SESSIONS_SEARCH_NONEMPTY_SERVERS_ONLY:String = "nonemptyonly"
Const EOS_SESSIONS_SEARCH_MIN_SLOTS_AVAILABLE:String = "minslotsavailable"

Enum EEOSOnlineSessionState
	NoSession = 0
	Creating = 1
	Pending = 2
	Starting = 3
	InProgress = 4
	Ending = 5
	Ended = 6
	Destroying = 7
End Enum

Enum EEOSOnlineSessionPermissionLevel
	PublicAdvertised = 0
	JoinViaPresence = 1
	InviteOnly = 2
End Enum

Enum EEOSSessionAttributeAdvertisementType
	DontAdvertise = 0
	Advertise = 1
End Enum

Enum EEOSSessionAttributeType
	Boolean = 0
	Int64 = 1
	DoubleValue = 2
	StringValue = 3
End Enum

Enum EEOSSessionOperation
	DestroySession
	JoinSession
	StartSession
	EndSession
	RegisterPlayers
	UnregisterPlayers
	SendInvite
	RejectInvite
	QueryInvites
End Enum

Type TEOSSessionCreateOptions
	Field SessionName:String
	Field BucketId:String
	Field MaxPlayers:UInt = 4
	Field LocalUserId:TEOSProductUserId
	Field PresenceEnabled:Int
	Field SessionId:String
	Field SanctionsEnabled:Int
	Field AllowedPlatformIds:Int[]
End Type

Type TEOSSessionJoinOptions
	Field SessionName:String
	Field SessionDetails:TEOSSessionDetails
	Field LocalUserId:TEOSProductUserId
	Field PresenceEnabled:Int
End Type

Rem
bbdoc: A copied snapshot of the searchable settings and address for a session.
End Rem
Type TEOSSessionInfo
	Field SessionId:String
	Field HostAddress:String
	Field OpenPublicConnections:UInt
	Field BucketId:String
	Field MaxPlayers:UInt
	Field AllowJoinInProgress:Int
	Field PermissionLevel:EEOSOnlineSessionPermissionLevel
	Field InvitesAllowed:Int
	Field SanctionsEnabled:Int
	Field AllowedPlatformIds:Int[]
	Field OwnerUserId:TEOSProductUserId
	Field OwnerServerClientId:String
End Type

Type TEOSActiveSessionInfo Extends TEOSSessionInfo
	Field SessionName:String
	Field LocalUserId:TEOSProductUserId
	Field State:EEOSOnlineSessionState
End Type

Type TEOSSessionAttribute
	Field Key:String
	Field ValueType:EEOSSessionAttributeType
	Field IntValue:Long
	Field DoubleValue:Double
	Field BoolValue:Int
	Field StringValue:String
	Field AdvertisementType:EEOSSessionAttributeAdvertisementType
End Type

Interface IEOSSessionUpdateListener
	Method OnEOSSessionUpdated(result:EEOSResult, sessionName:String, sessionId:String)
End Interface

Interface IEOSSessionOperationListener
	Method OnEOSSessionOperation(result:EEOSResult, operation:EEOSSessionOperation)
End Interface

Interface IEOSSessionSearchListener
	Method OnEOSSessionSearch(result:EEOSResult)
End Interface

Interface IEOSSessionPlayersListener
	Method OnEOSSessionPlayersChanged(result:EEOSResult, operation:EEOSSessionOperation, changedCount:Int, sanctionedCount:Int)
End Interface

Interface IEOSSessionInviteReceivedListener
	Method OnEOSSessionInviteReceived(inviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId)
End Interface

Interface IEOSSessionInviteAcceptedListener
	Method OnEOSSessionInviteAccepted(sessionId:String, inviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId)
End Interface

Interface IEOSSessionInviteRejectedListener
	Method OnEOSSessionInviteRejected(sessionId:String, inviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId)
End Interface

Interface IEOSJoinSessionAcceptedListener
	Method OnEOSJoinSessionAccepted(localUserId:TEOSProductUserId, uiEventId:ULong)
End Interface

Interface IEOSLeaveSessionRequestedListener
	Method OnEOSLeaveSessionRequested(localUserId:TEOSProductUserId, sessionName:String)
End Interface

Type TEOSSessionUpdateRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSessionUpdateListener
	Field _complete:Int

	Public
	Function _Create:TEOSSessionUpdateRequest(owner:TEOSPlatform, listener:IEOSSessionUpdateListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSSessionUpdateRequest = New TEOSSessionUpdateRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSSessionUpdateRequest, result:EEOSResult, sessionName:String, sessionId:String) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSSessionUpdateListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSSessionUpdated(result, sessionName, sessionId)
		End If
	End Function

	Function _Cancel(request:TEOSSessionUpdateRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "", "")
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSSessionOperationRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSessionOperationListener
	Field _operation:EEOSSessionOperation
	Field _complete:Int

	Public
	Function _Create:TEOSSessionOperationRequest(owner:TEOSPlatform, listener:IEOSSessionOperationListener, operation:EEOSSessionOperation)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSSessionOperationRequest = New TEOSSessionOperationRequest
		request._owner = owner
		request._listener = listener
		request._operation = operation
		Return request
	End Function

	Function _Complete(request:TEOSSessionOperationRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSSessionOperationListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSSessionOperation(result, request._operation)
		End If
	End Function

	Function _Cancel(request:TEOSSessionOperationRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSSessionSearchRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSessionSearchListener
	Field _complete:Int

	Public
	Function _Create:TEOSSessionSearchRequest(owner:TEOSPlatform, listener:IEOSSessionSearchListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSSessionSearchRequest = New TEOSSessionSearchRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSSessionSearchRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSSessionSearchListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSSessionSearch(result)
		End If
	End Function

	Function _Cancel(request:TEOSSessionSearchRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSSessionPlayersRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSessionPlayersListener
	Field _operation:EEOSSessionOperation
	Field _complete:Int

	Public
	Function _Create:TEOSSessionPlayersRequest(owner:TEOSPlatform, listener:IEOSSessionPlayersListener, operation:EEOSSessionOperation)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSSessionPlayersRequest = New TEOSSessionPlayersRequest
		request._owner = owner
		request._listener = listener
		request._operation = operation
		Return request
	End Function

	Function _Complete(request:TEOSSessionPlayersRequest, result:EEOSResult, changedCount:Int, sanctionedCount:Int) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSSessionPlayersListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSSessionPlayersChanged(result, request._operation, changedCount, sanctionedCount)
		End If
	End Function

	Function _Cancel(request:TEOSSessionPlayersRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, 0, 0)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSSessionInviteReceivedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSessionInviteReceivedListener
	Field _id:ULong

	Public
	Function _Create:TEOSSessionInviteReceivedSubscription(owner:TEOSPlatform, listener:IEOSSessionInviteReceivedListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSSessionInviteReceivedSubscription = New TEOSSessionInviteReceivedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSSessionInviteReceivedSubscription, inviteId:String, localHandle:Byte Ptr, senderHandle:Byte Ptr) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSSessionInviteReceived( ..
				inviteId, TEOSProductUserId._Create(localHandle), TEOSProductUserId._Create(senderHandle))
		End If
	End Function

	Function _Cancel(subscription:TEOSSessionInviteReceivedSubscription) { nomangle }
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
			bmx_eos_sessions_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSSessionInviteAcceptedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSessionInviteAcceptedListener
	Field _id:ULong

	Public
	Function _Create:TEOSSessionInviteAcceptedSubscription(owner:TEOSPlatform, listener:IEOSSessionInviteAcceptedListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSSessionInviteAcceptedSubscription = New TEOSSessionInviteAcceptedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSSessionInviteAcceptedSubscription, sessionId:String, inviteId:String, localHandle:Byte Ptr, senderHandle:Byte Ptr) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSSessionInviteAccepted( ..
				sessionId, inviteId, TEOSProductUserId._Create(localHandle), ..
				TEOSProductUserId._Create(senderHandle))
		End If
	End Function

	Function _Cancel(subscription:TEOSSessionInviteAcceptedSubscription) { nomangle }
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
			bmx_eos_sessions_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSSessionInviteRejectedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSessionInviteRejectedListener
	Field _id:ULong

	Public
	Function _Create:TEOSSessionInviteRejectedSubscription(owner:TEOSPlatform, listener:IEOSSessionInviteRejectedListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSSessionInviteRejectedSubscription = New TEOSSessionInviteRejectedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSSessionInviteRejectedSubscription, sessionId:String, inviteId:String, localHandle:Byte Ptr, senderHandle:Byte Ptr) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSSessionInviteRejected( ..
				sessionId, inviteId, TEOSProductUserId._Create(localHandle), ..
				TEOSProductUserId._Create(senderHandle))
		End If
	End Function

	Function _Cancel(subscription:TEOSSessionInviteRejectedSubscription) { nomangle }
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
			bmx_eos_sessions_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSJoinSessionAcceptedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSJoinSessionAcceptedListener
	Field _id:ULong

	Public
	Function _Create:TEOSJoinSessionAcceptedSubscription(owner:TEOSPlatform, listener:IEOSJoinSessionAcceptedListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSJoinSessionAcceptedSubscription = New TEOSJoinSessionAcceptedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSJoinSessionAcceptedSubscription, localHandle:Byte Ptr, uiEventId:ULong) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSJoinSessionAccepted( ..
				TEOSProductUserId._Create(localHandle), uiEventId)
		End If
	End Function

	Function _Cancel(subscription:TEOSJoinSessionAcceptedSubscription) { nomangle }
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
			bmx_eos_sessions_remove_notify(id)
		End If
	End Method

	Method IsActive:Int()
		Return _id <> 0 And _owner And _owner.IsValid()
	End Method

	Method Delete()
		Remove()
	End Method
End Type

Type TEOSLeaveSessionRequestedSubscription
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSLeaveSessionRequestedListener
	Field _id:ULong

	Public
	Function _Create:TEOSLeaveSessionRequestedSubscription(owner:TEOSPlatform, listener:IEOSLeaveSessionRequestedListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSLeaveSessionRequestedSubscription = New TEOSLeaveSessionRequestedSubscription
		subscription._owner = owner
		subscription._listener = listener
		Return subscription
	End Function

	Function _Notify(subscription:TEOSLeaveSessionRequestedSubscription, localHandle:Byte Ptr, sessionName:String) { nomangle }
		If subscription And subscription._listener Then
			subscription._listener.OnEOSLeaveSessionRequested( ..
				TEOSProductUserId._Create(localHandle), sessionName)
		End If
	End Function

	Function _Cancel(subscription:TEOSLeaveSessionRequestedSubscription) { nomangle }
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
			bmx_eos_sessions_remove_notify(id)
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
bbdoc: Creates, advertises, finds, joins, and manages EOS game sessions.
about: Sessions describe a match or server. They do not carry gameplay data;
use EOS P2P or another transport after joining.
End Rem
Type TEOSSessions
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSSessions(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local sessions:TEOSSessions = New TEOSSessions
		sessions._owner = owner
		sessions._handle = handle
		Return sessions
	End Function

	Method CreateSessionModification:EEOSResult(options:TEOSSessionCreateOptions, modification:TEOSSessionModification Var)
		modification = Null
		If Not _Valid() Or Not options Then
			Return EEOSResult.InvalidParameters
		End If
		If Not options.SessionName Or Not options.BucketId Or options.MaxPlayers = 0 Then
			Return EEOSResult.InvalidParameters
		End If
		If Not options.LocalUserId Or Not options.LocalUserId.IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_sessions_create_modification( ..
			_handle, options.SessionName, options.BucketId, options.MaxPlayers, ..
			options.LocalUserId._NativeHandle(), options.PresenceEnabled, ..
			options.SessionId, options.SanctionsEnabled, options.AllowedPlatformIds, handle)
		If result = EEOSResult.Success Then
			modification = TEOSSessionModification._Create(_owner, handle)
		End If
		Return result
	End Method

	Method UpdateSessionModification:EEOSResult(sessionName:String, modification:TEOSSessionModification Var)
		modification = Null
		If Not _Valid() Or Not sessionName Then
			Return EEOSResult.InvalidParameters
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_sessions_update_modification(_handle, sessionName, handle)
		If result = EEOSResult.Success Then
			modification = TEOSSessionModification._Create(_owner, handle)
		End If
		Return result
	End Method

	Method UpdateSession:TEOSSessionUpdateRequest(modification:TEOSSessionModification, listener:IEOSSessionUpdateListener)
		If Not _Valid() Or Not modification Or Not modification.IsValid() Or Not listener Then
			Return Null
		End If
		Local request:TEOSSessionUpdateRequest = TEOSSessionUpdateRequest._Create(_owner, listener)
		bmx_eos_sessions_update(_owner._NativeHandle(), _handle, request, modification._NativeHandle())
		Return request
	End Method

	Method DestroySession:TEOSSessionOperationRequest(sessionName:String, listener:IEOSSessionOperationListener)
		Return _NamedOperation(sessionName, listener, EEOSSessionOperation.DestroySession)
	End Method

	Method StartSession:TEOSSessionOperationRequest(sessionName:String, listener:IEOSSessionOperationListener)
		Return _NamedOperation(sessionName, listener, EEOSSessionOperation.StartSession)
	End Method

	Method EndSession:TEOSSessionOperationRequest(sessionName:String, listener:IEOSSessionOperationListener)
		Return _NamedOperation(sessionName, listener, EEOSSessionOperation.EndSession)
	End Method

	Method JoinSession:TEOSSessionOperationRequest(options:TEOSSessionJoinOptions, listener:IEOSSessionOperationListener)
		If Not _Valid() Or Not options Or Not listener Then
			Return Null
		End If
		If Not options.SessionName Or Not options.SessionDetails Or Not options.SessionDetails.IsValid() Then
			Return Null
		End If
		If Not options.LocalUserId Or Not options.LocalUserId.IsValid() Then
			Return Null
		End If
		Local request:TEOSSessionOperationRequest = TEOSSessionOperationRequest._Create( ..
			_owner, listener, EEOSSessionOperation.JoinSession)
		bmx_eos_sessions_join( ..
			_owner._NativeHandle(), _handle, request, options.SessionName, ..
			options.SessionDetails._NativeHandle(), options.LocalUserId._NativeHandle(), ..
			options.PresenceEnabled)
		Return request
	End Method

	Method RegisterPlayers:TEOSSessionPlayersRequest(sessionName:String, players:TEOSProductUserId[], listener:IEOSSessionPlayersListener)
		Return _ChangePlayers(sessionName, players, listener, EEOSSessionOperation.RegisterPlayers)
	End Method

	Method UnregisterPlayers:TEOSSessionPlayersRequest(sessionName:String, players:TEOSProductUserId[], listener:IEOSSessionPlayersListener)
		Return _ChangePlayers(sessionName, players, listener, EEOSSessionOperation.UnregisterPlayers)
	End Method

	Method SendInvite:TEOSSessionOperationRequest(sessionName:String, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId, listener:IEOSSessionOperationListener)
		If Not _Valid() Or Not sessionName Or Not listener Then
			Return Null
		End If
		If Not localUserId Or Not localUserId.IsValid() Then
			Return Null
		End If
		If Not targetUserId Or Not targetUserId.IsValid() Then
			Return Null
		End If
		Local request:TEOSSessionOperationRequest = TEOSSessionOperationRequest._Create( ..
			_owner, listener, EEOSSessionOperation.SendInvite)
		bmx_eos_sessions_send_invite( ..
			_owner._NativeHandle(), _handle, request, sessionName, ..
			localUserId._NativeHandle(), targetUserId._NativeHandle())
		Return request
	End Method

	Method RejectInvite:TEOSSessionOperationRequest(inviteId:String, localUserId:TEOSProductUserId, listener:IEOSSessionOperationListener)
		If Not _Valid() Or Not inviteId Or Not listener Then
			Return Null
		End If
		If Not localUserId Or Not localUserId.IsValid() Then
			Return Null
		End If
		Local request:TEOSSessionOperationRequest = TEOSSessionOperationRequest._Create( ..
			_owner, listener, EEOSSessionOperation.RejectInvite)
		bmx_eos_sessions_reject_invite( ..
			_owner._NativeHandle(), _handle, request, inviteId, localUserId._NativeHandle())
		Return request
	End Method

	Method QueryInvites:TEOSSessionOperationRequest(localUserId:TEOSProductUserId, listener:IEOSSessionOperationListener)
		If Not _Valid() Or Not listener Or Not localUserId Or Not localUserId.IsValid() Then
			Return Null
		End If
		Local request:TEOSSessionOperationRequest = TEOSSessionOperationRequest._Create( ..
			_owner, listener, EEOSSessionOperation.QueryInvites)
		bmx_eos_sessions_query_invites( ..
			_owner._NativeHandle(), _handle, request, localUserId._NativeHandle())
		Return request
	End Method

	Method InviteCount:UInt(localUserId:TEOSProductUserId)
		If Not _Valid() Or Not localUserId Or Not localUserId.IsValid() Then
			Return 0
		End If
		Return bmx_eos_sessions_invite_count(_handle, localUserId._NativeHandle())
	End Method

	Method GetInviteIdByIndex:EEOSResult(localUserId:TEOSProductUserId, index:UInt, inviteId:String Var)
		inviteId = ""
		If Not _Valid() Or Not localUserId Or Not localUserId.IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Return bmx_eos_sessions_invite_id( ..
			_handle, localUserId._NativeHandle(), index, inviteId)
	End Method

	Method CopySessionDetailsByInviteId:EEOSResult(inviteId:String, details:TEOSSessionDetails Var)
		details = Null
		If Not _Valid() Or Not inviteId Then
			Return EEOSResult.InvalidParameters
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_sessions_copy_details_by_invite(_handle, inviteId, handle)
		If result = EEOSResult.Success Then
			details = TEOSSessionDetails._Create(_owner, handle)
		End If
		Return result
	End Method

	Method CopySessionDetailsByUiEventId:EEOSResult(uiEventId:ULong, details:TEOSSessionDetails Var)
		details = Null
		If Not _Valid() Or uiEventId = 0 Then
			Return EEOSResult.InvalidParameters
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_sessions_copy_details_by_ui_event(_handle, uiEventId, handle)
		If result = EEOSResult.Success Then
			details = TEOSSessionDetails._Create(_owner, handle)
		End If
		Return result
	End Method

	Method CopySessionDetailsForPresence:EEOSResult(localUserId:TEOSProductUserId, details:TEOSSessionDetails Var)
		details = Null
		If Not _Valid() Or Not localUserId Or Not localUserId.IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_sessions_copy_details_for_presence( ..
			_handle, localUserId._NativeHandle(), handle)
		If result = EEOSResult.Success Then
			details = TEOSSessionDetails._Create(_owner, handle)
		End If
		Return result
	End Method

	Method AddNotifyInviteReceived:TEOSSessionInviteReceivedSubscription(listener:IEOSSessionInviteReceivedListener)
		If Not _Valid() Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSSessionInviteReceivedSubscription = ..
			TEOSSessionInviteReceivedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_sessions_add_notify_invite_received( ..
			_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then
			Return Null
		End If
		Return subscription
	End Method

	Method AddNotifyInviteAccepted:TEOSSessionInviteAcceptedSubscription(listener:IEOSSessionInviteAcceptedListener)
		If Not _Valid() Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSSessionInviteAcceptedSubscription = ..
			TEOSSessionInviteAcceptedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_sessions_add_notify_invite_accepted( ..
			_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then
			Return Null
		End If
		Return subscription
	End Method

	Method AddNotifyInviteRejected:TEOSSessionInviteRejectedSubscription(listener:IEOSSessionInviteRejectedListener)
		If Not _Valid() Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSSessionInviteRejectedSubscription = ..
			TEOSSessionInviteRejectedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_sessions_add_notify_invite_rejected( ..
			_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then
			Return Null
		End If
		Return subscription
	End Method

	Method AddNotifyJoinAccepted:TEOSJoinSessionAcceptedSubscription(listener:IEOSJoinSessionAcceptedListener)
		If Not _Valid() Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSJoinSessionAcceptedSubscription = ..
			TEOSJoinSessionAcceptedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_sessions_add_notify_join_accepted( ..
			_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then
			Return Null
		End If
		Return subscription
	End Method

	Method AddNotifyLeaveRequested:TEOSLeaveSessionRequestedSubscription(listener:IEOSLeaveSessionRequestedListener)
		If Not _Valid() Or Not listener Then
			Return Null
		End If
		Local subscription:TEOSLeaveSessionRequestedSubscription = ..
			TEOSLeaveSessionRequestedSubscription._Create(_owner, listener)
		subscription._SetId(bmx_eos_sessions_add_notify_leave_requested( ..
			_owner._NativeHandle(), _handle, subscription))
		If Not subscription.IsActive() Then
			Return Null
		End If
		Return subscription
	End Method

	Method CreateSearch:EEOSResult(maxResults:UInt, search:TEOSSessionSearch Var)
		search = Null
		If Not _Valid() Or maxResults = 0 Or maxResults > EOS_SESSIONS_MAX_SEARCH_RESULTS Then
			Return EEOSResult.InvalidParameters
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_sessions_create_search(_handle, maxResults, handle)
		If result = EEOSResult.Success Then
			search = TEOSSessionSearch._Create(_owner, handle)
		End If
		Return result
	End Method

	Method CopyActiveSession:EEOSResult(sessionName:String, activeSession:TEOSActiveSession Var)
		activeSession = Null
		If Not _Valid() Or Not sessionName Then
			Return EEOSResult.InvalidParameters
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_sessions_copy_active(_handle, sessionName, handle)
		If result = EEOSResult.Success Then
			activeSession = TEOSActiveSession._Create(_owner, handle)
		End If
		Return result
	End Method

	Method IsUserInSession:EEOSResult(sessionName:String, targetUserId:TEOSProductUserId)
		If Not _Valid() Or Not sessionName Or Not targetUserId Or Not targetUserId.IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Return bmx_eos_sessions_is_user_in_session(_handle, sessionName, targetUserId._NativeHandle())
	End Method

	Private
	Method _Valid:Int()
		Return _owner <> Null And _owner.IsValid() And _handle <> Null
	End Method

	Method _NamedOperation:TEOSSessionOperationRequest(sessionName:String, listener:IEOSSessionOperationListener, operation:EEOSSessionOperation)
		If Not _Valid() Or Not sessionName Or Not listener Then
			Return Null
		End If
		Local request:TEOSSessionOperationRequest = TEOSSessionOperationRequest._Create(_owner, listener, operation)
		bmx_eos_sessions_named_operation( ..
			_owner._NativeHandle(), _handle, request, sessionName, operation)
		Return request
	End Method

	Method _ChangePlayers:TEOSSessionPlayersRequest(sessionName:String, players:TEOSProductUserId[], listener:IEOSSessionPlayersListener, operation:EEOSSessionOperation)
		If Not _Valid() Or Not sessionName Or Not players Or players.Length = 0 Or Not listener Then
			Return Null
		End If
		Local handles:Byte Ptr[players.Length]
		For Local index:Int = 0 Until players.Length
			If Not players[index] Or Not players[index].IsValid() Then
				Return Null
			End If
			handles[index] = players[index]._NativeHandle()
		Next
		Local request:TEOSSessionPlayersRequest = TEOSSessionPlayersRequest._Create(_owner, listener, operation)
		bmx_eos_sessions_change_players( ..
			_owner._NativeHandle(), _handle, request, sessionName, handles, operation)
		Return request
	End Method
End Type

Type TEOSSessionModification
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSSessionModification(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local modification:TEOSSessionModification = New TEOSSessionModification
		modification._owner = owner
		modification._handle = handle
		Return modification
	End Function

	Method SetBucketId:EEOSResult(bucketId:String)
		Return bmx_eos_session_modification_set_string(_handle, 0, bucketId)
	End Method

	Method SetHostAddress:EEOSResult(hostAddress:String)
		Return bmx_eos_session_modification_set_string(_handle, 1, hostAddress)
	End Method

	Method SetPermissionLevel:EEOSResult(permissionLevel:EEOSOnlineSessionPermissionLevel)
		Return bmx_eos_session_modification_set_int(_handle, 0, permissionLevel)
	End Method

	Method SetJoinInProgressAllowed:EEOSResult(allowed:Int)
		Return bmx_eos_session_modification_set_int(_handle, 1, allowed)
	End Method

	Method SetMaxPlayers:EEOSResult(maxPlayers:UInt)
		Return bmx_eos_session_modification_set_int(_handle, 2, Int(maxPlayers))
	End Method

	Method SetInvitesAllowed:EEOSResult(allowed:Int)
		Return bmx_eos_session_modification_set_int(_handle, 3, allowed)
	End Method

	Method SetAllowedPlatformIds:EEOSResult(platformIds:Int[])
		Return bmx_eos_session_modification_set_platforms(_handle, platformIds)
	End Method

	Method AddStringAttribute:EEOSResult(key:String, value:String, advertisement:EEOSSessionAttributeAdvertisementType = EEOSSessionAttributeAdvertisementType.Advertise)
		Return bmx_eos_session_modification_add_attribute( ..
			_handle, key, EEOSSessionAttributeType.StringValue, 0, 0.0, False, value, advertisement)
	End Method

	Method AddIntAttribute:EEOSResult(key:String, value:Long, advertisement:EEOSSessionAttributeAdvertisementType = EEOSSessionAttributeAdvertisementType.Advertise)
		Return bmx_eos_session_modification_add_attribute( ..
			_handle, key, EEOSSessionAttributeType.Int64, value, 0.0, False, "", advertisement)
	End Method

	Method AddDoubleAttribute:EEOSResult(key:String, value:Double, advertisement:EEOSSessionAttributeAdvertisementType = EEOSSessionAttributeAdvertisementType.Advertise)
		Return bmx_eos_session_modification_add_attribute( ..
			_handle, key, EEOSSessionAttributeType.DoubleValue, 0, value, False, "", advertisement)
	End Method

	Method AddBoolAttribute:EEOSResult(key:String, value:Int, advertisement:EEOSSessionAttributeAdvertisementType = EEOSSessionAttributeAdvertisementType.Advertise)
		Return bmx_eos_session_modification_add_attribute( ..
			_handle, key, EEOSSessionAttributeType.Boolean, 0, 0.0, value, "", advertisement)
	End Method

	Method RemoveAttribute:EEOSResult(key:String)
		Return bmx_eos_session_modification_remove_attribute(_handle, key)
	End Method

	Method IsValid:Int()
		Return _owner <> Null And _owner.IsValid() And _handle <> Null
	End Method

	Method Release()
		If Not _handle Then
			Return
		End If
		Local handle:Byte Ptr = _handle
		_handle = Null
		bmx_eos_session_modification_release(handle)
	End Method

	Method Delete()
		Self.Release()
	End Method

	Method _NativeHandle:Byte Ptr()
		Return _handle
	End Method
End Type

Type TEOSSessionSearch
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSSessionSearch(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local search:TEOSSessionSearch = New TEOSSessionSearch
		search._owner = owner
		search._handle = handle
		Return search
	End Function

	Method SetSessionId:EEOSResult(sessionId:String)
		Return bmx_eos_session_search_set_string(_handle, 0, sessionId)
	End Method

	Method SetTargetUserId:EEOSResult(targetUserId:TEOSProductUserId)
		If Not targetUserId Or Not targetUserId.IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Return bmx_eos_session_search_set_target(_handle, targetUserId._NativeHandle())
	End Method

	Method SetStringParameter:EEOSResult(key:String, value:String, comparison:EEOSComparisonOp = EEOSComparisonOp.Equal)
		Return bmx_eos_session_search_set_parameter( ..
			_handle, key, EEOSSessionAttributeType.StringValue, 0, 0.0, False, value, comparison)
	End Method

	Method SetIntParameter:EEOSResult(key:String, value:Long, comparison:EEOSComparisonOp = EEOSComparisonOp.Equal)
		Return bmx_eos_session_search_set_parameter( ..
			_handle, key, EEOSSessionAttributeType.Int64, value, 0.0, False, "", comparison)
	End Method

	Method SetDoubleParameter:EEOSResult(key:String, value:Double, comparison:EEOSComparisonOp = EEOSComparisonOp.Equal)
		Return bmx_eos_session_search_set_parameter( ..
			_handle, key, EEOSSessionAttributeType.DoubleValue, 0, value, False, "", comparison)
	End Method

	Method SetBoolParameter:EEOSResult(key:String, value:Int, comparison:EEOSComparisonOp = EEOSComparisonOp.Equal)
		Return bmx_eos_session_search_set_parameter( ..
			_handle, key, EEOSSessionAttributeType.Boolean, 0, 0.0, value, "", comparison)
	End Method

	Method RemoveParameter:EEOSResult(key:String, comparison:EEOSComparisonOp = EEOSComparisonOp.Equal)
		Return bmx_eos_session_search_remove_parameter(_handle, key, comparison)
	End Method

	Method SetMaxResults:EEOSResult(maxResults:UInt)
		Return bmx_eos_session_search_set_max_results(_handle, maxResults)
	End Method

	Method Find:TEOSSessionSearchRequest(localUserId:TEOSProductUserId, listener:IEOSSessionSearchListener)
		If Not IsValid() Or Not localUserId Or Not localUserId.IsValid() Or Not listener Then
			Return Null
		End If
		Local request:TEOSSessionSearchRequest = TEOSSessionSearchRequest._Create(_owner, listener)
		bmx_eos_session_search_find( ..
			_owner._NativeHandle(), _handle, request, localUserId._NativeHandle())
		Return request
	End Method

	Method ResultCount:UInt()
		If Not IsValid() Then
			Return 0
		End If
		Return bmx_eos_session_search_result_count(_handle)
	End Method

	Method CopyResultByIndex:EEOSResult(index:UInt, details:TEOSSessionDetails Var)
		details = Null
		If Not IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Local handle:Byte Ptr
		Local result:EEOSResult = bmx_eos_session_search_copy_result(_handle, index, handle)
		If result = EEOSResult.Success Then
			details = TEOSSessionDetails._Create(_owner, handle)
		End If
		Return result
	End Method

	Method IsValid:Int()
		Return _owner <> Null And _owner.IsValid() And _handle <> Null
	End Method

	Method Release()
		If Not _handle Then
			Return
		End If
		Local handle:Byte Ptr = _handle
		_handle = Null
		bmx_eos_session_search_release(handle)
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type

Type TEOSSessionDetails
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSSessionDetails(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local details:TEOSSessionDetails = New TEOSSessionDetails
		details._owner = owner
		details._handle = handle
		Return details
	End Function

	Method CopyInfo:EEOSResult(info:TEOSSessionInfo Var)
		info = Null
		If Not IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Local value:TEOSSessionInfo = New TEOSSessionInfo
		Local ownerHandle:Byte Ptr
		Local result:EEOSResult = bmx_eos_session_details_copy_info( ..
			_handle, value.SessionId, value.HostAddress, value.OpenPublicConnections, ..
			value.BucketId, value.MaxPlayers, value.AllowJoinInProgress, ..
			value.PermissionLevel, value.InvitesAllowed, value.SanctionsEnabled, ..
			value.AllowedPlatformIds, ownerHandle, value.OwnerServerClientId)
		If result = EEOSResult.Success Then
			value.OwnerUserId = TEOSProductUserId._Create(ownerHandle)
			info = value
		End If
		Return result
	End Method

	Method AttributeCount:UInt()
		If Not IsValid() Then
			Return 0
		End If
		Return bmx_eos_session_details_attribute_count(_handle)
	End Method

	Method CopyAttributeByIndex:EEOSResult(index:UInt, attribute:TEOSSessionAttribute Var)
		attribute = Null
		If Not IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Local value:TEOSSessionAttribute = New TEOSSessionAttribute
		Local result:EEOSResult = bmx_eos_session_details_copy_attribute( ..
			_handle, index, value.Key, value.ValueType, value.IntValue, ..
			value.DoubleValue, value.BoolValue, value.StringValue, value.AdvertisementType)
		If result = EEOSResult.Success Then
			attribute = value
		End If
		Return result
	End Method

	Method IsValid:Int()
		Return _owner <> Null And _owner.IsValid() And _handle <> Null
	End Method

	Method Release()
		If Not _handle Then
			Return
		End If
		Local handle:Byte Ptr = _handle
		_handle = Null
		bmx_eos_session_details_release(handle)
	End Method

	Method Delete()
		Self.Release()
	End Method

	Method _NativeHandle:Byte Ptr()
		Return _handle
	End Method
End Type

Type TEOSActiveSession
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSActiveSession(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local active:TEOSActiveSession = New TEOSActiveSession
		active._owner = owner
		active._handle = handle
		Return active
	End Function

	Method CopyInfo:EEOSResult(info:TEOSActiveSessionInfo Var)
		info = Null
		If Not IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Local value:TEOSActiveSessionInfo = New TEOSActiveSessionInfo
		Local localHandle:Byte Ptr, ownerHandle:Byte Ptr
		Local result:EEOSResult = bmx_eos_active_session_copy_info( ..
			_handle, value.SessionName, localHandle, value.State, value.SessionId, ..
			value.HostAddress, value.OpenPublicConnections, value.BucketId, value.MaxPlayers, ..
			value.AllowJoinInProgress, value.PermissionLevel, value.InvitesAllowed, ..
			value.SanctionsEnabled, value.AllowedPlatformIds, ownerHandle, value.OwnerServerClientId)
		If result = EEOSResult.Success Then
			value.LocalUserId = TEOSProductUserId._Create(localHandle)
			value.OwnerUserId = TEOSProductUserId._Create(ownerHandle)
			info = value
		End If
		Return result
	End Method

	Method RegisteredPlayerCount:UInt()
		If Not IsValid() Then
			Return 0
		End If
		Return bmx_eos_active_session_player_count(_handle)
	End Method

	Method RegisteredPlayerByIndex:TEOSProductUserId(index:UInt)
		If Not IsValid() Then
			Return Null
		End If
		Return TEOSProductUserId._Create(bmx_eos_active_session_player_by_index(_handle, index))
	End Method

	Method IsValid:Int()
		Return _owner <> Null And _owner.IsValid() And _handle <> Null
	End Method

	Method Release()
		If Not _handle Then
			Return
		End If
		Local handle:Byte Ptr = _handle
		_handle = Null
		bmx_eos_active_session_release(handle)
	End Method

	Method Delete()
		Self.Release()
	End Method
End Type

Private

Extern
	Function bmx_eos_sessions_create_modification:EEOSResult(sessionsHandle:Byte Ptr, sessionName:String, bucketId:String, maxPlayers:UInt, localUserHandle:Byte Ptr, presenceEnabled:Int, sessionId:String, sanctionsEnabled:Int, allowedPlatformIds:Int[], modificationHandle:Byte Ptr Var)
	Function bmx_eos_sessions_update_modification:EEOSResult(sessionsHandle:Byte Ptr, sessionName:String, modificationHandle:Byte Ptr Var)
	Function bmx_eos_session_modification_release(modificationHandle:Byte Ptr)
	Function bmx_eos_session_modification_set_string:EEOSResult(modificationHandle:Byte Ptr, field:Int, value:String)
	Function bmx_eos_session_modification_set_int:EEOSResult(modificationHandle:Byte Ptr, field:Int, value:Int)
	Function bmx_eos_session_modification_set_platforms:EEOSResult(modificationHandle:Byte Ptr, platformIds:Int[])
	Function bmx_eos_session_modification_add_attribute:EEOSResult(modificationHandle:Byte Ptr, key:String, valueType:EEOSSessionAttributeType, intValue:Long, doubleValue:Double, boolValue:Int, stringValue:String, advertisement:EEOSSessionAttributeAdvertisementType)
	Function bmx_eos_session_modification_remove_attribute:EEOSResult(modificationHandle:Byte Ptr, key:String)
	Function bmx_eos_sessions_update(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, request:TEOSSessionUpdateRequest, modificationHandle:Byte Ptr)
	Function bmx_eos_sessions_named_operation(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, request:TEOSSessionOperationRequest, sessionName:String, operation:EEOSSessionOperation)
	Function bmx_eos_sessions_join(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, request:TEOSSessionOperationRequest, sessionName:String, detailsHandle:Byte Ptr, localUserHandle:Byte Ptr, presenceEnabled:Int)
	Function bmx_eos_sessions_change_players(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, request:TEOSSessionPlayersRequest, sessionName:String, playerHandles:Byte Ptr[], operation:EEOSSessionOperation)
	Function bmx_eos_sessions_send_invite(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, request:TEOSSessionOperationRequest, sessionName:String, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_sessions_reject_invite(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, request:TEOSSessionOperationRequest, inviteId:String, localUserHandle:Byte Ptr)
	Function bmx_eos_sessions_query_invites(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, request:TEOSSessionOperationRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_sessions_invite_count:UInt(sessionsHandle:Byte Ptr, localUserHandle:Byte Ptr)
	Function bmx_eos_sessions_invite_id:EEOSResult(sessionsHandle:Byte Ptr, localUserHandle:Byte Ptr, index:UInt, inviteId:String Var)
	Function bmx_eos_sessions_copy_details_by_invite:EEOSResult(sessionsHandle:Byte Ptr, inviteId:String, detailsHandle:Byte Ptr Var)
	Function bmx_eos_sessions_copy_details_by_ui_event:EEOSResult(sessionsHandle:Byte Ptr, uiEventId:ULong, detailsHandle:Byte Ptr Var)
	Function bmx_eos_sessions_copy_details_for_presence:EEOSResult(sessionsHandle:Byte Ptr, localUserHandle:Byte Ptr, detailsHandle:Byte Ptr Var)
	Function bmx_eos_sessions_add_notify_invite_received:ULong(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, subscription:TEOSSessionInviteReceivedSubscription)
	Function bmx_eos_sessions_add_notify_invite_accepted:ULong(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, subscription:TEOSSessionInviteAcceptedSubscription)
	Function bmx_eos_sessions_add_notify_invite_rejected:ULong(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, subscription:TEOSSessionInviteRejectedSubscription)
	Function bmx_eos_sessions_add_notify_join_accepted:ULong(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, subscription:TEOSJoinSessionAcceptedSubscription)
	Function bmx_eos_sessions_add_notify_leave_requested:ULong(platformHandle:Byte Ptr, sessionsHandle:Byte Ptr, subscription:TEOSLeaveSessionRequestedSubscription)
	Function bmx_eos_sessions_remove_notify(id:ULong)
	Function bmx_eos_sessions_create_search:EEOSResult(sessionsHandle:Byte Ptr, maxResults:UInt, searchHandle:Byte Ptr Var)
	Function bmx_eos_session_search_release(searchHandle:Byte Ptr)
	Function bmx_eos_session_search_set_string:EEOSResult(searchHandle:Byte Ptr, field:Int, value:String)
	Function bmx_eos_session_search_set_target:EEOSResult(searchHandle:Byte Ptr, targetUserHandle:Byte Ptr)
	Function bmx_eos_session_search_set_parameter:EEOSResult(searchHandle:Byte Ptr, key:String, valueType:EEOSSessionAttributeType, intValue:Long, doubleValue:Double, boolValue:Int, stringValue:String, comparison:EEOSComparisonOp)
	Function bmx_eos_session_search_remove_parameter:EEOSResult(searchHandle:Byte Ptr, key:String, comparison:EEOSComparisonOp)
	Function bmx_eos_session_search_set_max_results:EEOSResult(searchHandle:Byte Ptr, maxResults:UInt)
	Function bmx_eos_session_search_find(platformHandle:Byte Ptr, searchHandle:Byte Ptr, request:TEOSSessionSearchRequest, localUserHandle:Byte Ptr)
	Function bmx_eos_session_search_result_count:UInt(searchHandle:Byte Ptr)
	Function bmx_eos_session_search_copy_result:EEOSResult(searchHandle:Byte Ptr, index:UInt, detailsHandle:Byte Ptr Var)
	Function bmx_eos_session_details_copy_info:EEOSResult(detailsHandle:Byte Ptr, sessionId:String Var, hostAddress:String Var, openConnections:UInt Var, bucketId:String Var, maxPlayers:UInt Var, allowJoinInProgress:Int Var, permissionLevel:EEOSOnlineSessionPermissionLevel Var, invitesAllowed:Int Var, sanctionsEnabled:Int Var, allowedPlatformIds:Int[] Var, ownerUserHandle:Byte Ptr Var, ownerServerClientId:String Var)
	Function bmx_eos_session_details_attribute_count:UInt(detailsHandle:Byte Ptr)
	Function bmx_eos_session_details_copy_attribute:EEOSResult(detailsHandle:Byte Ptr, index:UInt, key:String Var, valueType:EEOSSessionAttributeType Var, intValue:Long Var, doubleValue:Double Var, boolValue:Int Var, stringValue:String Var, advertisement:EEOSSessionAttributeAdvertisementType Var)
	Function bmx_eos_session_details_release(detailsHandle:Byte Ptr)
	Function bmx_eos_sessions_copy_active:EEOSResult(sessionsHandle:Byte Ptr, sessionName:String, activeHandle:Byte Ptr Var)
	Function bmx_eos_active_session_copy_info:EEOSResult(activeHandle:Byte Ptr, sessionName:String Var, localUserHandle:Byte Ptr Var, state:EEOSOnlineSessionState Var, sessionId:String Var, hostAddress:String Var, openConnections:UInt Var, bucketId:String Var, maxPlayers:UInt Var, allowJoinInProgress:Int Var, permissionLevel:EEOSOnlineSessionPermissionLevel Var, invitesAllowed:Int Var, sanctionsEnabled:Int Var, allowedPlatformIds:Int[] Var, ownerUserHandle:Byte Ptr Var, ownerServerClientId:String Var)
	Function bmx_eos_active_session_player_count:UInt(activeHandle:Byte Ptr)
	Function bmx_eos_active_session_player_by_index:Byte Ptr(activeHandle:Byte Ptr, index:UInt)
	Function bmx_eos_active_session_release(activeHandle:Byte Ptr)
	Function bmx_eos_sessions_is_user_in_session:EEOSResult(sessionsHandle:Byte Ptr, sessionName:String, targetUserHandle:Byte Ptr)
End Extern

Public
