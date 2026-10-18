/* Copyright (c) 2026 Bruce A Henderson. Licensed under zlib/libpng. */

#include <brl.mod/blitz.mod/blitz.h>

#include "../SDK/Include/eos_reports.h"
#include "../SDK/Include/eos_sanctions.h"
#include "../SDK/Include/eos_sdk.h"

#include <algorithm>
#include <cstdint>
#include <vector>

extern "C" {
void eos_sdk_TEOSSanctionsQueryRequest__Complete(
	BBObject *, EOS_EResult, EOS_ProductUserId, EOS_ProductUserId);
void eos_sdk_TEOSSanctionsQueryRequest__Cancel(BBObject *);
void eos_sdk_TEOSSanctionAppealRequest__Complete(BBObject *, EOS_EResult, BBString *);
void eos_sdk_TEOSSanctionAppealRequest__Cancel(BBObject *);
void eos_sdk_TEOSPlayerReportRequest__Complete(BBObject *, EOS_EResult);
void eos_sdk_TEOSPlayerReportRequest__Cancel(BBObject *);
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

enum class RequestKind {
	SanctionsQuery,
	SanctionAppeal,
	PlayerReport
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

RequestContext *CreateRequest(
	EOS_HPlatform platform, BBObject *request, RequestKind kind) {
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

void EOS_CALL SanctionsQueryComplete(
	const EOS_Sanctions_QueryActivePlayerSanctionsCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) {
		CompleteRequest(context);
	}
	eos_sdk_TEOSSanctionsQueryRequest__Complete(
		context->request, data->ResultCode, data->LocalUserId, data->TargetUserId);
	if (terminal) {
		delete context;
	}
}

void EOS_CALL SanctionAppealComplete(
	const EOS_Sanctions_CreatePlayerSanctionAppealCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) {
		CompleteRequest(context);
	}
	eos_sdk_TEOSSanctionAppealRequest__Complete(
		context->request, data->ResultCode, ToBBString(data->ReferenceId));
	if (terminal) {
		delete context;
	}
}

void EOS_CALL PlayerReportComplete(
	const EOS_Reports_SendPlayerBehaviorReportCompleteCallbackInfo *data) {
	if (!data || !data->ClientData) {
		return;
	}
	auto *context = static_cast<RequestContext *>(data->ClientData);
	const bool terminal = EOS_EResult_IsOperationComplete(data->ResultCode);
	if (terminal) {
		CompleteRequest(context);
	}
	eos_sdk_TEOSPlayerReportRequest__Complete(context->request, data->ResultCode);
	if (terminal) {
		delete context;
	}
}

} // namespace

extern "C" {

EOS_HSanctions bmx_eos_platform_get_sanctions_interface(EOS_HPlatform platform) {
	return platform ? EOS_Platform_GetSanctionsInterface(platform) : nullptr;
}

EOS_HReports bmx_eos_platform_get_reports_interface(EOS_HPlatform platform) {
	return platform ? EOS_Platform_GetReportsInterface(platform) : nullptr;
}

void bmx_eos_sanctions_query(
	EOS_HPlatform platform,
	EOS_HSanctions sanctions,
	BBObject *request,
	EOS_ProductUserId localUser,
	EOS_ProductUserId targetUser) {
	EOS_Sanctions_QueryActivePlayerSanctionsOptions options{};
	options.ApiVersion = EOS_SANCTIONS_QUERYACTIVEPLAYERSANCTIONS_API_LATEST;
	options.LocalUserId = localUser;
	options.TargetUserId = targetUser;
	auto *context = CreateRequest(platform, request, RequestKind::SanctionsQuery);
	EOS_Sanctions_QueryActivePlayerSanctions(
		sanctions, &options, context, SanctionsQueryComplete);
}

int bmx_eos_sanctions_get_count(
	EOS_HSanctions sanctions, EOS_ProductUserId targetUser) {
	EOS_Sanctions_GetPlayerSanctionCountOptions options{};
	options.ApiVersion = EOS_SANCTIONS_GETPLAYERSANCTIONCOUNT_API_LATEST;
	options.TargetUserId = targetUser;
	return static_cast<int>(
		EOS_Sanctions_GetPlayerSanctionCount(sanctions, &options));
}

EOS_EResult bmx_eos_sanctions_copy_by_index(
	EOS_HSanctions sanctions,
	EOS_ProductUserId targetUser,
	uint32_t index,
	int64_t *timePlaced,
	BBString **action,
	int64_t *timeExpires,
	BBString **referenceId) {
	EOS_Sanctions_CopyPlayerSanctionByIndexOptions options{};
	options.ApiVersion = EOS_SANCTIONS_COPYPLAYERSANCTIONBYINDEX_API_LATEST;
	options.TargetUserId = targetUser;
	options.SanctionIndex = index;
	EOS_Sanctions_PlayerSanction *sanction = nullptr;
	const EOS_EResult result = EOS_Sanctions_CopyPlayerSanctionByIndex(
		sanctions, &options, &sanction);
	if (result != EOS_EResult::EOS_Success || !sanction) {
		return result;
	}
	*timePlaced = sanction->TimePlaced;
	*action = ToBBString(sanction->Action);
	*timeExpires = sanction->TimeExpires;
	*referenceId = ToBBString(sanction->ReferenceId);
	EOS_Sanctions_PlayerSanction_Release(sanction);
	return result;
}

void bmx_eos_sanctions_appeal(
	EOS_HPlatform platform,
	EOS_HSanctions sanctions,
	BBObject *request,
	EOS_ProductUserId localUser,
	EOS_ESanctionAppealReason reason,
	BBString *maxReferenceId) {
	UTF8String referenceId(maxReferenceId);
	EOS_Sanctions_CreatePlayerSanctionAppealOptions options{};
	options.ApiVersion = EOS_SANCTIONS_CREATEPLAYERSANCTIONAPPEAL_API_LATEST;
	options.LocalUserId = localUser;
	options.Reason = reason;
	options.ReferenceId = referenceId.required();
	auto *context = CreateRequest(platform, request, RequestKind::SanctionAppeal);
	EOS_Sanctions_CreatePlayerSanctionAppeal(
		sanctions, &options, context, SanctionAppealComplete);
}

void bmx_eos_reports_send(
	EOS_HPlatform platform,
	EOS_HReports reports,
	BBObject *request,
	EOS_ProductUserId reporterUser,
	EOS_ProductUserId reportedUser,
	EOS_EPlayerReportsCategory category,
	BBString *maxMessage,
	BBString *maxContext) {
	UTF8String message(maxMessage);
	UTF8String reportContext(maxContext);
	EOS_Reports_SendPlayerBehaviorReportOptions options{};
	options.ApiVersion = EOS_REPORTS_SENDPLAYERBEHAVIORREPORT_API_LATEST;
	options.ReporterUserId = reporterUser;
	options.ReportedUserId = reportedUser;
	options.Category = category;
	options.Message = message.optional();
	options.Context = reportContext.optional();
	auto *context = CreateRequest(platform, request, RequestKind::PlayerReport);
	EOS_Reports_SendPlayerBehaviorReport(
		reports, &options, context, PlayerReportComplete);
}

void bmx_eos_sanctions_reports_cancel_platform_requests(EOS_HPlatform platform) {
	for (std::size_t index = 0; index < g_requests.size();) {
		auto *context = g_requests[index];
		if (context->platform != platform) {
			++index;
			continue;
		}
		g_requests.erase(g_requests.begin() + static_cast<std::ptrdiff_t>(index));
		switch (context->kind) {
		case RequestKind::SanctionsQuery:
			eos_sdk_TEOSSanctionsQueryRequest__Cancel(context->request);
			break;
		case RequestKind::SanctionAppeal:
			eos_sdk_TEOSSanctionAppealRequest__Cancel(context->request);
			break;
		case RequestKind::PlayerReport:
			eos_sdk_TEOSPlayerReportRequest__Cancel(context->request);
			break;
		}
		delete context;
	}
}

} // extern "C"
