struct I2SGenerator: Synthesiser {
    var sampleRate: UInt32
    var bpm: UInt32
    var gain: Float

    init(sampleRate: UInt32 = 44100, bpm: UInt32 = 120, gain: Float = 0.5) {
        self.sampleRate = sampleRate
        self.bpm = bpm
        self.gain = gain
    }

    @discardableResult
    func initialise() -> Bool {
        return i2s_hw_init(sampleRate)
    }

    func start() { _ = i2s_hw_start() }

    func stop() { _ = i2s_hw_stop() }
    func deinitialise() { i2s_hw_deinit() }

    mutating func setGain(_ gain: Float) { self.gain = gain }

    func play(_ note: Note) throws(I2SError) {
        _ = i2s_hw_play_tone(note.frequency, note.duration.milliseconds(bpm: bpm), gain)
    }
    func play(_ notes: [Note]) throws(I2SError) { for n in notes { try play(n) } }

    // Play multiple voices simultaneously, blocking until all are done.
    // voices[] all start at t=0 and run for their individual durations.
    // master_duration caps total playback time (use longest voice duration).
    func playChord(_ voices: [Voice]) throws(I2SError) {
        guard !voices.isEmpty else { throw I2SError.invalidInput("No voices to play") }

        let bufSize = 512
        let buf = UnsafeMutableBufferPointer<Int16>.allocate(capacity: bufSize * 2)
        defer { buf.deallocate() }

        var state = voices
        for i in 0..<state.count {
            state[i].prepare(sampleRate: sampleRate)
        }

        // Master duration = longest voice
        let masterFrames = state.map { $0.totalFrames }.max() ?? 0
        guard masterFrames > 0 else { throw I2SError.invalidInput("No valid frames to play") }

        var remainingFrames = masterFrames
        var renderedFrames: UInt32 = 0

        let voiceScale = 1.0 / Float(state.count).squareRoot()  // Prevent clipping when mixing multiple voices

        while remainingFrames > 0 {
            let frames = min(remainingFrames, UInt32(bufSize))

            for i in 0..<Int(frames) {
                let frameIndex = renderedFrames + UInt32(i)
                var mix: Float = 0.0

                for v in 0..<state.count {
                    // Voice is silent after its own duration ends
                    if frameIndex < state[v].totalFrames {
                        mix += state[v].sample(at: frameIndex)
                    }
                }

                mix *= voiceScale  // perceptual headroom

                let pcm = Int16(softClip(mix) * 32767.0)
                buf[Int(i) * 2] = pcm
                buf[Int(i) * 2 + 1] = pcm
            }

            guard i2s_hw_write(buf.baseAddress!, Int16(frames * 2)) else {
                throw I2SError.writeFailed
            }

            remainingFrames -= frames
            renderedFrames += frames
        }
    }

    // Convenience: play a chord from Notes
    func playChord(_ notes: [Note]) throws(I2SError) {
        let voices = notes.map { note in
            Voice(
                frequencyHz: note.frequency,
                durationMs: note.duration.milliseconds(bpm: bpm),
                gain: 1.0
            )
        }
        try playChord(voices)
    }

    // Soft clip via tanh — smooth, no discontinuity
    // tanh(x) naturally saturates toward ±1.0
    private func softClip(_ x: Float) -> Float {
        // Fast tanh approximation valid for |x| < 4
        // For |x| >= 4, output is ±1.0 anyway
        let x2 = x * x
        return x * (27.0 + x2) / (27.0 + 9.0 * x2)
    }
}
