/* Copyright (c) 2026 Bruce A Henderson. Licensed under zlib/libpng. */

#include <brl.mod/blitz.mod/blitz.h>

#include "../SDK/Include/eos_sdk.h"
#include "../SDK/Include/eos_sessions.h"

#include <algorithm>
#include <cstdint>
#include <vector>

extern "C" {
void eos_sdk_TEOSSessionUpdateRequest__Complete(
	BBObject *, EOS_EResult, BBString *, BBString *);
void eos_sdk_TEOSSessionUpdateRequest__Cancel(BBObject *);
void eos_sdk_TEOSSessionOperationRequest__Complete(BBObject *, EOS_EResult);
void eos_sdk_TEOSSessionOperationRequest__Cancel(BBObject *);
void eos_sdk_TEOSSessionSearchRequest__Complete(BBObject *, EOS_EResult);
void eos_sdk_TEOSSessionSearchRequest__Cancel(BBObject *);
void eos_sdk_TEOSSessionPlayersRequest__Complete(BBObject *, EOS_EResult, int, int);
void eos_sdk_TEOSSessionPlayersRequest__Cancel(BBObject *);
void eos_sdk_TEOSSessionInviteReceivedSubscription__Notify(
	BBObject *, BBString *, EOS_ProductUserId, EOS_ProductUserId);
void eos_sdk_TEOSSessionInviteReceivedSubscription__Cancel(BBObject *);
void eos_sdk_TEOSSessionInviteAcceptedSubscription__Notify(
	BBObject *, BBString *, BBString *, EOS_ProductUserId, EOS_ProductUserId);
void eos_sdk_TEOSSessionInviteAcceptedSubscription__Cancel(BBObject *);
void eos_sdk_TEOSSessionInviteRejectedSubscription__Notify(
	BBObject *, BBString *, BBString *, EOS_ProductUserId, EOS_ProductUserId);
void eos_sdk_TEOSSessionInviteRejectedSubscription__Cancel(BBObject *);
void eos_sdk_TEOSJoinSessionAcceptedSubscription__Notify(
	BBObject *, EOS_ProductUserId, uint64_t);
void eos_sdk_TEOSJoinSessionAcceptedSubscription__Cancel(BBObject *);
void eos_sdk_TEOSLeaveSessionRequestedSubscription__Notify(
	BBObject *, EOS_ProductUserId, BBString *);
void eos_sdk_TEOSLeaveSessionRequestedSubscription__Cancel(BBObject *);
}

namespace {

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
		return required()[0] ? required() : nullptr;
	}

private:
	unsigned char *data_;
};

BBString *ToBBString(const char *value) {
	return bbStringFromUTF8String(
		reinterpret_cast<const unsigned char *>(value ? value : ""));
}

BBArray *IntArray(const uint32_t *values, uint32_t count) {
	BBArray *array = bbArrayNew1D("i", static_cast<int>(count));
	int *data = static_cast<int *>(BBARRAYDATA(array, array->dims));
	for (uint32_t index = 0; index < count; ++index) {
		data[index] = static_cast<int>(values[index]);
	}
	return array;
}

const uint32_t *IntArrayData(BBArray *array, uint32_t &count) {
	count = 0;
	if (!array || array == &bbEmptyArray || array->dims != 1) {
		return nullptr;
	}
	count = static_cast<uint32_t>(array->scales[0]);
	return reinterpret_cast<const uint32_t *>(BBARRAYDATA(array, array->dims));
}

std::vector<EOS_ProductUserId> ProductUsers(BBArray *array) {
	if (!array || array == &bbEmptyArray || array->dims != 1) {
		return {};
	}
	const int count = array->scales[0];
	auto **data = static_cast<void **>(BBARRAYDATA(array, array->dims));
	std::vector<EOS_ProductUserId> users(static_cast<std::size_t>(count));
	for (int index = 0; index < count; ++index) {
		users[static_cast<std::size_t>(index)] =
			static_cast<EOS_ProductUserId>(data[index]);
	}
	return users;
}

enum class RequestKind {
	Update,
	Operation,
	Search,
	Players
};

struct RequestContext {
	EOS_HPlatform platform;
	BBObject *request;
	RequestKind kind;

	RequestContext(EOS_HPlatform platformValue, BBObject *requestValue, RequestKind kindValue)
		: platform(platformValue), request(requestValue), kind(kindValue) {
		BBRETAIN(request);
	}

	~RequestContext() {
		BBRELEASE(request);
	}
};

std::vector<RequestContext *> g_requests;

enum class NotificationKind {
	InviteReceived,
	InviteAccepted,
	InviteRejected,
	JoinAccepted,
	LeaveRequested
};

struct NotificationContext {
	EOS_HPlatform platform;
	EOS_HSessions sessions;
	EOS_NotificationId id;
	NotificationKind kind;
	BBObject *subscription;

	NotificationContext(
		EOS_HPlatform platformValue,
		EOS_HSessions sessionsValue,
		NotificationKind kindValue,
		BBObject *subscriptionValue)
		: platform(platformValue), sessions(sessionsValue),
		  id(EOS_INVALID_NOTIFICATIONID), kind(kindValue),
		  subscription(subscriptionValue) {
		BBRETAIN(subscription);
	}

	~NotificationContext() {
		BBRELEASE(subscription);
	}
};

std::vector<NotificationContext *> g_notifications;

void RemoveNotification(NotificationContext *context) {
	if (!context) {
		return;
	}
	if (context->id != EOS_INVALID_NOTIFICATIONID) {
		switch (context->kind) {
		case NotificationKind::InviteReceived:
			EOS_Sessions_RemoveNotifySessionInviteReceived(context->sessions, context->id);
			break;
		case NotificationKind::InviteAccepted:
			EOS_Sessions_RemoveNotifySessionInviteAccepted(context->sessions, context->id);
			break;
		case NotificationKind::InviteRejected:
			EOS_Sessions_RemoveNotifySessionInviteRejected(context->sessions, context->id);
			break;
		case NotificationKind::JoinAccepted:
			EOS_Sessions_RemoveNotifyJoinSessionAccepted(context->sessions, context->id);
			break;
		case NotificationKind::LeaveRequested:
			EOS_Sessions_RemoveNotifyLeaveSessionRequested(context->sessions, context->id);
			break;
		}
	}
	auto found = std::find(g_notifications.begin(), g_notifications.end(), context);
	if (found != g_notifications.end()) {
		g_notifications.erase(found);
	}
	delete context;
}

RequestContext *CreateRequest(
	EOS_HPlatform platform, BBObject *request, RequestKind kind) {
	auto *context = new RequestContext(platform, request, kind);
	g_requests.push_back(context);
	return context;
}

bool FinishRequest(RequestContext *context, EOS_EResult result) {
	if (!EOS_EResult_IsOperationComplete(result)) {
		return false;
	}
	auto found = std::find(g_requests.begin(), g_requests.end(), context);
	if (found != g_requests.end()) {
		g_requests.erase(found);
	}
	return true;
}

void EOS_CALL UpdateComplete(const EOS_Sessions_UpdateSessionCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = FinishRequest(context, data->ResultCode);
	eos_sdk_TEOSSessionUpdateRequest__Complete(
		context->request, data->ResultCode,
		ToBBString(data->SessionName), ToBBString(data->SessionId));
	if (terminal) {
		delete context;
	}
}

template <typename T>
void CompleteOperation(const T *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = FinishRequest(context, data->ResultCode);
	eos_sdk_TEOSSessionOperationRequest__Complete(context->request, data->ResultCode);
	if (terminal) {
		delete context;
	}
}

void EOS_CALL DestroyComplete(const EOS_Sessions_DestroySessionCallbackInfo *data) {
	CompleteOperation(data);
}

void EOS_CALL JoinComplete(const EOS_Sessions_JoinSessionCallbackInfo *data) {
	CompleteOperation(data);
}

void EOS_CALL StartComplete(const EOS_Sessions_StartSessionCallbackInfo *data) {
	CompleteOperation(data);
}

void EOS_CALL EndComplete(const EOS_Sessions_EndSessionCallbackInfo *data) {
	CompleteOperation(data);
}

void EOS_CALL SendInviteComplete(const EOS_Sessions_SendInviteCallbackInfo *data) {
	CompleteOperation(data);
}

void EOS_CALL RejectInviteComplete(const EOS_Sessions_RejectInviteCallbackInfo *data) {
	CompleteOperation(data);
}

void EOS_CALL QueryInvitesComplete(const EOS_Sessions_QueryInvitesCallbackInfo *data) {
	CompleteOperation(data);
}

void EOS_CALL SearchComplete(const EOS_SessionSearch_FindCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = FinishRequest(context, data->ResultCode);
	eos_sdk_TEOSSessionSearchRequest__Complete(context->request, data->ResultCode);
	if (terminal) {
		delete context;
	}
}

void EOS_CALL RegisterComplete(const EOS_Sessions_RegisterPlayersCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = FinishRequest(context, data->ResultCode);
	eos_sdk_TEOSSessionPlayersRequest__Complete(
		context->request, data->ResultCode,
		static_cast<int>(data->RegisteredPlayersCount),
		static_cast<int>(data->SanctionedPlayersCount));
	if (terminal) {
		delete context;
	}
}

void EOS_CALL UnregisterComplete(const EOS_Sessions_UnregisterPlayersCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = FinishRequest(context, data->ResultCode);
	eos_sdk_TEOSSessionPlayersRequest__Complete(
		context->request, data->ResultCode,
		static_cast<int>(data->UnregisteredPlayersCount), 0);
	if (terminal) {
		delete context;
	}
}

void EOS_CALL InviteReceived(
	const EOS_Sessions_SessionInviteReceivedCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<NotificationContext *>(data->ClientData);
	eos_sdk_TEOSSessionInviteReceivedSubscription__Notify(
		context->subscription, ToBBString(data->InviteId),
		data->LocalUserId, data->TargetUserId);
}

void EOS_CALL InviteAccepted(
	const EOS_Sessions_SessionInviteAcceptedCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<NotificationContext *>(data->ClientData);
	eos_sdk_TEOSSessionInviteAcceptedSubscription__Notify(
		context->subscription, ToBBString(data->SessionId), ToBBString(data->InviteId),
		data->LocalUserId, data->TargetUserId);
}

void EOS_CALL InviteRejected(
	const EOS_Sessions_SessionInviteRejectedCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<NotificationContext *>(data->ClientData);
	eos_sdk_TEOSSessionInviteRejectedSubscription__Notify(
		context->subscription, ToBBString(data->SessionId), ToBBString(data->InviteId),
		data->LocalUserId, data->TargetUserId);
}

void EOS_CALL JoinAccepted(
	const EOS_Sessions_JoinSessionAcceptedCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<NotificationContext *>(data->ClientData);
	eos_sdk_TEOSJoinSessionAcceptedSubscription__Notify(
		context->subscription, data->LocalUserId, data->UiEventId);
}

void EOS_CALL LeaveRequested(
	const EOS_Sessions_LeaveSessionRequestedCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<NotificationContext *>(data->ClientData);
	eos_sdk_TEOSLeaveSessionRequestedSubscription__Notify(
		context->subscription, data->LocalUserId, ToBBString(data->SessionName));
}

void FillAttribute(
	EOS_Sessions_AttributeData &attribute,
	EOS_ESessionAttributeType valueType,
	int64_t intValue,
	double doubleValue,
	int boolValue,
	const UTF8String &stringValue,
	const UTF8String &key) {
	attribute.ApiVersion = EOS_SESSIONS_ATTRIBUTEDATA_API_LATEST;
	attribute.Key = key.required();
	attribute.ValueType = valueType;
	switch (valueType) {
	case EOS_ESessionAttributeType::EOS_AT_BOOLEAN:
		attribute.Value.AsBool = boolValue ? EOS_TRUE : EOS_FALSE;
		break;
	case EOS_ESessionAttributeType::EOS_AT_INT64:
		attribute.Value.AsInt64 = intValue;
		break;
	case EOS_ESessionAttributeType::EOS_AT_DOUBLE:
		attribute.Value.AsDouble = doubleValue;
		break;
	case EOS_ESessionAttributeType::EOS_AT_STRING:
		attribute.Value.AsUtf8 = stringValue.required();
		break;
	default:
		break;
	}
}

EOS_EResult CopyDetailsInfo(
	const EOS_SessionDetails_Info *info,
	BBString **sessionId,
	BBString **hostAddress,
	uint32_t *openConnections,
	BBString **bucketId,
	uint32_t *maxPlayers,
	int *allowJoinInProgress,
	EOS_EOnlineSessionPermissionLevel *permissionLevel,
	int *invitesAllowed,
	int *sanctionsEnabled,
	BBArray **allowedPlatformIds,
	EOS_ProductUserId *ownerUserId,
	BBString **ownerServerClientId) {
	if (!info || !info->Settings) {
		return EOS_EResult::EOS_NotFound;
	}
	*sessionId = ToBBString(info->SessionId);
	*hostAddress = ToBBString(info->HostAddress);
	*openConnections = info->NumOpenPublicConnections;
	*bucketId = ToBBString(info->Settings->BucketId);
	*maxPlayers = info->Settings->NumPublicConnections;
	*allowJoinInProgress = info->Settings->bAllowJoinInProgress == EOS_TRUE;
	*permissionLevel = info->Settings->PermissionLevel;
	*invitesAllowed = info->Settings->bInvitesAllowed == EOS_TRUE;
	*sanctionsEnabled = info->Settings->bSanctionsEnabled == EOS_TRUE;
	*allowedPlatformIds = IntArray(
		info->Settings->AllowedPlatformIds,
		info->Settings->AllowedPlatformIdsCount);
	*ownerUserId = info->OwnerUserId;
	*ownerServerClientId = ToBBString(info->OwnerServerClientId);
	return EOS_EResult::EOS_Success;
}

} // namespace

extern "C" {

EOS_HSessions bmx_eos_platform_get_sessions_interface(EOS_HPlatform platform) {
	return platform ? EOS_Platform_GetSessionsInterface(platform) : nullptr;
}

EOS_EResult bmx_eos_sessions_create_modification(
	EOS_HSessions sessions,
	BBString *maxSessionName,
	BBString *maxBucketId,
	uint32_t maxPlayers,
	EOS_ProductUserId localUser,
	int presenceEnabled,
	BBString *maxSessionId,
	int sanctionsEnabled,
	BBArray *maxAllowedPlatformIds,
	EOS_HSessionModification *modification) {
	UTF8String sessionName(maxSessionName);
	UTF8String bucketId(maxBucketId);
	UTF8String sessionId(maxSessionId);
	uint32_t platformCount = 0;
	const uint32_t *platformIds = IntArrayData(maxAllowedPlatformIds, platformCount);
	EOS_Sessions_CreateSessionModificationOptions options{};
	options.ApiVersion = EOS_SESSIONS_CREATESESSIONMODIFICATION_API_LATEST;
	options.SessionName = sessionName.required();
	options.BucketId = bucketId.required();
	options.MaxPlayers = maxPlayers;
	options.LocalUserId = localUser;
	options.bPresenceEnabled = presenceEnabled ? EOS_TRUE : EOS_FALSE;
	options.SessionId = sessionId.optional();
	options.bSanctionsEnabled = sanctionsEnabled ? EOS_TRUE : EOS_FALSE;
	options.AllowedPlatformIds = platformIds;
	options.AllowedPlatformIdsCount = platformCount;
	return EOS_Sessions_CreateSessionModification(sessions, &options, modification);
}

EOS_EResult bmx_eos_sessions_update_modification(
	EOS_HSessions sessions, BBString *maxSessionName,
	EOS_HSessionModification *modification) {
	UTF8String sessionName(maxSessionName);
	EOS_Sessions_UpdateSessionModificationOptions options{};
	options.ApiVersion = EOS_SESSIONS_UPDATESESSIONMODIFICATION_API_LATEST;
	options.SessionName = sessionName.required();
	return EOS_Sessions_UpdateSessionModification(sessions, &options, modification);
}

void bmx_eos_session_modification_release(EOS_HSessionModification modification) {
	if (modification) {
		EOS_SessionModification_Release(modification);
	}
}

EOS_EResult bmx_eos_session_modification_set_string(
	EOS_HSessionModification modification, int field, BBString *maxValue) {
	UTF8String value(maxValue);
	if (field == 0) {
		EOS_SessionModification_SetBucketIdOptions options{};
		options.ApiVersion = EOS_SESSIONMODIFICATION_SETBUCKETID_API_LATEST;
		options.BucketId = value.required();
		return EOS_SessionModification_SetBucketId(modification, &options);
	}
	if (field == 1) {
		EOS_SessionModification_SetHostAddressOptions options{};
		options.ApiVersion = EOS_SESSIONMODIFICATION_SETHOSTADDRESS_API_LATEST;
		options.HostAddress = value.required();
		return EOS_SessionModification_SetHostAddress(modification, &options);
	}
	return EOS_EResult::EOS_InvalidParameters;
}

EOS_EResult bmx_eos_session_modification_set_int(
	EOS_HSessionModification modification, int field, int value) {
	switch (field) {
	case 0: {
		EOS_SessionModification_SetPermissionLevelOptions options{};
		options.ApiVersion = EOS_SESSIONMODIFICATION_SETPERMISSIONLEVEL_API_LATEST;
		options.PermissionLevel = static_cast<EOS_EOnlineSessionPermissionLevel>(value);
		return EOS_SessionModification_SetPermissionLevel(modification, &options);
	}
	case 1: {
		EOS_SessionModification_SetJoinInProgressAllowedOptions options{};
		options.ApiVersion = EOS_SESSIONMODIFICATION_SETJOININPROGRESSALLOWED_API_LATEST;
		options.bAllowJoinInProgress = value ? EOS_TRUE : EOS_FALSE;
		return EOS_SessionModification_SetJoinInProgressAllowed(modification, &options);
	}
	case 2: {
		EOS_SessionModification_SetMaxPlayersOptions options{};
		options.ApiVersion = EOS_SESSIONMODIFICATION_SETMAXPLAYERS_API_LATEST;
		options.MaxPlayers = static_cast<uint32_t>(value);
		return EOS_SessionModification_SetMaxPlayers(modification, &options);
	}
	case 3: {
		EOS_SessionModification_SetInvitesAllowedOptions options{};
		options.ApiVersion = EOS_SESSIONMODIFICATION_SETINVITESALLOWED_API_LATEST;
		options.bInvitesAllowed = value ? EOS_TRUE : EOS_FALSE;
		return EOS_SessionModification_SetInvitesAllowed(modification, &options);
	}
	default:
		return EOS_EResult::EOS_InvalidParameters;
	}
}

EOS_EResult bmx_eos_session_modification_set_platforms(
	EOS_HSessionModification modification, BBArray *maxPlatformIds) {
	uint32_t count = 0;
	const uint32_t *platformIds = IntArrayData(maxPlatformIds, count);
	EOS_SessionModification_SetAllowedPlatformIdsOptions options{};
	options.ApiVersion = EOS_SESSIONMODIFICATION_SETALLOWEDPLATFORMIDS_API_LATEST;
	options.AllowedPlatformIds = platformIds;
	options.AllowedPlatformIdsCount = count;
	return EOS_SessionModification_SetAllowedPlatformIds(modification, &options);
}

EOS_EResult bmx_eos_session_modification_add_attribute(
	EOS_HSessionModification modification,
	BBString *maxKey,
	EOS_ESessionAttributeType valueType,
	int64_t intValue,
	double doubleValue,
	int boolValue,
	BBString *maxStringValue,
	EOS_ESessionAttributeAdvertisementType advertisement) {
	UTF8String key(maxKey);
	UTF8String stringValue(maxStringValue);
	EOS_Sessions_AttributeData attribute{};
	FillAttribute(
		attribute, valueType, intValue, doubleValue,
		boolValue, stringValue, key);
	EOS_SessionModification_AddAttributeOptions options{};
	options.ApiVersion = EOS_SESSIONMODIFICATION_ADDATTRIBUTE_API_LATEST;
	options.SessionAttribute = &attribute;
	options.AdvertisementType = advertisement;
	return EOS_SessionModification_AddAttribute(modification, &options);
}

EOS_EResult bmx_eos_session_modification_remove_attribute(
	EOS_HSessionModification modification, BBString *maxKey) {
	UTF8String key(maxKey);
	EOS_SessionModification_RemoveAttributeOptions options{};
	options.ApiVersion = EOS_SESSIONMODIFICATION_REMOVEATTRIBUTE_API_LATEST;
	options.Key = key.required();
	return EOS_SessionModification_RemoveAttribute(modification, &options);
}

void bmx_eos_sessions_update(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *request,
	EOS_HSessionModification modification) {
	EOS_Sessions_UpdateSessionOptions options{};
	options.ApiVersion = EOS_SESSIONS_UPDATESESSION_API_LATEST;
	options.SessionModificationHandle = modification;
	auto *context = CreateRequest(platform, request, RequestKind::Update);
	EOS_Sessions_UpdateSession(sessions, &options, context, UpdateComplete);
}

void bmx_eos_sessions_named_operation(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *request,
	BBString *maxSessionName, int operation) {
	UTF8String sessionName(maxSessionName);
	auto *context = CreateRequest(platform, request, RequestKind::Operation);
	switch (operation) {
	case 0: {
		EOS_Sessions_DestroySessionOptions options{};
		options.ApiVersion = EOS_SESSIONS_DESTROYSESSION_API_LATEST;
		options.SessionName = sessionName.required();
		EOS_Sessions_DestroySession(sessions, &options, context, DestroyComplete);
		break;
	}
	case 2: {
		EOS_Sessions_StartSessionOptions options{};
		options.ApiVersion = EOS_SESSIONS_STARTSESSION_API_LATEST;
		options.SessionName = sessionName.required();
		EOS_Sessions_StartSession(sessions, &options, context, StartComplete);
		break;
	}
	case 3: {
		EOS_Sessions_EndSessionOptions options{};
		options.ApiVersion = EOS_SESSIONS_ENDSESSION_API_LATEST;
		options.SessionName = sessionName.required();
		EOS_Sessions_EndSession(sessions, &options, context, EndComplete);
		break;
	}
	default:
		FinishRequest(context, EOS_EResult::EOS_InvalidParameters);
		eos_sdk_TEOSSessionOperationRequest__Complete(
			context->request, EOS_EResult::EOS_InvalidParameters);
		delete context;
		break;
	}
}

void bmx_eos_sessions_join(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *request,
	BBString *maxSessionName, EOS_HSessionDetails details,
	EOS_ProductUserId localUser, int presenceEnabled) {
	UTF8String sessionName(maxSessionName);
	EOS_Sessions_JoinSessionOptions options{};
	options.ApiVersion = EOS_SESSIONS_JOINSESSION_API_LATEST;
	options.SessionName = sessionName.required();
	options.SessionHandle = details;
	options.LocalUserId = localUser;
	options.bPresenceEnabled = presenceEnabled ? EOS_TRUE : EOS_FALSE;
	auto *context = CreateRequest(platform, request, RequestKind::Operation);
	EOS_Sessions_JoinSession(sessions, &options, context, JoinComplete);
}

void bmx_eos_sessions_change_players(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *request,
	BBString *maxSessionName, BBArray *maxPlayers, int operation) {
	UTF8String sessionName(maxSessionName);
	std::vector<EOS_ProductUserId> players = ProductUsers(maxPlayers);
	auto *context = CreateRequest(platform, request, RequestKind::Players);
	if (operation == 4) {
		EOS_Sessions_RegisterPlayersOptions options{};
		options.ApiVersion = EOS_SESSIONS_REGISTERPLAYERS_API_LATEST;
		options.SessionName = sessionName.required();
		options.PlayersToRegister = players.data();
		options.PlayersToRegisterCount = static_cast<uint32_t>(players.size());
		EOS_Sessions_RegisterPlayers(sessions, &options, context, RegisterComplete);
		return;
	}
	if (operation == 5) {
		EOS_Sessions_UnregisterPlayersOptions options{};
		options.ApiVersion = EOS_SESSIONS_UNREGISTERPLAYERS_API_LATEST;
		options.SessionName = sessionName.required();
		options.PlayersToUnregister = players.data();
		options.PlayersToUnregisterCount = static_cast<uint32_t>(players.size());
		EOS_Sessions_UnregisterPlayers(sessions, &options, context, UnregisterComplete);
		return;
	}
	FinishRequest(context, EOS_EResult::EOS_InvalidParameters);
	eos_sdk_TEOSSessionPlayersRequest__Complete(
		context->request, EOS_EResult::EOS_InvalidParameters, 0, 0);
	delete context;
}

void bmx_eos_sessions_send_invite(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *request,
	BBString *maxSessionName, EOS_ProductUserId localUser,
	EOS_ProductUserId targetUser) {
	UTF8String sessionName(maxSessionName);
	EOS_Sessions_SendInviteOptions options{};
	options.ApiVersion = EOS_SESSIONS_SENDINVITE_API_LATEST;
	options.SessionName = sessionName.required();
	options.LocalUserId = localUser;
	options.TargetUserId = targetUser;
	auto *context = CreateRequest(platform, request, RequestKind::Operation);
	EOS_Sessions_SendInvite(sessions, &options, context, SendInviteComplete);
}

void bmx_eos_sessions_reject_invite(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *request,
	BBString *maxInviteId, EOS_ProductUserId localUser) {
	UTF8String inviteId(maxInviteId);
	EOS_Sessions_RejectInviteOptions options{};
	options.ApiVersion = EOS_SESSIONS_REJECTINVITE_API_LATEST;
	options.LocalUserId = localUser;
	options.InviteId = inviteId.required();
	auto *context = CreateRequest(platform, request, RequestKind::Operation);
	EOS_Sessions_RejectInvite(sessions, &options, context, RejectInviteComplete);
}

void bmx_eos_sessions_query_invites(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *request,
	EOS_ProductUserId localUser) {
	EOS_Sessions_QueryInvitesOptions options{};
	options.ApiVersion = EOS_SESSIONS_QUERYINVITES_API_LATEST;
	options.LocalUserId = localUser;
	auto *context = CreateRequest(platform, request, RequestKind::Operation);
	EOS_Sessions_QueryInvites(sessions, &options, context, QueryInvitesComplete);
}

uint32_t bmx_eos_sessions_invite_count(
	EOS_HSessions sessions, EOS_ProductUserId localUser) {
	EOS_Sessions_GetInviteCountOptions options{};
	options.ApiVersion = EOS_SESSIONS_GETINVITECOUNT_API_LATEST;
	options.LocalUserId = localUser;
	return EOS_Sessions_GetInviteCount(sessions, &options);
}

EOS_EResult bmx_eos_sessions_invite_id(
	EOS_HSessions sessions, EOS_ProductUserId localUser,
	uint32_t index, BBString **inviteId) {
	EOS_Sessions_GetInviteIdByIndexOptions options{};
	options.ApiVersion = EOS_SESSIONS_GETINVITEIDBYINDEX_API_LATEST;
	options.LocalUserId = localUser;
	options.Index = index;
	char buffer[EOS_SESSIONS_INVITEID_MAX_LENGTH + 1]{};
	int32_t length = static_cast<int32_t>(sizeof(buffer));
	const EOS_EResult result = EOS_Sessions_GetInviteIdByIndex(
		sessions, &options, buffer, &length);
	if (result == EOS_EResult::EOS_Success) {
		*inviteId = ToBBString(buffer);
	}
	return result;
}

EOS_EResult bmx_eos_sessions_copy_details_by_invite(
	EOS_HSessions sessions, BBString *maxInviteId, EOS_HSessionDetails *details) {
	UTF8String inviteId(maxInviteId);
	EOS_Sessions_CopySessionHandleByInviteIdOptions options{};
	options.ApiVersion = EOS_SESSIONS_COPYSESSIONHANDLEBYINVITEID_API_LATEST;
	options.InviteId = inviteId.required();
	return EOS_Sessions_CopySessionHandleByInviteId(sessions, &options, details);
}

EOS_EResult bmx_eos_sessions_copy_details_by_ui_event(
	EOS_HSessions sessions, uint64_t uiEventId, EOS_HSessionDetails *details) {
	EOS_Sessions_CopySessionHandleByUiEventIdOptions options{};
	options.ApiVersion = EOS_SESSIONS_COPYSESSIONHANDLEBYUIEVENTID_API_LATEST;
	options.UiEventId = uiEventId;
	return EOS_Sessions_CopySessionHandleByUiEventId(sessions, &options, details);
}

EOS_EResult bmx_eos_sessions_copy_details_for_presence(
	EOS_HSessions sessions, EOS_ProductUserId localUser, EOS_HSessionDetails *details) {
	EOS_Sessions_CopySessionHandleForPresenceOptions options{};
	options.ApiVersion = EOS_SESSIONS_COPYSESSIONHANDLEFORPRESENCE_API_LATEST;
	options.LocalUserId = localUser;
	return EOS_Sessions_CopySessionHandleForPresence(sessions, &options, details);
}

uint64_t bmx_eos_sessions_add_notify_invite_received(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *subscription) {
	EOS_Sessions_AddNotifySessionInviteReceivedOptions options{};
	options.ApiVersion = EOS_SESSIONS_ADDNOTIFYSESSIONINVITERECEIVED_API_LATEST;
	auto *context = new NotificationContext(
		platform, sessions, NotificationKind::InviteReceived, subscription);
	context->id = EOS_Sessions_AddNotifySessionInviteReceived(
		sessions, &options, context, InviteReceived);
	if (context->id == EOS_INVALID_NOTIFICATIONID) {
		delete context;
		return 0;
	}
	g_notifications.push_back(context);
	return context->id;
}

uint64_t bmx_eos_sessions_add_notify_invite_accepted(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *subscription) {
	EOS_Sessions_AddNotifySessionInviteAcceptedOptions options{};
	options.ApiVersion = EOS_SESSIONS_ADDNOTIFYSESSIONINVITEACCEPTED_API_LATEST;
	auto *context = new NotificationContext(
		platform, sessions, NotificationKind::InviteAccepted, subscription);
	context->id = EOS_Sessions_AddNotifySessionInviteAccepted(
		sessions, &options, context, InviteAccepted);
	if (context->id == EOS_INVALID_NOTIFICATIONID) {
		delete context;
		return 0;
	}
	g_notifications.push_back(context);
	return context->id;
}

uint64_t bmx_eos_sessions_add_notify_invite_rejected(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *subscription) {
	EOS_Sessions_AddNotifySessionInviteRejectedOptions options{};
	options.ApiVersion = EOS_SESSIONS_ADDNOTIFYSESSIONINVITEREJECTED_API_LATEST;
	auto *context = new NotificationContext(
		platform, sessions, NotificationKind::InviteRejected, subscription);
	context->id = EOS_Sessions_AddNotifySessionInviteRejected(
		sessions, &options, context, InviteRejected);
	if (context->id == EOS_INVALID_NOTIFICATIONID) {
		delete context;
		return 0;
	}
	g_notifications.push_back(context);
	return context->id;
}

uint64_t bmx_eos_sessions_add_notify_join_accepted(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *subscription) {
	EOS_Sessions_AddNotifyJoinSessionAcceptedOptions options{};
	options.ApiVersion = EOS_SESSIONS_ADDNOTIFYJOINSESSIONACCEPTED_API_LATEST;
	auto *context = new NotificationContext(
		platform, sessions, NotificationKind::JoinAccepted, subscription);
	context->id = EOS_Sessions_AddNotifyJoinSessionAccepted(
		sessions, &options, context, JoinAccepted);
	if (context->id == EOS_INVALID_NOTIFICATIONID) {
		delete context;
		return 0;
	}
	g_notifications.push_back(context);
	return context->id;
}

uint64_t bmx_eos_sessions_add_notify_leave_requested(
	EOS_HPlatform platform, EOS_HSessions sessions, BBObject *subscription) {
	EOS_Sessions_AddNotifyLeaveSessionRequestedOptions options{};
	options.ApiVersion = EOS_SESSIONS_ADDNOTIFYLEAVESESSIONREQUESTED_API_LATEST;
	auto *context = new NotificationContext(
		platform, sessions, NotificationKind::LeaveRequested, subscription);
	context->id = EOS_Sessions_AddNotifyLeaveSessionRequested(
		sessions, &options, context, LeaveRequested);
	if (context->id == EOS_INVALID_NOTIFICATIONID) {
		delete context;
		return 0;
	}
	g_notifications.push_back(context);
	return context->id;
}

void bmx_eos_sessions_remove_notify(uint64_t id) {
	auto found = std::find_if(
		g_notifications.begin(), g_notifications.end(),
		[id](const NotificationContext *context) { return context->id == id; });
	if (found != g_notifications.end()) {
		RemoveNotification(*found);
	}
}

EOS_EResult bmx_eos_sessions_create_search(
	EOS_HSessions sessions, uint32_t maxResults, EOS_HSessionSearch *search) {
	EOS_Sessions_CreateSessionSearchOptions options{};
	options.ApiVersion = EOS_SESSIONS_CREATESESSIONSEARCH_API_LATEST;
	options.MaxSearchResults = maxResults;
	return EOS_Sessions_CreateSessionSearch(sessions, &options, search);
}

void bmx_eos_session_search_release(EOS_HSessionSearch search) {
	if (search) {
		EOS_SessionSearch_Release(search);
	}
}

EOS_EResult bmx_eos_session_search_set_string(
	EOS_HSessionSearch search, int field, BBString *maxValue) {
	UTF8String value(maxValue);
	if (field == 0) {
		EOS_SessionSearch_SetSessionIdOptions options{};
		options.ApiVersion = EOS_SESSIONSEARCH_SETSESSIONID_API_LATEST;
		options.SessionId = value.required();
		return EOS_SessionSearch_SetSessionId(search, &options);
	}
	return EOS_EResult::EOS_InvalidParameters;
}

EOS_EResult bmx_eos_session_search_set_target(
	EOS_HSessionSearch search, EOS_ProductUserId targetUser) {
	EOS_SessionSearch_SetTargetUserIdOptions options{};
	options.ApiVersion = EOS_SESSIONSEARCH_SETTARGETUSERID_API_LATEST;
	options.TargetUserId = targetUser;
	return EOS_SessionSearch_SetTargetUserId(search, &options);
}

EOS_EResult bmx_eos_session_search_set_parameter(
	EOS_HSessionSearch search,
	BBString *maxKey,
	EOS_ESessionAttributeType valueType,
	int64_t intValue,
	double doubleValue,
	int boolValue,
	BBString *maxStringValue,
	EOS_EOnlineComparisonOp comparison) {
	UTF8String key(maxKey);
	UTF8String stringValue(maxStringValue);
	EOS_Sessions_AttributeData attribute{};
	FillAttribute(
		attribute, valueType, intValue, doubleValue,
		boolValue, stringValue, key);
	EOS_SessionSearch_SetParameterOptions options{};
	options.ApiVersion = EOS_SESSIONSEARCH_SETPARAMETER_API_LATEST;
	options.Parameter = &attribute;
	options.ComparisonOp = comparison;
	return EOS_SessionSearch_SetParameter(search, &options);
}

EOS_EResult bmx_eos_session_search_remove_parameter(
	EOS_HSessionSearch search, BBString *maxKey, EOS_EOnlineComparisonOp comparison) {
	UTF8String key(maxKey);
	EOS_SessionSearch_RemoveParameterOptions options{};
	options.ApiVersion = EOS_SESSIONSEARCH_REMOVEPARAMETER_API_LATEST;
	options.Key = key.required();
	options.ComparisonOp = comparison;
	return EOS_SessionSearch_RemoveParameter(search, &options);
}

EOS_EResult bmx_eos_session_search_set_max_results(
	EOS_HSessionSearch search, uint32_t maxResults) {
	EOS_SessionSearch_SetMaxResultsOptions options{};
	options.ApiVersion = EOS_SESSIONSEARCH_SETMAXSEARCHRESULTS_API_LATEST;
	options.MaxSearchResults = maxResults;
	return EOS_SessionSearch_SetMaxResults(search, &options);
}

void bmx_eos_session_search_find(
	EOS_HPlatform platform, EOS_HSessionSearch search, BBObject *request,
	EOS_ProductUserId localUser) {
	EOS_SessionSearch_FindOptions options{};
	options.ApiVersion = EOS_SESSIONSEARCH_FIND_API_LATEST;
	options.LocalUserId = localUser;
	auto *context = CreateRequest(platform, request, RequestKind::Search);
	EOS_SessionSearch_Find(search, &options, context, SearchComplete);
}

uint32_t bmx_eos_session_search_result_count(EOS_HSessionSearch search) {
	EOS_SessionSearch_GetSearchResultCountOptions options{};
	options.ApiVersion = EOS_SESSIONSEARCH_GETSEARCHRESULTCOUNT_API_LATEST;
	return EOS_SessionSearch_GetSearchResultCount(search, &options);
}

EOS_EResult bmx_eos_session_search_copy_result(
	EOS_HSessionSearch search, uint32_t index, EOS_HSessionDetails *details) {
	EOS_SessionSearch_CopySearchResultByIndexOptions options{};
	options.ApiVersion = EOS_SESSIONSEARCH_COPYSEARCHRESULTBYINDEX_API_LATEST;
	options.SessionIndex = index;
	return EOS_SessionSearch_CopySearchResultByIndex(search, &options, details);
}

EOS_EResult bmx_eos_session_details_copy_info(
	EOS_HSessionDetails details,
	BBString **sessionId,
	BBString **hostAddress,
	uint32_t *openConnections,
	BBString **bucketId,
	uint32_t *maxPlayers,
	int *allowJoinInProgress,
	EOS_EOnlineSessionPermissionLevel *permissionLevel,
	int *invitesAllowed,
	int *sanctionsEnabled,
	BBArray **allowedPlatformIds,
	EOS_ProductUserId *ownerUserId,
	BBString **ownerServerClientId) {
	EOS_SessionDetails_CopyInfoOptions options{};
	options.ApiVersion = EOS_SESSIONDETAILS_COPYINFO_API_LATEST;
	EOS_SessionDetails_Info *info = nullptr;
	const EOS_EResult result = EOS_SessionDetails_CopyInfo(details, &options, &info);
	if (result != EOS_EResult::EOS_Success || !info) {
		return result;
	}
	const EOS_EResult copied = CopyDetailsInfo(
		info, sessionId, hostAddress, openConnections, bucketId, maxPlayers,
		allowJoinInProgress, permissionLevel, invitesAllowed, sanctionsEnabled,
		allowedPlatformIds, ownerUserId, ownerServerClientId);
	EOS_SessionDetails_Info_Release(info);
	return copied;
}

uint32_t bmx_eos_session_details_attribute_count(EOS_HSessionDetails details) {
	EOS_SessionDetails_GetSessionAttributeCountOptions options{};
	options.ApiVersion = EOS_SESSIONDETAILS_GETSESSIONATTRIBUTECOUNT_API_LATEST;
	return EOS_SessionDetails_GetSessionAttributeCount(details, &options);
}

EOS_EResult bmx_eos_session_details_copy_attribute(
	EOS_HSessionDetails details,
	uint32_t index,
	BBString **key,
	EOS_ESessionAttributeType *valueType,
	int64_t *intValue,
	double *doubleValue,
	int *boolValue,
	BBString **stringValue,
	EOS_ESessionAttributeAdvertisementType *advertisement) {
	EOS_SessionDetails_CopySessionAttributeByIndexOptions options{};
	options.ApiVersion = EOS_SESSIONDETAILS_COPYSESSIONATTRIBUTEBYINDEX_API_LATEST;
	options.AttrIndex = index;
	EOS_SessionDetails_Attribute *attribute = nullptr;
	const EOS_EResult result = EOS_SessionDetails_CopySessionAttributeByIndex(
		details, &options, &attribute);
	if (result != EOS_EResult::EOS_Success || !attribute || !attribute->Data) {
		return result;
	}
	*key = ToBBString(attribute->Data->Key);
	*valueType = attribute->Data->ValueType;
	*intValue = 0;
	*doubleValue = 0.0;
	*boolValue = false;
	*stringValue = &bbEmptyString;
	switch (attribute->Data->ValueType) {
	case EOS_ESessionAttributeType::EOS_AT_BOOLEAN:
		*boolValue = attribute->Data->Value.AsBool == EOS_TRUE;
		break;
	case EOS_ESessionAttributeType::EOS_AT_INT64:
		*intValue = attribute->Data->Value.AsInt64;
		break;
	case EOS_ESessionAttributeType::EOS_AT_DOUBLE:
		*doubleValue = attribute->Data->Value.AsDouble;
		break;
	case EOS_ESessionAttributeType::EOS_AT_STRING:
		*stringValue = ToBBString(attribute->Data->Value.AsUtf8);
		break;
	default:
		break;
	}
	*advertisement = attribute->AdvertisementType;
	EOS_SessionDetails_Attribute_Release(attribute);
	return result;
}

void bmx_eos_session_details_release(EOS_HSessionDetails details) {
	if (details) {
		EOS_SessionDetails_Release(details);
	}
}

EOS_EResult bmx_eos_sessions_copy_active(
	EOS_HSessions sessions, BBString *maxSessionName, EOS_HActiveSession *active) {
	UTF8String sessionName(maxSessionName);
	EOS_Sessions_CopyActiveSessionHandleOptions options{};
	options.ApiVersion = EOS_SESSIONS_COPYACTIVESESSIONHANDLE_API_LATEST;
	options.SessionName = sessionName.required();
	return EOS_Sessions_CopyActiveSessionHandle(sessions, &options, active);
}

EOS_EResult bmx_eos_active_session_copy_info(
	EOS_HActiveSession active,
	BBString **sessionName,
	EOS_ProductUserId *localUserId,
	EOS_EOnlineSessionState *state,
	BBString **sessionId,
	BBString **hostAddress,
	uint32_t *openConnections,
	BBString **bucketId,
	uint32_t *maxPlayers,
	int *allowJoinInProgress,
	EOS_EOnlineSessionPermissionLevel *permissionLevel,
	int *invitesAllowed,
	int *sanctionsEnabled,
	BBArray **allowedPlatformIds,
	EOS_ProductUserId *ownerUserId,
	BBString **ownerServerClientId) {
	EOS_ActiveSession_CopyInfoOptions options{};
	options.ApiVersion = EOS_ACTIVESESSION_COPYINFO_API_LATEST;
	EOS_ActiveSession_Info *info = nullptr;
	const EOS_EResult result = EOS_ActiveSession_CopyInfo(active, &options, &info);
	if (result != EOS_EResult::EOS_Success || !info) {
		return result;
	}
	*sessionName = ToBBString(info->SessionName);
	*localUserId = info->LocalUserId;
	*state = info->State;
	const EOS_EResult copied = CopyDetailsInfo(
		info->SessionDetails, sessionId, hostAddress, openConnections, bucketId,
		maxPlayers, allowJoinInProgress, permissionLevel, invitesAllowed,
		sanctionsEnabled, allowedPlatformIds, ownerUserId, ownerServerClientId);
	EOS_ActiveSession_Info_Release(info);
	return copied;
}

uint32_t bmx_eos_active_session_player_count(EOS_HActiveSession active) {
	EOS_ActiveSession_GetRegisteredPlayerCountOptions options{};
	options.ApiVersion = EOS_ACTIVESESSION_GETREGISTEREDPLAYERCOUNT_API_LATEST;
	return EOS_ActiveSession_GetRegisteredPlayerCount(active, &options);
}

EOS_ProductUserId bmx_eos_active_session_player_by_index(
	EOS_HActiveSession active, uint32_t index) {
	EOS_ActiveSession_GetRegisteredPlayerByIndexOptions options{};
	options.ApiVersion = EOS_ACTIVESESSION_GETREGISTEREDPLAYERBYINDEX_API_LATEST;
	options.PlayerIndex = index;
	return EOS_ActiveSession_GetRegisteredPlayerByIndex(active, &options);
}

void bmx_eos_active_session_release(EOS_HActiveSession active) {
	if (active) {
		EOS_ActiveSession_Release(active);
	}
}

EOS_EResult bmx_eos_sessions_is_user_in_session(
	EOS_HSessions sessions, BBString *maxSessionName, EOS_ProductUserId targetUser) {
	UTF8String sessionName(maxSessionName);
	EOS_Sessions_IsUserInSessionOptions options{};
	options.ApiVersion = EOS_SESSIONS_ISUSERINSESSION_API_LATEST;
	options.SessionName = sessionName.required();
	options.TargetUserId = targetUser;
	return EOS_Sessions_IsUserInSession(sessions, &options);
}

void bmx_eos_sessions_cancel_platform_requests(EOS_HPlatform platform) {
	for (std::size_t index = 0; index < g_requests.size();) {
		auto *context = g_requests[index];
		if (context->platform != platform) {
			++index;
			continue;
		}
		g_requests.erase(g_requests.begin() + static_cast<std::ptrdiff_t>(index));
		switch (context->kind) {
		case RequestKind::Update:
			eos_sdk_TEOSSessionUpdateRequest__Cancel(context->request);
			break;
		case RequestKind::Operation:
			eos_sdk_TEOSSessionOperationRequest__Cancel(context->request);
			break;
		case RequestKind::Search:
			eos_sdk_TEOSSessionSearchRequest__Cancel(context->request);
			break;
		case RequestKind::Players:
			eos_sdk_TEOSSessionPlayersRequest__Cancel(context->request);
			break;
		}
		delete context;
	}
	for (std::size_t index = 0; index < g_notifications.size();) {
		auto *context = g_notifications[index];
		if (context->platform != platform) {
			++index;
			continue;
		}
		g_notifications.erase(
			g_notifications.begin() + static_cast<std::ptrdiff_t>(index));
		if (context->id != EOS_INVALID_NOTIFICATIONID) {
			switch (context->kind) {
			case NotificationKind::InviteReceived:
				EOS_Sessions_RemoveNotifySessionInviteReceived(context->sessions, context->id);
				eos_sdk_TEOSSessionInviteReceivedSubscription__Cancel(context->subscription);
				break;
			case NotificationKind::InviteAccepted:
				EOS_Sessions_RemoveNotifySessionInviteAccepted(context->sessions, context->id);
				eos_sdk_TEOSSessionInviteAcceptedSubscription__Cancel(context->subscription);
				break;
			case NotificationKind::InviteRejected:
				EOS_Sessions_RemoveNotifySessionInviteRejected(context->sessions, context->id);
				eos_sdk_TEOSSessionInviteRejectedSubscription__Cancel(context->subscription);
				break;
			case NotificationKind::JoinAccepted:
				EOS_Sessions_RemoveNotifyJoinSessionAccepted(context->sessions, context->id);
				eos_sdk_TEOSJoinSessionAcceptedSubscription__Cancel(context->subscription);
				break;
			case NotificationKind::LeaveRequested:
				EOS_Sessions_RemoveNotifyLeaveSessionRequested(context->sessions, context->id);
				eos_sdk_TEOSLeaveSessionRequestedSubscription__Cancel(context->subscription);
				break;
			}
		}
		delete context;
	}
}

} // extern "C"
