struct Voice {
    var frequencyHz: UInt32
    var durationMs: UInt32
    var gain: Float
    var phase: Float = 0.0

    var totalFrames: UInt32 = 0
    var attackFrames: UInt32 = 0
    var releaseFrames: UInt32 = 0
    var step: Float = 0.0

    mutating func prepare(sampleRate: UInt32) {
        self.step = Float.pi * 2.0 * Float(frequencyHz) / Float(sampleRate)
        totalFrames = (sampleRate * durationMs) / 1000
        attackFrames = (sampleRate * 8) / 1000 + 1
        releaseFrames = (sampleRate * 24) / 1000 + 1
        if attackFrames + releaseFrames >= totalFrames {
            attackFrames = totalFrames / 4 + 1
            releaseFrames = totalFrames / 4 + 1
        }
    }

    // Returns the float sample for this frame index, envelope applied
    mutating func sample(at frameIndex: UInt32) -> Float {
        var env: Float = 1.0
        if frameIndex < attackFrames {
            env = cosineRampIn(idx: frameIndex, len: attackFrames)
        }
        if totalFrames > releaseFrames, frameIndex >= totalFrames - releaseFrames {
            let idxFromEnd = (totalFrames - 1) - frameIndex
            let rel = cosineRampOut(idxFromEnd: idxFromEnd, len: releaseFrames)
            if rel < env { env = rel }
        }
        let s = c_sinf(phase) * gain * env
        phase += self.step
        if phase >= Float.pi * 2.0 { phase -= Float.pi * 2.0 }
        return s
    }

    private func cosineRampIn(idx: UInt32, len: UInt32) -> Float {
        guard len > 1 else { return 1.0 }
        let t = Float(idx) / Float(len - 1)
        return 0.5 - 0.5 * c_cosf(Float.pi * t)
    }

    private func cosineRampOut(idxFromEnd: UInt32, len: UInt32) -> Float {
        guard len > 1 else { return 0.0 }
        let t = Float(idxFromEnd) / Float(len - 1)
        return 0.5 - 0.5 * c_cosf(Float.pi * t)
    }
}
