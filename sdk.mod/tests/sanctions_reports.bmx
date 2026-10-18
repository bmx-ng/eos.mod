SuperStrict

Framework EOS.SDK
Import BRL.StandardIO

Type TSanctionsEvents Implements IEOSSanctionsQueryListener, IEOSSanctionAppealListener, IEOSPlayerReportListener
	Field queryCount:Int
	Field appealCount:Int
	Field reportCount:Int
	Field lastResult:EEOSResult
	Field lastReferenceId:String
	Field lastLocalUserId:TEOSProductUserId
	Field lastTargetUserId:TEOSProductUserId

	Method OnEOSSanctionsQuery(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId) Override
		queryCount :+ 1
		lastResult = result
		lastLocalUserId = localUserId
		lastTargetUserId = targetUserId
	End Method

	Method OnEOSSanctionAppeal(result:EEOSResult, referenceId:String) Override
		appealCount :+ 1
		lastResult = result
		lastReferenceId = referenceId
	End Method

	Method OnEOSPlayerReport(result:EEOSResult) Override
		reportCount :+ 1
		lastResult = result
	End Method
End Type

Function Check(value:Int, message:String)
	If Not value Then
		RuntimeError message
	End If
End Function

Local owner:TEOSPlatform = New TEOSPlatform
Local events:TSanctionsEvents = New TSanctionsEvents

Local query:TEOSSanctionsQueryRequest = TEOSSanctionsQueryRequest._Create(owner, events)
Check(query <> Null, "query request should be created")
TEOSSanctionsQueryRequest._Complete(query, EEOSResult.Success, Byte Ptr(1), Byte Ptr(2))
Check(query.IsComplete(), "successful query should complete")
Check(events.queryCount = 1, "query listener should run once")
Check(events.lastResult = EEOSResult.Success, "query result should be preserved")
TEOSSanctionsQueryRequest._Complete(query, EEOSResult.Success, Byte Ptr(1), Byte Ptr(2))
Check(events.queryCount = 1, "completed query should ignore duplicate completion")

Local appeal:TEOSSanctionAppealRequest = TEOSSanctionAppealRequest._Create(owner, events)
Check(appeal <> Null, "appeal request should be created")
TEOSSanctionAppealRequest._Complete(appeal, EEOSResult.Success, "sanction-reference")
Check(appeal.IsComplete(), "successful appeal should complete")
Check(events.appealCount = 1, "appeal listener should run once")
Check(events.lastReferenceId = "sanction-reference", "appeal reference should be preserved")

Local report:TEOSPlayerReportRequest = TEOSPlayerReportRequest._Create(owner, events)
Check(report <> Null, "report request should be created")
TEOSPlayerReportRequest._Cancel(report)
Check(report.IsComplete(), "canceled report should complete")
Check(events.reportCount = 1, "report listener should run once")
Check(events.lastResult = EEOSResult.Canceled, "report cancellation should be preserved")

Local permanent:TEOSPlayerSanction = New TEOSPlayerSanction
Check(permanent.IsPermanent(), "zero expiration should mean permanent")
permanent.TimeExpires = 1
Check(Not permanent.IsPermanent(), "non-zero expiration should not mean permanent")

Check(EOS_REPORTS_REPORTMESSAGE_MAX_LENGTH = 512, "report message limit should match EOS")
Check(EOS_REPORTS_REPORTCONTEXT_MAX_LENGTH = 4096, "report context limit should match EOS")

Print "EOS sanctions and reports tests passed."
