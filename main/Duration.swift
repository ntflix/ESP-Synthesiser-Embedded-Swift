enum NoteValue {
    case whole
    case half
    case quarter
    case eighth
    case sixteenth
    case thirtySecond
}

enum Modifier {
    case none
    case dotted  // × 1.5
    case triplet  // × 0.667
    case doubleDotted  // × 1.75
}

struct Duration {
    let value: NoteValue
    let modifier: Modifier

    init(_ value: NoteValue, _ modifier: Modifier = .none) {
        self.value = value
        self.modifier = modifier
    }

    // Whole note = 4 beats. Each division halves the beat count.
    private var beats: Float {
        let base: Float
        switch value {
        case .whole: base = 4.0
        case .half: base = 2.0
        case .quarter: base = 1.0
        case .eighth: base = 0.5
        case .sixteenth: base = 0.25
        case .thirtySecond: base = 0.125
        }
        switch modifier {
        case .none: return base
        case .dotted: return base * 1.5
        case .triplet: return base * (2.0 / 3.0)
        case .doubleDotted: return base * 1.75
        }
    }

    func milliseconds(bpm: UInt32) -> UInt32 {
        // 1 quarter note = 60000ms / bpm
        let msPerBeat = 60000.0 / Float(bpm)
        return UInt32(beats * msPerBeat)
    }
}
