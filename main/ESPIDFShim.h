#pragma once
#include <stdbool.h>
#include <stdint.h>

#define MAX_VOICES    8
#define WAVETABLE_SIZE 1024
#define CMD_QUEUE_LEN  16
#define SAMPLES        512
#define CHANNELS       2

// Lifecycle
bool i2s_hw_init(uint32_t sample_rate);
bool i2s_hw_start(void);
bool i2s_hw_stop(void);
void i2s_hw_deinit(void);
bool i2s_hw_play_tone(uint32_t frequency_hz, uint32_t duration_ms, float gain);

// Called by Swift's audio task to write one buffer
bool i2s_hw_write(const int16_t *buf, int16_t len);

// Queue — Swift posts raw bytes, C owns the queue handle
bool  i2s_queue_send(const uint8_t *cmd_bytes, uint32_t len);
bool  i2s_queue_recv(uint8_t *cmd_bytes, uint32_t len);

// Utility
void swift_task_delay(uint32_t ticks);
void swift_task_start(void (*task_fn)(void *), const char *name,
                      uint32_t stack, uint8_t priority);

// Embedded file
const uint8_t *midi_get_embedded_file(uint32_t *out_length);

// sinf shim — Embedded Swift can't call sinf directly
float c_sinf(float x);