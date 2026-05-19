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

static inline int16_t float_to_pcm16(float sample) {
    if (sample > 1.0f) sample = 1.0f;
    if (sample < -1.0f) sample = -1.0f;
    return (int16_t)(sample * 32767.0f);
}

static inline float cosine_ramp_in(uint32_t idx, uint32_t len) {
    if (len <= 1U) return 1.0f;
    const float t = (float)idx / (float)(len - 1U);
    return 0.5f - 0.5f * cosf(3.14159265358979323846f * t);
}

static inline float cosine_ramp_out(uint32_t idx_from_end, uint32_t len) {
    if (len <= 1U) return 0.0f;
    const float t = (float)idx_from_end / (float)(len - 1U);
    return 0.5f - 0.5f * cosf(3.14159265358979323846f * t);
}

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
    if (duration_ms == 0U) return true;

    int16_t *out = malloc(SAMPLES * CHANNELS * sizeof(int16_t));
    if (out == NULL) return false;

    const float two_pi = 6.28318530717958647692f;
    const float voice_gain = fmaxf(0.0f, fminf(gain, 1.0f)) * 0.6f;
    const float step = two_pi * (float)frequency_hz / (float)s_sample_rate;
    const uint32_t total_frames = (s_sample_rate * duration_ms) / 1000;
    uint32_t attack_samples = ((s_sample_rate * 8U) / 1000U) + 1U;
    uint32_t release_samples = ((s_sample_rate * 24U) / 1000U) + 1U;
    if (attack_samples + release_samples >= total_frames) {
        attack_samples = (total_frames / 4U) + 1U;
        release_samples = (total_frames / 4U) + 1U;
    }

    float phase = 0.0f;
    float mix_bus[SAMPLES];
    uint32_t remaining_frames = total_frames;
    uint32_t rendered_frames = 0;

    while (remaining_frames > 0) {
        uint32_t frames = remaining_frames;
        if (frames > SAMPLES) frames = SAMPLES;

        for (uint32_t i = 0; i < frames; i++) {
            uint32_t frame_index = rendered_frames + i;

            float env = 1.0f;
            if (frame_index < attack_samples) {
                env = cosine_ramp_in(frame_index, attack_samples);
            }
            if (total_frames > release_samples && frame_index >= (total_frames - release_samples)) {
                uint32_t idx_from_end = (total_frames - 1U) - frame_index;
                float rel = cosine_ramp_out(idx_from_end, release_samples);
                if (rel < env) env = rel;
            }

            float voice = sinf(phase) * voice_gain * env;
            mix_bus[i] = voice;

            float out_sample = mix_bus[i];
            int16_t pcm = float_to_pcm16(out_sample);
            out[i * 2] = pcm;
            out[i * 2 + 1] = pcm;

            phase += step;
            if (phase >= two_pi) phase -= two_pi;
        }

        size_t written;
        if (i2s_channel_write(tx_handle,
                              out,
                              frames * CHANNELS * sizeof(int16_t),
                              &written,
                              portMAX_DELAY) != ESP_OK) {
            free(out);
            return false;
        }

        remaining_frames -= frames;
        rendered_frames += frames;
    }

    free(out);
    return true;
}

bool i2s_hw_start(void) { return true; }

float c_sinf(float x) { return sinf(x); }
float c_cosf(float x) { return cosf(x); }
