
// from pocVectomorphic.gp
to startup {
    world = (newVWorld)

    openWindow world

   

    for i 250 {
        // top offset to save space for the toolbar :)
        box = (newVBox (rect (rand 1 500) (rand 20 500) (rand 50 100) (rand 50 100)))
         addChild (morph world) (morph box)
    }

     // Special vbox that acts as a button
    (setGlobal 'ordered' false)
    button = (newVBox (rect 0 0 200 20) (action 'startAnimation')))
    addChild (morph world) (morph button)

    // box = (newVBox (rect 150 50 100 150))
    // addChild (morph world) (morph box)

    // // Add a few more box
    // box = (newVBox (rect 100 100 100 150))
    // addChild (morph world) (morph box)

    // box = (newVBox (rect 75 25 150 100))
    // addChild (morph world) (morph box)

    // box = (newVBox (rect 250 250 50 50))
    // addChild (morph world) (morph box)
    // box = (newVBox (rect (250 + 50) 250 50 50))
    // addChild (morph world) (morph box)

    // // partially off-screen in horizontal axis
    // box = (newVBox (rect -200 -200 (+ 200 500 200) 275))
    // addChild (morph world) (morph box)

    run world
}


to startAnimation {
    ordered = (global 'ordered')

    children = (children (morph (global 'world')))
    childrenCount = ((count children) - 1) // Skip  the button
    log 'about to start animation' childrenCount
    for i childrenCount {
        m = (at children i)
        vbox = (handler m)
        if ( ordered == true) {
            addAnimation (left (bounds m)) (rand 0 500) 300 (action 'setLeft' m)
            addAnimation (top (bounds m)) (rand 0 500) 150 (action 'setTop' m)
        } else {
            bgColor = (backgroundColor vbox)
            targetX = 0
            targetY = 0
            if ((red bgColor) > 128) {
                targetX = 500
            }
            if ((green bgColor) > 128) {
                targetY = 500
            }
            addAnimation (left (bounds m)) targetX 100 (action 'setLeft' m)
            addAnimation (top (bounds m)) targetY (rand 200 350) (action 'setTop' m)
        }



    }
    (setGlobal 'ordered' (not ordered))

}
// run (new 'Sketch') // from pocSketch.gp
// run (new 'Paint') // from pocPaing.gp


