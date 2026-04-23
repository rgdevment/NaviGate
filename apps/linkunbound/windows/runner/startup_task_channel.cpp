#include "startup_task_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <thread>

#include <winrt/base.h>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Foundation.h>

namespace startup_task {

namespace {

constexpr const char* kChannelName = "linkunbound/startup_task";
constexpr const wchar_t* kTaskId = L"LinkUnboundStartup";

using FlutterMethodResult = flutter::MethodResult<flutter::EncodableValue>;
using FlutterMethodCall = flutter::MethodCall<flutter::EncodableValue>;

std::string StateToString(winrt::Windows::ApplicationModel::StartupTaskState state) {
  using S = winrt::Windows::ApplicationModel::StartupTaskState;
  switch (state) {
    case S::Disabled:
      return "disabled";
    case S::DisabledByUser:
      return "disabledByUser";
    case S::DisabledByPolicy:
      return "disabledByPolicy";
    case S::Enabled:
      return "enabled";
    case S::EnabledByPolicy:
      return "enabledByPolicy";
  }
  return "unknown";
}

void RunOnWorker(std::function<void(std::shared_ptr<FlutterMethodResult>)> work,
                 std::shared_ptr<FlutterMethodResult> result) {
  std::thread([work = std::move(work), result = std::move(result)]() {
    try {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
    } catch (...) {
      // Apartment may already be initialized for this thread.
    }
    try {
      work(result);
    } catch (winrt::hresult_error const& e) {
      result->Error("STARTUP_TASK_ERROR", winrt::to_string(e.message()));
    } catch (std::exception const& e) {
      result->Error("STARTUP_TASK_ERROR", e.what());
    } catch (...) {
      result->Error("STARTUP_TASK_ERROR", "unknown failure");
    }
  }).detach();
}

void HandleMethodCall(const FlutterMethodCall& call,
                      std::unique_ptr<FlutterMethodResult> result) {
  std::shared_ptr<FlutterMethodResult> shared(result.release());
  const std::string& method = call.method_name();

  if (method == "getState") {
    RunOnWorker([](std::shared_ptr<FlutterMethodResult> r) {
      auto task = winrt::Windows::ApplicationModel::StartupTask::GetAsync(kTaskId).get();
      r->Success(flutter::EncodableValue(StateToString(task.State())));
    }, shared);
    return;
  }

  if (method == "enable") {
    RunOnWorker([](std::shared_ptr<FlutterMethodResult> r) {
      auto task = winrt::Windows::ApplicationModel::StartupTask::GetAsync(kTaskId).get();
      auto newState = task.RequestEnableAsync().get();
      r->Success(flutter::EncodableValue(StateToString(newState)));
    }, shared);
    return;
  }

  if (method == "disable") {
    RunOnWorker([](std::shared_ptr<FlutterMethodResult> r) {
      auto task = winrt::Windows::ApplicationModel::StartupTask::GetAsync(kTaskId).get();
      task.Disable();
      r->Success(flutter::EncodableValue(StateToString(task.State())));
    }, shared);
    return;
  }

  shared->NotImplemented();
}

}  // namespace

void RegisterChannel(flutter::BinaryMessenger* messenger) {
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const FlutterMethodCall& call,
         std::unique_ptr<FlutterMethodResult> result) {
        HandleMethodCall(call, std::move(result));
      });
}

}  // namespace startup_task
