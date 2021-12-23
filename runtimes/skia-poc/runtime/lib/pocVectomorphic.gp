
to assert condition message {
    if (condition == false){
        error 'ASSERION FAILED:' message
    }
}
to trace args... {
  result = (list)
  for i (argCount) {
    add result (toString (arg i))
    if (i != (argCount)) {add result ' '}
  }
  log 'TRACE:' (joinStringArray (toArray result))
}

to drawRect rect bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY {
    drawRectLTWH (left rect) (top rect) (width rect) (height rect)  bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY
}

to test_drawRect {
    r = (rect 20 20 40 40)
    drawRectLTWH (left r) (top r) (width r) (height r) bgColor bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY

    (translateBy r 50 0)
    bgColor = (color 100 100 100 100)
    drawRectLTWH (left r) (top r) (width r) (height r) bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY

    (translateBy r 50 0)
    bgColor = (color 100 200 100 100)
    cornerRadius = 8
    drawRectLTWH (left r) (top r) (width r) (height r) bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY

    (translateBy r 50 0)
    bgColor = (color 50 200 200 )
    cornerRadius = 10
    borderWidth = 5
    drawRectLTWH (left r) (top r) (width r) (height r) bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY

    (translateBy r 50 0)
    bgColor = (color 100 250 250 100)
    cornerRadius = nil
    borderWidth = 5
    borderColor = (color 200 0 200 100)
    drawRectLTWH (left r) (top r) (width r) (height r) bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY

    (translateBy r 50 0)
    bgColor = (color 250 50 250)
    cornerRadius = 10
    borderWidth = 5
    borderColor = (color 0 100 100 )
    shadowBlur = 10
    drawRectLTWH (left r) (top r) (width r) (height r) bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY

    (translateBy r 50 0)
    bgColor = (color 60 150 250)
    cornerRadius = 10
    borderWidth = 5
    borderColor = (color 0 100 100 )
    shadowBlur = 1
    shadowColor = (color 0 0 250)
    shadowOffsetX = 10
    shadowOffsetY = 0
    drawRectLTWH (left r) (top r) (width r) (height r) bgColor cornerRadius borderWidth borderColor shadowBlur shadowColor shadowOffsetX shadowOffsetY
}


// #region VMorph
defineClass VMorph handler bounds needsDisplay children parent
to newVMorph handler bounds {
    morph = (new 'VMorph' nil bounds true (list))
    setField morph 'handler' handler
    setField morph 'parent' nil
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
method parent VMorph { return parent }
method setParent VMorph m { parent = m }
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
    assert (isNil (parent m)) 'newly added morph should not have a parent'
    add children m
    setParent m this
    setNeedsDisplay this
}
method moveToFront VMorph {
    assert (notNil parent) 'morph should have a parent'
    
    childrenToReorder = (children parent)
    index = (indexOf childrenToReorder this)
    if (index == (count childrenToReorder)){
        return
    }
  
    removeAt childrenToReorder index
    add childrenToReorder this

    setNeedsDisplay this
}

method collectChildrenAt VMorph x y targetList {
    fromLast = (reversed children)
    for m fromLast {
        collectChildrenAt m x y targetList
    }
    // //TODO: remove this hack or change it into handler interface like 'skipHitTest'
    // if ( (className (classOf handler)) == 'VWorld' )  {
    //     return targetList
    // }
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

// Use more direct approach
method draw VBox bounds {
    if ( highlighted == true){
        alpha = (alpha backgroundColor)
        shadowColor = (gray 100 alpha)
        drawRect (bounds morph) backgroundColor  5.0 2.0 nil 20 shadowColor 0 5
    }else {
        drawRect (bounds morph) backgroundColor  5.0
    } 
}
method mouseEntered VBox {
    highlighted = true
    alpha = (alpha backgroundColor)
    addAnimation alpha 255 2000 (action 'setAlpha' this)
    // backgroundColor = (withAlpha backgroundColor (alpha + 50))
    // insetBounds = (insetBy (bounds morph) -15)
    // (setBounds morph insetBounds)

    moveToFront morph
    setNeedsDisplay morph
}
method mouseExited VBox {
    highlighted = false
     alpha = (alpha backgroundColor)
    // backgroundColor = (withAlpha backgroundColor (alpha - 50))    
    // outsetBounds = (insetBy (bounds morph) 15)
    // (setBounds morph outsetBounds)

    durationInMsecs = 2000 // 100ms

    addAnimation alpha 10 durationInMsecs (action 'setAlpha' this)

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
    drawRect (bounds morph) color   
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

    gcIfNeeded  
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
    // test_drawRect

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
