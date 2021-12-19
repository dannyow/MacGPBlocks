
// from pocVectomorphic.gp
to startup {
    world = (newVWorld)

    openWindow world

    box = (newVBox (rect 150 50 100 150))
    addChild (morph world) (morph box)
    

    run world
}

// run (new 'Sketch') // from pocSketch.gp
// run (new 'Paint') // from pocPaing.gp


