enum NoteName: Int {
    case c = 0
    case d = 2
    case e = 4
    case f = 5
    case g = 7
    case a = 9
    case b = 11
}

enum Accidental: Int {
    case flat = -1
    case natural = 0
    case sharp = 1
}

struct Note {
    let name: NoteName
    let accidental: Accidental
    let octave: Int
    let duration: Duration

    init(
        _ name: NoteName,
        _ accidental: Accidental = .natural,
        octave: Int,
        duration: Duration = Duration(.quarter)
    ) {
        self.name = name
        self.accidental = accidental
        self.octave = octave
        self.duration = duration
    }

    // MIDI note number: C4 = 60, A4 = 69
    var midiNumber: Int {
        (octave + 1) * 12 + name.rawValue + accidental.rawValue
    }

    // Equal temperament: f = 440 * 2^((n - 69) / 12)
    var frequency: UInt32 {
        let semitones = Float(midiNumber - 69)
        let freq = 440.0 * pow_float(2.0, semitones / 12.0)
        return UInt32(freq)
    }
}

extension Note {
    init(midiNote: UInt8, duration: Duration = Duration(.quarter)) {
        let semitone = Int(midiNote) % 12
        let oct = Int(midiNote) / 12 - 1
        // Map semitone → NoteName + Accidental
        let nameTable: [(NoteName, Accidental)] = [
            (.c, .natural), (.c, .sharp), (.d, .natural), (.d, .sharp),
            (.e, .natural), (.f, .natural), (.f, .sharp), (.g, .natural),
            (.g, .sharp), (.a, .natural), (.a, .sharp), (.b, .natural),
        ]
        let (n, a) = nameTable[semitone]
        self.init(n, a, octave: oct, duration: duration)
    }
}

// pow() isn't available in Embedded Swift
private func pow_float(_ base: Float, _ exp: Float) -> Float {
    // 2^x = e^(x * ln2) approximated via integer + fractional parts
    let ln2: Float = 0.693147180559945
    return exp_float(exp * ln2)
}

private func exp_float(_ x: Float) -> Float {
    // Taylor series: e^x ≈ 1 + x + x²/2! + x³/3! + x⁴/4! + x⁵/5!
    // Accurate enough for audio frequency calculation
    let x2 = x * x
    let x3 = x2 * x
    let x4 = x3 * x
    let x5 = x4 * x
    return 1.0 + x + x2 / 2.0 + x3 / 6.0 + x4 / 24.0 + x5 / 120.0
}

func midiNoteToFrequency(_ midiNote: UInt8) -> UInt32 {
    let semitones = Float(Int(midiNote) - 69)
    return UInt32(440.0 * pow_float(2.0, semitones / 12.0))
}
