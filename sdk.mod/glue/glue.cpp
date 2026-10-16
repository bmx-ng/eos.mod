/* Copyright (c) 2026 Bruce A Henderson. Licensed under zlib/libpng. */

#include <brl.mod/blitz.mod/blitz.h>

#include "../SDK/Include/eos_sdk.h"
#include "../SDK/Include/eos_auth.h"
#include "../SDK/Include/eos_connect.h"
#include "../SDK/Include/eos_logging.h"
#include "../SDK/Include/eos_version.h"

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <deque>
#include <mutex>
#include <string>
#include <vector>

extern "C" {
void eos_sdk_TEOSAuthLoginRequest__Complete(BBObject *, EOS_EResult, EOS_EpicAccountId,
	BBString *, BBString *, int, BBString *, EOS_ContinuanceToken, EOS_EpicAccountId);
void eos_sdk_TEOSAuthLoginRequest__Cancel(BBObject *);
void eos_sdk_TEOSAuthLogoutRequest__Complete(BBObject *, EOS_EResult, EOS_EpicAccountId);
void eos_sdk_TEOSAuthLogoutRequest__Cancel(BBObject *);
void eos_sdk_TEOSConnectLoginRequest__Complete(BBObject *, EOS_EResult, EOS_ProductUserId, EOS_ContinuanceToken);
void eos_sdk_TEOSConnectLoginRequest__Cancel(BBObject *);
void eos_sdk_TEOSConnectCreateUserRequest__Complete(BBObject *, EOS_EResult, EOS_ProductUserId);
void eos_sdk_TEOSConnectCreateUserRequest__Cancel(BBObject *);
void eos_sdk_TEOSConnectLogoutRequest__Complete(BBObject *, EOS_EResult, EOS_ProductUserId);
void eos_sdk_TEOSConnectLogoutRequest__Cancel(BBObject *);
}

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

enum class RequestKind {
	AuthLogin,
	AuthLogout,
	ConnectLogin,
	ConnectCreateUser,
	ConnectLogout
};

struct RequestContext {
	EOS_HPlatform platform;
	BBObject *request;
	RequestKind kind;

	RequestContext(EOS_HPlatform platform, BBObject *request, RequestKind kind)
		: platform(platform), request(request), kind(kind) {
		BBRETAIN(request);
	}

	~RequestContext() {
		BBRELEASE(request);
	}
};

std::vector<RequestContext *> g_requests;

RequestContext *CreateRequest(EOS_HPlatform platform, BBObject *request, RequestKind kind) {
	auto *context = new RequestContext(platform, request, kind);
	g_requests.push_back(context);
	return context;
}

void CompleteRequest(RequestContext *context) {
	auto found = std::find(g_requests.begin(), g_requests.end(), context);
	if (found != g_requests.end()) {
		g_requests.erase(found);
	}
}

void CancelPlatformRequests(EOS_HPlatform platform) {
	for (std::size_t index = 0; index < g_requests.size();) {
		RequestContext *context = g_requests[index];
		if (context->platform != platform) {
			++index;
			continue;
		}

		g_requests.erase(g_requests.begin() + static_cast<std::ptrdiff_t>(index));
		switch (context->kind) {
		case RequestKind::AuthLogin:
			eos_sdk_TEOSAuthLoginRequest__Cancel(context->request);
			break;
		case RequestKind::AuthLogout:
			eos_sdk_TEOSAuthLogoutRequest__Cancel(context->request);
			break;
		case RequestKind::ConnectLogin:
			eos_sdk_TEOSConnectLoginRequest__Cancel(context->request);
			break;
		case RequestKind::ConnectCreateUser:
			eos_sdk_TEOSConnectCreateUserRequest__Cancel(context->request);
			break;
		case RequestKind::ConnectLogout:
			eos_sdk_TEOSConnectLogoutRequest__Cancel(context->request);
			break;
		}
		delete context;
	}
}

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

void EOS_CALL AuthLoginCallback(const EOS_Auth_LoginCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);

	BBString *userCode = &bbEmptyString;
	BBString *verificationUri = &bbEmptyString;
	BBString *verificationUriComplete = &bbEmptyString;
	int expiresIn = 0;
	if (data->PinGrantInfo) {
		userCode = ToBBString(data->PinGrantInfo->UserCode);
		verificationUri = ToBBString(data->PinGrantInfo->VerificationURI);
		verificationUriComplete = ToBBString(data->PinGrantInfo->VerificationURIComplete);
		expiresIn = data->PinGrantInfo->ExpiresIn;
	}

	eos_sdk_TEOSAuthLoginRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, userCode, verificationUri, expiresIn,
		verificationUriComplete, data->ContinuanceToken, data->SelectedAccountId);
	if (terminal) delete context;
}

void EOS_CALL AuthLogoutCallback(const EOS_Auth_LogoutCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSAuthLogoutRequest__Complete(context->request, data->ResultCode, data->LocalUserId);
	if (terminal) delete context;
}

void EOS_CALL ConnectLoginCallback(const EOS_Connect_LoginCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSConnectLoginRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->ContinuanceToken);
	if (terminal) delete context;
}

void EOS_CALL ConnectCreateUserCallback(const EOS_Connect_CreateUserCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSConnectCreateUserRequest__Complete(context->request, data->ResultCode, data->LocalUserId);
	if (terminal) delete context;
}

void EOS_CALL ConnectLogoutCallback(const EOS_Connect_LogoutCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSConnectLogoutRequest__Complete(context->request, data->ResultCode, data->LocalUserId);
	if (terminal) delete context;
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
		CancelPlatformRequests(handle);
		EOS_Platform_Release(handle);
	}
}

EOS_HAuth bmx_eos_platform_get_auth_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetAuthInterface(handle) : nullptr;
}

EOS_HConnect bmx_eos_platform_get_connect_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetConnectInterface(handle) : nullptr;
}

void bmx_eos_auth_login(EOS_HPlatform platform, EOS_HAuth auth, BBObject *request,
	BBString *maxId, BBString *maxToken, EOS_ELoginCredentialType type,
	EOS_EExternalCredentialType externalType, EOS_EAuthScopeFlags scopeFlags, int loginFlags) {
	UTF8String id(maxId);
	UTF8String token(maxToken);
	EOS_Auth_Credentials credentials{};
	credentials.ApiVersion = EOS_AUTH_CREDENTIALS_API_LATEST;
	credentials.Id = id.optional();
	credentials.Token = token.optional();
	credentials.Type = type;
	credentials.ExternalType = externalType;

	EOS_Auth_LoginOptions options{};
	options.ApiVersion = EOS_AUTH_LOGIN_API_LATEST;
	options.Credentials = &credentials;
	options.ScopeFlags = scopeFlags;
	options.LoginFlags = static_cast<uint64_t>(loginFlags);
	auto *context = CreateRequest(platform, request, RequestKind::AuthLogin);
	EOS_Auth_Login(auth, &options, context, AuthLoginCallback);
}

void bmx_eos_auth_logout(EOS_HPlatform platform, EOS_HAuth auth, BBObject *request,
	EOS_EpicAccountId localUserId) {
	EOS_Auth_LogoutOptions options{};
	options.ApiVersion = EOS_AUTH_LOGOUT_API_LATEST;
	options.LocalUserId = localUserId;
	auto *context = CreateRequest(platform, request, RequestKind::AuthLogout);
	EOS_Auth_Logout(auth, &options, context, AuthLogoutCallback);
}

int bmx_eos_auth_get_logged_in_accounts_count(EOS_HAuth auth) {
	return auth ? EOS_Auth_GetLoggedInAccountsCount(auth) : 0;
}

EOS_EpicAccountId bmx_eos_auth_get_logged_in_account_by_index(EOS_HAuth auth, int index) {
	return auth ? EOS_Auth_GetLoggedInAccountByIndex(auth, index) : nullptr;
}

EOS_EResult bmx_eos_auth_copy_user_auth_token(EOS_HAuth auth, EOS_EpicAccountId localUserId,
	BBString **app, BBString **clientId, EOS_EpicAccountId *accountId,
	BBString **accessToken, double *expiresIn,
	BBString **expiresAt, int *authType, BBString **refreshToken,
	double *refreshExpiresIn, BBString **refreshExpiresAt) {
	EOS_Auth_CopyUserAuthTokenOptions options{};
	options.ApiVersion = EOS_AUTH_COPYUSERAUTHTOKEN_API_LATEST;
	EOS_Auth_Token *token = nullptr;
	EOS_EResult result = EOS_Auth_CopyUserAuthToken(auth, &options, localUserId, &token);
	if (result != EOS_EResult::EOS_Success || !token) return result;

	*app = ToBBString(token->App);
	*clientId = ToBBString(token->ClientId);
	*accountId = token->AccountId;
	*accessToken = ToBBString(token->AccessToken);
	*expiresIn = token->ExpiresIn;
	*expiresAt = ToBBString(token->ExpiresAt);
	*authType = static_cast<int>(token->AuthType);
	*refreshToken = ToBBString(token->RefreshToken);
	*refreshExpiresIn = token->RefreshExpiresIn;
	*refreshExpiresAt = ToBBString(token->RefreshExpiresAt);
	EOS_Auth_Token_Release(token);
	return result;
}

EOS_EResult bmx_eos_auth_copy_id_token(EOS_HAuth auth, EOS_EpicAccountId accountId,
	EOS_EpicAccountId *tokenAccountId, BBString **jsonWebToken) {
	EOS_Auth_CopyIdTokenOptions options{};
	options.ApiVersion = EOS_AUTH_COPYIDTOKEN_API_LATEST;
	options.AccountId = accountId;
	EOS_Auth_IdToken *token = nullptr;
	EOS_EResult result = EOS_Auth_CopyIdToken(auth, &options, &token);
	if (result != EOS_EResult::EOS_Success || !token) return result;

	*tokenAccountId = token->AccountId;
	*jsonWebToken = ToBBString(token->JsonWebToken);
	EOS_Auth_IdToken_Release(token);
	return result;
}

void bmx_eos_connect_login(EOS_HPlatform platform, EOS_HConnect connect, BBObject *request,
	BBString *maxToken, EOS_EExternalCredentialType type, BBString *maxDisplayName,
	BBString *maxNsaIdToken, int useUserLoginInfo) {
	UTF8String token(maxToken);
	UTF8String displayName(maxDisplayName);
	UTF8String nsaIdToken(maxNsaIdToken);
	EOS_Connect_Credentials credentials{};
	credentials.ApiVersion = EOS_CONNECT_CREDENTIALS_API_LATEST;
	credentials.Token = token.required();
	credentials.Type = type;

	EOS_Connect_UserLoginInfo userLoginInfo{};
	userLoginInfo.ApiVersion = EOS_CONNECT_USERLOGININFO_API_LATEST;
	userLoginInfo.DisplayName = displayName.optional();
	userLoginInfo.NsaIdToken = nsaIdToken.optional();

	EOS_Connect_LoginOptions options{};
	options.ApiVersion = EOS_CONNECT_LOGIN_API_LATEST;
	options.Credentials = &credentials;
	options.UserLoginInfo = useUserLoginInfo ? &userLoginInfo : nullptr;
	auto *context = CreateRequest(platform, request, RequestKind::ConnectLogin);
	EOS_Connect_Login(connect, &options, context, ConnectLoginCallback);
}

void bmx_eos_connect_create_user(EOS_HPlatform platform, EOS_HConnect connect,
	BBObject *request, EOS_ContinuanceToken continuanceToken) {
	EOS_Connect_CreateUserOptions options{};
	options.ApiVersion = EOS_CONNECT_CREATEUSER_API_LATEST;
	options.ContinuanceToken = continuanceToken;
	auto *context = CreateRequest(platform, request, RequestKind::ConnectCreateUser);
	EOS_Connect_CreateUser(connect, &options, context, ConnectCreateUserCallback);
}

void bmx_eos_connect_logout(EOS_HPlatform platform, EOS_HConnect connect,
	BBObject *request, EOS_ProductUserId localUserId) {
	EOS_Connect_LogoutOptions options{};
	options.ApiVersion = EOS_CONNECT_LOGOUT_API_LATEST;
	options.LocalUserId = localUserId;
	auto *context = CreateRequest(platform, request, RequestKind::ConnectLogout);
	EOS_Connect_Logout(connect, &options, context, ConnectLogoutCallback);
}

int bmx_eos_connect_get_logged_in_users_count(EOS_HConnect connect) {
	return connect ? EOS_Connect_GetLoggedInUsersCount(connect) : 0;
}

EOS_ProductUserId bmx_eos_connect_get_logged_in_user_by_index(EOS_HConnect connect, int index) {
	return connect ? EOS_Connect_GetLoggedInUserByIndex(connect, index) : nullptr;
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
