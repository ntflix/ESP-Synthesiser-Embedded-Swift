#include "BridgingHeader.h"

#include <stdint.h>
#include <string.h>

#include "esp_err.h"
#include "esp_log.h"

void swift_log_info(const char *message) {
    esp_log_write(ESP_LOG_INFO, LOG_TAG, "%s", message);
}

void swift_log_warn(const char *message) {
    esp_log_write(ESP_LOG_WARN, LOG_TAG, "%s", message);
}

void swift_log_error(const char *message) {
    esp_log_write(ESP_LOG_ERROR, LOG_TAG, "%s", message);
}

void swift_log_debug(const char *message) {
    esp_log_write(ESP_LOG_DEBUG, LOG_TAG, "%s", message);
}

void swift_log_frames_processed(uint32_t frame_count) {
    esp_log_write(ESP_LOG_INFO, LOG_TAG, "Frames processed: %lu\n", frame_count);
}
