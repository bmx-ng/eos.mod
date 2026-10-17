SuperStrict

Framework EOS.SDK
Import BRL.Bank
Import BRL.BankStream
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TStorageFlow Implements IEOSAuthLoginListener, IEOSConnectLoginListener, IEOSConnectCreateUserListener, IEOSStorageQueryListener, IEOSStorageTransferListener, IEOSStorageOperationListener
	Field Auth:TEOSAuth
	Field Connect:TEOSConnect
	Field TitleStorage:TEOSTitleStorage
	Field PlayerStorage:TEOSPlayerDataStorage
	Field TitleFilename:String
	Field CreateMissingProductUser:Int
	Field UserId:TEOSProductUserId
	Field Transfer:TEOSStorageTransferRequest
	Field Stream:TBankStream
	Field Bank:TBank
	Field ExpectedPlayerText:String = "Hello from BlitzMax Player Data Storage."
	Field PlayerFilename:String = "blitzmax-stream-test.txt"
	Field PlayerCopyFilename:String = "blitzmax-stream-test-copy.txt"
	Field Done:Int

	Method OnEOSAuthLogin(result:EEOSResult, localUserId:TEOSEpicAccountId, pinGrantInfo:TEOSAuthPinGrantInfo, continuanceToken:TEOSAuthContinuanceToken, selectedAccountId:TEOSEpicAccountId)
		Print "Auth login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result <> EEOSResult.Success Then Done = True; Return

		Local accountId:TEOSEpicAccountId = selectedAccountId
		If Not accountId Then accountId = localUserId
		Local token:TEOSAuthIdToken
		result = Auth.CopyIdToken(accountId, token)
		If result <> EEOSResult.Success Then Print "Copy ID token: " + EOSResultString(result); Done = True; Return

		Local credentials:TEOSConnectCredentials = New TEOSConnectCredentials
		credentials.Type = EEOSExternalCredentialType.EpicIdToken
		credentials.Token = token.JsonWebToken
		Local options:TEOSConnectLoginOptions = New TEOSConnectLoginOptions
		options.Credentials = credentials
		If Not Connect.Login(options, Self) Then Print "Could not start Connect login."; Done = True
	End Method

	Method OnEOSConnectLogin(result:EEOSResult, localUserId:TEOSProductUserId, continuanceToken:TEOSConnectContinuanceToken)
		Print "Connect login: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then StartStorage(localUserId); Return
		If result = EEOSResult.InvalidUser And continuanceToken And CreateMissingProductUser Then
			If Not Connect.CreateUser(continuanceToken, Self) Then Done = True
		Else
			Done = True
		End If
	End Method

	Method OnEOSConnectCreateUser(result:EEOSResult, localUserId:TEOSProductUserId)
		Print "Connect create user: " + EOSResultString(result)
		If Not EOSResultIsOperationComplete(result) Then Return
		If result = EEOSResult.Success Then StartStorage(localUserId) Else Done = True
	End Method

	Method StartStorage(userId:TEOSProductUserId)
		Self.UserId = userId
		Print "Product User ID: " + UserId.ToString()
		If TitleFilename Then
			Print "Querying Title Storage file: " + TitleFilename
			If Not TitleStorage.QueryFile(UserId, TitleFilename, Self) Then Print "Could not start Title Storage query."; Done = True
		Else
			Print "TITLE_STORAGE_FILENAME is empty; skipping the optional Title Storage read."
			StartPlayerWrite()
		End If
	End Method

	Method StartTitleRead()
		Bank = TBank.Create(0)
		Stream = CreateBankStream(Bank)
		Transfer = TitleStorage.ReadFile(UserId, TitleFilename, Stream, Self)
		If Not Transfer Then Print "Could not start Title Storage read."; Done = True
	End Method

	Method StartPlayerWrite()
		Bank = TBank.Create(0)
		Stream = CreateBankStream(Bank)
		Stream.WriteString(ExpectedPlayerText, True)
		Stream.Seek(0)
		Print "Uploading Player Data Storage file through a TBankStream."
		Transfer = PlayerStorage.WriteFile(UserId, PlayerFilename, Stream, Self)
		If Not Transfer Then Print "Could not start Player Data Storage write."; Done = True
	End Method

	Method StartPlayerRead()
		Bank = TBank.Create(0)
		Stream = CreateBankStream(Bank)
		Print "Downloading Player Data Storage file through a TBankStream."
		Transfer = PlayerStorage.ReadFile(UserId, PlayerFilename, Stream, Self)
		If Not Transfer Then Print "Could not start Player Data Storage read."; Done = True
	End Method

	Method OnEOSStorageQuery(operation:EEOSStorageOperation, result:EEOSResult, localUserId:TEOSProductUserId, fileCount:UInt)
		Print "Storage query " + Int(operation) + ": " + EOSResultString(result) + ", files = " + fileCount
		If result <> EEOSResult.Success Then Done = True; Return

		Select operation
			Case EEOSStorageOperation.TitleQueryFile
				Local metadata:TEOSTitleStorageFileMetadata
				result = TitleStorage.CopyFileMetadataByFilename(UserId, TitleFilename, metadata)
				If result = EEOSResult.Success Then Print "Title file size: " + metadata.FileSizeBytes + " bytes"
				StartTitleRead()
			Case EEOSStorageOperation.PlayerQueryFileList
				For Local index:Int = 0 Until PlayerStorage.FileMetadataCount(UserId)
					Local metadata:TEOSPlayerDataStorageFileMetadata
					If PlayerStorage.CopyFileMetadataByIndex(UserId, index, metadata) = EEOSResult.Success Then Print "Player file: " + metadata.Filename + " (" + metadata.FileSizeBytes + " bytes)"
				Next
				If Not PlayerStorage.DuplicateFile(UserId, PlayerFilename, PlayerCopyFilename, Self) Then Print "Could not start duplicate."; Done = True
		End Select
	End Method

	Method OnEOSStorageTransfer(operation:EEOSStorageOperation, result:EEOSResult, localUserId:TEOSProductUserId, filename:String)
		Print "Storage transfer " + Int(operation) + " for " + filename + ": " + EOSResultString(result)
		Transfer = Null
		If result <> EEOSResult.Success Then Done = True; Return

		Select operation
			Case EEOSStorageOperation.TitleReadFile
				Print "Downloaded Title Storage bytes: " + Bank.Size()
				StartPlayerWrite()
			Case EEOSStorageOperation.PlayerWriteFile
				StartPlayerRead()
			Case EEOSStorageOperation.PlayerReadFile
				Stream.Seek(0)
				Local actual:String = Stream.ReadString(Int(Stream.Size()), True)
				If actual <> ExpectedPlayerText Then Print "Downloaded data did not match the upload."; Done = True; Return
				Print "Player data round trip matched."
				If Not PlayerStorage.QueryFileList(UserId, Self) Then Print "Could not start Player Data Storage list query."; Done = True
		End Select
	End Method

	Method OnEOSStorageOperation(operation:EEOSStorageOperation, result:EEOSResult, localUserId:TEOSProductUserId, filename:String)
		Print "Storage operation " + Int(operation) + " for " + filename + ": " + EOSResultString(result)
		If result <> EEOSResult.Success Then Done = True; Return
		Select operation
			Case EEOSStorageOperation.PlayerDuplicateFile
				If Not PlayerStorage.DeleteFile(UserId, PlayerFilename, Self) Then Print "Could not delete original file."; Done = True
			Case EEOSStorageOperation.PlayerDeleteFile
				If filename = PlayerFilename Then
					If Not PlayerStorage.DeleteFile(UserId, PlayerCopyFilename, Self) Then Print "Could not delete copied file."; Done = True
				Else
					Print "Storage stream test completed."
					Done = True
				End If
		End Select
	End Method
End Type

Function ConfigValue:String(config:String, name:String)
	For Local line:String = EachIn config.Replace(Chr(13), "").Split("~n")
		line = line.Trim()
		If Not line Or line.StartsWith("#") Then Continue
		Local separator:Int = line.Find("=")
		If separator >= 0 And line[..separator].Trim() = name Then Return line[separator + 1..].Trim()
	Next
	Return ""
End Function

Local configPath:String = "eos.local.conf"
If AppArgs.Length > 1 Then configPath = AppArgs[1]
If FileType(configPath) <> FILETYPE_FILE Then RuntimeError "Copy eos.local.conf.example to eos.local.conf and fill in your EOS values."
Local config:String = LoadText(configPath)

Local initialize:TEOSInitializeOptions = New TEOSInitializeOptions
initialize.ProductName = "EOS Storage stream example"
initialize.ProductVersion = "0.18.0"
Local result:EEOSResult = EOSInitialize(initialize)
If result <> EEOSResult.Success Then RuntimeError "EOS initialization failed: " + EOSResultString(result)

Local options:TEOSPlatformOptions = New TEOSPlatformOptions
options.ProductId = ConfigValue(config, "PRODUCT_ID")
options.SandboxId = ConfigValue(config, "SANDBOX_ID")
options.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID")
options.ClientId = ConfigValue(config, "CLIENT_ID")
options.ClientSecret = ConfigValue(config, "CLIENT_SECRET")
options.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")
If Not options.EncryptionKey Then options.EncryptionKey = getenv_("EOS_ENCRYPTION_KEY")
If options.EncryptionKey.Length <> 64 Then RuntimeError "Set ENCRYPTION_KEY to a stable 64-character hexadecimal key before using EOS storage."
options.CacheDirectory = ConfigValue(config, "CACHE_DIRECTORY")
If Not options.CacheDirectory Then options.CacheDirectory = AppDir
Local platform:TEOSPlatform = TEOSPlatform.Create(options)
If Not platform Then RuntimeError "EOS platform creation failed."

Local flow:TStorageFlow = New TStorageFlow
flow.Auth = platform.Auth()
flow.Connect = platform.Connect()
flow.TitleStorage = platform.TitleStorage()
flow.PlayerStorage = platform.PlayerDataStorage()
flow.TitleFilename = ConfigValue(config, "TITLE_STORAGE_FILENAME")
flow.CreateMissingProductUser = Int(ConfigValue(config, "CREATE_MISSING_PRODUCT_USER"))
If Not flow.Auth Then RuntimeError "The EOS Auth interface is unavailable."
If Not flow.Connect Then RuntimeError "The EOS Connect interface is unavailable."
If Not flow.PlayerStorage Then RuntimeError "The EOS Player Data Storage interface is unavailable."
If flow.TitleFilename And Not flow.TitleStorage Then RuntimeError "The EOS Title Storage interface is unavailable."

Local credentials:TEOSAuthCredentials = New TEOSAuthCredentials
credentials.Type = EEOSLoginCredentialType.Developer
credentials.Id = ConfigValue(config, "DEV_AUTH_HOST")
credentials.Token = ConfigValue(config, "DEV_AUTH_CREDENTIAL")
Local login:TEOSAuthLoginOptions = New TEOSAuthLoginOptions
login.Credentials = credentials
If Not flow.Auth.Login(login, flow) Then RuntimeError "Could not start Auth login."

Local started:Int = MilliSecs()
While Not flow.Done And MilliSecs() - started < 120000
	platform.Tick()
	Delay 16
Wend
If Not flow.Done Then Print "Storage stream example timed out."

platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError "EOS shutdown failed: " + EOSResultString(result)
