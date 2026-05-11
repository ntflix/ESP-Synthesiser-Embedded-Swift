#ifndef BRIDGING_HEADER_H
#define BRIDGING_HEADER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

// ESP-IDF C API declarations for Swift bridging
#ifdef __cplusplus
extern "C" {
#endif

// Keep low-level ESP-IDF APIs inside the C shim implementation.
// Swift imports only the shim functions declared below.

// (Low-level ESP-IDF types and APIs are used inside the C shim implementation.)
// Swift should only see the lightweight shim APIs declared below.

#ifdef __cplusplus
} // extern "C"
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define LOG_TAG "ESPNOWMIDIBridge"

void swift_log_info(const char *message);
void swift_log_warn(const char *message);
void swift_log_error(const char *message);
void swift_log_debug(const char *message);
void swift_log_frames_processed(uint32_t frame_count);

#ifdef __cplusplus
}
#endif

#endif
