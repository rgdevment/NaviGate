#ifndef RUNNER_STARTUP_TASK_CHANNEL_H_
#define RUNNER_STARTUP_TASK_CHANNEL_H_

#include <flutter/binary_messenger.h>

namespace startup_task {

void RegisterChannel(flutter::BinaryMessenger* messenger);

}  // namespace startup_task

#endif  // RUNNER_STARTUP_TASK_CHANNEL_H_
