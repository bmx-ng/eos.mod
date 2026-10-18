' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

Const EOS_REPORTS_REPORTMESSAGE_MAX_LENGTH:Int = 512
Const EOS_REPORTS_REPORTCONTEXT_MAX_LENGTH:Int = 4096

Rem
bbdoc: Reason supplied when a player appeals one of their own sanctions.
End Rem
Enum EEOSSanctionAppealReason
	Invalid = 0
	IncorrectSanction = 1
	CompromisedAccount = 2
	UnfairPunishment = 3
	AppealForForgiveness = 4
End Enum

Rem
bbdoc: Player behavior category attached to a report.
End Rem
Enum EEOSPlayerReportsCategory
	Invalid = 0
	Cheating = 1
	Exploiting = 2
	OffensiveProfile = 3
	VerbalAbuse = 4
	Scamming = 5
	Spamming = 6
	Other = 7
End Enum

Type TEOSSanctionsQueryOptions
	Field LocalUserId:TEOSProductUserId
	Field TargetUserId:TEOSProductUserId
End Type

Rem
bbdoc: One active player sanction copied from the EOS query cache.
End Rem
Type TEOSPlayerSanction
	Field TimePlaced:Long
	Field Action:String
	Field TimeExpires:Long
	Field ReferenceId:String

	Method IsPermanent:Int()
		Return TimeExpires = 0
	End Method
End Type

Type TEOSSanctionAppealOptions
	Field LocalUserId:TEOSProductUserId
	Field Reason:EEOSSanctionAppealReason
	Field ReferenceId:String
End Type

Type TEOSPlayerReportOptions
	Field ReporterUserId:TEOSProductUserId
	Field ReportedUserId:TEOSProductUserId
	Field Category:EEOSPlayerReportsCategory
	Field Message:String
	Field Context:String
End Type

Interface IEOSSanctionsQueryListener
	Method OnEOSSanctionsQuery(result:EEOSResult, localUserId:TEOSProductUserId, targetUserId:TEOSProductUserId)
End Interface

Interface IEOSSanctionAppealListener
	Method OnEOSSanctionAppeal(result:EEOSResult, referenceId:String)
End Interface

Interface IEOSPlayerReportListener
	Method OnEOSPlayerReport(result:EEOSResult)
End Interface

Type TEOSSanctionsQueryRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSanctionsQueryListener
	Field _complete:Int

	Public
	Function _Create:TEOSSanctionsQueryRequest(owner:TEOSPlatform, listener:IEOSSanctionsQueryListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSSanctionsQueryRequest = New TEOSSanctionsQueryRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSSanctionsQueryRequest, result:EEOSResult, localUserHandle:Byte Ptr, targetUserHandle:Byte Ptr) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSSanctionsQueryListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSSanctionsQuery( ..
				result, ..
				TEOSProductUserId._Create(localUserHandle), ..
				TEOSProductUserId._Create(targetUserHandle))
		End If
	End Function

	Function _Cancel(request:TEOSSanctionsQueryRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, Null)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSSanctionAppealRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSSanctionAppealListener
	Field _complete:Int

	Public
	Function _Create:TEOSSanctionAppealRequest(owner:TEOSPlatform, listener:IEOSSanctionAppealListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSSanctionAppealRequest = New TEOSSanctionAppealRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSSanctionAppealRequest, result:EEOSResult, referenceId:String) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSSanctionAppealListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSSanctionAppeal(result, referenceId)
		End If
	End Function

	Function _Cancel(request:TEOSSanctionAppealRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, "")
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Type TEOSPlayerReportRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSPlayerReportListener
	Field _complete:Int

	Public
	Function _Create:TEOSPlayerReportRequest(owner:TEOSPlatform, listener:IEOSPlayerReportListener)
		If Not owner Or Not listener Then
			Return Null
		End If
		Local request:TEOSPlayerReportRequest = New TEOSPlayerReportRequest
		request._owner = owner
		request._listener = listener
		Return request
	End Function

	Function _Complete(request:TEOSPlayerReportRequest, result:EEOSResult) { nomangle }
		If Not request Or request._complete Then
			Return
		End If
		Local listener:IEOSPlayerReportListener = request._listener
		If EOSResultIsOperationComplete(result) Then
			request._complete = True
			request._listener = Null
		End If
		If listener Then
			listener.OnEOSPlayerReport(result)
		End If
	End Function

	Function _Cancel(request:TEOSPlayerReportRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled)
	End Function

	Method IsComplete:Int()
		Return _complete
	End Method
End Type

Rem
bbdoc: Queries active player sanctions and creates appeals.
about: Query results are held in the EOS cache and copied into ordinary
BlitzMax values with #CopyPlayerSanctionByIndex.
End Rem
Type TEOSSanctions
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSSanctions(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local sanctions:TEOSSanctions = New TEOSSanctions
		sanctions._owner = owner
		sanctions._handle = handle
		Return sanctions
	End Function

	Method QueryActivePlayerSanctions:TEOSSanctionsQueryRequest(options:TEOSSanctionsQueryOptions, listener:IEOSSanctionsQueryListener)
		If Not _owner Or Not _owner.IsValid() Or Not _handle Or Not options Or Not listener Then
			Return Null
		End If
		If Not options.TargetUserId Or Not options.TargetUserId.IsValid() Then
			Return Null
		End If
		Local localUserHandle:Byte Ptr
		If options.LocalUserId Then
			If Not options.LocalUserId.IsValid() Then
				Return Null
			End If
			localUserHandle = options.LocalUserId._NativeHandle()
		End If
		Local request:TEOSSanctionsQueryRequest = TEOSSanctionsQueryRequest._Create(_owner, listener)
		bmx_eos_sanctions_query( ..
			_owner._NativeHandle(), ..
			_handle, ..
			request, ..
			localUserHandle, ..
			options.TargetUserId._NativeHandle())
		Return request
	End Method

	Method PlayerSanctionCount:Int(targetUserId:TEOSProductUserId)
		If Not _owner Or Not _owner.IsValid() Or Not _handle Then
			Return 0
		End If
		If Not targetUserId Or Not targetUserId.IsValid() Then
			Return 0
		End If
		Return bmx_eos_sanctions_get_count(_handle, targetUserId._NativeHandle())
	End Method

	Method CopyPlayerSanctionByIndex:EEOSResult(targetUserId:TEOSProductUserId, index:Int, sanction:TEOSPlayerSanction Var)
		sanction = Null
		If Not _owner Or Not _owner.IsValid() Or Not _handle Or index < 0 Then
			Return EEOSResult.InvalidParameters
		End If
		If Not targetUserId Or Not targetUserId.IsValid() Then
			Return EEOSResult.InvalidParameters
		End If
		Local value:TEOSPlayerSanction = New TEOSPlayerSanction
		Local result:EEOSResult = bmx_eos_sanctions_copy_by_index( ..
			_handle, ..
			targetUserId._NativeHandle(), ..
			UInt(index), ..
			value.TimePlaced, ..
			value.Action, ..
			value.TimeExpires, ..
			value.ReferenceId)
		If result = EEOSResult.Success Then
			sanction = value
		End If
		Return result
	End Method

	Method CreatePlayerSanctionAppeal:TEOSSanctionAppealRequest(options:TEOSSanctionAppealOptions, listener:IEOSSanctionAppealListener)
		If Not _owner Or Not _owner.IsValid() Or Not _handle Or Not options Or Not listener Then
			Return Null
		End If
		If Not options.LocalUserId Or Not options.LocalUserId.IsValid() Or Not options.ReferenceId Then
			Return Null
		End If
		If options.Reason < EEOSSanctionAppealReason.IncorrectSanction Or options.Reason > EEOSSanctionAppealReason.AppealForForgiveness Then
			Return Null
		End If
		Local request:TEOSSanctionAppealRequest = TEOSSanctionAppealRequest._Create(_owner, listener)
		bmx_eos_sanctions_appeal( ..
			_owner._NativeHandle(), ..
			_handle, ..
			request, ..
			options.LocalUserId._NativeHandle(), ..
			options.Reason, ..
			options.ReferenceId)
		Return request
	End Method
End Type

Rem
bbdoc: Sends player behavior reports directly to EOS.
about: Calling #SendPlayerBehaviorReport is an externally visible moderation
action. Applications should require deliberate player confirmation and should
not use it for automated telemetry.
End Rem
Type TEOSReports
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr

	Public
	Function _Create:TEOSReports(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then
			Return Null
		End If
		Local reports:TEOSReports = New TEOSReports
		reports._owner = owner
		reports._handle = handle
		Return reports
	End Function

	Method SendPlayerBehaviorReport:TEOSPlayerReportRequest(options:TEOSPlayerReportOptions, listener:IEOSPlayerReportListener)
		If Not _owner Or Not _owner.IsValid() Or Not _handle Or Not options Or Not listener Then
			Return Null
		End If
		If Not options.ReporterUserId Or Not options.ReporterUserId.IsValid() Then
			Return Null
		End If
		If Not options.ReportedUserId Or Not options.ReportedUserId.IsValid() Then
			Return Null
		End If
		If options.Category < EEOSPlayerReportsCategory.Cheating Or options.Category > EEOSPlayerReportsCategory.Other Then
			Return Null
		End If
		If options.Message.Length > EOS_REPORTS_REPORTMESSAGE_MAX_LENGTH Then
			Return Null
		End If
		If options.Context.Length > EOS_REPORTS_REPORTCONTEXT_MAX_LENGTH Then
			Return Null
		End If
		Local request:TEOSPlayerReportRequest = TEOSPlayerReportRequest._Create(_owner, listener)
		bmx_eos_reports_send( ..
			_owner._NativeHandle(), ..
			_handle, ..
			request, ..
			options.ReporterUserId._NativeHandle(), ..
			options.ReportedUserId._NativeHandle(), ..
			options.Category, ..
			options.Message, ..
			options.Context)
		Return request
	End Method
End Type

Private
Extern
	Function bmx_eos_sanctions_query(platform:Byte Ptr, sanctions:Byte Ptr, request:TEOSSanctionsQueryRequest, localUser:Byte Ptr, targetUser:Byte Ptr)
	Function bmx_eos_sanctions_get_count:Int(sanctions:Byte Ptr, targetUser:Byte Ptr)
	Function bmx_eos_sanctions_copy_by_index:EEOSResult(sanctions:Byte Ptr, targetUser:Byte Ptr, index:UInt, timePlaced:Long Var, action:String Var, timeExpires:Long Var, referenceId:String Var)
	Function bmx_eos_sanctions_appeal(platform:Byte Ptr, sanctions:Byte Ptr, request:TEOSSanctionAppealRequest, localUser:Byte Ptr, reason:EEOSSanctionAppealReason, referenceId:String)
	Function bmx_eos_reports_send(platform:Byte Ptr, reports:Byte Ptr, request:TEOSPlayerReportRequest, reporterUser:Byte Ptr, reportedUser:Byte Ptr, category:EEOSPlayerReportsCategory, message:String, context:String)
End Extern

Public
