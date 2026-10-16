' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

SuperStrict

Framework Max2D.SDL3RenderMax2D
Import Archive.Zip
Import BRL.Event
Import BRL.FileSystem
Import BRL.Hook
Import BRL.PolledInput
Import BRL.StandardIO
Import BRL.TextStream
Import "eos_sdk_setup_core.bmx"

Const WINDOW_WIDTH:Int = 760
Const WINDOW_HEIGHT:Int = 420

Global pendingDrop:String
Global moduleRoot:String
Global statusTitle:String = "Drop the Epic Online Services SDK here"
Global statusDetail:String = "Accepts the downloaded ZIP or its extracted directory."
Global statusKind:Int
Global headless:Int

Function OpenFileHook:Object(id:Int, data:Object, context:Object)
	Local event:TEvent = TEvent(data)
	If event And event.id = EVENT_APPOPENFILE Then
		pendingDrop = String(event.extra)
	End If
	Return data
End Function

Function FindDefaultModuleRoot:String()
	Local candidate:String = RealPath(AppDir)
	For Local level:Int = 0 Until 7
		If FileType(candidate + "/sdk.mod/sdk.bmx") = FILETYPE_FILE Then Return candidate
		Local parent:String = ExtractDir(candidate)
		If parent = candidate Then Exit
		candidate = parent
	Next

	candidate = RealPath(CurrentDir())
	For Local level:Int = 0 Until 4
		If FileType(candidate + "/sdk.mod/sdk.bmx") = FILETYPE_FILE Then Return candidate
		Local parent:String = ExtractDir(candidate)
		If parent = candidate Then Exit
		candidate = parent
	Next
	Return ""
End Function

Function ProcessSource:Int(path:String)
	statusKind = 1
	statusTitle = "Installing EOS SDK..."
	statusDetail = path
	If Not headless Then DrawScreen()

	Local result:TSetupResult = InstallEOSSDK(path, moduleRoot)
	If result.Success Then
		statusKind = 2
		statusTitle = "EOS SDK " + result.Version + " is ready"
		statusDetail = result.FilesCopied + " files installed into sdk.mod/SDK."
		Print result.Message + " Version " + result.Version + "."
		Return True
	End If

	statusKind = 3
	statusTitle = "Setup could not complete"
	statusDetail = result.Message
	Print "EOS SDK setup failed: " + result.Message
	Return False
End Function

Function DrawScreen()
	Cls

	SetColor 22, 27, 38
	DrawRect 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT

	Select statusKind
		Case 1
			SetColor 245, 181, 66
		Case 2
			SetColor 75, 201, 126
		Case 3
			SetColor 235, 91, 91
		Default
			SetColor 75, 155, 235
	End Select
	DrawRect 0, 0, WINDOW_WIDTH, 9

	SetColor 245, 247, 250
	SetScale 1.5, 1.5
	DrawText statusTitle, 44, 70
	SetScale 1.0, 1.0

	SetColor 178, 187, 205
	DrawText statusDetail, 46, 130

	SetColor 49, 58, 76
	DrawRect 46, 185, WINDOW_WIDTH - 92, 118
	SetColor 212, 220, 234
	DrawText "Drop one of these onto this window:", 70, 211
	DrawText "- EOS-SDK-...zip downloaded from Epic", 70, 240
	DrawText "- the extracted EOS-SDK directory", 70, 267

	SetColor 130, 141, 160
	DrawText "Only headers, desktop runtime libraries, and legal notices are copied.", 46, 342
	DrawText "Press Escape to close.", 46, 370
	Flip
End Function

moduleRoot = FindDefaultModuleRoot()
Local initialSource:String

For Local index:Int = 1 Until AppArgs.Length
	Select AppArgs[index]
		Case "--headless"
			headless = True
		Case "--module-root"
			If index + 1 >= AppArgs.Length Then
				RuntimeError "--module-root requires the eos.mod directory."
			End If
			index :+ 1
			moduleRoot = AppArgs[index]
		Case "--help", "-h"
			Print "Usage: eos-sdk-setup [--headless] [--module-root /path/to/eos.mod] [SDK.zip|directory]"
			End
		Default
			If Not initialSource Then initialSource = AppArgs[index]
	End Select
Next

If Not moduleRoot Then
	Print "Could not locate eos.mod. Use --module-root /path/to/eos.mod."
	If headless Then RuntimeError "eos.mod could not be located."
	statusKind = 3
	statusTitle = "eos.mod could not be located"
	statusDetail = "Build this tool in eos.mod/tools or pass --module-root."
End If

If headless Then
	If Not initialSource Then
		RuntimeError "No EOS SDK ZIP or directory was provided."
	End If
	If ProcessSource(initialSource) Then End
	RuntimeError "EOS SDK setup failed."
End If

AddHook EmitEventHook, OpenFileHook
Graphics WINDOW_WIDTH, WINDOW_HEIGHT, 0, 60, GRAPHICS_BACKBUFFER
SetClsColor 22, 27, 38

If initialSource And moduleRoot Then pendingDrop = initialSource

While Not KeyHit(KEY_ESCAPE) And Not AppTerminate()
	If pendingDrop Then
		Local source:String = pendingDrop
		pendingDrop = ""
		ProcessSource(source)
	End If
	DrawScreen()
Wend

RemoveHook EmitEventHook, OpenFileHook
EndGraphics
