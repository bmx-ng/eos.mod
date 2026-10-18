/* Copyright (c) 2026 Bruce A Henderson. Licensed under zlib/libpng. */

#include <brl.mod/blitz.mod/blitz.h>

#include "../SDK/Include/eos_sdk.h"
#include "../SDK/Include/eos_integratedplatform.h"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

extern "C" {
void eos_sdk_TEOSIntegratedPlatformLoginStatusSubscription__Notify(
	BBObject *, BBString *, BBString *, EOS_EpicAccountId, EOS_ProductUserId,
	EOS_ELoginStatus, EOS_ELoginStatus);
void eos_sdk_TEOSIntegratedPlatformLoginStatusSubscription__Cancel(BBObject *);
int eos_sdk_TEOSIntegratedPlatformPreLogoutRegistration__Notify(
	BBObject *, BBString *, BBString *, EOS_EpicAccountId, EOS_ProductUserId);
void eos_sdk_TEOSIntegratedPlatformPreLogoutRegistration__Cancel(BBObject *);
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

struct LoginStatusContext {
	EOS_HPlatform platform;
	EOS_HIntegratedPlatform integratedPlatform;
	EOS_NotificationId id;
	BBObject *subscription;

	LoginStatusContext(
		EOS_HPlatform platformValue,
		EOS_HIntegratedPlatform integratedPlatformValue,
		BBObject *subscriptionValue)
		: platform(platformValue), integratedPlatform(integratedPlatformValue),
		  id(EOS_INVALID_NOTIFICATIONID), subscription(subscriptionValue) {
		BBRETAIN(subscription);
	}

	~LoginStatusContext() {
		BBRELEASE(subscription);
	}
};

struct PreLogoutContext {
	EOS_HPlatform platform;
	EOS_HIntegratedPlatform integratedPlatform;
	BBObject *registration;

	PreLogoutContext(
		EOS_HPlatform platformValue,
		EOS_HIntegratedPlatform integratedPlatformValue,
		BBObject *registrationValue)
		: platform(platformValue), integratedPlatform(integratedPlatformValue),
		  registration(registrationValue) {
		BBRETAIN(registration);
	}

	~PreLogoutContext() {
		BBRELEASE(registration);
	}
};

std::vector<LoginStatusContext *> g_loginStatusNotifications;
std::vector<PreLogoutContext *> g_preLogoutHandlers;

void EOS_CALL LoginStatusChanged(
	const EOS_IntegratedPlatform_UserLoginStatusChangedCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<LoginStatusContext *>(data->ClientData);
	eos_sdk_TEOSIntegratedPlatformLoginStatusSubscription__Notify(
		context->subscription,
		ToBBString(data->PlatformType),
		ToBBString(data->LocalPlatformUserId),
		data->AccountId,
		data->ProductUserId,
		data->PreviousLoginStatus,
		data->CurrentLoginStatus);
}

EOS_EIntegratedPlatformPreLogoutAction EOS_CALL PreLogout(
	const EOS_IntegratedPlatform_UserPreLogoutCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return EOS_EIntegratedPlatformPreLogoutAction::
			EOS_IPLA_ProcessLogoutImmediately;
	}
	auto *context = static_cast<PreLogoutContext *>(data->ClientData);
	const int action =
		eos_sdk_TEOSIntegratedPlatformPreLogoutRegistration__Notify(
			context->registration,
			ToBBString(data->PlatformType),
			ToBBString(data->LocalPlatformUserId),
			data->AccountId,
			data->ProductUserId);
	return static_cast<EOS_EIntegratedPlatformPreLogoutAction>(action);
}

void RemoveLoginStatusNotification(LoginStatusContext *context) {
	if (!context) {
		return;
	}
	if (context->id != EOS_INVALID_NOTIFICATIONID) {
		EOS_IntegratedPlatform_RemoveNotifyUserLoginStatusChanged(
			context->integratedPlatform, context->id);
	}
	auto found = std::find(
		g_loginStatusNotifications.begin(),
		g_loginStatusNotifications.end(), context);
	if (found != g_loginStatusNotifications.end()) {
		g_loginStatusNotifications.erase(found);
	}
	delete context;
}

void RemovePreLogoutHandler(PreLogoutContext *context) {
	if (!context) {
		return;
	}
	EOS_IntegratedPlatform_ClearUserPreLogoutCallbackOptions options{};
	options.ApiVersion =
		EOS_INTEGRATEDPLATFORM_CLEARUSERPRELOGOUTCALLBACK_API_LATEST;
	EOS_IntegratedPlatform_ClearUserPreLogoutCallback(
		context->integratedPlatform, &options);
	auto found = std::find(
		g_preLogoutHandlers.begin(), g_preLogoutHandlers.end(), context);
	if (found != g_preLogoutHandlers.end()) {
		g_preLogoutHandlers.erase(found);
	}
	delete context;
}

} // namespace

extern "C" {

EOS_EResult bmx_eos_integrated_platform_options_create(
	EOS_HIntegratedPlatformOptionsContainer *handle) {
	if (!handle) {
		return EOS_EResult::EOS_InvalidParameters;
	}
	*handle = nullptr;
	EOS_IntegratedPlatform_CreateIntegratedPlatformOptionsContainerOptions options{};
	options.ApiVersion =
		EOS_INTEGRATEDPLATFORM_CREATEINTEGRATEDPLATFORMOPTIONSCONTAINER_API_LATEST;
	return EOS_IntegratedPlatform_CreateIntegratedPlatformOptionsContainer(
		&options, handle);
}

EOS_EResult bmx_eos_integrated_platform_options_add_steam(
	EOS_HIntegratedPlatformOptionsContainer handle,
	int flags,
	BBString *maxOverrideLibraryPath,
	unsigned int steamMajorVersion,
	unsigned int steamMinorVersion,
	BBArray *maxInterfaceVersions) {
	UTF8String overrideLibraryPath(maxOverrideLibraryPath);
	const uint32_t interfaceVersionsLength =
		maxInterfaceVersions && maxInterfaceVersions != &bbEmptyArray &&
			maxInterfaceVersions->dims == 1
		? static_cast<uint32_t>(maxInterfaceVersions->scales[0])
		: 0;
	const char *interfaceVersions = interfaceVersionsLength
		? static_cast<const char *>(
			BBARRAYDATA(maxInterfaceVersions, maxInterfaceVersions->dims))
		: nullptr;

	EOS_IntegratedPlatform_Steam_Options steamOptions{};
	steamOptions.ApiVersion = EOS_INTEGRATEDPLATFORM_STEAM_OPTIONS_API_LATEST;
	steamOptions.OverrideLibraryPath = overrideLibraryPath.optional();
	steamOptions.SteamMajorVersion = steamMajorVersion;
	steamOptions.SteamMinorVersion = steamMinorVersion;
	steamOptions.SteamApiInterfaceVersionsArray = interfaceVersions;
	steamOptions.SteamApiInterfaceVersionsArrayBytes = interfaceVersionsLength;

	EOS_IntegratedPlatform_Options platformOptions{};
	platformOptions.ApiVersion = EOS_INTEGRATEDPLATFORM_OPTIONS_API_LATEST;
	platformOptions.Type = EOS_IPT_Steam;
	platformOptions.Flags =
		static_cast<EOS_EIntegratedPlatformManagementFlags>(flags);
	platformOptions.InitOptions = &steamOptions;

	EOS_IntegratedPlatformOptionsContainer_AddOptions addOptions{};
	addOptions.ApiVersion =
		EOS_INTEGRATEDPLATFORMOPTIONSCONTAINER_ADD_API_LATEST;
	addOptions.Options = &platformOptions;
	return EOS_IntegratedPlatformOptionsContainer_Add(handle, &addOptions);
}

void bmx_eos_integrated_platform_options_release(
	EOS_HIntegratedPlatformOptionsContainer handle) {
	EOS_IntegratedPlatformOptionsContainer_Release(handle);
}

EOS_HIntegratedPlatform bmx_eos_platform_get_integrated_platform_interface(
	EOS_HPlatform platform) {
	return platform
		? EOS_Platform_GetIntegratedPlatformInterface(platform)
		: nullptr;
}

EOS_EResult bmx_eos_integrated_platform_set_user_login_status(
	EOS_HIntegratedPlatform integratedPlatform,
	BBString *maxPlatformType,
	BBString *maxLocalPlatformUserId,
	EOS_ELoginStatus status) {
	UTF8String platformType(maxPlatformType);
	UTF8String localPlatformUserId(maxLocalPlatformUserId);
	EOS_IntegratedPlatform_SetUserLoginStatusOptions options{};
	options.ApiVersion = EOS_INTEGRATEDPLATFORM_SETUSERLOGINSTATUS_API_LATEST;
	options.PlatformType = platformType.required();
	options.LocalPlatformUserId = localPlatformUserId.required();
	options.CurrentLoginStatus = status;
	return EOS_IntegratedPlatform_SetUserLoginStatus(
		integratedPlatform, &options);
}

uint64_t bmx_eos_integrated_platform_add_login_status_notify(
	EOS_HPlatform platform,
	EOS_HIntegratedPlatform integratedPlatform,
	BBObject *subscription) {
	EOS_IntegratedPlatform_AddNotifyUserLoginStatusChangedOptions options{};
	options.ApiVersion =
		EOS_INTEGRATEDPLATFORM_ADDNOTIFYUSERLOGINSTATUSCHANGED_API_LATEST;
	auto *context =
		new LoginStatusContext(platform, integratedPlatform, subscription);
	context->id = EOS_IntegratedPlatform_AddNotifyUserLoginStatusChanged(
		integratedPlatform, &options, context, LoginStatusChanged);
	if (context->id == EOS_INVALID_NOTIFICATIONID) {
		delete context;
		return 0;
	}
	g_loginStatusNotifications.push_back(context);
	return context->id;
}

void bmx_eos_integrated_platform_remove_login_status_notify(uint64_t id) {
	auto found = std::find_if(
		g_loginStatusNotifications.begin(),
		g_loginStatusNotifications.end(),
		[id](const LoginStatusContext *context) { return context->id == id; });
	if (found != g_loginStatusNotifications.end()) {
		RemoveLoginStatusNotification(*found);
	}
}

EOS_EResult bmx_eos_integrated_platform_set_pre_logout(
	EOS_HPlatform platform,
	EOS_HIntegratedPlatform integratedPlatform,
	BBObject *registration) {
	EOS_IntegratedPlatform_SetUserPreLogoutCallbackOptions options{};
	options.ApiVersion =
		EOS_INTEGRATEDPLATFORM_SETUSERPRELOGOUTCALLBACK_API_LATEST;
	auto *context =
		new PreLogoutContext(platform, integratedPlatform, registration);
	const EOS_EResult result = EOS_IntegratedPlatform_SetUserPreLogoutCallback(
		integratedPlatform, &options, context, PreLogout);
	if (result != EOS_EResult::EOS_Success) {
		delete context;
		return result;
	}
	g_preLogoutHandlers.push_back(context);
	return result;
}

void bmx_eos_integrated_platform_clear_pre_logout(BBObject *registration) {
	auto found = std::find_if(
		g_preLogoutHandlers.begin(), g_preLogoutHandlers.end(),
		[registration](const PreLogoutContext *context) {
			return context->registration == registration;
		});
	if (found != g_preLogoutHandlers.end()) {
		RemovePreLogoutHandler(*found);
	}
}

EOS_EResult bmx_eos_integrated_platform_finalize_logout(
	EOS_HIntegratedPlatform integratedPlatform,
	BBString *maxPlatformType,
	BBString *maxLocalPlatformUserId,
	EOS_ELoginStatus expectedStatus) {
	UTF8String platformType(maxPlatformType);
	UTF8String localPlatformUserId(maxLocalPlatformUserId);
	EOS_IntegratedPlatform_FinalizeDeferredUserLogoutOptions options{};
	options.ApiVersion =
		EOS_INTEGRATEDPLATFORM_FINALIZEDEFERREDUSERLOGOUT_API_LATEST;
	options.PlatformType = platformType.required();
	options.LocalPlatformUserId = localPlatformUserId.required();
	options.ExpectedLoginStatus = expectedStatus;
	return EOS_IntegratedPlatform_FinalizeDeferredUserLogout(
		integratedPlatform, &options);
}

void bmx_eos_integrated_platform_cancel_platform_requests(
	EOS_HPlatform platform) {
	for (std::size_t index = 0;
		index < g_loginStatusNotifications.size();) {
		auto *context = g_loginStatusNotifications[index];
		if (context->platform != platform) {
			++index;
			continue;
		}
		g_loginStatusNotifications.erase(
			g_loginStatusNotifications.begin() +
			static_cast<std::ptrdiff_t>(index));
		if (context->id != EOS_INVALID_NOTIFICATIONID) {
			EOS_IntegratedPlatform_RemoveNotifyUserLoginStatusChanged(
				context->integratedPlatform, context->id);
			eos_sdk_TEOSIntegratedPlatformLoginStatusSubscription__Cancel(
				context->subscription);
		}
		delete context;
	}
	for (std::size_t index = 0; index < g_preLogoutHandlers.size();) {
		auto *context = g_preLogoutHandlers[index];
		if (context->platform != platform) {
			++index;
			continue;
		}
		g_preLogoutHandlers.erase(
			g_preLogoutHandlers.begin() +
			static_cast<std::ptrdiff_t>(index));
		EOS_IntegratedPlatform_ClearUserPreLogoutCallbackOptions options{};
		options.ApiVersion =
			EOS_INTEGRATEDPLATFORM_CLEARUSERPRELOGOUTCALLBACK_API_LATEST;
		EOS_IntegratedPlatform_ClearUserPreLogoutCallback(
			context->integratedPlatform, &options);
		eos_sdk_TEOSIntegratedPlatformPreLogoutRegistration__Cancel(
			context->registration);
		delete context;
	}
}

} // extern "C"
