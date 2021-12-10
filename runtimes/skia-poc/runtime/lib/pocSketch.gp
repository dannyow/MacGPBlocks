// Sketch.gp - drawing paths with Skia POC backend

defineClass Sketch colorButtons drawColor needsUpdate drawing lastX lastY mouseX mouseY mouseWasDown

method setup Sketch {
  openWindow
  addButtons this
  needsUpdate = true
  drawing = false
  mouseWasDown = false
}

method addButtons Sketch {
}

method redraw Sketch {
  log 'redrawing'

  needsUpdate = false
}

method drawPathSegment Sketch x0 y0 x1 y1 {

}


method handleMouseDown Sketch evt {
  // for i (count colorButtons) {
  //   b = (at colorButtons i)
  //   if (mouseInButton this b) {
  //     drawColor = (color (at b 5) (at b 6) (at b 7))
  //     log 'got color'
	//   return
	// }
  // }
  // drawing = true
  // lastX = mouseX
  // lastY = mouseY
}


method handleUserInput Sketch {
  evt = (nextEvent)
  while (notNil evt) {
    evtType = (at evt 'type')
    log 'Event:' evtType  (at evt 'x') (at evt 'y')
    if ('mouseDown' == evtType) {
        mouseX = (at evt 'x')
        mouseY = (at evt 'y')
        handleMouseDown this
    }
    if ('mouseMove' == evtType) {
        mouseX = (at evt 'x')
        mouseY = (at evt 'y')
      }
    if ('mouseUp' == evtType) {
        mouseX = (at evt 'x')
        mouseY = (at evt 'y')
        drawing = false
    }
    if ('quit' == evtType) {
        exit
    }
    evt = (nextEvent)
  }
}


method run Sketch {
  setup this

  while true {
    handleUserInput this
    if drawing {
      needsUpdate = true
      x = mouseX
      y = mouseY
      drawPathSegment this lastX lastY x y
      lastX = x
      lastY = y
    }
    if needsUpdate {
      redraw this
    }
    sleep 10
  }
}

//run (new 'Sketch')

