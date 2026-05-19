struct ScheduledVoice {
    var voice: Voice
    var startFrame: UInt32  // when this voice begins, relative to timeline start
    var endFrame: UInt32  // startFrame + voice.totalFrames
}

func schedule(
    _ notes: [Note],
    bpm: UInt32,
    sampleRate: UInt32,
    offsetFrames: UInt32 = 0
) -> [ScheduledVoice] {
    var cursor = offsetFrames
    var scheduled: [ScheduledVoice] = []
    scheduled.reserveCapacity(notes.count)

    for note in notes {
        let durationMs = note.duration.milliseconds(bpm: bpm)
        let totalFrames = (sampleRate * durationMs) / 1000
        guard totalFrames > 0 else {
            cursor &+= totalFrames
            continue
        }

        var voice = Voice(
            frequencyHz: Float(note.frequency),
            durationMs: durationMs,
            gain: 1.0
        )
        voice.prepare(sampleRate: sampleRate)

        scheduled.append(
            ScheduledVoice(
                voice: voice,
                startFrame: cursor,
                endFrame: cursor &+ totalFrames
            ))
        cursor &+= totalFrames
    }

    return scheduled
}
