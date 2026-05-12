struct I2SGenerator {
    var sampleRate: UInt32
    var bpm: UInt32
    var gain: Float

    init(sampleRate: UInt32 = 44100, bpm: UInt32 = 120, gain: Float = 1.0) {
        self.sampleRate = sampleRate
        self.bpm = bpm
        self.gain = gain
    }

    @discardableResult
    func initialise(gain: Float = 0.5) -> Bool {
        self.gain = gain
        return i2s_hw_init(sampleRate)
    }

    func start() { _ = i2s_hw_start() }

    func stop() { _ = i2s_hw_stop() }
    func deinitialise() { i2s_hw_deinit() }

    mutating func setGain(_ gain: Float) { self.gain = gain }

    func play(_ note: Note) {
        _ = i2s_hw_play_tone(note.frequency, note.duration.milliseconds(bpm: bpm), gain)
    }
    func play(_ notes: [Note]) { for n in notes { play(n) } }
}
