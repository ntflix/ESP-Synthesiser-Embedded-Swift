struct I2SConfig {
    var sampleRate: UInt32
    var frequencyHz: UInt32

    static let `default` = I2SConfig(sampleRate: 44100, frequencyHz: 440)
}

struct I2SGenerator {
    let config: I2SConfig

    init(config: I2SConfig = .default) {
        self.config = config
    }

    func initialise() -> Bool {
        i2s_sine_init(config.sampleRate, config.frequencyHz)
    }

    func start() -> Bool {
        i2s_sine_start()
    }

    func stop() -> Bool {
        i2s_sine_stop()
    }

    func deinitialise() {
        i2s_sine_deinit()
    }
}
