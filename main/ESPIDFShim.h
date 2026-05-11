#pragma once
#include <stdbool.h>
#include <stdint.h>

#define MAX_VOICES 8

bool i2s_sine_init(uint32_t sample_rate, uint32_t freq_hz);
bool i2s_sine_start(void);
bool i2s_sine_stop(void);
void i2s_sine_deinit(void);

// Polyphony control
// int   i2s_voice_add(uint32_t freq_hz);    // returns voice index, -1 if full
// void  i2s_voice_remove(int voice_index);
// void  i2s_voice_remove_all(void);
// void  i2s_voice_set_freq(int voice_index, uint32_t freq_hz);