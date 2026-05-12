@_cdecl("app_main")
func app_main() {
    var synth = I2SGenerator()
    synth.initialise()
    synth.start()

    // playSomething(synth: synth)
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

    while true {
        synth.play(notes)
    }
}
