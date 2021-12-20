
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
method handler VMorph { return handler }
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
method children VMorph { return children }
method addChild VMorph m {
    add children m
    setNeedsDisplay this
}

method collectChildrenAt VMorph x y targetList {
    fromLast = (reversed children)
    for m fromLast {
        collectChildrenAt m x y targetList
    }
    //TODO: remove this hack or change it into handler interface like 'skipHitTest'
    if ( (className (classOf handler)) == 'VWorld' )  {
        return targetList
    }
    if (containsPoint bounds x y) {
        (add targetList this)
    }
    return targetList
}

method mouseEntered VMorph {
    if (and (notNil handler) (acceptsEvents handler) ){
        (mouseEntered handler)
    }
}

method mouseExited VMorph {
    if (and (notNil handler) (acceptsEvents handler) ){
        (mouseExited handler)
    }
}
// #endregion

// #region VBox
defineClass VBox morph backgroundColor borderColor borderWidth 
to newVBox bounds {
    box = (new 'VBox' nil (withAlpha (randomColor) 200) (randomColor) 2.0)

    morph = (newVMorph box)
    setField box 'morph' morph

    (setBounds morph bounds)

    return box
}
method acceptsEvents VBox { return true }
method draw VBox bounds {
    // drawFilledRect (randomColor) (bounds morph)
    drawFilledRect backgroundColor (bounds morph)
}

method mouseEntered VBox {
    alpha = (alpha backgroundColor)
    backgroundColor = (withAlpha backgroundColor (alpha + 50))
    setNeedsDisplay morph
}
method mouseExited VBox {
    alpha = (alpha backgroundColor)
    backgroundColor = (withAlpha backgroundColor (alpha - 50))
    setNeedsDisplay morph
}
// #endregion


// #region VHandController
defineClass VHandController morph color world mouseX mouseY morphsUnderMouse
to newVHandController {
    hand = (new 'VHandController' nil (randomColor) nil 0 0 (list))

    handMorph = (newVMorph hand (rect 0 0 10 10))
    setField hand 'morph' handMorph

    return hand
}
method setWorld VHandController w { world = w }
method setPosition VHandController x y { 
    mouseX = x
    mouseY = y
    setLeft morph mouseX
    setTop morph mouseY
}
method morph VHandController { return morph }
method draw VHandController bounds {
    drawFilledRect color (bounds morph)
}
method processEvent VHandController event {
    // x = (at event 'x')
    // y = (at event 'y')
    setPosition this (at event 'x') (at event 'y')
    type = (at event 'type')
    if (type == 'mouseMove') {
        processMouseMove this
    }
}

method processMouseMove VHandController {
    rootMorph = (morph world)

    newMorphsUnderMouse = (collectChildrenAt rootMorph mouseX mouseY (list))
    oldMorphsUnderMouse = (copy morphsUnderMouse)

    for m newMorphsUnderMouse {
        if (contains oldMorphsUnderMouse m) {
            remove oldMorphsUnderMouse m
        } else {
            mouseEntered m
        }
    }
    for m oldMorphsUnderMouse {
        mouseExited m
    }

    morphsUnderMouse = newMorphsUnderMouse
}

// #endregion

// #region VWorld
defineClass VWorld hand morph 
to newVWorld {
    world = (new 'VWorld' nil nil )
    hand = (newVHandController)
    setWorld hand world
    setField world 'hand' hand

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
// Morph Handler 'interface'
method draw VWorld bounds {}
method acceptsEvents VWorld { return false }

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
