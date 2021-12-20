
// from pocVectomorphic.gp
to startup {
    world = (newVWorld)

    openWindow world

    
    box = (newVBox (rect 150 50 100 150))
    addChild (morph world) (morph box)

    // Add a few more box
    box = (newVBox (rect 100 100 100 150))
    addChild (morph world) (morph box)

    box = (newVBox (rect 75 25 150 100))
    addChild (morph world) (morph box)

    box = (newVBox (rect 250 250 50 50))
    addChild (morph world) (morph box)
    box = (newVBox (rect (250 + 50) 250 50 50))
    addChild (morph world) (morph box)

    // partially off-screen in horizontal axis
    box = (newVBox (rect -200 -200 (+ 200 500 200) 275))
    addChild (morph world) (morph box)


    run world
}

// run (new 'Sketch') // from pocSketch.gp
// run (new 'Paint') // from pocPaing.gp


