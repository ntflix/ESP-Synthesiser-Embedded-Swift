#include "ESPIDFShim.h"
#include <math.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/i2s_std.h"

#define SAMPLES   256
#define CHANNELS  2
#define DMA_BUF_COUNT 2
#define DMA_BUF_LEN   256
#define WAVETABLE_SIZE 2048

static i2s_chan_handle_t tx_handle = NULL;
static uint32_t          s_sample_rate = 44100;
static int16_t           s_out_buf[SAMPLES * CHANNELS];

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
    return 0.5f + 0.5f * cosf(3.14159265358979323846f * t);
}

bool i2s_hw_init(uint32_t sample_rate) {
    wavetable_init();
    s_sample_rate = sample_rate;

    i2s_chan_config_t chan = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    chan.dma_desc_num = DMA_BUF_COUNT;
    chan.dma_frame_num = DMA_BUF_LEN;
    if (i2s_new_channel(&chan, &tx_handle, NULL) != ESP_OK) return false;

    i2s_std_clk_config_t clk_cfg = {
        .sample_rate_hz = sample_rate,
        .clk_src = I2S_CLK_SRC_DEFAULT,
        .mclk_multiple = I2S_MCLK_MULTIPLE_256,
    };

    i2s_std_config_t cfg = {
        .clk_cfg  = clk_cfg,
        .slot_cfg = I2S_STD_MSB_SLOT_DEFAULT_CONFIG(
                        I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_STEREO),
        .gpio_cfg = {
            .bclk = 5,
            .ws = 7,
            .dout = 6,
            .mclk = I2S_GPIO_UNUSED,
            .din = I2S_GPIO_UNUSED,
        },
    };

    if (i2s_channel_init_std_mode(tx_handle, &cfg) != ESP_OK) return false;
    return i2s_channel_enable(tx_handle) == ESP_OK;
}

bool i2s_hw_write(const int16_t *buf, uint32_t len) {
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
            int16_t pcm = float_to_pcm16(voice);
            s_out_buf[i * 2] = pcm;
            s_out_buf[i * 2 + 1] = pcm;

            phase += step;
            if (phase >= two_pi) phase -= two_pi;
        }

        size_t written;
        if (i2s_channel_write(tx_handle,
                              s_out_buf,
                              frames * CHANNELS * sizeof(int16_t),
                              &written,
                              portMAX_DELAY) != ESP_OK) {
            return false;
        }

        remaining_frames -= frames;
        rendered_frames += frames;
    }

    return true;
}

bool i2s_hw_start(void) { return true; }

// Placed in flash (.rodata), not SRAM
static DRAM_ATTR float s_sine_table[WAVETABLE_SIZE] = { /* generated at startup */ };
static bool s_table_ready = false;

void wavetable_init(void) {
    if (s_table_ready) return;
    const float two_pi = 6.28318530717958647692f;
    for (int i = 0; i < WAVETABLE_SIZE; i++) {
        // Cast away const — only done once at init, not in audio path
        s_sine_table[i] = sinf(two_pi * (float)i / (float)WAVETABLE_SIZE);
    }
    s_table_ready = true;
}

// Linear interpolation lookup — called per sample per voice
float wavetable_lookup(uint32_t phase_fixed) {
    // phase_fixed is a 32-bit fixed-point number: top 11 bits = table index,
    // next 21 bits = fractional part for interpolation
    const uint32_t index_mask = WAVETABLE_SIZE - 1; // 0x7FF
    uint32_t idx0 = (phase_fixed >> 21) & index_mask;
    uint32_t idx1 = (idx0 + 1) & index_mask;
    // frac is 0.0–1.0 from the lower 21 bits
    float frac = (float)(phase_fixed & 0x1FFFFF) * (1.0f / (float)(1 << 21));
    return s_sine_table[idx0] + frac * (s_sine_table[idx1] - s_sine_table[idx0]);
}

// Phase increment for a given frequency
uint32_t wavetable_phase_inc(float frequency_hz, uint32_t sample_rate) {
    // Maps one full cycle (WAVETABLE_SIZE steps) onto the 32-bit fixed-point range
    return (uint32_t)((frequency_hz / (float)sample_rate) * (float)(1ULL << 32));
}

float c_sinf(float x) { return sinf(x); }
float c_cosf(float x) { return cosf(x); }
