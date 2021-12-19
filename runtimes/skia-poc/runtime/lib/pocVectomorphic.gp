
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
defineClass VMorph handler bounds needsDisplay
to newVMorph handler bounds {
    morph = (new 'VMorph' nil (rect) true)
    setField morph 'handler' handler
    return morph
}

method clearNeedsDisplay VMorph { needsDisplay = false }
method needsDisplay VMorph { return needsDisplay }
method setNeedsDisplay VMorph { needsDisplay = true}
method bounds VMorph { return bounds }
method setBounds VMorph aRect { bounds = aRect; setNeedsDisplay this }

method setLeft VMorph v { setLeft bounds v; setNeedsDisplay this }
method setTop VMorph v { setTop bounds v; setNeedsDisplay this }
method draw VMorph {
    if (notNil handler) {
        (draw handler bounds)
    }
}
// #endregion

// #region VHandController
defineClass VHandController morph color
to newVHandController {
    hand = (new 'VHandController' nil (randomColor))

    handMorph = (newVMorph hand)
    setField hand 'morph' handMorph

    (setBounds handMorph (rect 0 0 20 20))
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
    world = (new 'VWorld' (newVHandController) nil)
    return world
}


method hand VWorld {return hand}
method morph VWorld {return morph}
method openWindow VWorld {openWindow}

method setup VWorld {

}

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
    // DEBUG
    m = (morph hand)
    draw m

    if (needsDisplay m) {
        flipBuffer
        clearNeedsDisplay m
    }

    sleepTime = (max 5 (15 - (msecs startTime)))
    sleep sleepTime
    //sleep 60
}

method interactionLoop VWorld {
    while true { doOneCycle this }
}

method run VWorld {
    interactionLoop this  

}
// #endregion
