#include "ESPIDFShim.h"
#include <math.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/i2s_std.h"

#define SAMPLES 512
#define CHANNELS 2

static i2s_chan_handle_t tx_handle = NULL;
static TaskHandle_t      tx_task   = NULL;
static uint32_t          s_sample_rate = 44100;
static uint32_t          s_freq_hz     = 440;

static void sine_task(void *_) {
    int16_t *buf = malloc(SAMPLES * CHANNELS * sizeof(int16_t));
    float phase = 0.0f;
    const float step = 2.0f * M_PI * s_freq_hz / s_sample_rate;

    while (true) {
        for (int i = 0; i < SAMPLES * CHANNELS; i += CHANNELS) {
            int16_t s = (int16_t)(sinf(phase) * 30000.0f);
            buf[i] = s; buf[i + 1] = s;
            phase += step;
            if (phase >= 2.0f * M_PI) phase -= 2.0f * M_PI;
        }
        size_t written;
        i2s_channel_write(tx_handle, buf, SAMPLES * CHANNELS * sizeof(int16_t), &written, portMAX_DELAY);
    }
    free(buf);
    vTaskDelete(NULL);
}

bool i2s_sine_init(uint32_t sample_rate, uint32_t freq_hz) {
    s_sample_rate = sample_rate;
    s_freq_hz     = freq_hz;

    i2s_chan_config_t chan = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
    if (i2s_new_channel(&chan, &tx_handle, NULL) != ESP_OK) return false;

    i2s_std_config_t cfg = {
        .clk_cfg  = I2S_STD_CLK_DEFAULT_CONFIG(sample_rate),
        .slot_cfg = I2S_STD_MSB_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_STEREO),
        .gpio_cfg = { .bclk = 5, .ws = 7, .dout = 6, .mclk = I2S_GPIO_UNUSED, .din = I2S_GPIO_UNUSED },
    };
    if (i2s_channel_init_std_mode(tx_handle, &cfg) != ESP_OK) return false;
    return i2s_channel_enable(tx_handle) == ESP_OK;
}

bool i2s_sine_start(void) {
    return xTaskCreatePinnedToCore(sine_task, "i2s_sine", 4096, NULL, 5, &tx_task, 0) == pdPASS;
}

bool i2s_sine_stop(void) {
    if (tx_task) { vTaskDelete(tx_task); tx_task = NULL; }
    return i2s_channel_disable(tx_handle) == ESP_OK;
}

void i2s_sine_deinit(void) {
    i2s_sine_stop();
    if (tx_handle) { i2s_del_channel(tx_handle); tx_handle = NULL; }
}