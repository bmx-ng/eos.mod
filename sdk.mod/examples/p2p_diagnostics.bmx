SuperStrict

Framework EOS.SDK
Import BRL.FileSystem
Import BRL.StandardIO
Import BRL.TextStream

Type TP2PDiagnostics Implements IEOSP2PQueryNATTypeListener, IEOSP2PIncomingPacketQueueFullListener
	Field Done:Int
	Field Success:Int
	Field QueueFullSubscription:TEOSP2PIncomingPacketQueueFullSubscription

	Method OnEOSP2PQueryNATType(result:EEOSResult, natType:EEOSNATType)
		Print "NAT query: " + EOSResultString(result)
		If result = EEOSResult.Success Then
			Print "NAT type: " + NATTypeName(natType)
			Success = True
		End If
		Done = True
	End Method

	Method OnEOSP2PIncomingPacketQueueFull(maxSizeBytes:ULong, currentSizeBytes:ULong, localUserId:TEOSProductUserId, channel:Int, packetSizeBytes:UInt)
		Print "Incoming packet queue full: " + currentSizeBytes + "/" + maxSizeBytes + " bytes; channel " + channel + "; rejected packet " + packetSizeBytes + " bytes"
	End Method
End Type

Function NATTypeName:String(natType:EEOSNATType)
	Select natType
		Case EEOSNATType.Open Return "Open"
		Case EEOSNATType.Moderate Return "Moderate"
		Case EEOSNATType.Strict Return "Strict"
		Default Return "Unknown"
	End Select
End Function

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
If FileType(configPath) <> FILETYPE_FILE Then RuntimeError "Pass the path to eos.local.conf."
Local config:String = LoadText(configPath)

Local initializeOptions:TEOSInitializeOptions = New TEOSInitializeOptions
initializeOptions.ProductName = "EOS P2P diagnostics example"
initializeOptions.ProductVersion = "0.17.0"
Local result:EEOSResult = EOSInitialize(initializeOptions)
If result <> EEOSResult.Success Then RuntimeError "EOS initialization failed: " + EOSResultString(result)

Local platformOptions:TEOSPlatformOptions = New TEOSPlatformOptions
platformOptions.ProductId = ConfigValue(config, "PRODUCT_ID")
platformOptions.SandboxId = ConfigValue(config, "SANDBOX_ID")
platformOptions.DeploymentId = ConfigValue(config, "DEPLOYMENT_ID")
platformOptions.ClientId = ConfigValue(config, "CLIENT_ID")
platformOptions.ClientSecret = ConfigValue(config, "CLIENT_SECRET")
platformOptions.EncryptionKey = ConfigValue(config, "ENCRYPTION_KEY")
Local platform:TEOSPlatform = TEOSPlatform.Create(platformOptions)
If Not platform Then RuntimeError "EOS platform creation failed."

Local p2p:TEOSP2P = platform.P2P()
If Not p2p Then RuntimeError "EOS P2P interface is unavailable."

Local relayControl:EEOSRelayControl
result = p2p.GetRelayControl(relayControl)
Print "Relay control: " + EOSResultString(result) + " (" + Int(relayControl) + ")"
If result = EEOSResult.Success Then
	result = p2p.SetRelayControl(relayControl)
	Print "Relay control round-trip: " + EOSResultString(result)
End If

Local port:Int, additionalPorts:Int
result = p2p.GetPortRange(port, additionalPorts)
Print "Port range: " + EOSResultString(result) + " (" + port + " + " + additionalPorts + ")"
If result = EEOSResult.Success Then
	result = p2p.SetPortRange(port, additionalPorts)
	Print "Port range round-trip: " + EOSResultString(result)
End If

Local queueInfo:TEOSP2PPacketQueueInfo
result = p2p.GetPacketQueueInfo(queueInfo)
Print "Packet queues: " + EOSResultString(result)
If result = EEOSResult.Success Then
	Print "  Incoming: " + queueInfo.IncomingCurrentPacketCount + " packets, " + queueInfo.IncomingCurrentSizeBytes + "/" + queueInfo.IncomingMaxSizeBytes + " bytes"
	Print "  Outgoing: " + queueInfo.OutgoingCurrentPacketCount + " packets, " + queueInfo.OutgoingCurrentSizeBytes + "/" + queueInfo.OutgoingMaxSizeBytes + " bytes"
	result = p2p.SetPacketQueueSize(queueInfo.IncomingMaxSizeBytes, queueInfo.OutgoingMaxSizeBytes)
	Print "Packet queue limits round-trip: " + EOSResultString(result)
End If

Local diagnostics:TP2PDiagnostics = New TP2PDiagnostics
diagnostics.QueueFullSubscription = p2p.AddNotifyIncomingPacketQueueFull(diagnostics)
If diagnostics.QueueFullSubscription Then
	Print "Incoming queue-full notification: registered"
Else
	Print "Incoming queue-full notification: registration failed"
End If
If Not p2p.QueryNATType(diagnostics) Then RuntimeError "Could not start the NAT query."
Local started:Int = MilliSecs()
While Not diagnostics.Done And MilliSecs() - started < 60000
	platform.Tick()
	Delay 16
Wend
If Not diagnostics.Done Then Print "NAT query timed out."

If diagnostics.QueueFullSubscription Then diagnostics.QueueFullSubscription.Remove()
platform.Release()
result = EOSShutdown()
If result <> EEOSResult.Success Then RuntimeError "EOS shutdown failed: " + EOSResultString(result)
