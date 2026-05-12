@_cdecl("app_main")
func app_main() {
    let synth = I2SGenerator(gain: 0.05)
    synth.initialise()
    synth.start()

    playSomething(synth: synth)
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
        synth.play(notes)
        synth.play(bassline)
    }
}
