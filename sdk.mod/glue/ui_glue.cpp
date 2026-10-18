/* Copyright (c) 2026 Bruce A Henderson. Licensed under zlib/libpng. */

#include <brl.mod/blitz.mod/blitz.h>

#include "../SDK/Include/eos_sdk.h"
#include "../SDK/Include/eos_ui.h"

#include <algorithm>
#include <cstdint>
#include <vector>

extern "C" {
void eos_sdk_TEOSUIOperationRequest__Complete(
	BBObject *, EOS_EResult, EOS_EpicAccountId, EOS_EpicAccountId);
void eos_sdk_TEOSUIOperationRequest__Cancel(BBObject *);
void eos_sdk_TEOSUIDisplaySettingsSubscription__Notify(BBObject *, int, int);
void eos_sdk_TEOSUIDisplaySettingsSubscription__Cancel(BBObject *);
}

namespace {

struct RequestContext {
	EOS_HPlatform platform;
	BBObject *request;

	RequestContext(EOS_HPlatform platformValue, BBObject *requestValue)
		: platform(platformValue), request(requestValue) {
		BBRETAIN(request);
	}

	~RequestContext() {
		BBRELEASE(request);
	}
};

struct NotificationContext {
	EOS_HPlatform platform;
	EOS_HUI ui;
	EOS_NotificationId id;
	BBObject *subscription;

	NotificationContext(
		EOS_HPlatform platformValue,
		EOS_HUI uiValue,
		BBObject *subscriptionValue)
		: platform(platformValue), ui(uiValue), id(EOS_INVALID_NOTIFICATIONID),
		  subscription(subscriptionValue) {
		BBRETAIN(subscription);
	}

	~NotificationContext() {
		BBRELEASE(subscription);
	}
};

std::vector<RequestContext *> g_requests;
std::vector<NotificationContext *> g_notifications;

RequestContext *CreateRequest(EOS_HPlatform platform, BBObject *request) {
	auto *context = new RequestContext(platform, request);
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

void CompleteRequest(
	RequestContext *context,
	EOS_EResult result,
	EOS_EpicAccountId localUser,
	EOS_EpicAccountId targetUser) {
	const bool terminal = FinishRequest(context, result);
	eos_sdk_TEOSUIOperationRequest__Complete(
		context->request, result, localUser, targetUser);
	if (terminal) {
		delete context;
	}
}

void EOS_CALL ShowFriendsComplete(const EOS_UI_ShowFriendsCallbackInfo *data) {
	if (data && data->ClientData) {
		CompleteRequest(
			static_cast<RequestContext *>(data->ClientData),
			data->ResultCode, data->LocalUserId, nullptr);
	}
}

void EOS_CALL HideFriendsComplete(const EOS_UI_HideFriendsCallbackInfo *data) {
	if (data && data->ClientData) {
		CompleteRequest(
			static_cast<RequestContext *>(data->ClientData),
			data->ResultCode, data->LocalUserId, nullptr);
	}
}

void EOS_CALL ShowBlockPlayerComplete(
	const EOS_UI_OnShowBlockPlayerCallbackInfo *data) {
	if (data && data->ClientData) {
		CompleteRequest(
			static_cast<RequestContext *>(data->ClientData),
			data->ResultCode, data->LocalUserId, data->TargetUserId);
	}
}

void EOS_CALL ShowReportPlayerComplete(
	const EOS_UI_OnShowReportPlayerCallbackInfo *data) {
	if (data && data->ClientData) {
		CompleteRequest(
			static_cast<RequestContext *>(data->ClientData),
			data->ResultCode, data->LocalUserId, data->TargetUserId);
	}
}

void EOS_CALL DisplaySettingsUpdated(
	const EOS_UI_OnDisplaySettingsUpdatedCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<NotificationContext *>(data->ClientData);
	eos_sdk_TEOSUIDisplaySettingsSubscription__Notify(
		context->subscription,
		data->bIsVisible == EOS_TRUE,
		data->bIsExclusiveInput == EOS_TRUE);
}

void RemoveNotification(NotificationContext *context) {
	if (!context) {
		return;
	}
	if (context->id != EOS_INVALID_NOTIFICATIONID) {
		EOS_UI_RemoveNotifyDisplaySettingsUpdated(context->ui, context->id);
	}
	auto found = std::find(g_notifications.begin(), g_notifications.end(), context);
	if (found != g_notifications.end()) {
		g_notifications.erase(found);
	}
	delete context;
}

} // namespace

extern "C" {

EOS_HUI bmx_eos_platform_get_ui_interface(EOS_HPlatform platform) {
	return platform ? EOS_Platform_GetUIInterface(platform) : nullptr;
}

void bmx_eos_ui_friends_operation(
	EOS_HPlatform platform,
	EOS_HUI ui,
	BBObject *request,
	EOS_EpicAccountId localUser,
	int operation) {
	auto *context = CreateRequest(platform, request);
	if (operation == 0) {
		EOS_UI_ShowFriendsOptions options{};
		options.ApiVersion = EOS_UI_SHOWFRIENDS_API_LATEST;
		options.LocalUserId = localUser;
		EOS_UI_ShowFriends(ui, &options, context, ShowFriendsComplete);
	} else {
		EOS_UI_HideFriendsOptions options{};
		options.ApiVersion = EOS_UI_HIDEFRIENDS_API_LATEST;
		options.LocalUserId = localUser;
		EOS_UI_HideFriends(ui, &options, context, HideFriendsComplete);
	}
}

void bmx_eos_ui_player_operation(
	EOS_HPlatform platform,
	EOS_HUI ui,
	BBObject *request,
	EOS_EpicAccountId localUser,
	EOS_EpicAccountId targetUser,
	int operation) {
	auto *context = CreateRequest(platform, request);
	if (operation == 2) {
		EOS_UI_ShowBlockPlayerOptions options{};
		options.ApiVersion = EOS_UI_SHOWBLOCKPLAYER_API_LATEST;
		options.LocalUserId = localUser;
		options.TargetUserId = targetUser;
		EOS_UI_ShowBlockPlayer(ui, &options, context, ShowBlockPlayerComplete);
	} else {
		EOS_UI_ShowReportPlayerOptions options{};
		options.ApiVersion = EOS_UI_SHOWREPORTPLAYER_API_LATEST;
		options.LocalUserId = localUser;
		options.TargetUserId = targetUser;
		EOS_UI_ShowReportPlayer(ui, &options, context, ShowReportPlayerComplete);
	}
}

int bmx_eos_ui_friends_visible(EOS_HUI ui, EOS_EpicAccountId localUser) {
	EOS_UI_GetFriendsVisibleOptions options{};
	options.ApiVersion = EOS_UI_GETFRIENDSVISIBLE_API_LATEST;
	options.LocalUserId = localUser;
	return EOS_UI_GetFriendsVisible(ui, &options) == EOS_TRUE;
}

int bmx_eos_ui_friends_exclusive_input(
	EOS_HUI ui, EOS_EpicAccountId localUser) {
	EOS_UI_GetFriendsExclusiveInputOptions options{};
	options.ApiVersion = EOS_UI_GETFRIENDSEXCLUSIVEINPUT_API_LATEST;
	options.LocalUserId = localUser;
	return EOS_UI_GetFriendsExclusiveInput(ui, &options) == EOS_TRUE;
}

EOS_EResult bmx_eos_ui_set_display_preference(
	EOS_HUI ui, EOS_UI_ENotificationLocation location) {
	EOS_UI_SetDisplayPreferenceOptions options{};
	options.ApiVersion = EOS_UI_SETDISPLAYPREFERENCE_API_LATEST;
	options.NotificationLocation = location;
	return EOS_UI_SetDisplayPreference(ui, &options);
}

EOS_UI_ENotificationLocation bmx_eos_ui_get_display_preference(EOS_HUI ui) {
	return EOS_UI_GetNotificationLocationPreference(ui);
}

EOS_EResult bmx_eos_ui_acknowledge_event(
	EOS_HUI ui, uint64_t uiEventId, EOS_EResult result) {
	EOS_UI_AcknowledgeEventIdOptions options{};
	options.ApiVersion = EOS_UI_ACKNOWLEDGEEVENTID_API_LATEST;
	options.UiEventId = uiEventId;
	options.Result = result;
	return EOS_UI_AcknowledgeEventId(ui, &options);
}

EOS_EResult bmx_eos_ui_pause_social_overlay(EOS_HUI ui, int paused) {
	EOS_UI_PauseSocialOverlayOptions options{};
	options.ApiVersion = EOS_UI_PAUSESOCIALOVERLAY_API_LATEST;
	options.bIsPaused = paused ? EOS_TRUE : EOS_FALSE;
	return EOS_UI_PauseSocialOverlay(ui, &options);
}

int bmx_eos_ui_is_social_overlay_paused(EOS_HUI ui) {
	EOS_UI_IsSocialOverlayPausedOptions options{};
	options.ApiVersion = EOS_UI_ISSOCIALOVERLAYPAUSED_API_LATEST;
	return EOS_UI_IsSocialOverlayPaused(ui, &options) == EOS_TRUE;
}

uint64_t bmx_eos_ui_add_notify_display_settings(
	EOS_HPlatform platform, EOS_HUI ui, BBObject *subscription) {
	EOS_UI_AddNotifyDisplaySettingsUpdatedOptions options{};
	options.ApiVersion = EOS_UI_ADDNOTIFYDISPLAYSETTINGSUPDATED_API_LATEST;
	auto *context = new NotificationContext(platform, ui, subscription);
	context->id = EOS_UI_AddNotifyDisplaySettingsUpdated(
		ui, &options, context, DisplaySettingsUpdated);
	if (context->id == EOS_INVALID_NOTIFICATIONID) {
		delete context;
		return 0;
	}
	g_notifications.push_back(context);
	return context->id;
}

void bmx_eos_ui_remove_notify(uint64_t id) {
	auto found = std::find_if(
		g_notifications.begin(), g_notifications.end(),
		[id](const NotificationContext *context) { return context->id == id; });
	if (found != g_notifications.end()) {
		RemoveNotification(*found);
	}
}

void bmx_eos_ui_cancel_platform_requests(EOS_HPlatform platform) {
	for (std::size_t index = 0; index < g_requests.size();) {
		auto *context = g_requests[index];
		if (context->platform != platform) {
			++index;
			continue;
		}
		g_requests.erase(
			g_requests.begin() + static_cast<std::ptrdiff_t>(index));
		eos_sdk_TEOSUIOperationRequest__Cancel(context->request);
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
			EOS_UI_RemoveNotifyDisplaySettingsUpdated(context->ui, context->id);
			eos_sdk_TEOSUIDisplaySettingsSubscription__Cancel(context->subscription);
		}
		delete context;
	}
}

} // extern "C"
