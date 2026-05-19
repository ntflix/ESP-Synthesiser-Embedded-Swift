protocol Synthesiser {
    var sampleRate: UInt32 { get }
    var bpm: UInt32 { get }
    var gain: Float { get }

    init(sampleRate: UInt32, bpm: UInt32, gain: Float)

    @discardableResult
    func initialise() -> Bool
    func start()
    func stop()
    func deinitialise()

    mutating func setGain(_ gain: Float)

    func play(_ note: Note) throws(I2SError)
    func play(_ notes: [Note]) throws(I2SError)

    // Play multiple voices simultaneously, blocking until all are done.
    // voices[] all start at t=0 and run for their individual durations.
    // master_duration caps total playback time (use longest voice duration).
    func playChord(_ voices: [Voice]) throws(I2SError)

    // Convenience: play a chord from Notes
    func playChord(_ notes: [Note]) throws(I2SError)
}
