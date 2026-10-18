SuperStrict

Framework EOS.SDK
Import BRL.StandardIO

Type TUIEvents Implements IEOSUIOperationListener, IEOSUIDisplaySettingsListener
	Field operationCount:Int
	Field displayCount:Int
	Field lastResult:EEOSResult
	Field lastOperation:EEOSUIOperation
	Field visible:Int
	Field exclusiveInput:Int

	Method OnEOSUIOperation(result:EEOSResult, operation:EEOSUIOperation, localUserId:TEOSEpicAccountId, targetUserId:TEOSEpicAccountId) Override
		operationCount :+ 1
		lastResult = result
		lastOperation = operation
	End Method

	Method OnEOSUIDisplaySettingsUpdated(isVisible:Int, isExclusiveInput:Int) Override
		displayCount :+ 1
		visible = isVisible
		exclusiveInput = isExclusiveInput
	End Method
End Type

Function Check(value:Int, message:String)
	If Not value Then
		RuntimeError message
	End If
End Function

Local owner:TEOSPlatform = New TEOSPlatform
Local events:TUIEvents = New TUIEvents

Local request:TEOSUIOperationRequest = TEOSUIOperationRequest._Create( ..
	owner, events, EEOSUIOperation.ShowFriends)
Check(request <> Null, "UI request should be created")
TEOSUIOperationRequest._Complete(request, EEOSResult.Success, Byte Ptr(1), Null)
Check(request.IsComplete(), "successful UI request should complete")
Check(events.operationCount = 1, "UI listener should run once")
Check(events.lastResult = EEOSResult.Success, "UI result should be preserved")
Check(events.lastOperation = EEOSUIOperation.ShowFriends, "UI operation should be preserved")
TEOSUIOperationRequest._Complete(request, EEOSResult.Success, Byte Ptr(1), Null)
Check(events.operationCount = 1, "completed UI request should ignore duplicate completion")

Local canceled:TEOSUIOperationRequest = TEOSUIOperationRequest._Create( ..
	owner, events, EEOSUIOperation.HideFriends)
TEOSUIOperationRequest._Cancel(canceled)
Check(canceled.IsComplete(), "canceled UI request should complete")
Check(events.lastResult = EEOSResult.Canceled, "UI cancellation should be preserved")

Local subscription:TEOSUIDisplaySettingsSubscription = ..
	TEOSUIDisplaySettingsSubscription._Create(owner, events)
Check(subscription <> Null, "display-settings subscription should be created")
TEOSUIDisplaySettingsSubscription._Notify(subscription, True, True)
Check(events.displayCount = 1, "display-settings listener should run")
Check(events.visible, "visible state should be preserved")
Check(events.exclusiveInput, "exclusive-input state should be preserved")
TEOSUIDisplaySettingsSubscription._Cancel(subscription)
Check(Not subscription.IsActive(), "canceled display-settings subscription should be inactive")

Local invalidUI:TEOSUI = TEOSUI._Create(owner, Byte Ptr(1))
Check(invalidUI.AcknowledgeEvent(1, EEOSResult.Success) = EEOSResult.InvalidState, ..
	"event acknowledgement should reject an invalid UI interface")
Check(invalidUI.PauseSocialOverlay(True) = EEOSResult.InvalidState, ..
	"overlay pause should reject an invalid UI interface")
Check(EOS_UI_EVENT_ID_INVALID = 0, "invalid UI event ID should match EOS")
Check(EEOSUINotificationLocation.BottomRight = 3, ..
	"notification locations should match EOS")

?macos
Check(Not EOSSocialOverlaySupportedOnPlatform(), ..
	"macOS should report that the Social Overlay is unsupported")
?
?linux
Check(Not EOSSocialOverlaySupportedOnPlatform(), ..
	"Linux should report that the Social Overlay is unsupported")
?
?win32arm64
Check(Not EOSSocialOverlaySupportedOnPlatform(), ..
	"Windows ARM64 should report that the Social Overlay is unsupported")
?
?win32x64
Check(EOSSocialOverlaySupportedOnPlatform(), ..
	"Windows x64 should report that the Social Overlay is supported")
?

Print "EOS UI tests passed."
