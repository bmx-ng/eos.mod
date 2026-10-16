' Copyright (c) 2026 Bruce A Henderson
' Licensed under the zlib/libpng license. See ../LICENSE.

SuperStrict

Import Archive.Zip
Import BRL.FileSystem
Import BRL.Stream
Import BRL.TextStream

Const EOS_SETUP_EXPECTED_VERSION:String = "1.19.2.1"

Type TSetupResult
	Field Success:Int
	Field Message:String
	Field Version:String
	Field FilesCopied:Int

	Function Ok:TSetupResult(message:String, version:String, filesCopied:Int)
		Local result:TSetupResult = New TSetupResult
		result.Success = True
		result.Message = message
		result.Version = version
		result.FilesCopied = filesCopied
		Return result
	End Function

	Function Failed:TSetupResult(message:String)
		Local result:TSetupResult = New TSetupResult
		result.Message = message
		Return result
	End Function
End Type

Function InstallEOSSDK:TSetupResult(sourcePath:String, moduleRoot:String)
	sourcePath = RealPath(sourcePath)
	moduleRoot = RealPath(moduleRoot)

	If FileType(moduleRoot + "/sdk.mod/sdk.bmx") <> FILETYPE_FILE Then
		Return TSetupResult.Failed("Destination is not an eos.mod repository: " + moduleRoot)
	End If

	Select FileType(sourcePath)
		Case FILETYPE_DIR
			Return InstallEOSSDKDirectory(sourcePath, moduleRoot)
		Case FILETYPE_FILE
			If ExtractExt(sourcePath).ToLower() <> "zip" Then
				Return TSetupResult.Failed("Drop the EOS SDK ZIP or its extracted directory.")
			End If
			Return InstallEOSSDKZip(sourcePath, moduleRoot)
	End Select

	Return TSetupResult.Failed("The dropped path does not exist: " + sourcePath)
End Function

Function InstallEOSSDKDirectory:TSetupResult(sourcePath:String, moduleRoot:String)
	Local sdkRoot:String = FindSDKRoot(sourcePath)
	If Not sdkRoot Then
		Return TSetupResult.Failed("No SDK/Include/eos_sdk.h layout was found in that directory.")
	End If

	Local validation:TSetupResult = ValidateSDKDirectory(sdkRoot)
	If Not validation.Success Then Return validation

	Local destination:String = moduleRoot + "/sdk.mod/SDK"
	If Not CreateDir(destination, True) Then
		Return TSetupResult.Failed("Could not create the module SDK directory: " + destination)
	End If
	If Not CopyDir(sdkRoot + "/Include", destination + "/Include") Then
		Return TSetupResult.Failed("Could not copy the EOS SDK headers.")
	End If
	If Not CopyDir(sdkRoot + "/Bin", destination + "/Bin") Then
		Return TSetupResult.Failed("Could not copy the EOS runtime libraries.")
	End If

	Local noticeRoot:String = ExtractDir(sdkRoot) + "/ThirdPartyNotices"
	If FileType(noticeRoot) = FILETYPE_DIR Then
		If Not CopyDir(noticeRoot, destination + "/ThirdPartyNotices") Then
			Return TSetupResult.Failed("Could not copy the EOS third-party notices.")
		End If
	End If

	Return TSetupResult.Ok("EOS SDK installed and ready to build.", validation.Version, CountFiles(destination))
End Function

Function InstallEOSSDKZip:TSetupResult(sourcePath:String, moduleRoot:String)
	Local archive:TReadArchive = New TReadArchive
	archive.SetFormat(EArchiveFormat.ZIP)
	If archive.Open(sourcePath) <> ARCHIVE_OK Then
		Local message:String = archive.ErrorString()
		archive.Free()
		Return TSetupResult.Failed("Could not open the ZIP: " + message)
	End If

	Local entry:TArchiveEntry = New TArchiveEntry
	Local prefix:String
	Local foundSDKRoot:Int
	Local versionText:String
	Local status:Int

	Repeat
		status = archive.ReadNextHeader(entry)
		If status = ARCHIVE_EOF Then Exit
		If status < ARCHIVE_OK Then
			Local message:String = archive.ErrorString()
			archive.Free()
			Return TSetupResult.Failed("Could not inspect the ZIP: " + message)
		End If

		Local path:String = NormalizedArchivePath(entry.Pathname())
		Local marker:Int = path.Find("SDK/Include/eos_version.h")
		If marker >= 0 Then
			prefix = path[..marker]
			foundSDKRoot = True
			versionText = LoadText(archive.DataStream())
		End If
	Forever
	archive.Free()

	If Not foundSDKRoot Or Not versionText Then
		Return TSetupResult.Failed("The ZIP does not contain an EOS SDK directory.")
	End If
	Local version:String = SDKVersionFromHeader(versionText)
	If version <> EOS_SETUP_EXPECTED_VERSION Then
		Return TSetupResult.Failed("Expected EOS SDK " + EOS_SETUP_EXPECTED_VERSION + " but found " + SafeVersion(version) + ".")
	End If

	' The runtime entries can precede the version header, so validate them in a
	' separate pass after the archive root prefix is known.
	Local foundWindowsX64:Int
	Local foundWindowsArm64:Int
	Local foundLinuxX64:Int
	Local foundLinuxArm64:Int
	Local foundMac:Int
	archive = New TReadArchive
	archive.SetFormat(EArchiveFormat.ZIP)
	If archive.Open(sourcePath) <> ARCHIVE_OK Then
		Local reopenMessage:String = archive.ErrorString()
		archive.Free()
		Return TSetupResult.Failed("Could not reopen the ZIP: " + reopenMessage)
	End If
	entry = New TArchiveEntry
	Repeat
		status = archive.ReadNextHeader(entry)
		If status = ARCHIVE_EOF Then Exit
		If status < ARCHIVE_OK Then
			Local inspectMessage:String = archive.ErrorString()
			archive.Free()
			Return TSetupResult.Failed("Could not inspect the ZIP: " + inspectMessage)
		End If

		Local relative:String = PathAfterSDK(NormalizedArchivePath(entry.Pathname()), prefix)
		Select relative
			Case "Bin/EOSSDK-Win64-Shipping.dll"
				foundWindowsX64 = True
			Case "Bin/EOSSDK-Win64-Shippingarm64.dll"
				foundWindowsArm64 = True
			Case "Bin/libEOSSDK-Linux-Shipping.so"
				foundLinuxX64 = True
			Case "Bin/libEOSSDK-LinuxArm64-Shipping.so"
				foundLinuxArm64 = True
			Case "Bin/libEOSSDK-Mac-Shipping.dylib"
				foundMac = True
		End Select
	Forever
	archive.Free()

	If Not foundWindowsX64 Or Not foundWindowsArm64 Or Not foundLinuxX64 Or Not foundLinuxArm64 Or Not foundMac Then
		Return TSetupResult.Failed("The ZIP is missing one or more Windows, Linux, or macOS runtime libraries.")
	End If

	Local destination:String = moduleRoot + "/sdk.mod/SDK"
	If Not CreateDir(destination, True) Then
		Return TSetupResult.Failed("Could not create the module SDK directory: " + destination)
	End If

	archive = New TReadArchive
	archive.SetFormat(EArchiveFormat.ZIP)
	If archive.Open(sourcePath) <> ARCHIVE_OK Then
		Local message:String = archive.ErrorString()
		archive.Free()
		Return TSetupResult.Failed("Could not reopen the ZIP: " + message)
	End If

	entry = New TArchiveEntry
	Local copied:Int
	Repeat
		status = archive.ReadNextHeader(entry)
		If status = ARCHIVE_EOF Then Exit
		If status < ARCHIVE_OK Then
			Local message:String = archive.ErrorString()
			archive.Free()
			Return TSetupResult.Failed("ZIP extraction failed: " + message)
		End If

		Local archivePath:String = NormalizedArchivePath(entry.Pathname())
		Local relative:String = SelectedArchivePath(archivePath, prefix)
		If Not relative Then Continue
		If Not SafeRelativePath(relative) Then
			archive.Free()
			Return TSetupResult.Failed("The ZIP contains an unsafe path: " + archivePath)
		End If

		Local outputPath:String = destination + "/" + relative
		If entry.FileType() = EArchiveFileType.Dir Then
			If Not CreateDir(outputPath, True) Then
				archive.Free()
				Return TSetupResult.Failed("Could not create: " + outputPath)
			End If
		Else If entry.FileType() = EArchiveFileType.File Then
			If Not CreateDir(ExtractDir(outputPath), True) Then
				archive.Free()
				Return TSetupResult.Failed("Could not create: " + ExtractDir(outputPath))
			End If
			Local output:TStream = WriteStream(outputPath)
			If Not output Then
				archive.Free()
				Return TSetupResult.Failed("Could not write: " + outputPath)
			End If
			CopyStream(archive.DataStream(), output)
			output.Close()
			copied :+ 1
		End If
	Forever
	archive.Free()

	Return TSetupResult.Ok("EOS SDK installed and ready to build.", version, copied)
End Function

Function FindSDKRoot:String(sourcePath:String)
	If FileType(sourcePath + "/Include/eos_sdk.h") = FILETYPE_FILE Then Return sourcePath
	If FileType(sourcePath + "/SDK/Include/eos_sdk.h") = FILETYPE_FILE Then Return sourcePath + "/SDK"

	For Local name:String = EachIn LoadDir(sourcePath)
		If name = "." Or name = ".." Then Continue
		Local candidate:String = sourcePath + "/" + name + "/SDK"
		If FileType(candidate + "/Include/eos_sdk.h") = FILETYPE_FILE Then Return candidate
	Next
	Return ""
End Function

Function ValidateSDKDirectory:TSetupResult(sdkRoot:String)
	Local versionHeader:String = sdkRoot + "/Include/eos_version.h"
	If FileType(versionHeader) <> FILETYPE_FILE Then
		Return TSetupResult.Failed("The EOS SDK version header is missing.")
	End If

	Local version:String = SDKVersionFromHeader(LoadText(versionHeader))
	If version <> EOS_SETUP_EXPECTED_VERSION Then
		Return TSetupResult.Failed("Expected EOS SDK " + EOS_SETUP_EXPECTED_VERSION + " but found " + SafeVersion(version) + ".")
	End If

	Local required:String[] = [ ..
		"Bin/EOSSDK-Win64-Shipping.dll", ..
		"Bin/EOSSDK-Win64-Shippingarm64.dll", ..
		"Bin/libEOSSDK-Linux-Shipping.so", ..
		"Bin/libEOSSDK-LinuxArm64-Shipping.so", ..
		"Bin/libEOSSDK-Mac-Shipping.dylib" ..
	]
	For Local relative:String = EachIn required
		If FileType(sdkRoot + "/" + relative) <> FILETYPE_FILE Then
			Return TSetupResult.Failed("The SDK is missing " + relative + ".")
		End If
	Next

	Return TSetupResult.Ok("EOS SDK layout is valid.", version, 0)
End Function

Function SDKVersionFromHeader:String(text:String)
	Local major:Int = HeaderDefineValue(text, "EOS_MAJOR_VERSION")
	Local minor:Int = HeaderDefineValue(text, "EOS_MINOR_VERSION")
	Local patch:Int = HeaderDefineValue(text, "EOS_PATCH_VERSION")
	Local hotfix:Int = HeaderDefineValue(text, "EOS_HOTFIX_VERSION")
	If major < 0 Or minor < 0 Or patch < 0 Or hotfix < 0 Then Return ""
	Return major + "." + minor + "." + patch + "." + hotfix
End Function

Function HeaderDefineValue:Int(text:String, name:String)
	For Local line:String = EachIn text.Replace(Chr(13), "").Split("~n")
		line = line.Trim()
		If Not line.StartsWith("#define") Or line.Find(name) < 0 Then Continue
		Local value:String = line[name.Length + line.Find(name)..].Trim()
		Local separator:Int = value.Find(" ")
		If separator >= 0 Then value = value[..separator]
		Return Int(value)
	Next
	Return -1
End Function

Function NormalizedArchivePath:String(path:String)
	Return path.Replace("\", "/")
End Function

Function PathAfterSDK:String(path:String, prefix:String)
	Local root:String = prefix + "SDK/"
	If Not path.StartsWith(root) Then Return ""
	Return path[root.Length..]
End Function

Function SelectedArchivePath:String(path:String, prefix:String)
	Local relative:String = PathAfterSDK(path, prefix)
	If relative.StartsWith("Include/") Or relative.StartsWith("Bin/") Then Return relative

	Local noticesRoot:String = prefix + "ThirdPartyNotices/"
	If path.StartsWith(noticesRoot) Then Return "ThirdPartyNotices/" + path[noticesRoot.Length..]
	Return ""
End Function

Function SafeRelativePath:Int(path:String)
	If Not path Or path.StartsWith("/") Or path.Find(":") >= 0 Then Return False
	For Local part:String = EachIn path.Split("/")
		If part = ".." Then Return False
	Next
	Return True
End Function

Function SafeVersion:String(version:String)
	If version Then Return version
	Return "an unreadable version"
End Function

Function CountFiles:Int(path:String)
	If FileType(path) = FILETYPE_FILE Then Return 1
	If FileType(path) <> FILETYPE_DIR Then Return 0
	Local count:Int
	For Local name:String = EachIn LoadDir(path)
		If name = "." Or name = ".." Then Continue
		count :+ CountFiles(path + "/" + name)
	Next
	Return count
End Function
