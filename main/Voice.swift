struct Voice {
    var frequencyHz: Float
    var durationMs: UInt32
    var gain: Float

    // Runtime state — set by prepare()
    var totalFrames: UInt32 = 0
    var attackFrames: UInt32 = 0
    var releaseFrames: UInt32 = 0
    private(set) var phaseAccum: UInt32 = 0
    private(set) var phaseInc: UInt32 = 0
    private var voiceGain: Float = 0

    public init(frequencyHz: Float, durationMs: UInt32, gain: Float) {
        self.frequencyHz = frequencyHz
        self.durationMs = durationMs
        self.gain = gain
    }

    mutating func prepare(sampleRate: UInt32) {
        totalFrames = (sampleRate * durationMs) / 1000
        attackFrames = max(1, (sampleRate * 8) / 1000)
        releaseFrames = max(1, (sampleRate * 24) / 1000)
        if attackFrames + releaseFrames >= totalFrames {
            attackFrames = totalFrames / 4 + 1
            releaseFrames = totalFrames / 4 + 1
        }
        phaseAccum = 0
        phaseInc = wavetable_phase_inc(frequencyHz, sampleRate)
        voiceGain = max(0, min(gain, 1.0))
    }

    // Returns a float in [-voiceGain, +voiceGain]; called once per sample
    mutating func nextSample(frameIndex: UInt32) -> Float {
        let raw = wavetable_lookup(phaseAccum)  // C shim call
        phaseAccum &+= phaseInc  // wrapping add = free modulo

        let env = envelope(at: frameIndex)
        return raw * voiceGain * env
    }

    private func envelope(at frameIndex: UInt32) -> Float {
        var env: Float = 1.0
        if frameIndex < attackFrames {
            let t = Float(frameIndex) / Float(attackFrames - 1)
            env = 0.5 - 0.5 * c_cosf(Float.pi * t)
        }
        if totalFrames > releaseFrames, frameIndex >= totalFrames - releaseFrames {
            let idxFromEnd = (totalFrames - 1) - frameIndex
            let t = Float(idxFromEnd) / Float(releaseFrames - 1)
            let rel = 0.5 + 0.5 * c_cosf(Float.pi * t)
            if rel < env { env = rel }
        }
        return env
    }
}
