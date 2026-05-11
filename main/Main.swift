@_cdecl("app_main")
func app_main() {
    let generator = I2SGenerator(config: I2SConfig(sampleRate: 44100, frequencyHz: 220))

    let initialised = generator.initialise()
    // let started = generator.start()

    print(
        "I2S sine wave generator started"
    )
    // generator.stop() / generator.deinitialise() when done
}
