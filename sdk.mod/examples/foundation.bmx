SuperStrict

Framework EOS.SDK
Import BRL.StandardIO

Type TConsoleLogListener Implements IEOSLogListener
	Method OnEOSLog(category:String, message:String, level:EEOSLogLevel)
		Print "[" + category + "] " + message
	End Method
End Type

Local options:TEOSInitializeOptions = New TEOSInitializeOptions
options.ProductName = "EOS.SDK foundation test"
options.ProductVersion = "0.1.0"

Print "Starting EOS.SDK foundation test"
Print "Runtime SDK: " + EOSVersion()
Local result:EEOSResult = EOSInitialize(options)
Print "EOS_Initialize: " + EOSResultString(result)
If result <> EEOSResult.Success Then RuntimeError "EOS initialization failed"

TEOSLogging.SetListener(New TConsoleLogListener)
TEOSLogging.SetLevel(EEOSLogCategory.AllCategories, EEOSLogLevel.Info)

Const TestId:String = "0123456789abcdef0123456789abcdef"
Local epicId:TEOSEpicAccountId = TEOSEpicAccountId.FromString(TestId)
Local productUserId:TEOSProductUserId = TEOSProductUserId.FromString(TestId)

Assert epicId And epicId.IsValid()
Assert epicId.ToString() = TestId
Assert productUserId And productUserId.IsValid()
Assert productUserId.ToString() = TestId

TEOSLogging.Pump()
result = EOSShutdown()
Print "EOS_Shutdown: " + EOSResultString(result)
If result <> EEOSResult.Success Then RuntimeError "EOS shutdown failed"
End
