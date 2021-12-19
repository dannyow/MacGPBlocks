
to trace args... {
  result = (list)
  for i (argCount) {
    add result (toString (arg i))
    if (i != (argCount)) {add result ' '}
  }
  log 'TRACE:' (joinStringArray (toArray result))
}

to drawFilledRect color rect {
    // trace 'primfillRect' (toString color) (toString rect)
    fillRect nil color (left rect) (top rect) (width rect) (height rect)
}


// #region VMorph
defineClass VMorph handler bounds needsDisplay children owner
to newVMorph handler bounds {
    morph = (new 'VMorph' nil bounds true (list))
    setField morph 'handler' handler
    setField morph 'owner' handler
    return morph
}

method clearNeedsDisplay VMorph { needsDisplay = false }
method setNeedsDisplay VMorph { needsDisplay = true}
method needsDisplay VMorph { 
    if (needsDisplay == true) {
        return true
    }
    for p children { 
        if (needsDisplay p) {
            return true
        }
    }
    return false
}

method bounds VMorph { return bounds }
method setBounds VMorph aRect { bounds = aRect; setNeedsDisplay this }

method setLeft VMorph v { setLeft bounds v; setNeedsDisplay this }
method setTop VMorph v { setTop bounds v; setNeedsDisplay this }
method draw VMorph {
    if (notNil handler) {
        (draw handler bounds)
    }
    clearNeedsDisplay this
    for p children { draw p  }
}

method addChild VMorph m {
    add children m
    setNeedsDisplay this
}
// #endregion

// #region VBox
defineClass VBox morph backgroundColor borderColor borderWidth
to newVBox bounds {
    box = (new 'VBox' nil (randomColor) (randomColor) 2.0)

    morph = (newVMorph box)
    setField box 'morph' morph
    (setBounds morph bounds)

    return box
}

method draw VBox bounds {
    // drawFilledRect (randomColor) (bounds morph)
    drawFilledRect backgroundColor (bounds morph)
}
// #endregion


// #region VHandController
defineClass VHandController morph color
to newVHandController {
    hand = (new 'VHandController' nil (randomColor))

    handMorph = (newVMorph hand (rect 0 0 10 10))
    setField hand 'morph' handMorph

    return hand
}
method morph VHandController { return morph }
method draw VHandController bounds {
    drawFilledRect color (bounds morph)
}
method processEvent VHandController event {
    setLeft morph (at event 'x')
    setTop morph (at event 'y')
}

// #endregion

// #region VWorld
defineClass VWorld hand morph 
to newVWorld {
    world = (new 'VWorld' (newVHandController) nil )
    return world
}


method hand VWorld {return hand}
method morph VWorld {return morph}
method setMorph VWorld aMorph { morph = aMorph }
method openWindow VWorld {
    openWindow
    setup this
}

method setup VWorld {
    windowSize = (windowSize)
    rootMorph = (newVMorph this (rect 0 0 (at windowSize 1) (at windowSize 2)))
    (setMorph this rootMorph)
}
method draw VWorld bounds {}
method processEvents VWorld {
    evt = (nextEvent)
    while (notNil evt) {
        // log 'Event' (toString evt)
        type = (at evt 'type')
        if (or (type == 'mouseMove') (type == 'mouseDown') (type == 'mouseUp')) {
            processEvent hand evt
        } ('quit' == evtType) {
            exit
        }
        evt = (nextEvent)
    }
}

method OLDprocessEvents VWorld {
    evt = (nextEvent)
    if (isNil evt) {
        return
    }
    type = (at evt 'type')
    if (or (type == 'mouseMove') (type == 'mouseDown') (type == 'mouseUp')) {
        (processEvent hand evt)
    } (type == 'quit') {
        exit
    }
    
}

method doOneCycle VWorld {
   startTime = (newTimer)

    //gcIfNeeded  
    processEvents this
    // step hand
    // step morph

    // // step animations?
    // repaint this

    rootMorph = (morph this)

    mouseMoveInducedRepaint = (needsDisplay (morph hand))
    shouldRepaint = (or (needsDisplay rootMorph) mouseMoveInducedRepaint)
    if (shouldRepaint == true){
        draw rootMorph
    }

     // Debug draw of mouse
     draw (morph hand)
    
    if (shouldRepaint == true) {
        flipBuffer
    }

    sleepTime = (max 5 (15 - (msecs startTime)))
    sleep sleepTime
    // sleep 1000
}



method interactionLoop VWorld {
    while true { doOneCycle this }
}

method run VWorld {
    interactionLoop this  

}
// #endregion
