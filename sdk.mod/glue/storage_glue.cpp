/* Copyright (c) 2026 Bruce A Henderson. Licensed under zlib/libpng. */

#include "../SDK/Include/eos_playerdatastorage.h"
#include "../SDK/Include/eos_sdk.h"
#include "../SDK/Include/eos_titlestorage.h"
#include <brl.mod/blitz.mod/blitz.h>

#include <algorithm>
#include <string>
#include <vector>

extern "C" {
void eos_sdk_TEOSStorageRequest__CompleteQuery(BBObject *, EOS_EResult, EOS_ProductUserId, unsigned int);
void eos_sdk_TEOSStorageRequest__CompleteOperation(BBObject *, EOS_EResult, EOS_ProductUserId, BBString *);
void eos_sdk_TEOSStorageRequest__Cancel(BBObject *);
void eos_sdk_TEOSStorageTransferRequest__Progress(BBObject *, unsigned int, unsigned int);
int eos_sdk_TEOSStorageTransferRequest__WriteChunk(BBObject *, void *, int);
int eos_sdk_TEOSStorageTransferRequest__ReadChunk(BBObject *, void *, int);
void eos_sdk_TEOSStorageTransferRequest__Complete(BBObject *, EOS_EResult, EOS_ProductUserId, BBString *);
void eos_sdk_TEOSStorageTransferRequest__Cancel(BBObject *);
}

namespace {

class UTF8String {
  public:
	explicit UTF8String(BBString *value) : data_(value ? bbStringToUTF8String(value) : nullptr) {
	}
	~UTF8String() {
		if (data_)
			bbMemFree(data_);
	}
	const char *required() const {
		return data_ ? reinterpret_cast<const char *>(data_) : "";
	}
	const char *optional() const {
		return required()[0] ? required() : nullptr;
	}

  private:
	unsigned char *data_;
};

class UTF8StringArray {
  public:
	explicit UTF8StringArray(BBArray *array) {
		if (!array || array == &bbEmptyArray || array->dims != 1)
			return;
		BBString **strings = static_cast<BBString **>(BBARRAYDATA(array, array->dims));
		for (int index = 0; index < array->scales[0]; ++index) {
			auto *value = bbStringToUTF8String(strings[index]);
			owned_.push_back(value);
			values_.push_back(reinterpret_cast<const char *>(value));
		}
	}
	~UTF8StringArray() {
		for (auto *value : owned_)
			bbMemFree(value);
	}
	const char *const *data() const {
		return values_.empty() ? nullptr : values_.data();
	}
	uint32_t size() const {
		return static_cast<uint32_t>(values_.size());
	}

  private:
	std::vector<unsigned char *> owned_;
	std::vector<const char *> values_;
};

BBString *ToBBString(const char *value) {
	return bbStringFromUTF8String(reinterpret_cast<const unsigned char *>(value ? value : ""));
}

enum class SimpleKind { Query, Operation };

struct SimpleContext {
	EOS_HPlatform platform;
	BBObject *request;
	SimpleKind kind;
	std::string filename;
	SimpleContext(EOS_HPlatform p, BBObject *r, SimpleKind k, const char *name = nullptr)
		: platform(p), request(r), kind(k), filename(name ? name : "") {
		BBRETAIN(request);
	}
	~SimpleContext() {
		BBRELEASE(request);
	}
};

enum class TransferKind { TitleRead, PlayerRead, PlayerWrite };

struct TransferContext {
	EOS_HPlatform platform;
	BBObject *request;
	TransferKind kind;
	void *handle = nullptr;
	TransferContext(EOS_HPlatform p, BBObject *r, TransferKind k) : platform(p), request(r), kind(k) {
		BBRETAIN(request);
	}
	~TransferContext() {
		BBRELEASE(request);
	}
};

std::vector<SimpleContext *> g_simple;
std::vector<TransferContext *> g_transfers;

void Remove(SimpleContext *context) {
	auto found = std::find(g_simple.begin(), g_simple.end(), context);
	if (found != g_simple.end())
		g_simple.erase(found);
}

void ReleaseTransferHandle(TransferContext *context) {
	if (!context || !context->handle)
		return;
	if (context->kind == TransferKind::TitleRead)
		EOS_TitleStorageFileTransferRequest_Release(static_cast<EOS_HTitleStorageFileTransferRequest>(context->handle));
	else
		EOS_PlayerDataStorageFileTransferRequest_Release(
			static_cast<EOS_HPlayerDataStorageFileTransferRequest>(context->handle));
	context->handle = nullptr;
}

void Remove(TransferContext *context) {
	auto found = std::find(g_transfers.begin(), g_transfers.end(), context);
	if (found != g_transfers.end())
		g_transfers.erase(found);
}

void CompleteSimple(SimpleContext *context, EOS_EResult result, EOS_ProductUserId user, uint32_t count = 0) {
	Remove(context);
	if (context->kind == SimpleKind::Query)
		eos_sdk_TEOSStorageRequest__CompleteQuery(context->request, result, user, count);
	else
		eos_sdk_TEOSStorageRequest__CompleteOperation(context->request, result, user,
													  ToBBString(context->filename.c_str()));
	delete context;
}

void CompleteTransfer(TransferContext *context, EOS_EResult result, EOS_ProductUserId user, const char *filename) {
	Remove(context);
	ReleaseTransferHandle(context);
	eos_sdk_TEOSStorageTransferRequest__Complete(context->request, result, user, ToBBString(filename));
	delete context;
}

void EOS_CALL TitleQueryFileComplete(const EOS_TitleStorage_QueryFileCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteSimple(static_cast<SimpleContext *>(info->ClientData), info->ResultCode, info->LocalUserId,
					   info->ResultCode == EOS_EResult::EOS_Success ? 1 : 0);
}
void EOS_CALL TitleQueryListComplete(const EOS_TitleStorage_QueryFileListCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteSimple(static_cast<SimpleContext *>(info->ClientData), info->ResultCode, info->LocalUserId,
					   info->FileCount);
}
void EOS_CALL TitleDeleteCacheComplete(const EOS_TitleStorage_DeleteCacheCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteSimple(static_cast<SimpleContext *>(info->ClientData), info->ResultCode, info->LocalUserId);
}
void EOS_CALL PlayerQueryFileComplete(const EOS_PlayerDataStorage_QueryFileCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteSimple(static_cast<SimpleContext *>(info->ClientData), info->ResultCode, info->LocalUserId,
					   info->ResultCode == EOS_EResult::EOS_Success ? 1 : 0);
}
void EOS_CALL PlayerQueryListComplete(const EOS_PlayerDataStorage_QueryFileListCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteSimple(static_cast<SimpleContext *>(info->ClientData), info->ResultCode, info->LocalUserId,
					   info->FileCount);
}
void EOS_CALL PlayerDuplicateComplete(const EOS_PlayerDataStorage_DuplicateFileCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteSimple(static_cast<SimpleContext *>(info->ClientData), info->ResultCode, info->LocalUserId);
}
void EOS_CALL PlayerDeleteComplete(const EOS_PlayerDataStorage_DeleteFileCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteSimple(static_cast<SimpleContext *>(info->ClientData), info->ResultCode, info->LocalUserId);
}
void EOS_CALL PlayerDeleteCacheComplete(const EOS_PlayerDataStorage_DeleteCacheCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteSimple(static_cast<SimpleContext *>(info->ClientData), info->ResultCode, info->LocalUserId);
}

EOS_TitleStorage_EReadResult EOS_CALL TitleReadData(const EOS_TitleStorage_ReadFileDataCallbackInfo *info) {
	if (!info || !info->ClientData)
		return EOS_TitleStorage_EReadResult::EOS_TS_RR_FailRequest;
	auto *context = static_cast<TransferContext *>(info->ClientData);
	return eos_sdk_TEOSStorageTransferRequest__WriteChunk(context->request, const_cast<void *>(info->DataChunk),
														  static_cast<int>(info->DataChunkLengthBytes))
			   ? EOS_TitleStorage_EReadResult::EOS_TS_RR_ContinueReading
			   : EOS_TitleStorage_EReadResult::EOS_TS_RR_FailRequest;
}
void EOS_CALL TitleProgress(const EOS_TitleStorage_FileTransferProgressCallbackInfo *info) {
	if (info && info->ClientData)
		eos_sdk_TEOSStorageTransferRequest__Progress(static_cast<TransferContext *>(info->ClientData)->request,
													 info->BytesTransferred, info->TotalFileSizeBytes);
}
void EOS_CALL TitleReadComplete(const EOS_TitleStorage_ReadFileCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteTransfer(static_cast<TransferContext *>(info->ClientData), info->ResultCode, info->LocalUserId,
						 info->Filename);
}

EOS_PlayerDataStorage_EReadResult EOS_CALL PlayerReadData(const EOS_PlayerDataStorage_ReadFileDataCallbackInfo *info) {
	if (!info || !info->ClientData)
		return EOS_PlayerDataStorage_EReadResult::EOS_RR_FailRequest;
	auto *context = static_cast<TransferContext *>(info->ClientData);
	return eos_sdk_TEOSStorageTransferRequest__WriteChunk(context->request, const_cast<void *>(info->DataChunk),
														  static_cast<int>(info->DataChunkLengthBytes))
			   ? EOS_PlayerDataStorage_EReadResult::EOS_RR_ContinueReading
			   : EOS_PlayerDataStorage_EReadResult::EOS_RR_FailRequest;
}
EOS_PlayerDataStorage_EWriteResult EOS_CALL PlayerWriteData(const EOS_PlayerDataStorage_WriteFileDataCallbackInfo *info,
															void *buffer, uint32_t *written) {
	if (!info || !info->ClientData || !buffer || !written)
		return EOS_PlayerDataStorage_EWriteResult::EOS_WR_FailRequest;
	auto *context = static_cast<TransferContext *>(info->ClientData);
	const int result = eos_sdk_TEOSStorageTransferRequest__ReadChunk(context->request, buffer,
																	 static_cast<int>(info->DataBufferLengthBytes));
	if (result < 0) {
		*written = static_cast<uint32_t>(-result - 1);
		return EOS_PlayerDataStorage_EWriteResult::EOS_WR_CompleteRequest;
	}
	*written = static_cast<uint32_t>(result);
	return EOS_PlayerDataStorage_EWriteResult::EOS_WR_ContinueWriting;
}
void EOS_CALL PlayerProgress(const EOS_PlayerDataStorage_FileTransferProgressCallbackInfo *info) {
	if (info && info->ClientData)
		eos_sdk_TEOSStorageTransferRequest__Progress(static_cast<TransferContext *>(info->ClientData)->request,
													 info->BytesTransferred, info->TotalFileSizeBytes);
}
void EOS_CALL PlayerReadComplete(const EOS_PlayerDataStorage_ReadFileCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteTransfer(static_cast<TransferContext *>(info->ClientData), info->ResultCode, info->LocalUserId,
						 info->Filename);
}
void EOS_CALL PlayerWriteComplete(const EOS_PlayerDataStorage_WriteFileCallbackInfo *info) {
	if (info && info->ClientData)
		CompleteTransfer(static_cast<TransferContext *>(info->ClientData), info->ResultCode, info->LocalUserId,
						 info->Filename);
}

} // namespace

extern "C" {

EOS_HTitleStorage bmx_eos_platform_get_title_storage_interface(EOS_HPlatform platform) {
	return platform ? EOS_Platform_GetTitleStorageInterface(platform) : nullptr;
}
EOS_HPlayerDataStorage bmx_eos_platform_get_player_storage_interface(EOS_HPlatform platform) {
	return platform ? EOS_Platform_GetPlayerDataStorageInterface(platform) : nullptr;
}

void bmx_eos_title_storage_query_file(EOS_HPlatform platform, EOS_HTitleStorage storage, BBObject *request,
									  EOS_ProductUserId user, BBString *maxFilename) {
	UTF8String filename(maxFilename);
	EOS_TitleStorage_QueryFileOptions options{};
	options.ApiVersion = EOS_TITLESTORAGE_QUERYFILE_API_LATEST;
	options.LocalUserId = user;
	options.Filename = filename.required();
	auto *context = new SimpleContext(platform, request, SimpleKind::Query);
	g_simple.push_back(context);
	EOS_TitleStorage_QueryFile(storage, &options, context, TitleQueryFileComplete);
}
void bmx_eos_title_storage_query_list(EOS_HPlatform platform, EOS_HTitleStorage storage, BBObject *request,
									  EOS_ProductUserId user, BBArray *maxTags) {
	UTF8StringArray tags(maxTags);
	EOS_TitleStorage_QueryFileListOptions options{};
	options.ApiVersion = EOS_TITLESTORAGE_QUERYFILELIST_API_LATEST;
	options.LocalUserId = user;
	options.ListOfTags = tags.data();
	options.ListOfTagsCount = tags.size();
	auto *context = new SimpleContext(platform, request, SimpleKind::Query);
	g_simple.push_back(context);
	EOS_TitleStorage_QueryFileList(storage, &options, context, TitleQueryListComplete);
}
uint32_t bmx_eos_title_storage_metadata_count(EOS_HTitleStorage storage, EOS_ProductUserId user) {
	EOS_TitleStorage_GetFileMetadataCountOptions options{};
	options.ApiVersion = EOS_TITLESTORAGE_GETFILEMETADATACOUNT_API_LATEST;
	options.LocalUserId = user;
	return EOS_TitleStorage_GetFileMetadataCount(storage, &options);
}
EOS_EResult bmx_eos_title_storage_copy_metadata_index(EOS_HTitleStorage storage, EOS_ProductUserId user, uint32_t index,
													  uint32_t *size, BBString **md5, BBString **filename,
													  uint32_t *unencrypted) {
	EOS_TitleStorage_CopyFileMetadataAtIndexOptions options{};
	options.ApiVersion = EOS_TITLESTORAGE_COPYFILEMETADATAATINDEX_API_LATEST;
	options.LocalUserId = user;
	options.Index = index;
	EOS_TitleStorage_FileMetadata *value = nullptr;
	EOS_EResult result = EOS_TitleStorage_CopyFileMetadataAtIndex(storage, &options, &value);
	if (result != EOS_EResult::EOS_Success || !value)
		return result;
	*size = value->FileSizeBytes;
	*md5 = ToBBString(value->MD5Hash);
	*filename = ToBBString(value->Filename);
	*unencrypted = value->UnencryptedDataSizeBytes;
	EOS_TitleStorage_FileMetadata_Release(value);
	return result;
}
EOS_EResult bmx_eos_title_storage_copy_metadata_name(EOS_HTitleStorage storage, EOS_ProductUserId user,
													 BBString *maxRequested, uint32_t *size, BBString **md5,
													 BBString **filename, uint32_t *unencrypted) {
	UTF8String requested(maxRequested);
	EOS_TitleStorage_CopyFileMetadataByFilenameOptions options{};
	options.ApiVersion = EOS_TITLESTORAGE_COPYFILEMETADATABYFILENAME_API_LATEST;
	options.LocalUserId = user;
	options.Filename = requested.required();
	EOS_TitleStorage_FileMetadata *value = nullptr;
	EOS_EResult result = EOS_TitleStorage_CopyFileMetadataByFilename(storage, &options, &value);
	if (result != EOS_EResult::EOS_Success || !value)
		return result;
	*size = value->FileSizeBytes;
	*md5 = ToBBString(value->MD5Hash);
	*filename = ToBBString(value->Filename);
	*unencrypted = value->UnencryptedDataSizeBytes;
	EOS_TitleStorage_FileMetadata_Release(value);
	return result;
}
void *bmx_eos_title_storage_read(EOS_HPlatform platform, EOS_HTitleStorage storage, BBObject *request,
								 EOS_ProductUserId user, BBString *maxFilename, uint32_t chunkLength) {
	UTF8String filename(maxFilename);
	EOS_TitleStorage_ReadFileOptions options{};
	options.ApiVersion = EOS_TITLESTORAGE_READFILE_API_LATEST;
	options.LocalUserId = user;
	options.Filename = filename.required();
	options.ReadChunkLengthBytes = chunkLength;
	options.ReadFileDataCallback = TitleReadData;
	options.FileTransferProgressCallback = TitleProgress;
	auto *context = new TransferContext(platform, request, TransferKind::TitleRead);
	g_transfers.push_back(context);
	context->handle = EOS_TitleStorage_ReadFile(storage, &options, context, TitleReadComplete);
	if (!context->handle) {
		Remove(context);
		delete context;
		return nullptr;
	}
	return context;
}
EOS_EResult bmx_eos_title_storage_delete_cache(EOS_HPlatform platform, EOS_HTitleStorage storage, BBObject *request,
											   EOS_ProductUserId user) {
	EOS_TitleStorage_DeleteCacheOptions options{};
	options.ApiVersion = EOS_TITLESTORAGE_DELETECACHE_API_LATEST;
	options.LocalUserId = user;
	auto *context = new SimpleContext(platform, request, SimpleKind::Operation);
	EOS_EResult result = EOS_TitleStorage_DeleteCache(storage, &options, context, TitleDeleteCacheComplete);
	if (result == EOS_EResult::EOS_Success)
		g_simple.push_back(context);
	else
		delete context;
	return result;
}

void bmx_eos_player_storage_query_file(EOS_HPlatform platform, EOS_HPlayerDataStorage storage, BBObject *request,
									   EOS_ProductUserId user, BBString *maxFilename) {
	UTF8String filename(maxFilename);
	EOS_PlayerDataStorage_QueryFileOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_QUERYFILE_API_LATEST;
	options.LocalUserId = user;
	options.Filename = filename.required();
	auto *context = new SimpleContext(platform, request, SimpleKind::Query);
	g_simple.push_back(context);
	EOS_PlayerDataStorage_QueryFile(storage, &options, context, PlayerQueryFileComplete);
}
void bmx_eos_player_storage_query_list(EOS_HPlatform platform, EOS_HPlayerDataStorage storage, BBObject *request,
									   EOS_ProductUserId user) {
	EOS_PlayerDataStorage_QueryFileListOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_QUERYFILELIST_API_LATEST;
	options.LocalUserId = user;
	auto *context = new SimpleContext(platform, request, SimpleKind::Query);
	g_simple.push_back(context);
	EOS_PlayerDataStorage_QueryFileList(storage, &options, context, PlayerQueryListComplete);
}
int bmx_eos_player_storage_metadata_count(EOS_HPlayerDataStorage storage, EOS_ProductUserId user) {
	EOS_PlayerDataStorage_GetFileMetadataCountOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_GETFILEMETADATACOUNT_API_LATEST;
	options.LocalUserId = user;
	int32_t count = 0;
	return EOS_PlayerDataStorage_GetFileMetadataCount(storage, &options, &count) == EOS_EResult::EOS_Success ? count
																											 : 0;
}
EOS_EResult bmx_eos_player_storage_copy_metadata_index(EOS_HPlayerDataStorage storage, EOS_ProductUserId user,
													   int index, uint32_t *size, BBString **md5, BBString **filename,
													   int64_t *modified, uint32_t *unencrypted) {
	EOS_PlayerDataStorage_CopyFileMetadataAtIndexOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_COPYFILEMETADATAATINDEX_API_LATEST;
	options.LocalUserId = user;
	options.Index = static_cast<uint32_t>(index);
	EOS_PlayerDataStorage_FileMetadata *value = nullptr;
	EOS_EResult result = EOS_PlayerDataStorage_CopyFileMetadataAtIndex(storage, &options, &value);
	if (result != EOS_EResult::EOS_Success || !value)
		return result;
	*size = value->FileSizeBytes;
	*md5 = ToBBString(value->MD5Hash);
	*filename = ToBBString(value->Filename);
	*modified = value->LastModifiedTime;
	*unencrypted = value->UnencryptedDataSizeBytes;
	EOS_PlayerDataStorage_FileMetadata_Release(value);
	return result;
}
EOS_EResult bmx_eos_player_storage_copy_metadata_name(EOS_HPlayerDataStorage storage, EOS_ProductUserId user,
													  BBString *maxRequested, uint32_t *size, BBString **md5,
													  BBString **filename, int64_t *modified, uint32_t *unencrypted) {
	UTF8String requested(maxRequested);
	EOS_PlayerDataStorage_CopyFileMetadataByFilenameOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_COPYFILEMETADATABYFILENAME_API_LATEST;
	options.LocalUserId = user;
	options.Filename = requested.required();
	EOS_PlayerDataStorage_FileMetadata *value = nullptr;
	EOS_EResult result = EOS_PlayerDataStorage_CopyFileMetadataByFilename(storage, &options, &value);
	if (result != EOS_EResult::EOS_Success || !value)
		return result;
	*size = value->FileSizeBytes;
	*md5 = ToBBString(value->MD5Hash);
	*filename = ToBBString(value->Filename);
	*modified = value->LastModifiedTime;
	*unencrypted = value->UnencryptedDataSizeBytes;
	EOS_PlayerDataStorage_FileMetadata_Release(value);
	return result;
}
void *bmx_eos_player_storage_read(EOS_HPlatform platform, EOS_HPlayerDataStorage storage, BBObject *request,
								  EOS_ProductUserId user, BBString *maxFilename, uint32_t chunkLength) {
	UTF8String filename(maxFilename);
	EOS_PlayerDataStorage_ReadFileOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_READFILE_API_LATEST;
	options.LocalUserId = user;
	options.Filename = filename.required();
	options.ReadChunkLengthBytes = chunkLength;
	options.ReadFileDataCallback = PlayerReadData;
	options.FileTransferProgressCallback = PlayerProgress;
	auto *context = new TransferContext(platform, request, TransferKind::PlayerRead);
	g_transfers.push_back(context);
	context->handle = EOS_PlayerDataStorage_ReadFile(storage, &options, context, PlayerReadComplete);
	if (!context->handle) {
		Remove(context);
		delete context;
		return nullptr;
	}
	return context;
}
void *bmx_eos_player_storage_write(EOS_HPlatform platform, EOS_HPlayerDataStorage storage, BBObject *request,
								   EOS_ProductUserId user, BBString *maxFilename, uint32_t chunkLength) {
	UTF8String filename(maxFilename);
	auto *context = new TransferContext(platform, request, TransferKind::PlayerWrite);
	EOS_PlayerDataStorage_WriteFileOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_WRITEFILE_API_LATEST;
	options.LocalUserId = user;
	options.Filename = filename.required();
	options.ChunkLengthBytes = chunkLength;
	options.WriteFileDataCallback = PlayerWriteData;
	options.FileTransferProgressCallback = PlayerProgress;
	g_transfers.push_back(context);
	context->handle = EOS_PlayerDataStorage_WriteFile(storage, &options, context, PlayerWriteComplete);
	if (!context->handle) {
		Remove(context);
		delete context;
		return nullptr;
	}
	return context;
}
void bmx_eos_player_storage_duplicate(EOS_HPlatform platform, EOS_HPlayerDataStorage storage, BBObject *request,
									  EOS_ProductUserId user, BBString *maxSource, BBString *maxDestination) {
	UTF8String source(maxSource), destination(maxDestination);
	EOS_PlayerDataStorage_DuplicateFileOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_DUPLICATEFILE_API_LATEST;
	options.LocalUserId = user;
	options.SourceFilename = source.required();
	options.DestinationFilename = destination.required();
	auto *context = new SimpleContext(platform, request, SimpleKind::Operation, destination.required());
	g_simple.push_back(context);
	EOS_PlayerDataStorage_DuplicateFile(storage, &options, context, PlayerDuplicateComplete);
}
void bmx_eos_player_storage_delete(EOS_HPlatform platform, EOS_HPlayerDataStorage storage, BBObject *request,
								   EOS_ProductUserId user, BBString *maxFilename) {
	UTF8String filename(maxFilename);
	EOS_PlayerDataStorage_DeleteFileOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_DELETEFILE_API_LATEST;
	options.LocalUserId = user;
	options.Filename = filename.required();
	auto *context = new SimpleContext(platform, request, SimpleKind::Operation, filename.required());
	g_simple.push_back(context);
	EOS_PlayerDataStorage_DeleteFile(storage, &options, context, PlayerDeleteComplete);
}
EOS_EResult bmx_eos_player_storage_delete_cache(EOS_HPlatform platform, EOS_HPlayerDataStorage storage,
												BBObject *request, EOS_ProductUserId user) {
	EOS_PlayerDataStorage_DeleteCacheOptions options{};
	options.ApiVersion = EOS_PLAYERDATASTORAGE_DELETECACHE_API_LATEST;
	options.LocalUserId = user;
	auto *context = new SimpleContext(platform, request, SimpleKind::Operation);
	EOS_EResult result = EOS_PlayerDataStorage_DeleteCache(storage, &options, context, PlayerDeleteCacheComplete);
	if (result == EOS_EResult::EOS_Success)
		g_simple.push_back(context);
	else
		delete context;
	return result;
}
EOS_EResult bmx_eos_storage_transfer_cancel(void *pointer) {
	auto *context = static_cast<TransferContext *>(pointer);
	if (!context || !context->handle)
		return EOS_EResult::EOS_InvalidState;
	if (context->kind == TransferKind::TitleRead)
		return EOS_TitleStorageFileTransferRequest_CancelRequest(
			static_cast<EOS_HTitleStorageFileTransferRequest>(context->handle));
	return EOS_PlayerDataStorageFileTransferRequest_CancelRequest(
		static_cast<EOS_HPlayerDataStorageFileTransferRequest>(context->handle));
}
void bmx_eos_storage_cancel_platform_requests(EOS_HPlatform platform) {
	for (std::size_t i = 0; i < g_simple.size();) {
		auto *context = g_simple[i];
		if (context->platform != platform) {
			++i;
			continue;
		}
		g_simple.erase(g_simple.begin() + static_cast<std::ptrdiff_t>(i));
		eos_sdk_TEOSStorageRequest__Cancel(context->request);
		delete context;
	}
	for (std::size_t i = 0; i < g_transfers.size();) {
		auto *context = g_transfers[i];
		if (context->platform != platform) {
			++i;
			continue;
		}
		g_transfers.erase(g_transfers.begin() + static_cast<std::ptrdiff_t>(i));
		ReleaseTransferHandle(context);
		eos_sdk_TEOSStorageTransferRequest__Cancel(context->request);
		delete context;
	}
}

} // extern "C"
