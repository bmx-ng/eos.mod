/* Copyright (c) 2026 Bruce A Henderson. Licensed under zlib/libpng. */

#include <brl.mod/blitz.mod/blitz.h>

#include "../SDK/Include/eos_sdk.h"
#include "../SDK/Include/eos_logging.h"
#include "../SDK/Include/eos_version.h"

#include <atomic>
#include <cstdint>
#include <deque>
#include <mutex>
#include <string>

namespace {

struct LogEntry {
	std::string category;
	std::string message;
	EOS_ELogLevel level;
};

constexpr std::size_t kMaximumQueuedLogs = 1024;
std::atomic<bool> g_loggingEnabled{false};
std::mutex g_logMutex;
std::deque<LogEntry> g_logQueue;

class UTF8String {
public:
	explicit UTF8String(BBString *value)
		: data_(value ? bbStringToUTF8String(value) : nullptr) {
	}

	~UTF8String() {
		if (data_) {
			bbMemFree(data_);
		}
	}

	const char *required() const {
		return data_ ? reinterpret_cast<const char *>(data_) : "";
	}

	const char *optional() const {
		const char *value = required();
		return value[0] ? value : nullptr;
	}

private:
	unsigned char *data_;
};

BBString *ToBBString(const char *value) {
	return bbStringFromUTF8String(reinterpret_cast<const unsigned char *>(value ? value : ""));
}

void EOS_CALL LogCallback(const EOS_LogMessage *message) {
	if (!g_loggingEnabled.load(std::memory_order_relaxed) || !message) {
		return;
	}

	LogEntry entry{
		message->Category ? message->Category : "",
		message->Message ? message->Message : "",
		message->Level
	};

	std::lock_guard<std::mutex> lock(g_logMutex);
	if (g_logQueue.size() == kMaximumQueuedLogs) {
		g_logQueue.pop_front();
	}
	g_logQueue.push_back(std::move(entry));
}

void ClearLogQueue() {
	std::lock_guard<std::mutex> lock(g_logMutex);
	g_logQueue.clear();
}

} // namespace

extern "C" {

EOS_EResult bmx_eos_initialize(BBString *productName, BBString *productVersion) {
	UTF8String nativeProductName(productName);
	UTF8String nativeProductVersion(productVersion);

	EOS_InitializeOptions options{};
	options.ApiVersion = EOS_INITIALIZE_API_LATEST;
	options.ProductName = nativeProductName.required();
	options.ProductVersion = nativeProductVersion.required();
	return EOS_Initialize(&options);
}

EOS_EResult bmx_eos_shutdown() {
	g_loggingEnabled.store(false, std::memory_order_relaxed);
	ClearLogQueue();
	return EOS_Shutdown();
}

BBString *bmx_eos_version() {
	return ToBBString(EOS_GetVersion());
}

BBString *bmx_eos_result_string(EOS_EResult result) {
	return ToBBString(EOS_EResult_ToString(result));
}

int bmx_eos_result_is_operation_complete(EOS_EResult result) {
	return EOS_EResult_IsOperationComplete(result);
}

EOS_EResult bmx_eos_logging_set_enabled(int enabled) {
	if (enabled) {
		EOS_EResult result = EOS_Logging_SetCallback(LogCallback);
		if (result == EOS_EResult::EOS_Success) {
			g_loggingEnabled.store(true, std::memory_order_relaxed);
		}
		return result;
	}

	g_loggingEnabled.store(false, std::memory_order_relaxed);
	ClearLogQueue();
	return EOS_EResult::EOS_Success;
}

EOS_EResult bmx_eos_logging_set_level(EOS_ELogCategory category, EOS_ELogLevel level) {
	return EOS_Logging_SetLogLevel(category, level);
}

int bmx_eos_logging_poll(BBString **category, BBString **message, EOS_ELogLevel *level) {
	LogEntry entry;
	{
		std::lock_guard<std::mutex> lock(g_logMutex);
		if (g_logQueue.empty()) {
			return 0;
		}
		entry = std::move(g_logQueue.front());
		g_logQueue.pop_front();
	}

	*category = ToBBString(entry.category.c_str());
	*message = ToBBString(entry.message.c_str());
	*level = entry.level;
	return 1;
}

EOS_HPlatform bmx_eos_platform_create(
	BBString *maxProductId,
	BBString *maxSandboxId,
	BBString *maxDeploymentId,
	BBString *maxClientId,
	BBString *maxClientSecret,
	BBString *maxEncryptionKey,
	BBString *maxCountryCode,
	BBString *maxLocaleCode,
	BBString *maxCacheDirectory,
	int isServer,
	int flags,
	unsigned int tickBudgetInMilliseconds,
	int useTaskNetworkTimeout,
	double taskNetworkTimeoutSeconds) {
	UTF8String productId(maxProductId);
	UTF8String sandboxId(maxSandboxId);
	UTF8String deploymentId(maxDeploymentId);
	UTF8String clientId(maxClientId);
	UTF8String clientSecret(maxClientSecret);
	UTF8String encryptionKey(maxEncryptionKey);
	UTF8String countryCode(maxCountryCode);
	UTF8String localeCode(maxLocaleCode);
	UTF8String cacheDirectory(maxCacheDirectory);

	double taskNetworkTimeout = taskNetworkTimeoutSeconds;
	EOS_Platform_Options options{};
	options.ApiVersion = EOS_PLATFORM_OPTIONS_API_LATEST;
	options.ProductId = productId.required();
	options.SandboxId = sandboxId.required();
	options.DeploymentId = deploymentId.required();
	options.ClientCredentials.ClientId = clientId.optional();
	options.ClientCredentials.ClientSecret = clientSecret.optional();
	options.bIsServer = isServer ? EOS_TRUE : EOS_FALSE;
	options.EncryptionKey = encryptionKey.optional();
	options.OverrideCountryCode = countryCode.optional();
	options.OverrideLocaleCode = localeCode.optional();
	options.Flags = static_cast<uint64_t>(flags);
	options.CacheDirectory = cacheDirectory.optional();
	options.TickBudgetInMilliseconds = tickBudgetInMilliseconds;
	options.TaskNetworkTimeoutSeconds = useTaskNetworkTimeout
		? &taskNetworkTimeout
		: nullptr;
	return EOS_Platform_Create(&options);
}

void bmx_eos_platform_tick(EOS_HPlatform handle) {
	if (handle) {
		EOS_Platform_Tick(handle);
	}
}

void bmx_eos_platform_release(EOS_HPlatform handle) {
	if (handle) {
		EOS_Platform_Release(handle);
	}
}

EOS_EpicAccountId bmx_eos_epic_account_id_from_string(BBString *value) {
	UTF8String nativeValue(value);
	return EOS_EpicAccountId_FromString(nativeValue.required());
}

int bmx_eos_epic_account_id_is_valid(EOS_EpicAccountId handle) {
	return EOS_EpicAccountId_IsValid(handle);
}

BBString *bmx_eos_epic_account_id_to_string(EOS_EpicAccountId handle) {
	char buffer[EOS_EPICACCOUNTID_MAX_LENGTH + 1]{};
	int32_t length = static_cast<int32_t>(sizeof(buffer));
	if (EOS_EpicAccountId_ToString(handle, buffer, &length) != EOS_EResult::EOS_Success) {
		return &bbEmptyString;
	}
	return ToBBString(buffer);
}

EOS_ProductUserId bmx_eos_product_user_id_from_string(BBString *value) {
	UTF8String nativeValue(value);
	return EOS_ProductUserId_FromString(nativeValue.required());
}

int bmx_eos_product_user_id_is_valid(EOS_ProductUserId handle) {
	return EOS_ProductUserId_IsValid(handle);
}

BBString *bmx_eos_product_user_id_to_string(EOS_ProductUserId handle) {
	char buffer[EOS_PRODUCTUSERID_MAX_LENGTH + 1]{};
	int32_t length = static_cast<int32_t>(sizeof(buffer));
	if (EOS_ProductUserId_ToString(handle, buffer, &length) != EOS_EResult::EOS_Success) {
		return &bbEmptyString;
	}
	return ToBBString(buffer);
}

} // extern "C"
