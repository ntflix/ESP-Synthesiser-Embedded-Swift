@_cdecl("app_main")
func app_main() {
    let synth = I2SGenerator(gain: 1.0)
    synth.initialise()
    synth.start()

    playSomething(synth: synth)

    // while true {
    //     try! synth.playChord([
    //         Note(.c, octave: 4, duration: Duration(.whole)),
    //         Note(.e, octave: 4, duration: Duration(.whole)),
    //         Note(.g, octave: 4, duration: Duration(.whole)),
    //     ])

    //     try! synth.playChord([
    //         Note(.c, octave: 5, duration: Duration(.whole)),
    //         Note(.e, octave: 5, duration: Duration(.whole)),
    //         Note(.g, octave: 5, duration: Duration(.whole)),
    //     ])
    // }
}

func playSomething(synth: I2SGenerator) {
    let notes: [Note] = [
        Note(.c, octave: 5, duration: Duration(.quarter)),
        Note(.d, octave: 5, duration: Duration(.quarter)),
        Note(.e, octave: 5, duration: Duration(.quarter)),
        Note(.g, octave: 5, duration: Duration(.quarter)),
        Note(.a, octave: 5, duration: Duration(.quarter)),
        Note(.b, octave: 5, duration: Duration(.eighth)),
        Note(.a, octave: 5, duration: Duration(.quarter)),
        Note(.g, octave: 5, duration: Duration(.quarter)),
        Note(.e, octave: 5, duration: Duration(.whole)),
        Note(.d, octave: 5, duration: Duration(.whole)),
    ]

    let bassline: [Note] = [
        Note(.a, octave: 2, duration: Duration(.eighth)),
        Note(.a, octave: 3, duration: Duration(.eighth)),
        Note(.a, octave: 2, duration: Duration(.eighth)),
        Note(.a, octave: 3, duration: Duration(.eighth)),
        Note(.a, octave: 2, duration: Duration(.eighth)),
        Note(.a, octave: 3, duration: Duration(.eighth)),
        Note(.a, octave: 2, duration: Duration(.eighth)),
        Note(.a, octave: 3, duration: Duration(.eighth)),
        Note(.f, octave: 2, duration: Duration(.eighth)),
        Note(.f, octave: 3, duration: Duration(.eighth)),
        Note(.f, octave: 2, duration: Duration(.eighth)),
        Note(.f, octave: 3, duration: Duration(.eighth)),
        Note(.f, octave: 2, duration: Duration(.eighth)),
        Note(.f, octave: 3, duration: Duration(.eighth)),
        Note(.f, octave: 2, duration: Duration(.eighth)),
        Note(.f, octave: 3, duration: Duration(.eighth)),
        Note(.c, octave: 2, duration: Duration(.eighth)),
        Note(.c, octave: 3, duration: Duration(.eighth)),
        Note(.c, octave: 2, duration: Duration(.eighth)),
        Note(.c, octave: 3, duration: Duration(.eighth)),
        Note(.c, octave: 2, duration: Duration(.eighth)),
        Note(.c, octave: 3, duration: Duration(.eighth)),
        Note(.c, octave: 2, duration: Duration(.eighth)),
        Note(.c, octave: 3, duration: Duration(.eighth)),
        Note(.c, octave: 2, duration: Duration(.eighth)),
        Note(.c, octave: 3, duration: Duration(.eighth)),
        Note(.c, octave: 2, duration: Duration(.eighth)),
        Note(.c, octave: 3, duration: Duration(.eighth)),
        Note(.b, octave: 2, duration: Duration(.eighth)),
        Note(.b, octave: 3, duration: Duration(.eighth)),
        Note(.b, octave: 2, duration: Duration(.eighth)),
        Note(.b, octave: 3, duration: Duration(.eighth)),
    ]

    while true {
        // Build two independent timelines starting at frame 0
        let melodyVoices = schedule(notes, bpm: synth.bpm, sampleRate: synth.sampleRate)
        let bassVoices = schedule(bassline, bpm: synth.bpm, sampleRate: synth.sampleRate)

        // Merge — both start at t=0, play in parallel
        let timeline = melodyVoices + bassVoices

        try! synth.playTimeline(timeline)
    }
}
