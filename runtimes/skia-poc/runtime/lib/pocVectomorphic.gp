

to trace args... {
  result = (list)
  for i (argCount) {
    add result (toString (arg i))
    if (i != (argCount)) {add result ' '}
  }
  log 'TRACE:' (joinStringArray (toArray result))
}

to drawFilledRect color rect addShadow {
    // trace 'primfillRect' (toString color) (toString rect)
    // TODO: idea for new drawRect primitive
    // Draws a filled rectangle
    // drawRect left top width height bgColor
    
    // Draws a filled rectangle with border
    // drawRect left top width height bgColor borderWidth

    // // Draws a filled rectangle with border and other color of t
    // drawRect left top width height bgColor borderWidth borderColor
    // drawRect left top width height bgColor borderWidth borderColor shadowBlur
    // drawRect left top width height bgColor borderWidth borderColor shadowBlur shadowColor


    //fillRect nil color (left rect) (top rect) (width rect) (height rect)
    shadowFlag = nil
    if (addShadow == true){
        shadowFlag = true // any value will work
    }

    fillRect shadowFlag color (left rect) (top rect) (width rect) (height rect)
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
    // TODO: implement kindof respondsToSelector aka check if handler has a required method 
    // handlerClass =  (classOf handler)
    // inspect handlerClass // methods contains list of Functions that can be called

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
defineClass VBox morph backgroundColor borderColor borderWidth highlighted fadeColor
to newVBox bounds {
    box = (new 'VBox' nil (withAlpha (randomColor) 200) (randomColor) 2.0)

    morph = (newVMorph box)
    setField box 'morph' morph

    (setBounds morph bounds)

    return box
}
method acceptsEvents VBox { return true }


    // // Use model approach
    // method draw VBox bounds {
    //     color = backgroundColor
    //     rect = bounds
    //     if (highlighted == true){
    //         alpha = (alpha backgroundColor)
    //         color = (withAlpha color (alpha + 50))
    //         rect = (insetBy bounds 15)
    //     }
    //     drawFilledRect color rect
    // }
    // method mouseEntered VBox {
    //     highlighted = true
    //     setNeedsDisplay morph
    // }
    // method mouseExited VBox {
    //     highlighted = false
    //     setNeedsDisplay morph
    // }

// Use more direct approach
method draw VBox bounds {
    // drawFilledRect (randomColor) (bounds morph)
    drawFilledRect backgroundColor (bounds morph) highlighted 
}
method mouseEntered VBox {
    highlighted = true
    alpha = (alpha backgroundColor)
    // backgroundColor = (withAlpha backgroundColor (alpha + 50))
    addAnimation alpha 255 2000 (action 'setAlpha' this)

    insetBounds = (insetBy (bounds morph) -15)
    // (setBounds morph insetBounds)

    setNeedsDisplay morph
}
method mouseExited VBox {
    highlighted = false
     alpha = (alpha backgroundColor)
    // backgroundColor = (withAlpha backgroundColor (alpha - 50))
    
    outsetBounds = (insetBy (bounds morph) 15)
    // (setBounds morph outsetBounds)

    durationInMsecs = 2000 // 100ms
    repeatCounter = 1

    addAnimation alpha 0 durationInMsecs (action 'setAlpha' this)

    // setNeedsDisplay morph
}
method printArg VBox arg {
    trace 'Arg: ' arg
}
method setAlpha VBox alpha {
    setAlpha backgroundColor alpha
    setNeedsDisplay morph
}

// #endregion
to addAnimation startValue endValue duration setterAction doneAction useFloats {
    world = (global 'world')
    if (isNil world) {
        error 'no global variable "world" was found'
    }
    addSchedule world (newAnimation startValue endValue duration setterAction doneAction useFloats)
}


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

   //log 'old:' (toString oldMorphsUnderMouse) 'new:' (toString newMorphsUnderMouse)

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
defineClass VWorld hand morph schedules
to newVWorld {
    world = (new 'VWorld' nil nil (list))
    hand = (newVHandController)
    setWorld hand world
    setField world 'hand' hand

    setGlobal 'world' world

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
        } ('quit' == type) {
            log 'Exiting'
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
    stepSchedules this

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
    // sleep 500
}

method interactionLoop VWorld {
    while true { doOneCycle this }
}

// scheduling

method addSchedule VWorld aSchedule {add schedules aSchedule}

method stepSchedules VWorld {
  if (isEmpty schedules) {return}
  done = (list)
  for each schedules {
    step each
    if (isDone each) {add done each}
  }
  removeAll schedules done
}

method removeSchedulesFor VWorld op aMorph {
  if (isEmpty schedules) {return}
  newSchedules = (list)
  for each schedules {
    if (op == (op each)) {
      if (isClass aMorph 'Morph') {
        match = (aMorph == (first (args each)))
      } else {
        match = true
      }
    } else {
      match = false
    }
    if (not match) {add newSchedules each}
    // if (op != (op each)) {add newSchedules each}
  }
  schedules = newSchedules
}

method run VWorld {
    interactionLoop this  

}
// #endregion
