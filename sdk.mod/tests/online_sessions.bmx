SuperStrict

Framework EOS.SDK
Import BRL.StandardIO

Type TSessionEvents Implements IEOSSessionUpdateListener, IEOSSessionOperationListener, IEOSSessionSearchListener, IEOSSessionPlayersListener, IEOSSessionInviteReceivedListener, IEOSSessionInviteAcceptedListener, IEOSSessionInviteRejectedListener, IEOSJoinSessionAcceptedListener, IEOSLeaveSessionRequestedListener
	Field updateCount:Int
	Field operationCount:Int
	Field searchCount:Int
	Field playersCount:Int
	Field lastResult:EEOSResult
	Field lastOperation:EEOSSessionOperation
	Field lastSessionName:String
	Field lastSessionId:String
	Field lastChangedCount:Int
	Field lastSanctionedCount:Int
	Field inviteReceivedCount:Int
	Field inviteAcceptedCount:Int
	Field inviteRejectedCount:Int
	Field joinAcceptedCount:Int
	Field leaveRequestedCount:Int
	Field lastInviteId:String
	Field lastUiEventId:ULong

	Method OnEOSSessionUpdated(result:EEOSResult, sessionName:String, sessionId:String) Override
		updateCount :+ 1
		lastResult = result
		lastSessionName = sessionName
		lastSessionId = sessionId
	End Method

	Method OnEOSSessionOperation(result:EEOSResult, operation:EEOSSessionOperation) Override
		operationCount :+ 1
		lastResult = result
		lastOperation = operation
	End Method

	Method OnEOSSessionSearch(result:EEOSResult) Override
		searchCount :+ 1
		lastResult = result
	End Method

	Method OnEOSSessionPlayersChanged(result:EEOSResult, operation:EEOSSessionOperation, changedCount:Int, sanctionedCount:Int) Override
		playersCount :+ 1
		lastResult = result
		lastOperation = operation
		lastChangedCount = changedCount
		lastSanctionedCount = sanctionedCount
	End Method

	Method OnEOSSessionInviteReceived(inviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId) Override
		inviteReceivedCount :+ 1
		lastInviteId = inviteId
	End Method

	Method OnEOSSessionInviteAccepted(sessionId:String, inviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId) Override
		inviteAcceptedCount :+ 1
		lastSessionId = sessionId
		lastInviteId = inviteId
	End Method

	Method OnEOSSessionInviteRejected(sessionId:String, inviteId:String, localUserId:TEOSProductUserId, senderUserId:TEOSProductUserId) Override
		inviteRejectedCount :+ 1
		lastSessionId = sessionId
		lastInviteId = inviteId
	End Method

	Method OnEOSJoinSessionAccepted(localUserId:TEOSProductUserId, uiEventId:ULong) Override
		joinAcceptedCount :+ 1
		lastUiEventId = uiEventId
	End Method

	Method OnEOSLeaveSessionRequested(localUserId:TEOSProductUserId, sessionName:String) Override
		leaveRequestedCount :+ 1
		lastSessionName = sessionName
	End Method
End Type

Function Check(value:Int, message:String)
	If Not value Then
		RuntimeError message
	End If
End Function

Local owner:TEOSPlatform = New TEOSPlatform
Local events:TSessionEvents = New TSessionEvents

Local update:TEOSSessionUpdateRequest = TEOSSessionUpdateRequest._Create(owner, events)
Check(update <> Null, "update request should be created")
TEOSSessionUpdateRequest._Complete(update, EEOSResult.Success, "Game", "session-id")
Check(update.IsComplete(), "successful update should complete")
Check(events.updateCount = 1, "update listener should run once")
Check(events.lastSessionName = "Game", "session name should be preserved")
Check(events.lastSessionId = "session-id", "session id should be preserved")
TEOSSessionUpdateRequest._Complete(update, EEOSResult.Success, "Game", "session-id")
Check(events.updateCount = 1, "completed update should ignore duplicate completion")

Local operation:TEOSSessionOperationRequest = TEOSSessionOperationRequest._Create( ..
	owner, events, EEOSSessionOperation.StartSession)
Check(operation <> Null, "operation request should be created")
TEOSSessionOperationRequest._Cancel(operation)
Check(operation.IsComplete(), "canceled operation should complete")
Check(events.operationCount = 1, "operation listener should run once")
Check(events.lastResult = EEOSResult.Canceled, "operation cancellation should be preserved")
Check(events.lastOperation = EEOSSessionOperation.StartSession, "operation kind should be preserved")

Local search:TEOSSessionSearchRequest = TEOSSessionSearchRequest._Create(owner, events)
Check(search <> Null, "search request should be created")
TEOSSessionSearchRequest._Complete(search, EEOSResult.Success)
Check(search.IsComplete(), "successful search should complete")
Check(events.searchCount = 1, "search listener should run once")

Local players:TEOSSessionPlayersRequest = TEOSSessionPlayersRequest._Create( ..
	owner, events, EEOSSessionOperation.RegisterPlayers)
Check(players <> Null, "players request should be created")
TEOSSessionPlayersRequest._Complete(players, EEOSResult.Success, 2, 1)
Check(players.IsComplete(), "successful player registration should complete")
Check(events.playersCount = 1, "players listener should run once")
Check(events.lastChangedCount = 2, "changed player count should be preserved")
Check(events.lastSanctionedCount = 1, "sanctioned player count should be preserved")

Local inviteReceived:TEOSSessionInviteReceivedSubscription = ..
	TEOSSessionInviteReceivedSubscription._Create(owner, events)
inviteReceived._SetId(1)
TEOSSessionInviteReceivedSubscription._Notify(inviteReceived, "invite-1", Byte Ptr(1), Byte Ptr(2))
Check(events.inviteReceivedCount = 1, "invite-received listener should run")
Check(events.lastInviteId = "invite-1", "received invite id should be preserved")
TEOSSessionInviteReceivedSubscription._Cancel(inviteReceived)
Check(Not inviteReceived.IsActive(), "canceled invite subscription should be inactive")

Local inviteAccepted:TEOSSessionInviteAcceptedSubscription = ..
	TEOSSessionInviteAcceptedSubscription._Create(owner, events)
TEOSSessionInviteAcceptedSubscription._Notify( ..
	inviteAccepted, "session-1", "invite-2", Byte Ptr(1), Byte Ptr(2))
Check(events.inviteAcceptedCount = 1, "invite-accepted listener should run")
Check(events.lastSessionId = "session-1", "accepted session id should be preserved")

Local inviteRejected:TEOSSessionInviteRejectedSubscription = ..
	TEOSSessionInviteRejectedSubscription._Create(owner, events)
TEOSSessionInviteRejectedSubscription._Notify( ..
	inviteRejected, "session-2", "invite-3", Byte Ptr(1), Byte Ptr(2))
Check(events.inviteRejectedCount = 1, "invite-rejected listener should run")

Local joinAccepted:TEOSJoinSessionAcceptedSubscription = ..
	TEOSJoinSessionAcceptedSubscription._Create(owner, events)
TEOSJoinSessionAcceptedSubscription._Notify(joinAccepted, Byte Ptr(1), 42)
Check(events.joinAcceptedCount = 1, "join-accepted listener should run")
Check(events.lastUiEventId = 42, "UI event id should be preserved")

Local leaveRequested:TEOSLeaveSessionRequestedSubscription = ..
	TEOSLeaveSessionRequestedSubscription._Create(owner, events)
TEOSLeaveSessionRequestedSubscription._Notify(leaveRequested, Byte Ptr(1), "ClientGame")
Check(events.leaveRequestedCount = 1, "leave-requested listener should run")
Check(events.lastSessionName = "ClientGame", "leave session name should be preserved")

Check(EOS_SESSIONS_MAX_REGISTERED_PLAYERS = 1000, "registered-player limit should match EOS")
Check(EOS_SESSIONS_MAX_SEARCH_RESULTS = 200, "search-result limit should match EOS")
Check(EOS_SESSIONMODIFICATION_MAX_ATTRIBUTES = 64, "attribute limit should match EOS")
Check(EOS_SESSIONS_SEARCH_BUCKET_ID = "bucket", "bucket search key should match EOS")

Print "EOS online sessions tests passed."
