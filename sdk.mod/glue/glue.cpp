/* Copyright (c) 2026 Bruce A Henderson. Licensed under zlib/libpng. */

#include <brl.mod/blitz.mod/blitz.h>

#include "../SDK/Include/eos_sdk.h"
#include "../SDK/Include/eos_achievements.h"
#include "../SDK/Include/eos_auth.h"
#include "../SDK/Include/eos_connect.h"
#include "../SDK/Include/eos_friends.h"
#include "../SDK/Include/eos_logging.h"
#include "../SDK/Include/eos_leaderboards.h"
#include "../SDK/Include/eos_lobby.h"
#include "../SDK/Include/eos_presence.h"
#include "../SDK/Include/eos_stats.h"
#include "../SDK/Include/eos_userinfo.h"
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
void eos_sdk_TEOSStatsIngestRequest__Complete(BBObject *, EOS_EResult, EOS_ProductUserId, EOS_ProductUserId);
void eos_sdk_TEOSStatsIngestRequest__Cancel(BBObject *);
void eos_sdk_TEOSStatsQueryRequest__Complete(BBObject *, EOS_EResult, EOS_ProductUserId, EOS_ProductUserId);
void eos_sdk_TEOSStatsQueryRequest__Cancel(BBObject *);
void eos_sdk_TEOSAchievementsQueryDefinitionsRequest__Complete(BBObject *, EOS_EResult);
void eos_sdk_TEOSAchievementsQueryDefinitionsRequest__Cancel(BBObject *);
void eos_sdk_TEOSAchievementsQueryPlayerRequest__Complete(BBObject *, EOS_EResult, EOS_ProductUserId, EOS_ProductUserId);
void eos_sdk_TEOSAchievementsQueryPlayerRequest__Cancel(BBObject *);
void eos_sdk_TEOSAchievementsUnlockRequest__Complete(BBObject *, EOS_EResult, EOS_ProductUserId, unsigned int);
void eos_sdk_TEOSAchievementsUnlockRequest__Cancel(BBObject *);
void eos_sdk_TEOSAchievementsUnlockedSubscription__Notify(BBObject *, EOS_ProductUserId, BBString *, int64_t);
void eos_sdk_TEOSAchievementsUnlockedSubscription__Cancel(BBObject *);
void eos_sdk_TEOSLeaderboardsQueryDefinitionsRequest__Complete(BBObject *, EOS_EResult);
void eos_sdk_TEOSLeaderboardsQueryDefinitionsRequest__Cancel(BBObject *);
void eos_sdk_TEOSLeaderboardsQueryRanksRequest__Complete(BBObject *, EOS_EResult, BBString *);
void eos_sdk_TEOSLeaderboardsQueryRanksRequest__Cancel(BBObject *);
void eos_sdk_TEOSLeaderboardsQueryUserScoresRequest__Complete(BBObject *, EOS_EResult);
void eos_sdk_TEOSLeaderboardsQueryUserScoresRequest__Cancel(BBObject *);
void eos_sdk_TEOSUserInfoQueryRequest__Complete(BBObject *, EOS_EResult, EOS_EpicAccountId, EOS_EpicAccountId);
void eos_sdk_TEOSUserInfoQueryRequest__Cancel(BBObject *);
void eos_sdk_TEOSUserInfoQueryByDisplayNameRequest__Complete(BBObject *, EOS_EResult, EOS_EpicAccountId, EOS_EpicAccountId, BBString *);
void eos_sdk_TEOSUserInfoQueryByDisplayNameRequest__Cancel(BBObject *);
void eos_sdk_TEOSUserInfoQueryByExternalAccountRequest__Complete(BBObject *, EOS_EResult, EOS_EpicAccountId, EOS_EpicAccountId, BBString *, EOS_EExternalAccountType);
void eos_sdk_TEOSUserInfoQueryByExternalAccountRequest__Cancel(BBObject *);
void eos_sdk_TEOSFriendsQueryRequest__Complete(BBObject *, EOS_EResult, EOS_EpicAccountId);
void eos_sdk_TEOSFriendsQueryRequest__Cancel(BBObject *);
void eos_sdk_TEOSPresenceQueryRequest__Complete(BBObject *, EOS_EResult, EOS_EpicAccountId, EOS_EpicAccountId);
void eos_sdk_TEOSPresenceQueryRequest__Cancel(BBObject *);
void eos_sdk_TEOSPresenceSetRequest__Complete(BBObject *, EOS_EResult, EOS_EpicAccountId, EOS_EResult);
void eos_sdk_TEOSPresenceSetRequest__Cancel(BBObject *);
void eos_sdk_TEOSFriendsUpdateSubscription__Notify(BBObject *, EOS_EpicAccountId, EOS_EpicAccountId, EOS_EFriendsStatus, EOS_EFriendsStatus);
void eos_sdk_TEOSFriendsUpdateSubscription__Cancel(BBObject *);
void eos_sdk_TEOSBlockedUsersUpdateSubscription__Notify(BBObject *, EOS_EpicAccountId, EOS_EpicAccountId, int);
void eos_sdk_TEOSBlockedUsersUpdateSubscription__Cancel(BBObject *);
void eos_sdk_TEOSPresenceChangedSubscription__Notify(BBObject *, EOS_EpicAccountId, EOS_EpicAccountId);
void eos_sdk_TEOSPresenceChangedSubscription__Cancel(BBObject *);
void eos_sdk_TEOSAuthLoginStatusSubscription__Notify(BBObject *, EOS_EpicAccountId, EOS_ELoginStatus, EOS_ELoginStatus);
void eos_sdk_TEOSAuthLoginStatusSubscription__Cancel(BBObject *);
void eos_sdk_TEOSConnectAuthExpirationSubscription__Notify(BBObject *, EOS_ProductUserId);
void eos_sdk_TEOSConnectAuthExpirationSubscription__Cancel(BBObject *);
void eos_sdk_TEOSConnectLoginStatusSubscription__Notify(BBObject *, EOS_ProductUserId, EOS_ELoginStatus, EOS_ELoginStatus);
void eos_sdk_TEOSConnectLoginStatusSubscription__Cancel(BBObject *);
void eos_sdk_TEOSLobbyCreateRequest__Complete(BBObject *, EOS_EResult, BBString *);
void eos_sdk_TEOSLobbyCreateRequest__Cancel(BBObject *);
void eos_sdk_TEOSLobbyDestroyRequest__Complete(BBObject *, EOS_EResult, BBString *);
void eos_sdk_TEOSLobbyDestroyRequest__Cancel(BBObject *);
void eos_sdk_TEOSLobbyLeaveRequest__Complete(BBObject *, EOS_EResult, BBString *);
void eos_sdk_TEOSLobbyLeaveRequest__Cancel(BBObject *);
void eos_sdk_TEOSLobbyJoinRequest__Complete(BBObject *, EOS_EResult, BBString *);
void eos_sdk_TEOSLobbyJoinRequest__Cancel(BBObject *);
void eos_sdk_TEOSLobbySearchFindRequest__Complete(BBObject *, EOS_EResult);
void eos_sdk_TEOSLobbySearchFindRequest__Cancel(BBObject *);
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
	ConnectLogout,
	StatsIngest,
	StatsQuery,
	AchievementsQueryDefinitions,
	AchievementsQueryPlayer,
	AchievementsUnlock,
	LeaderboardsQueryDefinitions,
	LeaderboardsQueryRanks,
	LeaderboardsQueryUserScores,
	UserInfoQuery,
	UserInfoQueryByDisplayName,
	UserInfoQueryByExternalAccount,
	FriendsQuery,
	PresenceQuery,
	PresenceSet,
	LobbyCreate,
	LobbyDestroy,
	LobbyLeave,
	LobbyJoin,
	LobbySearchFind
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
		case RequestKind::StatsIngest:
			eos_sdk_TEOSStatsIngestRequest__Cancel(context->request);
			break;
		case RequestKind::StatsQuery:
			eos_sdk_TEOSStatsQueryRequest__Cancel(context->request);
			break;
		case RequestKind::AchievementsQueryDefinitions:
			eos_sdk_TEOSAchievementsQueryDefinitionsRequest__Cancel(context->request);
			break;
		case RequestKind::AchievementsQueryPlayer:
			eos_sdk_TEOSAchievementsQueryPlayerRequest__Cancel(context->request);
			break;
		case RequestKind::AchievementsUnlock:
			eos_sdk_TEOSAchievementsUnlockRequest__Cancel(context->request);
			break;
		case RequestKind::LeaderboardsQueryDefinitions:
			eos_sdk_TEOSLeaderboardsQueryDefinitionsRequest__Cancel(context->request);
			break;
		case RequestKind::LeaderboardsQueryRanks:
			eos_sdk_TEOSLeaderboardsQueryRanksRequest__Cancel(context->request);
			break;
		case RequestKind::LeaderboardsQueryUserScores:
			eos_sdk_TEOSLeaderboardsQueryUserScoresRequest__Cancel(context->request);
			break;
		case RequestKind::UserInfoQuery:
			eos_sdk_TEOSUserInfoQueryRequest__Cancel(context->request);
			break;
		case RequestKind::UserInfoQueryByDisplayName:
			eos_sdk_TEOSUserInfoQueryByDisplayNameRequest__Cancel(context->request);
			break;
		case RequestKind::UserInfoQueryByExternalAccount:
			eos_sdk_TEOSUserInfoQueryByExternalAccountRequest__Cancel(context->request);
			break;
		case RequestKind::FriendsQuery:
			eos_sdk_TEOSFriendsQueryRequest__Cancel(context->request);
			break;
		case RequestKind::PresenceQuery:
			eos_sdk_TEOSPresenceQueryRequest__Cancel(context->request);
			break;
		case RequestKind::PresenceSet:
			eos_sdk_TEOSPresenceSetRequest__Cancel(context->request);
			break;
		case RequestKind::LobbyCreate:
			eos_sdk_TEOSLobbyCreateRequest__Cancel(context->request);
			break;
		case RequestKind::LobbyDestroy:
			eos_sdk_TEOSLobbyDestroyRequest__Cancel(context->request);
			break;
		case RequestKind::LobbyLeave:
			eos_sdk_TEOSLobbyLeaveRequest__Cancel(context->request);
			break;
		case RequestKind::LobbyJoin:
			eos_sdk_TEOSLobbyJoinRequest__Cancel(context->request);
			break;
		case RequestKind::LobbySearchFind:
			eos_sdk_TEOSLobbySearchFindRequest__Cancel(context->request);
			break;
		}
		delete context;
	}
}

struct AchievementNotificationContext {
	EOS_HPlatform platform;
	EOS_HAchievements achievements;
	EOS_NotificationId id;
	BBObject *subscription;

	AchievementNotificationContext(EOS_HPlatform platform, EOS_HAchievements achievements, BBObject *subscription)
		: platform(platform), achievements(achievements), id(EOS_INVALID_NOTIFICATIONID), subscription(subscription) {
		BBRETAIN(subscription);
	}

	~AchievementNotificationContext() { BBRELEASE(subscription); }
};

std::vector<AchievementNotificationContext *> g_achievementNotifications;

enum class FriendsNotificationKind { FriendsUpdate, BlockedUsersUpdate };

struct FriendsNotificationContext {
	EOS_HPlatform platform;
	EOS_HFriends friends;
	EOS_NotificationId id;
	FriendsNotificationKind kind;
	BBObject *subscription;

	FriendsNotificationContext(EOS_HPlatform platform, EOS_HFriends friends,
		FriendsNotificationKind kind, BBObject *subscription)
		: platform(platform), friends(friends), id(EOS_INVALID_NOTIFICATIONID),
		  kind(kind), subscription(subscription) { BBRETAIN(subscription); }
	~FriendsNotificationContext() { BBRELEASE(subscription); }
};

std::vector<FriendsNotificationContext *> g_friendsNotifications;

struct PresenceNotificationContext {
	EOS_HPlatform platform;
	EOS_HPresence presence;
	EOS_NotificationId id;
	BBObject *subscription;

	PresenceNotificationContext(EOS_HPlatform platform, EOS_HPresence presence, BBObject *subscription)
		: platform(platform), presence(presence), id(EOS_INVALID_NOTIFICATIONID), subscription(subscription) {
		BBRETAIN(subscription);
	}
	~PresenceNotificationContext() { BBRELEASE(subscription); }
};

std::vector<PresenceNotificationContext *> g_presenceNotifications;

enum class LoginNotificationKind { AuthStatus, ConnectExpiration, ConnectStatus };

struct LoginNotificationContext {
	EOS_HPlatform platform;
	EOS_HAuth auth;
	EOS_HConnect connect;
	EOS_NotificationId id;
	LoginNotificationKind kind;
	BBObject *subscription;

	LoginNotificationContext(EOS_HPlatform platform, EOS_HAuth auth, EOS_HConnect connect,
		LoginNotificationKind kind, BBObject *subscription)
		: platform(platform), auth(auth), connect(connect), id(EOS_INVALID_NOTIFICATIONID),
		  kind(kind), subscription(subscription) { BBRETAIN(subscription); }
	~LoginNotificationContext() { BBRELEASE(subscription); }
};

std::vector<LoginNotificationContext *> g_loginNotifications;

void RemoveAchievementNotification(AchievementNotificationContext *context) {
	if (!context) return;
	if (context->id != EOS_INVALID_NOTIFICATIONID) {
		EOS_Achievements_RemoveNotifyAchievementsUnlocked(context->achievements, context->id);
	}
	auto found = std::find(g_achievementNotifications.begin(), g_achievementNotifications.end(), context);
	if (found != g_achievementNotifications.end()) g_achievementNotifications.erase(found);
	delete context;
}

void RemoveFriendsNotification(FriendsNotificationContext *context) {
	if (!context) return;
	if (context->id != EOS_INVALID_NOTIFICATIONID) {
		if (context->kind == FriendsNotificationKind::FriendsUpdate) {
			EOS_Friends_RemoveNotifyFriendsUpdate(context->friends, context->id);
		} else {
			EOS_Friends_RemoveNotifyBlockedUsersUpdate(context->friends, context->id);
		}
	}
	auto found = std::find(g_friendsNotifications.begin(), g_friendsNotifications.end(), context);
	if (found != g_friendsNotifications.end()) g_friendsNotifications.erase(found);
	delete context;
}

void RemovePresenceNotification(PresenceNotificationContext *context) {
	if (!context) return;
	if (context->id != EOS_INVALID_NOTIFICATIONID) {
		EOS_Presence_RemoveNotifyOnPresenceChanged(context->presence, context->id);
	}
	auto found = std::find(g_presenceNotifications.begin(), g_presenceNotifications.end(), context);
	if (found != g_presenceNotifications.end()) g_presenceNotifications.erase(found);
	delete context;
}

void RemoveLoginNotification(LoginNotificationContext *context) {
	if (!context) return;
	if (context->id != EOS_INVALID_NOTIFICATIONID) {
		switch (context->kind) {
		case LoginNotificationKind::AuthStatus:
			EOS_Auth_RemoveNotifyLoginStatusChanged(context->auth, context->id);
			break;
		case LoginNotificationKind::ConnectExpiration:
			EOS_Connect_RemoveNotifyAuthExpiration(context->connect, context->id);
			break;
		case LoginNotificationKind::ConnectStatus:
			EOS_Connect_RemoveNotifyLoginStatusChanged(context->connect, context->id);
			break;
		}
	}
	auto found = std::find(g_loginNotifications.begin(), g_loginNotifications.end(), context);
	if (found != g_loginNotifications.end()) g_loginNotifications.erase(found);
	delete context;
}

void CancelPlatformNotifications(EOS_HPlatform platform) {
	for (std::size_t index = 0; index < g_achievementNotifications.size();) {
		auto *context = g_achievementNotifications[index];
		if (context->platform != platform) { ++index; continue; }
		g_achievementNotifications.erase(g_achievementNotifications.begin() + static_cast<std::ptrdiff_t>(index));
		if (context->id != EOS_INVALID_NOTIFICATIONID) {
			EOS_Achievements_RemoveNotifyAchievementsUnlocked(context->achievements, context->id);
		}
		eos_sdk_TEOSAchievementsUnlockedSubscription__Cancel(context->subscription);
		delete context;
	}
	for (std::size_t index = 0; index < g_friendsNotifications.size();) {
		auto *context = g_friendsNotifications[index];
		if (context->platform != platform) { ++index; continue; }
		g_friendsNotifications.erase(g_friendsNotifications.begin() + static_cast<std::ptrdiff_t>(index));
		if (context->id != EOS_INVALID_NOTIFICATIONID) {
			if (context->kind == FriendsNotificationKind::FriendsUpdate) {
				EOS_Friends_RemoveNotifyFriendsUpdate(context->friends, context->id);
				eos_sdk_TEOSFriendsUpdateSubscription__Cancel(context->subscription);
			} else {
				EOS_Friends_RemoveNotifyBlockedUsersUpdate(context->friends, context->id);
				eos_sdk_TEOSBlockedUsersUpdateSubscription__Cancel(context->subscription);
			}
		}
		delete context;
	}
	for (std::size_t index = 0; index < g_presenceNotifications.size();) {
		auto *context = g_presenceNotifications[index];
		if (context->platform != platform) { ++index; continue; }
		g_presenceNotifications.erase(g_presenceNotifications.begin() + static_cast<std::ptrdiff_t>(index));
		if (context->id != EOS_INVALID_NOTIFICATIONID) {
			EOS_Presence_RemoveNotifyOnPresenceChanged(context->presence, context->id);
			eos_sdk_TEOSPresenceChangedSubscription__Cancel(context->subscription);
		}
		delete context;
	}
	for (std::size_t index = 0; index < g_loginNotifications.size();) {
		auto *context = g_loginNotifications[index];
		if (context->platform != platform) { ++index; continue; }
		g_loginNotifications.erase(g_loginNotifications.begin() + static_cast<std::ptrdiff_t>(index));
		if (context->id != EOS_INVALID_NOTIFICATIONID) {
			switch (context->kind) {
			case LoginNotificationKind::AuthStatus:
				EOS_Auth_RemoveNotifyLoginStatusChanged(context->auth, context->id);
				eos_sdk_TEOSAuthLoginStatusSubscription__Cancel(context->subscription);
				break;
			case LoginNotificationKind::ConnectExpiration:
				EOS_Connect_RemoveNotifyAuthExpiration(context->connect, context->id);
				eos_sdk_TEOSConnectAuthExpirationSubscription__Cancel(context->subscription);
				break;
			case LoginNotificationKind::ConnectStatus:
				EOS_Connect_RemoveNotifyLoginStatusChanged(context->connect, context->id);
				eos_sdk_TEOSConnectLoginStatusSubscription__Cancel(context->subscription);
				break;
			}
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

class UTF8StringArray {
public:
	explicit UTF8StringArray(BBArray *array) {
		if (!array || array == &bbEmptyArray || array->dims != 1) return;
		const int count = array->scales[0];
		BBString **strings = static_cast<BBString **>(BBARRAYDATA(array, array->dims));
		owned_.reserve(count);
		values_.reserve(count);
		for (int index = 0; index < count; ++index) {
			auto *value = bbStringToUTF8String(strings[index]);
			owned_.push_back(value);
			values_.push_back(reinterpret_cast<const char *>(value));
		}
	}

	~UTF8StringArray() {
		for (auto *value : owned_) bbMemFree(value);
	}

	const char **data() { return values_.empty() ? nullptr : values_.data(); }
	std::size_t size() const { return values_.size(); }

private:
	std::vector<unsigned char *> owned_;
	std::vector<const char *> values_;
};

BBString *ToBBString(const char *value) {
	return bbStringFromUTF8String(reinterpret_cast<const unsigned char *>(value ? value : ""));
}

BBArray *StringArray(const std::vector<const char *> &values) {
	BBArray *array = bbArrayNew1D("$", static_cast<int>(values.size()));
	BBString **data = static_cast<BBString **>(BBARRAYDATA(array, array->dims));
	for (std::size_t index = 0; index < values.size(); ++index) data[index] = ToBBString(values[index]);
	return array;
}

BBArray *IntArray(const std::vector<int> &values) {
	BBArray *array = bbArrayNew1D("i", static_cast<int>(values.size()));
	int *data = static_cast<int *>(BBARRAYDATA(array, array->dims));
	for (std::size_t index = 0; index < values.size(); ++index) data[index] = values[index];
	return array;
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

void EOS_CALL StatsIngestCallback(const EOS_Stats_IngestStatCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSStatsIngestRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->TargetUserId);
	if (terminal) delete context;
}

void EOS_CALL StatsQueryCallback(const EOS_Stats_OnQueryStatsCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSStatsQueryRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->TargetUserId);
	if (terminal) delete context;
}

void EOS_CALL AchievementsQueryDefinitionsCallback(const EOS_Achievements_OnQueryDefinitionsCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSAchievementsQueryDefinitionsRequest__Complete(context->request, data->ResultCode);
	if (terminal) delete context;
}

void EOS_CALL AchievementsQueryPlayerCallback(const EOS_Achievements_OnQueryPlayerAchievementsCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSAchievementsQueryPlayerRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->TargetUserId);
	if (terminal) delete context;
}

void EOS_CALL AchievementsUnlockCallback(const EOS_Achievements_OnUnlockAchievementsCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSAchievementsUnlockRequest__Complete(context->request, data->ResultCode,
		data->UserId, data->AchievementsCount);
	if (terminal) delete context;
}

void EOS_CALL AchievementsUnlockedCallback(const EOS_Achievements_OnAchievementsUnlockedCallbackV2Info *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<AchievementNotificationContext *>(data->ClientData);
	eos_sdk_TEOSAchievementsUnlockedSubscription__Notify(context->subscription, data->UserId,
		ToBBString(data->AchievementId), data->UnlockTime);
}

void EOS_CALL LeaderboardsQueryDefinitionsCallback(const EOS_Leaderboards_OnQueryLeaderboardDefinitionsCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSLeaderboardsQueryDefinitionsRequest__Complete(context->request, data->ResultCode);
	if (terminal) delete context;
}

void EOS_CALL LeaderboardsQueryRanksCallback(const EOS_Leaderboards_OnQueryLeaderboardRanksCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSLeaderboardsQueryRanksRequest__Complete(context->request, data->ResultCode,
		ToBBString(data->LeaderboardId));
	if (terminal) delete context;
}

void EOS_CALL LeaderboardsQueryUserScoresCallback(const EOS_Leaderboards_OnQueryLeaderboardUserScoresCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSLeaderboardsQueryUserScoresRequest__Complete(context->request, data->ResultCode);
	if (terminal) delete context;
}

void EOS_CALL UserInfoQueryCallback(const EOS_UserInfo_QueryUserInfoCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSUserInfoQueryRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->TargetUserId);
	if (terminal) delete context;
}

void EOS_CALL UserInfoQueryByDisplayNameCallback(const EOS_UserInfo_QueryUserInfoByDisplayNameCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSUserInfoQueryByDisplayNameRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->TargetUserId, ToBBString(data->DisplayName));
	if (terminal) delete context;
}

void EOS_CALL UserInfoQueryByExternalAccountCallback(const EOS_UserInfo_QueryUserInfoByExternalAccountCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSUserInfoQueryByExternalAccountRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->TargetUserId, ToBBString(data->ExternalAccountId), data->AccountType);
	if (terminal) delete context;
}

void EOS_CALL FriendsQueryCallback(const EOS_Friends_QueryFriendsCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSFriendsQueryRequest__Complete(context->request, data->ResultCode, data->LocalUserId);
	if (terminal) delete context;
}

void EOS_CALL FriendsUpdateCallback(const EOS_Friends_OnFriendsUpdateInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<FriendsNotificationContext *>(data->ClientData);
	eos_sdk_TEOSFriendsUpdateSubscription__Notify(context->subscription, data->LocalUserId,
		data->TargetUserId, data->PreviousStatus, data->CurrentStatus);
}

void EOS_CALL BlockedUsersUpdateCallback(const EOS_Friends_OnBlockedUsersUpdateInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<FriendsNotificationContext *>(data->ClientData);
	eos_sdk_TEOSBlockedUsersUpdateSubscription__Notify(context->subscription, data->LocalUserId,
		data->TargetUserId, data->bBlocked == EOS_TRUE);
}

void EOS_CALL PresenceQueryCallback(const EOS_Presence_QueryPresenceCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSPresenceQueryRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->TargetUserId);
	if (terminal) delete context;
}

void EOS_CALL PresenceSetCallback(const EOS_Presence_SetPresenceCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSPresenceSetRequest__Complete(context->request, data->ResultCode,
		data->LocalUserId, data->RichPresenceResultCode);
	if (terminal) delete context;
}

void EOS_CALL PresenceChangedCallback(const EOS_Presence_PresenceChangedCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<PresenceNotificationContext *>(data->ClientData);
	eos_sdk_TEOSPresenceChangedSubscription__Notify(context->subscription,
		data->LocalUserId, data->PresenceUserId);
}

void EOS_CALL AuthLoginStatusCallback(const EOS_Auth_LoginStatusChangedCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<LoginNotificationContext *>(data->ClientData);
	eos_sdk_TEOSAuthLoginStatusSubscription__Notify(context->subscription, data->LocalUserId,
		data->PrevStatus, data->CurrentStatus);
}

void EOS_CALL ConnectAuthExpirationCallback(const EOS_Connect_AuthExpirationCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<LoginNotificationContext *>(data->ClientData);
	eos_sdk_TEOSConnectAuthExpirationSubscription__Notify(context->subscription, data->LocalUserId);
}

void EOS_CALL ConnectLoginStatusCallback(const EOS_Connect_LoginStatusChangedCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<LoginNotificationContext *>(data->ClientData);
	eos_sdk_TEOSConnectLoginStatusSubscription__Notify(context->subscription, data->LocalUserId,
		data->PreviousStatus, data->CurrentStatus);
}

void EOS_CALL LobbyCreateCallback(const EOS_Lobby_CreateLobbyCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSLobbyCreateRequest__Complete(context->request, data->ResultCode,
		ToBBString(data->LobbyId));
	if (terminal) delete context;
}

void EOS_CALL LobbyDestroyCallback(const EOS_Lobby_DestroyLobbyCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSLobbyDestroyRequest__Complete(context->request, data->ResultCode,
		ToBBString(data->LobbyId));
	if (terminal) delete context;
}

void EOS_CALL LobbyLeaveCallback(const EOS_Lobby_LeaveLobbyCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSLobbyLeaveRequest__Complete(context->request, data->ResultCode,
		ToBBString(data->LobbyId));
	if (terminal) delete context;
}

void EOS_CALL LobbyJoinCallback(const EOS_Lobby_JoinLobbyCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSLobbyJoinRequest__Complete(context->request, data->ResultCode,
		ToBBString(data->LobbyId));
	if (terminal) delete context;
}

void EOS_CALL LobbySearchFindCallback(const EOS_LobbySearch_FindCallbackInfo *data) {
	if (!data || !data->ClientData) return;
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) CompleteRequest(context);
	eos_sdk_TEOSLobbySearchFindRequest__Complete(context->request, data->ResultCode);
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
		CancelPlatformNotifications(handle);
		EOS_Platform_Release(handle);
	}
}

EOS_HAuth bmx_eos_platform_get_auth_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetAuthInterface(handle) : nullptr;
}

EOS_HConnect bmx_eos_platform_get_connect_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetConnectInterface(handle) : nullptr;
}

EOS_HStats bmx_eos_platform_get_stats_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetStatsInterface(handle) : nullptr;
}

EOS_HAchievements bmx_eos_platform_get_achievements_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetAchievementsInterface(handle) : nullptr;
}

EOS_HLeaderboards bmx_eos_platform_get_leaderboards_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetLeaderboardsInterface(handle) : nullptr;
}

EOS_HUserInfo bmx_eos_platform_get_user_info_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetUserInfoInterface(handle) : nullptr;
}

EOS_HFriends bmx_eos_platform_get_friends_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetFriendsInterface(handle) : nullptr;
}

EOS_HPresence bmx_eos_platform_get_presence_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetPresenceInterface(handle) : nullptr;
}

EOS_HLobby bmx_eos_platform_get_lobby_interface(EOS_HPlatform handle) {
	return handle ? EOS_Platform_GetLobbyInterface(handle) : nullptr;
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

void bmx_eos_stats_ingest(EOS_HPlatform platform, EOS_HStats stats, BBObject *request,
	EOS_ProductUserId localUserId, EOS_ProductUserId targetUserId,
	BBArray *maxNames, BBArray *maxAmounts) {
	UTF8StringArray names(maxNames);
	const int *amounts = (maxAmounts && maxAmounts != &bbEmptyArray)
		? static_cast<const int *>(BBARRAYDATA(maxAmounts, maxAmounts->dims))
		: nullptr;
	std::vector<EOS_Stats_IngestData> ingestData(names.size());
	for (std::size_t index = 0; index < names.size(); ++index) {
		ingestData[index].ApiVersion = EOS_STATS_INGESTDATA_API_LATEST;
		ingestData[index].StatName = names.data()[index];
		ingestData[index].IngestAmount = amounts[index];
	}

	EOS_Stats_IngestStatOptions options{};
	options.ApiVersion = EOS_STATS_INGESTSTAT_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	options.Stats = ingestData.empty() ? nullptr : ingestData.data();
	options.StatsCount = static_cast<uint32_t>(ingestData.size());
	auto *context = CreateRequest(platform, request, RequestKind::StatsIngest);
	EOS_Stats_IngestStat(stats, &options, context, StatsIngestCallback);
}

void bmx_eos_stats_query(EOS_HPlatform platform, EOS_HStats stats, BBObject *request,
	EOS_ProductUserId localUserId, EOS_ProductUserId targetUserId,
	int64_t startTime, int64_t endTime, BBArray *maxNames) {
	UTF8StringArray names(maxNames);
	EOS_Stats_QueryStatsOptions options{};
	options.ApiVersion = EOS_STATS_QUERYSTATS_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	options.StartTime = startTime;
	options.EndTime = endTime;
	options.StatNames = names.data();
	options.StatNamesCount = static_cast<uint32_t>(names.size());
	auto *context = CreateRequest(platform, request, RequestKind::StatsQuery);
	EOS_Stats_QueryStats(stats, &options, context, StatsQueryCallback);
}

int bmx_eos_stats_get_count(EOS_HStats stats, EOS_ProductUserId targetUserId) {
	EOS_Stats_GetStatCountOptions options{};
	options.ApiVersion = EOS_STATS_GETSTATSCOUNT_API_LATEST;
	options.TargetUserId = targetUserId;
	return static_cast<int>(EOS_Stats_GetStatsCount(stats, &options));
}

static EOS_EResult CopyStat(EOS_Stats_Stat *stat, BBString **name,
	int64_t *startTime, int64_t *endTime, int *value, EOS_EResult result) {
	if (result != EOS_EResult::EOS_Success || !stat) return result;
	*name = ToBBString(stat->Name);
	*startTime = stat->StartTime;
	*endTime = stat->EndTime;
	*value = stat->Value;
	EOS_Stats_Stat_Release(stat);
	return result;
}

EOS_EResult bmx_eos_stats_copy_by_index(EOS_HStats stats, EOS_ProductUserId targetUserId,
	unsigned int index, BBString **name, int64_t *startTime, int64_t *endTime, int *value) {
	EOS_Stats_CopyStatByIndexOptions options{};
	options.ApiVersion = EOS_STATS_COPYSTATBYINDEX_API_LATEST;
	options.TargetUserId = targetUserId;
	options.StatIndex = index;
	EOS_Stats_Stat *stat = nullptr;
	EOS_EResult result = EOS_Stats_CopyStatByIndex(stats, &options, &stat);
	return CopyStat(stat, name, startTime, endTime, value, result);
}

EOS_EResult bmx_eos_stats_copy_by_name(EOS_HStats stats, EOS_ProductUserId targetUserId,
	BBString *maxName, BBString **name, int64_t *startTime, int64_t *endTime, int *value) {
	UTF8String nativeName(maxName);
	EOS_Stats_CopyStatByNameOptions options{};
	options.ApiVersion = EOS_STATS_COPYSTATBYNAME_API_LATEST;
	options.TargetUserId = targetUserId;
	options.Name = nativeName.required();
	EOS_Stats_Stat *stat = nullptr;
	EOS_EResult result = EOS_Stats_CopyStatByName(stats, &options, &stat);
	return CopyStat(stat, name, startTime, endTime, value, result);
}

void bmx_eos_achievements_query_definitions(EOS_HPlatform platform, EOS_HAchievements achievements,
	BBObject *request, EOS_ProductUserId localUserId) {
	EOS_Achievements_QueryDefinitionsOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_QUERYDEFINITIONS_API_LATEST;
	options.LocalUserId = localUserId;
	auto *context = CreateRequest(platform, request, RequestKind::AchievementsQueryDefinitions);
	EOS_Achievements_QueryDefinitions(achievements, &options, context, AchievementsQueryDefinitionsCallback);
}

void bmx_eos_achievements_query_player(EOS_HPlatform platform, EOS_HAchievements achievements,
	BBObject *request, EOS_ProductUserId localUserId, EOS_ProductUserId targetUserId) {
	EOS_Achievements_QueryPlayerAchievementsOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_QUERYPLAYERACHIEVEMENTS_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	auto *context = CreateRequest(platform, request, RequestKind::AchievementsQueryPlayer);
	EOS_Achievements_QueryPlayerAchievements(achievements, &options, context, AchievementsQueryPlayerCallback);
}

int bmx_eos_achievements_definition_count(EOS_HAchievements achievements) {
	EOS_Achievements_GetAchievementDefinitionCountOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_GETACHIEVEMENTDEFINITIONCOUNT_API_LATEST;
	return static_cast<int>(EOS_Achievements_GetAchievementDefinitionCount(achievements, &options));
}

static EOS_EResult CopyAchievementDefinition(EOS_Achievements_DefinitionV2 *definition,
	BBString **achievementId, BBString **unlockedDisplayName, BBString **unlockedDescription,
	BBString **lockedDisplayName, BBString **lockedDescription, BBString **flavorText,
	BBString **unlockedIconUrl, BBString **lockedIconUrl, int *isHidden,
	BBArray **statNames, BBArray **thresholds, EOS_EResult result) {
	if (result != EOS_EResult::EOS_Success || !definition) return result;
	*achievementId = ToBBString(definition->AchievementId);
	*unlockedDisplayName = ToBBString(definition->UnlockedDisplayName);
	*unlockedDescription = ToBBString(definition->UnlockedDescription);
	*lockedDisplayName = ToBBString(definition->LockedDisplayName);
	*lockedDescription = ToBBString(definition->LockedDescription);
	*flavorText = ToBBString(definition->FlavorText);
	*unlockedIconUrl = ToBBString(definition->UnlockedIconURL);
	*lockedIconUrl = ToBBString(definition->LockedIconURL);
	*isHidden = definition->bIsHidden;
	std::vector<const char *> names;
	std::vector<int> values;
	for (uint32_t index = 0; index < definition->StatThresholdsCount; ++index) {
		names.push_back(definition->StatThresholds[index].Name);
		values.push_back(definition->StatThresholds[index].Threshold);
	}
	*statNames = StringArray(names);
	*thresholds = IntArray(values);
	EOS_Achievements_DefinitionV2_Release(definition);
	return result;
}

EOS_EResult bmx_eos_achievements_copy_definition_by_index(EOS_HAchievements achievements, unsigned int index,
	BBString **achievementId, BBString **unlockedDisplayName, BBString **unlockedDescription,
	BBString **lockedDisplayName, BBString **lockedDescription, BBString **flavorText,
	BBString **unlockedIconUrl, BBString **lockedIconUrl, int *isHidden,
	BBArray **statNames, BBArray **thresholds) {
	EOS_Achievements_CopyAchievementDefinitionV2ByIndexOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_COPYACHIEVEMENTDEFINITIONV2BYINDEX_API_LATEST;
	options.AchievementIndex = index;
	EOS_Achievements_DefinitionV2 *definition = nullptr;
	EOS_EResult result = EOS_Achievements_CopyAchievementDefinitionV2ByIndex(achievements, &options, &definition);
	return CopyAchievementDefinition(definition, achievementId, unlockedDisplayName, unlockedDescription,
		lockedDisplayName, lockedDescription, flavorText, unlockedIconUrl, lockedIconUrl, isHidden,
		statNames, thresholds, result);
}

EOS_EResult bmx_eos_achievements_copy_definition_by_id(EOS_HAchievements achievements, BBString *maxId,
	BBString **achievementId, BBString **unlockedDisplayName, BBString **unlockedDescription,
	BBString **lockedDisplayName, BBString **lockedDescription, BBString **flavorText,
	BBString **unlockedIconUrl, BBString **lockedIconUrl, int *isHidden,
	BBArray **statNames, BBArray **thresholds) {
	UTF8String id(maxId);
	EOS_Achievements_CopyAchievementDefinitionV2ByAchievementIdOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_COPYACHIEVEMENTDEFINITIONV2BYACHIEVEMENTID_API_LATEST;
	options.AchievementId = id.required();
	EOS_Achievements_DefinitionV2 *definition = nullptr;
	EOS_EResult result = EOS_Achievements_CopyAchievementDefinitionV2ByAchievementId(achievements, &options, &definition);
	return CopyAchievementDefinition(definition, achievementId, unlockedDisplayName, unlockedDescription,
		lockedDisplayName, lockedDescription, flavorText, unlockedIconUrl, lockedIconUrl, isHidden,
		statNames, thresholds, result);
}

int bmx_eos_achievements_player_count(EOS_HAchievements achievements, EOS_ProductUserId targetUserId) {
	EOS_Achievements_GetPlayerAchievementCountOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_GETPLAYERACHIEVEMENTCOUNT_API_LATEST;
	options.UserId = targetUserId;
	return static_cast<int>(EOS_Achievements_GetPlayerAchievementCount(achievements, &options));
}

static EOS_EResult CopyPlayerAchievement(EOS_Achievements_PlayerAchievement *achievement,
	BBString **achievementId, double *progress, int64_t *unlockTime, BBString **displayName,
	BBString **description, BBString **iconUrl, BBString **flavorText, BBArray **statNames,
	BBArray **currentValues, BBArray **thresholdValues, EOS_EResult result) {
	if (result != EOS_EResult::EOS_Success || !achievement) return result;
	*achievementId = ToBBString(achievement->AchievementId);
	*progress = achievement->Progress;
	*unlockTime = achievement->UnlockTime;
	*displayName = ToBBString(achievement->DisplayName);
	*description = ToBBString(achievement->Description);
	*iconUrl = ToBBString(achievement->IconURL);
	*flavorText = ToBBString(achievement->FlavorText);
	std::vector<const char *> names;
	std::vector<int> current;
	std::vector<int> thresholds;
	for (int32_t index = 0; index < achievement->StatInfoCount; ++index) {
		names.push_back(achievement->StatInfo[index].Name);
		current.push_back(achievement->StatInfo[index].CurrentValue);
		thresholds.push_back(achievement->StatInfo[index].ThresholdValue);
	}
	*statNames = StringArray(names);
	*currentValues = IntArray(current);
	*thresholdValues = IntArray(thresholds);
	EOS_Achievements_PlayerAchievement_Release(achievement);
	return result;
}

EOS_EResult bmx_eos_achievements_copy_player_by_index(EOS_HAchievements achievements,
	EOS_ProductUserId localUserId, EOS_ProductUserId targetUserId, unsigned int index,
	BBString **achievementId, double *progress, int64_t *unlockTime, BBString **displayName,
	BBString **description, BBString **iconUrl, BBString **flavorText, BBArray **statNames,
	BBArray **currentValues, BBArray **thresholdValues) {
	EOS_Achievements_CopyPlayerAchievementByIndexOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_COPYPLAYERACHIEVEMENTBYINDEX_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	options.AchievementIndex = index;
	EOS_Achievements_PlayerAchievement *achievement = nullptr;
	EOS_EResult result = EOS_Achievements_CopyPlayerAchievementByIndex(achievements, &options, &achievement);
	return CopyPlayerAchievement(achievement, achievementId, progress, unlockTime, displayName,
		description, iconUrl, flavorText, statNames, currentValues, thresholdValues, result);
}

EOS_EResult bmx_eos_achievements_copy_player_by_id(EOS_HAchievements achievements,
	EOS_ProductUserId localUserId, EOS_ProductUserId targetUserId, BBString *maxId,
	BBString **achievementId, double *progress, int64_t *unlockTime, BBString **displayName,
	BBString **description, BBString **iconUrl, BBString **flavorText, BBArray **statNames,
	BBArray **currentValues, BBArray **thresholdValues) {
	UTF8String id(maxId);
	EOS_Achievements_CopyPlayerAchievementByAchievementIdOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_COPYPLAYERACHIEVEMENTBYACHIEVEMENTID_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	options.AchievementId = id.required();
	EOS_Achievements_PlayerAchievement *achievement = nullptr;
	EOS_EResult result = EOS_Achievements_CopyPlayerAchievementByAchievementId(achievements, &options, &achievement);
	return CopyPlayerAchievement(achievement, achievementId, progress, unlockTime, displayName,
		description, iconUrl, flavorText, statNames, currentValues, thresholdValues, result);
}

void bmx_eos_achievements_unlock(EOS_HPlatform platform, EOS_HAchievements achievements,
	BBObject *request, EOS_ProductUserId userId, BBArray *maxIds) {
	UTF8StringArray ids(maxIds);
	EOS_Achievements_UnlockAchievementsOptions options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_UNLOCKACHIEVEMENTS_API_LATEST;
	options.UserId = userId;
	options.AchievementIds = ids.data();
	options.AchievementsCount = static_cast<uint32_t>(ids.size());
	auto *context = CreateRequest(platform, request, RequestKind::AchievementsUnlock);
	EOS_Achievements_UnlockAchievements(achievements, &options, context, AchievementsUnlockCallback);
}

uint64_t bmx_eos_achievements_add_notify_unlocked(EOS_HPlatform platform,
	EOS_HAchievements achievements, BBObject *subscription) {
	auto *context = new AchievementNotificationContext(platform, achievements, subscription);
	EOS_Achievements_AddNotifyAchievementsUnlockedV2Options options{};
	options.ApiVersion = EOS_ACHIEVEMENTS_ADDNOTIFYACHIEVEMENTSUNLOCKEDV2_API_LATEST;
	context->id = EOS_Achievements_AddNotifyAchievementsUnlockedV2(
		achievements, &options, context, AchievementsUnlockedCallback);
	if (context->id == EOS_INVALID_NOTIFICATIONID) {
		delete context;
		return EOS_INVALID_NOTIFICATIONID;
	}
	g_achievementNotifications.push_back(context);
	return context->id;
}

void bmx_eos_achievements_remove_notify_unlocked(uint64_t id) {
	auto found = std::find_if(g_achievementNotifications.begin(), g_achievementNotifications.end(),
		[id](const AchievementNotificationContext *context) { return context->id == id; });
	if (found != g_achievementNotifications.end()) RemoveAchievementNotification(*found);
}

void bmx_eos_leaderboards_query_definitions(EOS_HPlatform platform, EOS_HLeaderboards leaderboards,
	BBObject *request, EOS_ProductUserId localUserId, int64_t startTime, int64_t endTime) {
	EOS_Leaderboards_QueryLeaderboardDefinitionsOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_QUERYLEADERBOARDDEFINITIONS_API_LATEST;
	options.LocalUserId = localUserId;
	options.StartTime = startTime;
	options.EndTime = endTime;
	auto *context = CreateRequest(platform, request, RequestKind::LeaderboardsQueryDefinitions);
	EOS_Leaderboards_QueryLeaderboardDefinitions(leaderboards, &options, context, LeaderboardsQueryDefinitionsCallback);
}

void bmx_eos_leaderboards_query_ranks(EOS_HPlatform platform, EOS_HLeaderboards leaderboards,
	BBObject *request, EOS_ProductUserId localUserId, BBString *maxLeaderboardId) {
	UTF8String leaderboardId(maxLeaderboardId);
	EOS_Leaderboards_QueryLeaderboardRanksOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_QUERYLEADERBOARDRANKS_API_LATEST;
	options.LocalUserId = localUserId;
	options.LeaderboardId = leaderboardId.required();
	auto *context = CreateRequest(platform, request, RequestKind::LeaderboardsQueryRanks);
	EOS_Leaderboards_QueryLeaderboardRanks(leaderboards, &options, context, LeaderboardsQueryRanksCallback);
}

int bmx_eos_leaderboards_definition_count(EOS_HLeaderboards leaderboards) {
	EOS_Leaderboards_GetLeaderboardDefinitionCountOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_GETLEADERBOARDDEFINITIONCOUNT_API_LATEST;
	return static_cast<int>(EOS_Leaderboards_GetLeaderboardDefinitionCount(leaderboards, &options));
}

static EOS_EResult CopyLeaderboardDefinition(EOS_Leaderboards_Definition *definition,
	BBString **leaderboardId, BBString **statName, int *aggregation,
	int64_t *startTime, int64_t *endTime, EOS_EResult result) {
	if (result != EOS_EResult::EOS_Success || !definition) return result;
	*leaderboardId = ToBBString(definition->LeaderboardId);
	*statName = ToBBString(definition->StatName);
	*aggregation = static_cast<int>(definition->Aggregation);
	*startTime = definition->StartTime;
	*endTime = definition->EndTime;
	EOS_Leaderboards_Definition_Release(definition);
	return result;
}

EOS_EResult bmx_eos_leaderboards_copy_definition_by_index(EOS_HLeaderboards leaderboards,
	unsigned int index, BBString **leaderboardId, BBString **statName, int *aggregation,
	int64_t *startTime, int64_t *endTime) {
	EOS_Leaderboards_CopyLeaderboardDefinitionByIndexOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_COPYLEADERBOARDDEFINITIONBYINDEX_API_LATEST;
	options.LeaderboardIndex = index;
	EOS_Leaderboards_Definition *definition = nullptr;
	EOS_EResult result = EOS_Leaderboards_CopyLeaderboardDefinitionByIndex(leaderboards, &options, &definition);
	return CopyLeaderboardDefinition(definition, leaderboardId, statName, aggregation, startTime, endTime, result);
}

EOS_EResult bmx_eos_leaderboards_copy_definition_by_id(EOS_HLeaderboards leaderboards,
	BBString *maxId, BBString **leaderboardId, BBString **statName, int *aggregation,
	int64_t *startTime, int64_t *endTime) {
	UTF8String id(maxId);
	EOS_Leaderboards_CopyLeaderboardDefinitionByLeaderboardIdOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_COPYLEADERBOARDDEFINITIONBYLEADERBOARDID_API_LATEST;
	options.LeaderboardId = id.required();
	EOS_Leaderboards_Definition *definition = nullptr;
	EOS_EResult result = EOS_Leaderboards_CopyLeaderboardDefinitionByLeaderboardId(leaderboards, &options, &definition);
	return CopyLeaderboardDefinition(definition, leaderboardId, statName, aggregation, startTime, endTime, result);
}

int bmx_eos_leaderboards_record_count(EOS_HLeaderboards leaderboards) {
	EOS_Leaderboards_GetLeaderboardRecordCountOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_GETLEADERBOARDRECORDCOUNT_API_LATEST;
	return static_cast<int>(EOS_Leaderboards_GetLeaderboardRecordCount(leaderboards, &options));
}

static EOS_EResult CopyLeaderboardRecord(EOS_Leaderboards_LeaderboardRecord *record,
	EOS_ProductUserId *userId, unsigned int *rank, int *score, BBString **displayName,
	EOS_EResult result) {
	if (result != EOS_EResult::EOS_Success || !record) return result;
	*userId = record->UserId;
	*rank = record->Rank;
	*score = record->Score;
	*displayName = ToBBString(record->UserDisplayName);
	EOS_Leaderboards_LeaderboardRecord_Release(record);
	return result;
}

EOS_EResult bmx_eos_leaderboards_copy_record_by_index(EOS_HLeaderboards leaderboards,
	unsigned int index, EOS_ProductUserId *userId, unsigned int *rank, int *score,
	BBString **displayName) {
	EOS_Leaderboards_CopyLeaderboardRecordByIndexOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_COPYLEADERBOARDRECORDBYINDEX_API_LATEST;
	options.LeaderboardRecordIndex = index;
	EOS_Leaderboards_LeaderboardRecord *record = nullptr;
	EOS_EResult result = EOS_Leaderboards_CopyLeaderboardRecordByIndex(leaderboards, &options, &record);
	return CopyLeaderboardRecord(record, userId, rank, score, displayName, result);
}

EOS_EResult bmx_eos_leaderboards_copy_record_by_user(EOS_HLeaderboards leaderboards,
	EOS_ProductUserId requestedUserId, EOS_ProductUserId *userId, unsigned int *rank,
	int *score, BBString **displayName) {
	EOS_Leaderboards_CopyLeaderboardRecordByUserIdOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_COPYLEADERBOARDRECORDBYUSERID_API_LATEST;
	options.UserId = requestedUserId;
	EOS_Leaderboards_LeaderboardRecord *record = nullptr;
	EOS_EResult result = EOS_Leaderboards_CopyLeaderboardRecordByUserId(leaderboards, &options, &record);
	return CopyLeaderboardRecord(record, userId, rank, score, displayName, result);
}

void bmx_eos_leaderboards_query_user_scores(EOS_HPlatform platform, EOS_HLeaderboards leaderboards,
	BBObject *request, EOS_ProductUserId localUserId, BBArray *maxUserIds,
	BBArray *maxStatNames, BBArray *maxAggregations, int64_t startTime, int64_t endTime) {
	const int userCount = maxUserIds && maxUserIds != &bbEmptyArray ? maxUserIds->scales[0] : 0;
	auto *userData = userCount
		? static_cast<void **>(BBARRAYDATA(maxUserIds, maxUserIds->dims)) : nullptr;
	std::vector<EOS_ProductUserId> userIds(userCount);
	for (int index = 0; index < userCount; ++index) {
		userIds[index] = static_cast<EOS_ProductUserId>(userData[index]);
	}
	UTF8StringArray statNames(maxStatNames);
	const int *aggregations = maxAggregations && maxAggregations != &bbEmptyArray
		? static_cast<const int *>(BBARRAYDATA(maxAggregations, maxAggregations->dims)) : nullptr;
	std::vector<EOS_Leaderboards_UserScoresQueryStatInfo> statInfo(statNames.size());
	for (std::size_t index = 0; index < statNames.size(); ++index) {
		statInfo[index].ApiVersion = EOS_LEADERBOARDS_USERSCORESQUERYSTATINFO_API_LATEST;
		statInfo[index].StatName = statNames.data()[index];
		statInfo[index].Aggregation = static_cast<EOS_ELeaderboardAggregation>(aggregations[index]);
	}
	EOS_Leaderboards_QueryLeaderboardUserScoresOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_QUERYLEADERBOARDUSERSCORES_API_LATEST;
	options.LocalUserId = localUserId;
	options.UserIds = userIds.data();
	options.UserIdsCount = static_cast<uint32_t>(userIds.size());
	options.StatInfo = statInfo.data();
	options.StatInfoCount = static_cast<uint32_t>(statInfo.size());
	options.StartTime = startTime;
	options.EndTime = endTime;
	auto *context = CreateRequest(platform, request, RequestKind::LeaderboardsQueryUserScores);
	EOS_Leaderboards_QueryLeaderboardUserScores(leaderboards, &options, context, LeaderboardsQueryUserScoresCallback);
}

int bmx_eos_leaderboards_user_score_count(EOS_HLeaderboards leaderboards, BBString *maxStatName) {
	UTF8String statName(maxStatName);
	EOS_Leaderboards_GetLeaderboardUserScoreCountOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_GETLEADERBOARDUSERSCORECOUNT_API_LATEST;
	options.StatName = statName.required();
	return static_cast<int>(EOS_Leaderboards_GetLeaderboardUserScoreCount(leaderboards, &options));
}

static EOS_EResult CopyLeaderboardUserScore(EOS_Leaderboards_LeaderboardUserScore *userScore,
	EOS_ProductUserId *userId, int *score, EOS_EResult result) {
	if (result != EOS_EResult::EOS_Success || !userScore) return result;
	*userId = userScore->UserId;
	*score = userScore->Score;
	EOS_Leaderboards_LeaderboardUserScore_Release(userScore);
	return result;
}

EOS_EResult bmx_eos_leaderboards_copy_user_score_by_index(EOS_HLeaderboards leaderboards,
	unsigned int index, BBString *maxStatName, EOS_ProductUserId *userId, int *score) {
	UTF8String statName(maxStatName);
	EOS_Leaderboards_CopyLeaderboardUserScoreByIndexOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_COPYLEADERBOARDUSERSCOREBYINDEX_API_LATEST;
	options.LeaderboardUserScoreIndex = index;
	options.StatName = statName.required();
	EOS_Leaderboards_LeaderboardUserScore *userScore = nullptr;
	EOS_EResult result = EOS_Leaderboards_CopyLeaderboardUserScoreByIndex(leaderboards, &options, &userScore);
	return CopyLeaderboardUserScore(userScore, userId, score, result);
}

EOS_EResult bmx_eos_leaderboards_copy_user_score_by_user(EOS_HLeaderboards leaderboards,
	EOS_ProductUserId requestedUserId, BBString *maxStatName, EOS_ProductUserId *userId, int *score) {
	UTF8String statName(maxStatName);
	EOS_Leaderboards_CopyLeaderboardUserScoreByUserIdOptions options{};
	options.ApiVersion = EOS_LEADERBOARDS_COPYLEADERBOARDUSERSCOREBYUSERID_API_LATEST;
	options.UserId = requestedUserId;
	options.StatName = statName.required();
	EOS_Leaderboards_LeaderboardUserScore *userScore = nullptr;
	EOS_EResult result = EOS_Leaderboards_CopyLeaderboardUserScoreByUserId(leaderboards, &options, &userScore);
	return CopyLeaderboardUserScore(userScore, userId, score, result);
}

void bmx_eos_user_info_query(EOS_HPlatform platform, EOS_HUserInfo userInfo,
	BBObject *request, EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId) {
	EOS_UserInfo_QueryUserInfoOptions options{};
	options.ApiVersion = EOS_USERINFO_QUERYUSERINFO_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	auto *context = CreateRequest(platform, request, RequestKind::UserInfoQuery);
	EOS_UserInfo_QueryUserInfo(userInfo, &options, context, UserInfoQueryCallback);
}

void bmx_eos_user_info_query_by_display_name(EOS_HPlatform platform, EOS_HUserInfo userInfo,
	BBObject *request, EOS_EpicAccountId localUserId, BBString *maxDisplayName) {
	UTF8String displayName(maxDisplayName);
	EOS_UserInfo_QueryUserInfoByDisplayNameOptions options{};
	options.ApiVersion = EOS_USERINFO_QUERYUSERINFOBYDISPLAYNAME_API_LATEST;
	options.LocalUserId = localUserId;
	options.DisplayName = displayName.required();
	auto *context = CreateRequest(platform, request, RequestKind::UserInfoQueryByDisplayName);
	EOS_UserInfo_QueryUserInfoByDisplayName(userInfo, &options, context, UserInfoQueryByDisplayNameCallback);
}

void bmx_eos_user_info_query_by_external_account(EOS_HPlatform platform, EOS_HUserInfo userInfo,
	BBObject *request, EOS_EpicAccountId localUserId, BBString *maxExternalAccountId,
	EOS_EExternalAccountType accountType) {
	UTF8String externalAccountId(maxExternalAccountId);
	EOS_UserInfo_QueryUserInfoByExternalAccountOptions options{};
	options.ApiVersion = EOS_USERINFO_QUERYUSERINFOBYEXTERNALACCOUNT_API_LATEST;
	options.LocalUserId = localUserId;
	options.ExternalAccountId = externalAccountId.required();
	options.AccountType = accountType;
	auto *context = CreateRequest(platform, request, RequestKind::UserInfoQueryByExternalAccount);
	EOS_UserInfo_QueryUserInfoByExternalAccount(userInfo, &options, context, UserInfoQueryByExternalAccountCallback);
}

EOS_EResult bmx_eos_user_info_copy(EOS_HUserInfo userInfo,
	EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId,
	EOS_EpicAccountId *userId, BBString **country, BBString **displayName,
	BBString **preferredLanguage, BBString **nickname, BBString **displayNameSanitized) {
	EOS_UserInfo_CopyUserInfoOptions options{};
	options.ApiVersion = EOS_USERINFO_COPYUSERINFO_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	EOS_UserInfo *info = nullptr;
	EOS_EResult result = EOS_UserInfo_CopyUserInfo(userInfo, &options, &info);
	if (result != EOS_EResult::EOS_Success || !info) return result;
	*userId = info->UserId;
	*country = ToBBString(info->Country);
	*displayName = ToBBString(info->DisplayName);
	*preferredLanguage = ToBBString(info->PreferredLanguage);
	*nickname = ToBBString(info->Nickname);
	*displayNameSanitized = ToBBString(info->DisplayNameSanitized);
	EOS_UserInfo_Release(info);
	return result;
}

uint32_t bmx_eos_user_info_get_external_count(EOS_HUserInfo userInfo,
	EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId) {
	EOS_UserInfo_GetExternalUserInfoCountOptions options{};
	options.ApiVersion = EOS_USERINFO_GETEXTERNALUSERINFOCOUNT_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	return EOS_UserInfo_GetExternalUserInfoCount(userInfo, &options);
}

static EOS_EResult CopyExternalUserInfo(EOS_UserInfo_ExternalUserInfo *info, EOS_EResult result,
	EOS_EExternalAccountType *accountType, BBString **accountId, BBString **displayName,
	BBString **displayNameSanitized) {
	if (result != EOS_EResult::EOS_Success || !info) return result;
	*accountType = info->AccountType;
	*accountId = ToBBString(info->AccountId);
	*displayName = ToBBString(info->DisplayName);
	*displayNameSanitized = ToBBString(info->DisplayNameSanitized);
	EOS_UserInfo_ExternalUserInfo_Release(info);
	return result;
}

EOS_EResult bmx_eos_user_info_copy_external_by_index(EOS_HUserInfo userInfo,
	EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId, uint32_t index,
	EOS_EExternalAccountType *accountType, BBString **accountId, BBString **displayName,
	BBString **displayNameSanitized) {
	EOS_UserInfo_CopyExternalUserInfoByIndexOptions options{};
	options.ApiVersion = EOS_USERINFO_COPYEXTERNALUSERINFOBYINDEX_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	options.Index = index;
	EOS_UserInfo_ExternalUserInfo *info = nullptr;
	EOS_EResult result = EOS_UserInfo_CopyExternalUserInfoByIndex(userInfo, &options, &info);
	return CopyExternalUserInfo(info, result, accountType, accountId, displayName, displayNameSanitized);
}

EOS_EResult bmx_eos_user_info_copy_external_by_type(EOS_HUserInfo userInfo,
	EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId, EOS_EExternalAccountType requestedType,
	EOS_EExternalAccountType *accountType, BBString **accountId, BBString **displayName,
	BBString **displayNameSanitized) {
	EOS_UserInfo_CopyExternalUserInfoByAccountTypeOptions options{};
	options.ApiVersion = EOS_USERINFO_COPYEXTERNALUSERINFOBYACCOUNTTYPE_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	options.AccountType = requestedType;
	EOS_UserInfo_ExternalUserInfo *info = nullptr;
	EOS_EResult result = EOS_UserInfo_CopyExternalUserInfoByAccountType(userInfo, &options, &info);
	return CopyExternalUserInfo(info, result, accountType, accountId, displayName, displayNameSanitized);
}

EOS_EResult bmx_eos_user_info_copy_external_by_id(EOS_HUserInfo userInfo,
	EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId, BBString *maxRequestedAccountId,
	EOS_EExternalAccountType *accountType, BBString **accountId, BBString **displayName,
	BBString **displayNameSanitized) {
	UTF8String requestedAccountId(maxRequestedAccountId);
	EOS_UserInfo_CopyExternalUserInfoByAccountIdOptions options{};
	options.ApiVersion = EOS_USERINFO_COPYEXTERNALUSERINFOBYACCOUNTID_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	options.AccountId = requestedAccountId.required();
	EOS_UserInfo_ExternalUserInfo *info = nullptr;
	EOS_EResult result = EOS_UserInfo_CopyExternalUserInfoByAccountId(userInfo, &options, &info);
	return CopyExternalUserInfo(info, result, accountType, accountId, displayName, displayNameSanitized);
}

void bmx_eos_friends_query(EOS_HPlatform platform, EOS_HFriends friends,
	BBObject *request, EOS_EpicAccountId localUserId) {
	EOS_Friends_QueryFriendsOptions options{};
	options.ApiVersion = EOS_FRIENDS_QUERYFRIENDS_API_LATEST;
	options.LocalUserId = localUserId;
	auto *context = CreateRequest(platform, request, RequestKind::FriendsQuery);
	EOS_Friends_QueryFriends(friends, &options, context, FriendsQueryCallback);
}

int32_t bmx_eos_friends_get_count(EOS_HFriends friends, EOS_EpicAccountId localUserId) {
	EOS_Friends_GetFriendsCountOptions options{};
	options.ApiVersion = EOS_FRIENDS_GETFRIENDSCOUNT_API_LATEST;
	options.LocalUserId = localUserId;
	return EOS_Friends_GetFriendsCount(friends, &options);
}

EOS_EpicAccountId bmx_eos_friends_get_by_index(EOS_HFriends friends,
	EOS_EpicAccountId localUserId, int32_t index) {
	EOS_Friends_GetFriendAtIndexOptions options{};
	options.ApiVersion = EOS_FRIENDS_GETFRIENDATINDEX_API_LATEST;
	options.LocalUserId = localUserId;
	options.Index = index;
	return EOS_Friends_GetFriendAtIndex(friends, &options);
}

EOS_EFriendsStatus bmx_eos_friends_get_status(EOS_HFriends friends,
	EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId) {
	EOS_Friends_GetStatusOptions options{};
	options.ApiVersion = EOS_FRIENDS_GETSTATUS_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	return EOS_Friends_GetStatus(friends, &options);
}

int32_t bmx_eos_friends_get_blocked_count(EOS_HFriends friends, EOS_EpicAccountId localUserId) {
	EOS_Friends_GetBlockedUsersCountOptions options{};
	options.ApiVersion = EOS_FRIENDS_GETBLOCKEDUSERSCOUNT_API_LATEST;
	options.LocalUserId = localUserId;
	return EOS_Friends_GetBlockedUsersCount(friends, &options);
}

EOS_EpicAccountId bmx_eos_friends_get_blocked_by_index(EOS_HFriends friends,
	EOS_EpicAccountId localUserId, int32_t index) {
	EOS_Friends_GetBlockedUserAtIndexOptions options{};
	options.ApiVersion = EOS_FRIENDS_GETBLOCKEDUSERATINDEX_API_LATEST;
	options.LocalUserId = localUserId;
	options.Index = index;
	return EOS_Friends_GetBlockedUserAtIndex(friends, &options);
}

uint64_t bmx_eos_friends_add_notify_update(EOS_HPlatform platform, EOS_HFriends friends,
	BBObject *subscription) {
	auto *context = new FriendsNotificationContext(platform, friends,
		FriendsNotificationKind::FriendsUpdate, subscription);
	EOS_Friends_AddNotifyFriendsUpdateOptions options{};
	options.ApiVersion = EOS_FRIENDS_ADDNOTIFYFRIENDSUPDATE_API_LATEST;
	context->id = EOS_Friends_AddNotifyFriendsUpdate(friends, &options, context, FriendsUpdateCallback);
	if (context->id == EOS_INVALID_NOTIFICATIONID) { delete context; return 0; }
	g_friendsNotifications.push_back(context);
	return context->id;
}

uint64_t bmx_eos_friends_add_notify_blocked(EOS_HPlatform platform, EOS_HFriends friends,
	BBObject *subscription) {
	auto *context = new FriendsNotificationContext(platform, friends,
		FriendsNotificationKind::BlockedUsersUpdate, subscription);
	EOS_Friends_AddNotifyBlockedUsersUpdateOptions options{};
	options.ApiVersion = EOS_FRIENDS_ADDNOTIFYBLOCKEDUSERSUPDATE_API_LATEST;
	context->id = EOS_Friends_AddNotifyBlockedUsersUpdate(friends, &options, context, BlockedUsersUpdateCallback);
	if (context->id == EOS_INVALID_NOTIFICATIONID) { delete context; return 0; }
	g_friendsNotifications.push_back(context);
	return context->id;
}

void bmx_eos_friends_remove_notify(uint64_t id) {
	auto found = std::find_if(g_friendsNotifications.begin(), g_friendsNotifications.end(),
		[id](const FriendsNotificationContext *context) { return context->id == id; });
	if (found != g_friendsNotifications.end()) RemoveFriendsNotification(*found);
}

void bmx_eos_presence_query(EOS_HPlatform platform, EOS_HPresence presence,
	BBObject *request, EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId) {
	EOS_Presence_QueryPresenceOptions options{};
	options.ApiVersion = EOS_PRESENCE_QUERYPRESENCE_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	auto *context = CreateRequest(platform, request, RequestKind::PresenceQuery);
	EOS_Presence_QueryPresence(presence, &options, context, PresenceQueryCallback);
}

int bmx_eos_presence_has(EOS_HPresence presence,
	EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId) {
	EOS_Presence_HasPresenceOptions options{};
	options.ApiVersion = EOS_PRESENCE_HASPRESENCE_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	return EOS_Presence_HasPresence(presence, &options) == EOS_TRUE;
}

EOS_EResult bmx_eos_presence_copy(EOS_HPresence presence,
	EOS_EpicAccountId localUserId, EOS_EpicAccountId targetUserId,
	EOS_Presence_EStatus *status, EOS_EpicAccountId *userId, BBString **productId,
	BBString **productVersion, BBString **platform, BBString **richText,
	BBString **productName, BBString **integratedPlatform, BBArray **recordKeys,
	BBArray **recordValues) {
	EOS_Presence_CopyPresenceOptions options{};
	options.ApiVersion = EOS_PRESENCE_COPYPRESENCE_API_LATEST;
	options.LocalUserId = localUserId;
	options.TargetUserId = targetUserId;
	EOS_Presence_Info *info = nullptr;
	EOS_EResult result = EOS_Presence_CopyPresence(presence, &options, &info);
	if (result != EOS_EResult::EOS_Success || !info) return result;
	*status = info->Status;
	*userId = info->UserId;
	*productId = ToBBString(info->ProductId);
	*productVersion = ToBBString(info->ProductVersion);
	*platform = ToBBString(info->Platform);
	*richText = ToBBString(info->RichText);
	*productName = ToBBString(info->ProductName);
	*integratedPlatform = ToBBString(info->IntegratedPlatform);
	std::vector<const char *> keys;
	std::vector<const char *> values;
	keys.reserve(info->RecordsCount);
	values.reserve(info->RecordsCount);
	for (int32_t index = 0; index < info->RecordsCount; ++index) {
		keys.push_back(info->Records[index].Key);
		values.push_back(info->Records[index].Value);
	}
	*recordKeys = StringArray(keys);
	*recordValues = StringArray(values);
	EOS_Presence_Info_Release(info);
	return result;
}

EOS_EResult bmx_eos_presence_create_modification(EOS_HPresence presence,
	EOS_EpicAccountId localUserId, EOS_HPresenceModification *modification) {
	EOS_Presence_CreatePresenceModificationOptions options{};
	options.ApiVersion = EOS_PRESENCE_CREATEPRESENCEMODIFICATION_API_LATEST;
	options.LocalUserId = localUserId;
	return EOS_Presence_CreatePresenceModification(presence, &options, modification);
}

void bmx_eos_presence_modification_release(EOS_HPresenceModification modification) {
	if (modification) EOS_PresenceModification_Release(modification);
}

EOS_EResult bmx_eos_presence_modification_set_status(EOS_HPresenceModification modification,
	EOS_Presence_EStatus status) {
	EOS_PresenceModification_SetStatusOptions options{};
	options.ApiVersion = EOS_PRESENCEMODIFICATION_SETSTATUS_API_LATEST;
	options.Status = status;
	return EOS_PresenceModification_SetStatus(modification, &options);
}

EOS_EResult bmx_eos_presence_modification_set_rich_text(EOS_HPresenceModification modification,
	BBString *maxRichText) {
	UTF8String richText(maxRichText);
	EOS_PresenceModification_SetRawRichTextOptions options{};
	options.ApiVersion = EOS_PRESENCEMODIFICATION_SETRAWRICHTEXT_API_LATEST;
	options.RichText = richText.optional();
	return EOS_PresenceModification_SetRawRichText(modification, &options);
}

EOS_EResult bmx_eos_presence_modification_set_join_info(EOS_HPresenceModification modification,
	BBString *maxJoinInfo) {
	UTF8String joinInfo(maxJoinInfo);
	EOS_PresenceModification_SetJoinInfoOptions options{};
	options.ApiVersion = EOS_PRESENCEMODIFICATION_SETJOININFO_API_LATEST;
	options.JoinInfo = joinInfo.optional();
	return EOS_PresenceModification_SetJoinInfo(modification, &options);
}

void bmx_eos_presence_set(EOS_HPlatform platform, EOS_HPresence presence, BBObject *request,
	EOS_EpicAccountId localUserId, EOS_HPresenceModification modification) {
	EOS_Presence_SetPresenceOptions options{};
	options.ApiVersion = EOS_PRESENCE_SETPRESENCE_API_LATEST;
	options.LocalUserId = localUserId;
	options.PresenceModificationHandle = modification;
	auto *context = CreateRequest(platform, request, RequestKind::PresenceSet);
	EOS_Presence_SetPresence(presence, &options, context, PresenceSetCallback);
}

uint64_t bmx_eos_presence_add_notify_changed(EOS_HPlatform platform, EOS_HPresence presence,
	BBObject *subscription) {
	auto *context = new PresenceNotificationContext(platform, presence, subscription);
	EOS_Presence_AddNotifyOnPresenceChangedOptions options{};
	options.ApiVersion = EOS_PRESENCE_ADDNOTIFYONPRESENCECHANGED_API_LATEST;
	context->id = EOS_Presence_AddNotifyOnPresenceChanged(presence, &options, context, PresenceChangedCallback);
	if (context->id == EOS_INVALID_NOTIFICATIONID) { delete context; return 0; }
	g_presenceNotifications.push_back(context);
	return context->id;
}

void bmx_eos_presence_remove_notify_changed(uint64_t id) {
	auto found = std::find_if(g_presenceNotifications.begin(), g_presenceNotifications.end(),
		[id](const PresenceNotificationContext *context) { return context->id == id; });
	if (found != g_presenceNotifications.end()) RemovePresenceNotification(*found);
}

int bmx_eos_auth_get_login_status(EOS_HAuth auth, EOS_EpicAccountId localUserId) {
	return static_cast<int>(EOS_Auth_GetLoginStatus(auth, localUserId));
}

uint64_t bmx_eos_auth_add_notify_login_status(EOS_HPlatform platform, EOS_HAuth auth,
	BBObject *subscription) {
	auto *context = new LoginNotificationContext(platform, auth, nullptr,
		LoginNotificationKind::AuthStatus, subscription);
	EOS_Auth_AddNotifyLoginStatusChangedOptions options{};
	options.ApiVersion = EOS_AUTH_ADDNOTIFYLOGINSTATUSCHANGED_API_LATEST;
	context->id = EOS_Auth_AddNotifyLoginStatusChanged(auth, &options, context, AuthLoginStatusCallback);
	if (context->id == EOS_INVALID_NOTIFICATIONID) { delete context; return 0; }
	g_loginNotifications.push_back(context);
	return context->id;
}

int bmx_eos_connect_get_login_status(EOS_HConnect connect, EOS_ProductUserId localUserId) {
	return static_cast<int>(EOS_Connect_GetLoginStatus(connect, localUserId));
}

uint64_t bmx_eos_connect_add_notify_auth_expiration(EOS_HPlatform platform, EOS_HConnect connect,
	BBObject *subscription) {
	auto *context = new LoginNotificationContext(platform, nullptr, connect,
		LoginNotificationKind::ConnectExpiration, subscription);
	EOS_Connect_AddNotifyAuthExpirationOptions options{};
	options.ApiVersion = EOS_CONNECT_ADDNOTIFYAUTHEXPIRATION_API_LATEST;
	context->id = EOS_Connect_AddNotifyAuthExpiration(connect, &options, context, ConnectAuthExpirationCallback);
	if (context->id == EOS_INVALID_NOTIFICATIONID) { delete context; return 0; }
	g_loginNotifications.push_back(context);
	return context->id;
}

uint64_t bmx_eos_connect_add_notify_login_status(EOS_HPlatform platform, EOS_HConnect connect,
	BBObject *subscription) {
	auto *context = new LoginNotificationContext(platform, nullptr, connect,
		LoginNotificationKind::ConnectStatus, subscription);
	EOS_Connect_AddNotifyLoginStatusChangedOptions options{};
	options.ApiVersion = EOS_CONNECT_ADDNOTIFYLOGINSTATUSCHANGED_API_LATEST;
	context->id = EOS_Connect_AddNotifyLoginStatusChanged(connect, &options, context, ConnectLoginStatusCallback);
	if (context->id == EOS_INVALID_NOTIFICATIONID) { delete context; return 0; }
	g_loginNotifications.push_back(context);
	return context->id;
}

void bmx_eos_login_remove_notify(uint64_t id) {
	auto found = std::find_if(g_loginNotifications.begin(), g_loginNotifications.end(),
		[id](const LoginNotificationContext *context) { return context->id == id; });
	if (found != g_loginNotifications.end()) RemoveLoginNotification(*found);
}

void bmx_eos_lobby_create(EOS_HPlatform platform, EOS_HLobby lobby, BBObject *request,
	EOS_ProductUserId localUserId, unsigned int maxMembers, EOS_ELobbyPermissionLevel permissionLevel,
	int presenceEnabled, int allowInvites, BBString *maxBucketId, int disableHostMigration,
	int enableRtcRoom, int enableJoinById, int rejoinAfterKickRequiresInvite, int crossplayOptOut) {
	UTF8String bucketId(maxBucketId);
	EOS_Lobby_CreateLobbyOptions options{};
	options.ApiVersion = EOS_LOBBY_CREATELOBBY_API_LATEST;
	options.LocalUserId = localUserId;
	options.MaxLobbyMembers = maxMembers;
	options.PermissionLevel = permissionLevel;
	options.bPresenceEnabled = presenceEnabled ? EOS_TRUE : EOS_FALSE;
	options.bAllowInvites = allowInvites ? EOS_TRUE : EOS_FALSE;
	options.BucketId = bucketId.required();
	options.bDisableHostMigration = disableHostMigration ? EOS_TRUE : EOS_FALSE;
	options.bEnableRTCRoom = enableRtcRoom ? EOS_TRUE : EOS_FALSE;
	options.LocalRTCOptions = nullptr;
	options.LobbyId = nullptr;
	options.bEnableJoinById = enableJoinById ? EOS_TRUE : EOS_FALSE;
	options.bRejoinAfterKickRequiresInvite = rejoinAfterKickRequiresInvite ? EOS_TRUE : EOS_FALSE;
	options.AllowedPlatformIds = nullptr;
	options.AllowedPlatformIdsCount = 0;
	options.bCrossplayOptOut = crossplayOptOut ? EOS_TRUE : EOS_FALSE;
	options.RTCRoomJoinActionType = EOS_ELobbyRTCRoomJoinActionType::EOS_LRRJAT_AutomaticJoin;
	auto *context = CreateRequest(platform, request, RequestKind::LobbyCreate);
	EOS_Lobby_CreateLobby(lobby, &options, context, LobbyCreateCallback);
}

void bmx_eos_lobby_destroy(EOS_HPlatform platform, EOS_HLobby lobby, BBObject *request,
	EOS_ProductUserId localUserId, BBString *maxLobbyId) {
	UTF8String lobbyId(maxLobbyId);
	EOS_Lobby_DestroyLobbyOptions options{};
	options.ApiVersion = EOS_LOBBY_DESTROYLOBBY_API_LATEST;
	options.LocalUserId = localUserId;
	options.LobbyId = lobbyId.required();
	auto *context = CreateRequest(platform, request, RequestKind::LobbyDestroy);
	EOS_Lobby_DestroyLobby(lobby, &options, context, LobbyDestroyCallback);
}

void bmx_eos_lobby_leave(EOS_HPlatform platform, EOS_HLobby lobby, BBObject *request,
	EOS_ProductUserId localUserId, BBString *maxLobbyId) {
	UTF8String lobbyId(maxLobbyId);
	EOS_Lobby_LeaveLobbyOptions options{};
	options.ApiVersion = EOS_LOBBY_LEAVELOBBY_API_LATEST;
	options.LocalUserId = localUserId;
	options.LobbyId = lobbyId.required();
	auto *context = CreateRequest(platform, request, RequestKind::LobbyLeave);
	EOS_Lobby_LeaveLobby(lobby, &options, context, LobbyLeaveCallback);
}

void bmx_eos_lobby_join(EOS_HPlatform platform, EOS_HLobby lobby, BBObject *request,
	EOS_HLobbyDetails details, EOS_ProductUserId localUserId, int presenceEnabled,
	int crossplayOptOut) {
	EOS_Lobby_JoinLobbyOptions options{};
	options.ApiVersion = EOS_LOBBY_JOINLOBBY_API_LATEST;
	options.LobbyDetailsHandle = details;
	options.LocalUserId = localUserId;
	options.bPresenceEnabled = presenceEnabled ? EOS_TRUE : EOS_FALSE;
	options.LocalRTCOptions = nullptr;
	options.bCrossplayOptOut = crossplayOptOut ? EOS_TRUE : EOS_FALSE;
	options.RTCRoomJoinActionType = EOS_ELobbyRTCRoomJoinActionType::EOS_LRRJAT_AutomaticJoin;
	auto *context = CreateRequest(platform, request, RequestKind::LobbyJoin);
	EOS_Lobby_JoinLobby(lobby, &options, context, LobbyJoinCallback);
}

EOS_EResult bmx_eos_lobby_create_search(EOS_HLobby lobby, unsigned int maxResults,
	EOS_HLobbySearch *searchHandle) {
	EOS_Lobby_CreateLobbySearchOptions options{};
	options.ApiVersion = EOS_LOBBY_CREATELOBBYSEARCH_API_LATEST;
	options.MaxResults = maxResults;
	return EOS_Lobby_CreateLobbySearch(lobby, &options, searchHandle);
}

void bmx_eos_lobby_search_release(EOS_HLobbySearch search) {
	if (search) EOS_LobbySearch_Release(search);
}

EOS_EResult bmx_eos_lobby_search_set_lobby_id(EOS_HLobbySearch search, BBString *maxLobbyId) {
	UTF8String lobbyId(maxLobbyId);
	EOS_LobbySearch_SetLobbyIdOptions options{};
	options.ApiVersion = EOS_LOBBYSEARCH_SETLOBBYID_API_LATEST;
	options.LobbyId = lobbyId.required();
	return EOS_LobbySearch_SetLobbyId(search, &options);
}

EOS_EResult bmx_eos_lobby_search_set_target_user(EOS_HLobbySearch search,
	EOS_ProductUserId targetUserId) {
	EOS_LobbySearch_SetTargetUserIdOptions options{};
	options.ApiVersion = EOS_LOBBYSEARCH_SETTARGETUSERID_API_LATEST;
	options.TargetUserId = targetUserId;
	return EOS_LobbySearch_SetTargetUserId(search, &options);
}

EOS_EResult bmx_eos_lobby_search_set_string_parameter(EOS_HLobbySearch search,
	BBString *maxKey, BBString *maxValue, EOS_EComparisonOp comparison) {
	UTF8String key(maxKey);
	UTF8String value(maxValue);
	EOS_Lobby_AttributeData attribute{};
	attribute.ApiVersion = EOS_LOBBY_ATTRIBUTEDATA_API_LATEST;
	attribute.Key = key.required();
	attribute.Value.AsUtf8 = value.required();
	attribute.ValueType = EOS_EAttributeType::EOS_AT_STRING;
	EOS_LobbySearch_SetParameterOptions options{};
	options.ApiVersion = EOS_LOBBYSEARCH_SETPARAMETER_API_LATEST;
	options.Parameter = &attribute;
	options.ComparisonOp = comparison;
	return EOS_LobbySearch_SetParameter(search, &options);
}

EOS_EResult bmx_eos_lobby_search_set_max_results(EOS_HLobbySearch search,
	unsigned int maxResults) {
	EOS_LobbySearch_SetMaxResultsOptions options{};
	options.ApiVersion = EOS_LOBBYSEARCH_SETMAXRESULTS_API_LATEST;
	options.MaxResults = maxResults;
	return EOS_LobbySearch_SetMaxResults(search, &options);
}

void bmx_eos_lobby_search_find(EOS_HPlatform platform, EOS_HLobbySearch search,
	BBObject *request, EOS_ProductUserId localUserId) {
	EOS_LobbySearch_FindOptions options{};
	options.ApiVersion = EOS_LOBBYSEARCH_FIND_API_LATEST;
	options.LocalUserId = localUserId;
	auto *context = CreateRequest(platform, request, RequestKind::LobbySearchFind);
	EOS_LobbySearch_Find(search, &options, context, LobbySearchFindCallback);
}

unsigned int bmx_eos_lobby_search_get_result_count(EOS_HLobbySearch search) {
	EOS_LobbySearch_GetSearchResultCountOptions options{};
	options.ApiVersion = EOS_LOBBYSEARCH_GETSEARCHRESULTCOUNT_API_LATEST;
	return EOS_LobbySearch_GetSearchResultCount(search, &options);
}

EOS_EResult bmx_eos_lobby_search_copy_result(EOS_HLobbySearch search,
	unsigned int index, EOS_HLobbyDetails *detailsHandle) {
	EOS_LobbySearch_CopySearchResultByIndexOptions options{};
	options.ApiVersion = EOS_LOBBYSEARCH_COPYSEARCHRESULTBYINDEX_API_LATEST;
	options.LobbyIndex = index;
	return EOS_LobbySearch_CopySearchResultByIndex(search, &options, detailsHandle);
}

EOS_EResult bmx_eos_lobby_copy_details(EOS_HLobby lobby, EOS_ProductUserId localUserId,
	BBString *maxLobbyId, EOS_HLobbyDetails *detailsHandle) {
	UTF8String lobbyId(maxLobbyId);
	EOS_Lobby_CopyLobbyDetailsHandleOptions options{};
	options.ApiVersion = EOS_LOBBY_COPYLOBBYDETAILSHANDLE_API_LATEST;
	options.LocalUserId = localUserId;
	options.LobbyId = lobbyId.required();
	return EOS_Lobby_CopyLobbyDetailsHandle(lobby, &options, detailsHandle);
}

void bmx_eos_lobby_details_release(EOS_HLobbyDetails details) {
	if (details) EOS_LobbyDetails_Release(details);
}

EOS_EResult bmx_eos_lobby_details_copy_info(EOS_HLobbyDetails details,
	BBString **lobbyId, EOS_ProductUserId *ownerUserId, EOS_ELobbyPermissionLevel *permissionLevel,
	unsigned int *availableSlots, unsigned int *maxMembers, int *allowInvites, BBString **bucketId,
	int *allowHostMigration, int *rtcRoomEnabled, int *allowJoinById,
	int *rejoinAfterKickRequiresInvite, int *presenceEnabled, BBArray **allowedPlatformIds) {
	EOS_LobbyDetails_CopyInfoOptions options{};
	options.ApiVersion = EOS_LOBBYDETAILS_COPYINFO_API_LATEST;
	EOS_LobbyDetails_Info *info = nullptr;
	EOS_EResult result = EOS_LobbyDetails_CopyInfo(details, &options, &info);
	if (result != EOS_EResult::EOS_Success || !info) return result;
	*lobbyId = ToBBString(info->LobbyId);
	*ownerUserId = info->LobbyOwnerUserId;
	*permissionLevel = info->PermissionLevel;
	*availableSlots = info->AvailableSlots;
	*maxMembers = info->MaxMembers;
	*allowInvites = info->bAllowInvites == EOS_TRUE;
	*bucketId = ToBBString(info->BucketId);
	*allowHostMigration = info->bAllowHostMigration == EOS_TRUE;
	*rtcRoomEnabled = info->bRTCRoomEnabled == EOS_TRUE;
	*allowJoinById = info->bAllowJoinById == EOS_TRUE;
	*rejoinAfterKickRequiresInvite = info->bRejoinAfterKickRequiresInvite == EOS_TRUE;
	*presenceEnabled = info->bPresenceEnabled == EOS_TRUE;
	std::vector<int> platforms;
	platforms.reserve(info->AllowedPlatformIdsCount);
	for (uint32_t index = 0; index < info->AllowedPlatformIdsCount; ++index) {
		platforms.push_back(static_cast<int>(info->AllowedPlatformIds[index]));
	}
	*allowedPlatformIds = IntArray(platforms);
	EOS_LobbyDetails_Info_Release(info);
	return result;
}

unsigned int bmx_eos_lobby_details_get_member_count(EOS_HLobbyDetails details) {
	EOS_LobbyDetails_GetMemberCountOptions options{};
	options.ApiVersion = EOS_LOBBYDETAILS_GETMEMBERCOUNT_API_LATEST;
	return EOS_LobbyDetails_GetMemberCount(details, &options);
}

EOS_ProductUserId bmx_eos_lobby_details_get_member_by_index(EOS_HLobbyDetails details,
	unsigned int index) {
	EOS_LobbyDetails_GetMemberByIndexOptions options{};
	options.ApiVersion = EOS_LOBBYDETAILS_GETMEMBERBYINDEX_API_LATEST;
	options.MemberIndex = index;
	return EOS_LobbyDetails_GetMemberByIndex(details, &options);
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
