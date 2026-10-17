' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

Const EOS_TITLESTORAGE_FILENAME_MAX_LENGTH_BYTES:Int = 64
Const EOS_PLAYERDATASTORAGE_FILENAME_MAX_LENGTH_BYTES:Int = 64
Const EOS_PLAYERDATASTORAGE_TIME_UNDEFINED:Long = -1
Const EOS_STORAGE_DEFAULT_CHUNK_LENGTH:UInt = 65536

Rem
bbdoc: Identifies the storage operation delivered to a listener.
End Rem
Enum EEOSStorageOperation:Byte
	TitleQueryFile
	TitleQueryFileList
	TitleReadFile
	TitleDeleteCache
	PlayerQueryFile
	PlayerQueryFileList
	PlayerReadFile
	PlayerWriteFile
	PlayerDuplicateFile
	PlayerDeleteFile
	PlayerDeleteCache
End Enum

Rem
bbdoc: Metadata for a read-only Title Storage file.
End Rem
Type TEOSTitleStorageFileMetadata
	Field FileSizeBytes:UInt
	Field MD5Hash:String
	Field Filename:String
	Field UnencryptedDataSizeBytes:UInt
End Type

Rem
bbdoc: Metadata for a Player Data Storage file.
End Rem
Type TEOSPlayerDataStorageFileMetadata
	Field FileSizeBytes:UInt
	Field MD5Hash:String
	Field Filename:String
	Field LastModifiedTime:Long = EOS_PLAYERDATASTORAGE_TIME_UNDEFINED
	Field UnencryptedDataSizeBytes:UInt
End Type

Rem
bbdoc: Receives completion of a storage metadata query.
End Rem
Interface IEOSStorageQueryListener
	Method OnEOSStorageQuery(operation:EEOSStorageOperation, result:EEOSResult, localUserId:TEOSProductUserId, fileCount:UInt)
End Interface

Rem
bbdoc: Receives completion of a non-transfer storage operation.
End Rem
Interface IEOSStorageOperationListener
	Method OnEOSStorageOperation(operation:EEOSStorageOperation, result:EEOSResult, localUserId:TEOSProductUserId, filename:String)
End Interface

Rem
bbdoc: Receives completion of a stream transfer.
about: The stream has been flushed, and optionally closed, before this method is called.
End Rem
Interface IEOSStorageTransferListener
	Method OnEOSStorageTransfer(operation:EEOSStorageOperation, result:EEOSResult, localUserId:TEOSProductUserId, filename:String)
End Interface

Rem
bbdoc: Tracks an asynchronous storage query or operation.
End Rem
Type TEOSStorageRequest
	Private
	Field _owner:TEOSPlatform
	Field _queryListener:IEOSStorageQueryListener
	Field _operationListener:IEOSStorageOperationListener
	Field _operation:EEOSStorageOperation
	Field _complete:Int

	Public
	Function _CreateQuery:TEOSStorageRequest(owner:TEOSPlatform, operation:EEOSStorageOperation, listener:IEOSStorageQueryListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSStorageRequest = New TEOSStorageRequest
		request._owner = owner; request._operation = operation; request._queryListener = listener
		Return request
	End Function

	Function _CreateOperation:TEOSStorageRequest(owner:TEOSPlatform, operation:EEOSStorageOperation, listener:IEOSStorageOperationListener)
		If Not owner Or Not listener Then Return Null
		Local request:TEOSStorageRequest = New TEOSStorageRequest
		request._owner = owner; request._operation = operation; request._operationListener = listener
		Return request
	End Function

	Function _CompleteQuery(request:TEOSStorageRequest, result:EEOSResult, localUserHandle:Byte Ptr, fileCount:UInt) { nomangle }
		If Not request Or request._complete Then Return
		request._complete = True
		Local listener:IEOSStorageQueryListener = request._queryListener
		request._queryListener = Null; request._operationListener = Null
		If listener Then listener.OnEOSStorageQuery(request._operation, result, TEOSProductUserId._Create(localUserHandle), fileCount)
	End Function

	Function _CompleteOperation(request:TEOSStorageRequest, result:EEOSResult, localUserHandle:Byte Ptr, filename:String) { nomangle }
		If Not request Or request._complete Then Return
		request._complete = True
		Local listener:IEOSStorageOperationListener = request._operationListener
		request._queryListener = Null; request._operationListener = Null
		If listener Then listener.OnEOSStorageOperation(request._operation, result, TEOSProductUserId._Create(localUserHandle), filename)
	End Function

	Function _Cancel(request:TEOSStorageRequest) { nomangle }
		If Not request Or request._complete Then Return
		If request._queryListener Then
			_CompleteQuery(request, EEOSResult.Canceled, Null, 0)
		Else
			_CompleteOperation(request, EEOSResult.Canceled, Null, "")
		End If
	End Function

	Method IsComplete:Int() Return _complete End Method
	Method Operation:EEOSStorageOperation() Return _operation End Method
End Type

Rem
bbdoc: Tracks an asynchronous file transfer between EOS and a #TStream.
about: Keep this object alive until its completion callback. #BytesTransferred and
#TotalBytes contain the most recent progress reported by EOS. #Cancel requests
cancellation; completion is still reported asynchronously.
End Rem
Type TEOSStorageTransferRequest
	Private
	Field _owner:TEOSPlatform
	Field _listener:IEOSStorageTransferListener
	Field _operation:EEOSStorageOperation
	Field _context:Byte Ptr
	Field _stream:TStream
	Field _closeStream:Int
	Field _complete:Int
	Field _bytesTransferred:UInt
	Field _totalBytes:UInt

	Public
	Function _Create:TEOSStorageTransferRequest(owner:TEOSPlatform, operation:EEOSStorageOperation, stream:TStream, closeStream:Int, listener:IEOSStorageTransferListener)
		If Not owner Or Not stream Or Not listener Then Return Null
		Local request:TEOSStorageTransferRequest = New TEOSStorageTransferRequest
		request._owner = owner; request._operation = operation; request._stream = stream; request._closeStream = closeStream; request._listener = listener
		Return request
	End Function

	Method _SetContext:Int(context:Byte Ptr)
		_context = context
		Return _context <> Null
	End Method

	Function _Progress(request:TEOSStorageTransferRequest, bytesTransferred:UInt, totalBytes:UInt) { nomangle }
		If Not request Or request._complete Then Return
		request._bytesTransferred = bytesTransferred; request._totalBytes = totalBytes
	End Function

	Function _WriteChunk:Int(request:TEOSStorageTransferRequest, buffer:Byte Ptr, length:Int) { nomangle }
		If Not request Or request._complete Or Not request._stream Or Not buffer Or length < 0 Then Return False
		Local succeeded:Int
		Try
			Local offset:Int
			While offset < length
				Local count:Long = request._stream.Write(buffer + offset, length - offset)
				If count <= 0 Then Exit
				offset :+ Int(count)
			Wend
			succeeded = offset = length
		Catch error:Object
			succeeded = False
		End Try
		Return succeeded
	End Function

	' Returns -(count + 1) when the stream reached EOF, otherwise count.
	Function _ReadChunk:Int(request:TEOSStorageTransferRequest, buffer:Byte Ptr, length:Int) { nomangle }
		If Not request Or request._complete Or Not request._stream Or Not buffer Or length < 0 Then Return -1
		Local result:Int = -1
		Try
			Local offset:Int
			While offset < length
				Local count:Long = request._stream.Read(buffer + offset, length - offset)
				If count <= 0 Then
					result = -(offset + 1)
					Exit
				End If
				offset :+ Int(count)
			Wend
			If offset = length Then result = offset
		Catch error:Object
			result = -1
		End Try
		Return result
	End Function

	Function _Complete(request:TEOSStorageTransferRequest, result:EEOSResult, localUserHandle:Byte Ptr, filename:String) { nomangle }
		If Not request Or request._complete Then Return
		request._complete = True; request._context = Null
		Local listener:IEOSStorageTransferListener = request._listener
		request._listener = Null
		Try
			If request._stream And request._operation <> EEOSStorageOperation.PlayerWriteFile Then request._stream.Flush()
			If request._closeStream And request._stream Then request._stream.Close()
		Catch error:Object
			If result = EEOSResult.Success Then
				result = EEOSResult.UnexpectedError
			End If
		End Try
		request._stream = Null
		If listener Then listener.OnEOSStorageTransfer(request._operation, result, TEOSProductUserId._Create(localUserHandle), filename)
	End Function

	Function _Cancel(request:TEOSStorageTransferRequest) { nomangle }
		_Complete(request, EEOSResult.Canceled, Null, "")
	End Function

	Method Cancel:EEOSResult()
		If _complete Then Return EEOSResult.InvalidState
		If Not _context Then Return EEOSResult.NotFound
		Return bmx_eos_storage_transfer_cancel(_context)
	End Method
	Method IsComplete:Int()
		Return _complete
	End Method
	Method Operation:EEOSStorageOperation()
		Return _operation
	End Method
	Method BytesTransferred:UInt()
		Return _bytesTransferred
	End Method
	Method TotalBytes:UInt()
		Return _totalBytes
	End Method
End Type

Rem
bbdoc: Provides read-only files configured for the product in EOS Title Storage.
about: A local Product User ID is optional for Title Storage operations. Downloads
are written incrementally to the supplied destination stream.
End Rem
Type TEOSTitleStorage
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr
	Public
	Function _Create:TEOSTitleStorage(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local storage:TEOSTitleStorage = New TEOSTitleStorage
		storage._owner = owner; storage._handle = handle
		Return storage
	End Function
	Method QueryFile:TEOSStorageRequest(localUserId:TEOSProductUserId, filename:String, listener:IEOSStorageQueryListener)
		If Not ValidOptional(localUserId) Or Not FilenameValid(filename) Or Not listener Then Return Null
		Local request:TEOSStorageRequest = TEOSStorageRequest._CreateQuery(_owner, EEOSStorageOperation.TitleQueryFile, listener)
		bmx_eos_title_storage_query_file(_owner._NativeHandle(), _handle, request, UserHandle(localUserId), filename)
		Return request
	End Method
	Method QueryFileList:TEOSStorageRequest(localUserId:TEOSProductUserId, tags:String[], listener:IEOSStorageQueryListener)
		If Not _owner Or Not _owner.IsValid() Or Not listener Then Return Null
		If localUserId And Not localUserId.IsValid() Then Return Null
		Local request:TEOSStorageRequest = TEOSStorageRequest._CreateQuery(_owner, EEOSStorageOperation.TitleQueryFileList, listener)
		bmx_eos_title_storage_query_list(_owner._NativeHandle(), _handle, request, UserHandle(localUserId), tags)
		Return request
	End Method
	Method FileMetadataCount:UInt(localUserId:TEOSProductUserId = Null)
		If Not ValidOptional(localUserId) Then Return 0
		Return bmx_eos_title_storage_metadata_count(_handle, UserHandle(localUserId))
	End Method
	Method CopyFileMetadataByIndex:EEOSResult(localUserId:TEOSProductUserId, index:UInt, metadata:TEOSTitleStorageFileMetadata Var)
		metadata = Null; If Not ValidOptional(localUserId) Then Return EEOSResult.InvalidParameters
		Local value:TEOSTitleStorageFileMetadata = New TEOSTitleStorageFileMetadata
		Local result:EEOSResult = bmx_eos_title_storage_copy_metadata_index(_handle, UserHandle(localUserId), index, value.FileSizeBytes, value.MD5Hash, value.Filename, value.UnencryptedDataSizeBytes)
		If result = EEOSResult.Success Then metadata = value
		Return result
	End Method
	Method CopyFileMetadataByFilename:EEOSResult(localUserId:TEOSProductUserId, filename:String, metadata:TEOSTitleStorageFileMetadata Var)
		metadata = Null; If Not ValidOptional(localUserId) Or Not FilenameValid(filename) Then Return EEOSResult.InvalidParameters
		Local value:TEOSTitleStorageFileMetadata = New TEOSTitleStorageFileMetadata
		Local result:EEOSResult = bmx_eos_title_storage_copy_metadata_name(_handle, UserHandle(localUserId), filename, value.FileSizeBytes, value.MD5Hash, value.Filename, value.UnencryptedDataSizeBytes)
		If result = EEOSResult.Success Then metadata = value
		Return result
	End Method
	Method ReadFile:TEOSStorageTransferRequest(localUserId:TEOSProductUserId, filename:String, destination:TStream, listener:IEOSStorageTransferListener, chunkLength:UInt = EOS_STORAGE_DEFAULT_CHUNK_LENGTH, closeStream:Int = False)
		If Not ValidOptional(localUserId) Or Not FilenameValid(filename) Or Not destination Or Not listener Or chunkLength = 0 Then Return Null
		Local request:TEOSStorageTransferRequest = TEOSStorageTransferRequest._Create(_owner, EEOSStorageOperation.TitleReadFile, destination, closeStream, listener)
		If Not request._SetContext(bmx_eos_title_storage_read(_owner._NativeHandle(), _handle, request, UserHandle(localUserId), filename, chunkLength)) Then Return Null
		Return request
	End Method
	Method DeleteCache:TEOSStorageRequest(localUserId:TEOSProductUserId, listener:IEOSStorageOperationListener)
		If Not ValidOptional(localUserId) Or Not listener Then Return Null
		Local request:TEOSStorageRequest = TEOSStorageRequest._CreateOperation(_owner, EEOSStorageOperation.TitleDeleteCache, listener)
		If bmx_eos_title_storage_delete_cache(_owner._NativeHandle(), _handle, request, UserHandle(localUserId)) <> EEOSResult.Success Then Return Null
		Return request
	End Method
	Private
	Method UserHandle:Byte Ptr(user:TEOSProductUserId) If user Then Return user._NativeHandle() Else Return Null
	End Method
	Method FilenameValid:Int(filename:String) Return filename.Length > 0 And filename.Length <= EOS_TITLESTORAGE_FILENAME_MAX_LENGTH_BYTES End Method
	Method ValidOptional:Int(user:TEOSProductUserId) Return _owner And _owner.IsValid() And _handle And (Not user Or user.IsValid()) End Method
End Type

Rem
bbdoc: Provides private persistent files belonging to a Product User.
about: Reads write incrementally to a destination #TStream and writes read
incrementally from a source #TStream, so files do not need to be buffered fully
in memory. If closeStream is true, the stream is closed before completion is
reported; otherwise ownership remains with the caller.
End Rem
Type TEOSPlayerDataStorage
	Private
	Field _owner:TEOSPlatform
	Field _handle:Byte Ptr
	Public
	Function _Create:TEOSPlayerDataStorage(owner:TEOSPlatform, handle:Byte Ptr)
		If Not owner Or Not handle Then Return Null
		Local storage:TEOSPlayerDataStorage = New TEOSPlayerDataStorage
		storage._owner = owner; storage._handle = handle
		Return storage
	End Function
	Method QueryFile:TEOSStorageRequest(user:TEOSProductUserId, filename:String, listener:IEOSStorageQueryListener)
		If Not Valid(user, filename) Or Not listener Then Return Null
		Local request:TEOSStorageRequest = TEOSStorageRequest._CreateQuery(_owner, EEOSStorageOperation.PlayerQueryFile, listener)
		bmx_eos_player_storage_query_file(_owner._NativeHandle(), _handle, request, user._NativeHandle(), filename); Return request
	End Method
	Method QueryFileList:TEOSStorageRequest(user:TEOSProductUserId, listener:IEOSStorageQueryListener)
		If Not ValidUser(user) Or Not listener Then Return Null
		Local request:TEOSStorageRequest = TEOSStorageRequest._CreateQuery(_owner, EEOSStorageOperation.PlayerQueryFileList, listener)
		bmx_eos_player_storage_query_list(_owner._NativeHandle(), _handle, request, user._NativeHandle()); Return request
	End Method
	Method FileMetadataCount:Int(user:TEOSProductUserId)
		If Not ValidUser(user) Then Return 0
		Return bmx_eos_player_storage_metadata_count(_handle, user._NativeHandle())
	End Method
	Method CopyFileMetadataByIndex:EEOSResult(user:TEOSProductUserId, index:Int, metadata:TEOSPlayerDataStorageFileMetadata Var)
		metadata = Null; If Not ValidUser(user) Or index < 0 Then Return EEOSResult.InvalidParameters
		Local value:TEOSPlayerDataStorageFileMetadata = New TEOSPlayerDataStorageFileMetadata
		Local result:EEOSResult = bmx_eos_player_storage_copy_metadata_index(_handle, user._NativeHandle(), index, value.FileSizeBytes, value.MD5Hash, value.Filename, value.LastModifiedTime, value.UnencryptedDataSizeBytes)
		If result = EEOSResult.Success Then metadata = value
		Return result
	End Method
	Method CopyFileMetadataByFilename:EEOSResult(user:TEOSProductUserId, filename:String, metadata:TEOSPlayerDataStorageFileMetadata Var)
		metadata = Null; If Not Valid(user, filename) Then Return EEOSResult.InvalidParameters
		Local value:TEOSPlayerDataStorageFileMetadata = New TEOSPlayerDataStorageFileMetadata
		Local result:EEOSResult = bmx_eos_player_storage_copy_metadata_name(_handle, user._NativeHandle(), filename, value.FileSizeBytes, value.MD5Hash, value.Filename, value.LastModifiedTime, value.UnencryptedDataSizeBytes)
		If result = EEOSResult.Success Then metadata = value
		Return result
	End Method
	Method ReadFile:TEOSStorageTransferRequest(user:TEOSProductUserId, filename:String, destination:TStream, listener:IEOSStorageTransferListener, chunkLength:UInt = EOS_STORAGE_DEFAULT_CHUNK_LENGTH, closeStream:Int = False)
		If Not Valid(user, filename) Or Not destination Or Not listener Or chunkLength = 0 Then Return Null
		Local request:TEOSStorageTransferRequest = TEOSStorageTransferRequest._Create(_owner, EEOSStorageOperation.PlayerReadFile, destination, closeStream, listener)
		If Not request._SetContext(bmx_eos_player_storage_read(_owner._NativeHandle(), _handle, request, user._NativeHandle(), filename, chunkLength)) Then Return Null
		Return request
	End Method
	Method WriteFile:TEOSStorageTransferRequest(user:TEOSProductUserId, filename:String, source:TStream, listener:IEOSStorageTransferListener, chunkLength:UInt = EOS_STORAGE_DEFAULT_CHUNK_LENGTH, closeStream:Int = False)
		If Not Valid(user, filename) Or Not source Or Not listener Or chunkLength = 0 Then Return Null
		Local request:TEOSStorageTransferRequest = TEOSStorageTransferRequest._Create(_owner, EEOSStorageOperation.PlayerWriteFile, source, closeStream, listener)
		If Not request._SetContext(bmx_eos_player_storage_write(_owner._NativeHandle(), _handle, request, user._NativeHandle(), filename, chunkLength)) Then Return Null
		Return request
	End Method
	Method DuplicateFile:TEOSStorageRequest(user:TEOSProductUserId, sourceFilename:String, destinationFilename:String, listener:IEOSStorageOperationListener)
		If Not Valid(user, sourceFilename) Or Not FilenameValid(destinationFilename) Or Not listener Then Return Null
		Local request:TEOSStorageRequest = TEOSStorageRequest._CreateOperation(_owner, EEOSStorageOperation.PlayerDuplicateFile, listener)
		bmx_eos_player_storage_duplicate(_owner._NativeHandle(), _handle, request, user._NativeHandle(), sourceFilename, destinationFilename); Return request
	End Method
	Method DeleteFile:TEOSStorageRequest(user:TEOSProductUserId, filename:String, listener:IEOSStorageOperationListener)
		If Not Valid(user, filename) Or Not listener Then Return Null
		Local request:TEOSStorageRequest = TEOSStorageRequest._CreateOperation(_owner, EEOSStorageOperation.PlayerDeleteFile, listener)
		bmx_eos_player_storage_delete(_owner._NativeHandle(), _handle, request, user._NativeHandle(), filename); Return request
	End Method
	Method DeleteCache:TEOSStorageRequest(user:TEOSProductUserId, listener:IEOSStorageOperationListener)
		If Not ValidUser(user) Or Not listener Then Return Null
		Local request:TEOSStorageRequest = TEOSStorageRequest._CreateOperation(_owner, EEOSStorageOperation.PlayerDeleteCache, listener)
		If bmx_eos_player_storage_delete_cache(_owner._NativeHandle(), _handle, request, user._NativeHandle()) <> EEOSResult.Success Then Return Null
		Return request
	End Method
	Private
	Method FilenameValid:Int(filename:String) Return filename.Length > 0 And filename.Length <= EOS_PLAYERDATASTORAGE_FILENAME_MAX_LENGTH_BYTES End Method
	Method ValidUser:Int(user:TEOSProductUserId) Return _owner And _owner.IsValid() And _handle And user And user.IsValid() End Method
	Method Valid:Int(user:TEOSProductUserId, filename:String) Return ValidUser(user) And FilenameValid(filename) End Method
End Type

Private
Extern
	Function bmx_eos_title_storage_query_file(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageRequest, user:Byte Ptr, filename:String)
	Function bmx_eos_title_storage_query_list(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageRequest, user:Byte Ptr, tags:String[])
	Function bmx_eos_title_storage_metadata_count:UInt(storage:Byte Ptr, user:Byte Ptr)
	Function bmx_eos_title_storage_copy_metadata_index:EEOSResult(storage:Byte Ptr, user:Byte Ptr, index:UInt, size:UInt Var, md5:String Var, filename:String Var, unencryptedSize:UInt Var)
	Function bmx_eos_title_storage_copy_metadata_name:EEOSResult(storage:Byte Ptr, user:Byte Ptr, requestedFilename:String, size:UInt Var, md5:String Var, filename:String Var, unencryptedSize:UInt Var)
	Function bmx_eos_title_storage_read:Byte Ptr(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageTransferRequest, user:Byte Ptr, filename:String, chunkLength:UInt)
	Function bmx_eos_title_storage_delete_cache:EEOSResult(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageRequest, user:Byte Ptr)
	Function bmx_eos_player_storage_query_file(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageRequest, user:Byte Ptr, filename:String)
	Function bmx_eos_player_storage_query_list(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageRequest, user:Byte Ptr)
	Function bmx_eos_player_storage_metadata_count:Int(storage:Byte Ptr, user:Byte Ptr)
	Function bmx_eos_player_storage_copy_metadata_index:EEOSResult(storage:Byte Ptr, user:Byte Ptr, index:Int, size:UInt Var, md5:String Var, filename:String Var, modified:Long Var, unencryptedSize:UInt Var)
	Function bmx_eos_player_storage_copy_metadata_name:EEOSResult(storage:Byte Ptr, user:Byte Ptr, requestedFilename:String, size:UInt Var, md5:String Var, filename:String Var, modified:Long Var, unencryptedSize:UInt Var)
	Function bmx_eos_player_storage_read:Byte Ptr(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageTransferRequest, user:Byte Ptr, filename:String, chunkLength:UInt)
	Function bmx_eos_player_storage_write:Byte Ptr(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageTransferRequest, user:Byte Ptr, filename:String, chunkLength:UInt)
	Function bmx_eos_player_storage_duplicate(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageRequest, user:Byte Ptr, sourceFilename:String, destinationFilename:String)
	Function bmx_eos_player_storage_delete(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageRequest, user:Byte Ptr, filename:String)
	Function bmx_eos_player_storage_delete_cache:EEOSResult(platform:Byte Ptr, storage:Byte Ptr, request:TEOSStorageRequest, user:Byte Ptr)
	Function bmx_eos_storage_transfer_cancel:EEOSResult(context:Byte Ptr)
End Extern
