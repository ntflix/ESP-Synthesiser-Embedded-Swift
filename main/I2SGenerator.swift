struct I2SGenerator: Synthesiser {
    var sampleRate: UInt32
    var bpm: UInt32
    var gain: Float

    init(sampleRate: UInt32 = 44100, bpm: UInt32 = 120, gain: Float = 0.8) {
        self.sampleRate = sampleRate
        self.bpm = bpm
        self.gain = gain
    }

    @discardableResult
    func initialise() {
        i2s_hw_init(sampleRate)
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

        let bufSize = 256
        let pcmBuf = UnsafeMutableBufferPointer<Int16>.allocate(capacity: bufSize * 2)
        defer {
            pcmBuf.deallocate()
        }

        var state = voices
        for i in 0..<state.count {
            state[i].prepare(sampleRate: sampleRate)
        }

        // Master duration = longest voice
        let masterFrames = state.map { $0.totalFrames }.max() ?? 0
        guard masterFrames > 0 else { throw I2SError.invalidInput("No valid frames to play") }

        var remainingFrames = masterFrames
        var renderedFrames: UInt32 = 0

        let voiceCount = max(1, state.count)
        var headroomShift = 0
        var pow2 = 1
        while pow2 < voiceCount {
            pow2 <<= 1
            headroomShift += 1
        }

        while remainingFrames > 0 {
            let frames = min(remainingFrames, UInt32(bufSize))

            for i in 0..<Int(frames) {
                let frameIndex = renderedFrames + UInt32(i)
                var mix: Int32 = 0

                for v in 0..<state.count {
                    if frameIndex < state[v].totalFrames {
                        // nextSample is mutating — advances phaseAccum
                        let s = state[v].nextSample(frameIndex: frameIndex)
                        mix += Int32(s * 32767.0)
                    }
                }

                let scaled = mix >> headroomShift
                let clamped = Int16(clamping: scaled)
                pcmBuf[i * 2] = clamped
                pcmBuf[i * 2 + 1] = clamped
            }

            guard i2s_hw_write(pcmBuf.baseAddress!, UInt32(frames * 2)) else {
                throw I2SError.writeFailed
            }

            remainingFrames -= frames
            renderedFrames += frames
        }
    }

    // Play scheduled voices that start at arbitrary offsets on a shared timeline.
    func playTimeline(_ scheduledVoices: [ScheduledVoice]) throws(I2SError) {
        guard !scheduledVoices.isEmpty else { return }

        var state = scheduledVoices
        let masterFrames = state.map { $0.endFrame }.max() ?? 0
        guard masterFrames > 0 else { return }

        // Normalise by peak simultaneous voices — applied as float before Int16 conversion
        let peak = Float(maxSimultaneousVoices(state))
        let normScale = 1.0 / peak  // e.g. 0.5 for 2 simultaneous voices

        let bufSize = 256
        var remainingFrames = masterFrames
        var renderedFrames: UInt32 = 0

        let pcmBuf = UnsafeMutableBufferPointer<Int16>.allocate(capacity: bufSize * 2)
        defer { pcmBuf.deallocate() }

        while remainingFrames > 0 {
            let frames = min(remainingFrames, UInt32(bufSize))

            for i in 0..<Int(frames) {
                let frameIndex = renderedFrames + UInt32(i)
                var mix: Float = 0.0  // ← Float mix bus, not Int32

                for v in 0..<state.count {
                    let sv = state[v]
                    guard frameIndex >= sv.startFrame, frameIndex < sv.endFrame else { continue }
                    let localFrame = frameIndex - sv.startFrame
                    mix += state[v].voice.nextSample(frameIndex: localFrame)
                }

                // Scale, then convert — no bit-shift rounding artifacts
                let clamped = Int16(clamping: Int32(mix * normScale * 32767.0))
                pcmBuf[i * 2] = clamped
                pcmBuf[i * 2 + 1] = clamped
            }

            guard i2s_hw_write(pcmBuf.baseAddress!, UInt32(frames * 2)) else {
                throw I2SError.writeFailed
            }

            remainingFrames -= frames
            renderedFrames += frames
        }
    }

    private func maxSimultaneousVoices(_ scheduled: [ScheduledVoice]) -> Int {
        guard !scheduled.isEmpty else { return 1 }

        var events: [(frame: UInt32, delta: Int)] = []
        events.reserveCapacity(scheduled.count * 2)
        for sv in scheduled {
            events.append((sv.startFrame, 1))
            events.append((sv.endFrame, -1))
        }

        events.sort {
            if $0.frame == $1.frame {
                return $0.delta < $1.delta
            }
            return $0.frame < $1.frame
        }

        var peak = 0
        var current = 0
        for e in events {
            current += e.delta
            if current > peak { peak = current }
        }

        return max(1, peak)
    }

    // Convenience: play a chord from Notes
    func playChord(_ notes: [Note]) throws(I2SError) {
        let voices = notes.map { note in
            Voice(
                frequencyHz: Float(note.frequency),
                durationMs: note.duration.milliseconds(bpm: bpm),
                gain: 1.0
            )
        }
        try playChord(voices)
    }

}
