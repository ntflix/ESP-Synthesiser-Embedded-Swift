#include "ESPIDFShim.h"
#include <math.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/i2s_std.h"

#define SAMPLES  512
#define CHANNELS  2

static i2s_chan_handle_t tx_handle = NULL;
static uint32_t          s_sample_rate = 44100;

bool i2s_hw_init(uint32_t sample_rate) {
    s_sample_rate = sample_rate;

    i2s_chan_config_t chan = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    if (i2s_new_channel(&chan, &tx_handle, NULL) != ESP_OK) return false;

    i2s_std_config_t cfg = {
        .clk_cfg  = I2S_STD_CLK_DEFAULT_CONFIG(sample_rate),
        .slot_cfg = I2S_STD_MSB_SLOT_DEFAULT_CONFIG(
                        I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_STEREO),
        .gpio_cfg = { .bclk = 5, .ws = 7, .dout = 6,
                      .mclk = I2S_GPIO_UNUSED, .din = I2S_GPIO_UNUSED },
    };
    if (i2s_channel_init_std_mode(tx_handle, &cfg) != ESP_OK) return false;
    return i2s_channel_enable(tx_handle) == ESP_OK;
}

bool i2s_hw_write(const int16_t *buf, int16_t len) {
    size_t written;
    return i2s_channel_write(tx_handle, buf,
                             (size_t)len * sizeof(int16_t),
                             &written, portMAX_DELAY) == ESP_OK;
}

bool i2s_hw_stop(void) {
    return i2s_channel_disable(tx_handle) == ESP_OK;
}

void i2s_hw_deinit(void) {
    i2s_hw_stop();
    if (tx_handle) { i2s_del_channel(tx_handle); tx_handle = NULL; }
}

bool i2s_hw_play_tone(uint32_t frequency_hz, uint32_t duration_ms, float gain) {
    if (tx_handle == NULL) return false;

    int16_t *buf = malloc(SAMPLES * CHANNELS * sizeof(int16_t));
    if (buf == NULL) return false;

    const float two_pi = 6.28318530717958647692f;
    const float amplitude = fmaxf(0.0f, fminf(gain, 1.0f)) * 30000.0f;
    const float step = two_pi * (float)frequency_hz / (float)s_sample_rate;
    const uint32_t total_frames = (s_sample_rate * duration_ms) / 1000;

    float phase = 0.0f;
    uint32_t remaining_frames = total_frames;

    while (remaining_frames > 0) {
        uint32_t frames = remaining_frames;
        if (frames > SAMPLES) frames = SAMPLES;

        for (uint32_t i = 0; i < frames * CHANNELS; i += CHANNELS) {
            int16_t sample = (int16_t)(sinf(phase) * amplitude);
            buf[i] = sample;
            buf[i + 1] = sample;
            phase += step;
            if (phase >= two_pi) phase -= two_pi;
        }

        size_t written;
        if (i2s_channel_write(tx_handle,
                              buf,
                              frames * CHANNELS * sizeof(int16_t),
                              &written,
                              portMAX_DELAY) != ESP_OK) {
            free(buf);
            return false;
        }

        remaining_frames -= frames;
    }

    free(buf);
    return true;
}

bool i2s_hw_start(void) { return true; }

float c_sinf(float x) { return sinf(x); }