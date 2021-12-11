// Sketch.gp - drawing paths with Skia POC backend


defineClass Path color strokeWidth points 

to newPath color strokeWidth startX startY {
    return (new 'Path' color strokeWidth (list startX startY))
}

method toString Path {
    return (join '<Path color ' color ' points ' (toString points) '>')
}

method addSegment Path x y {
    lastX = (at points ((count points) - 1))
    lastY = (last points)

    if (and (x != lastX) (y != lastY)) {
        (add points x)
        (add points y)
    }
}

method segmentsCount Path {
    return (count points) / 2
}

method draw Path {
    // log 'points' (toString points)
    // TODO: don't know how to get points contents from list in C code
    drawPath color strokeWidth (toArray points)
}

to sketchColorButton y r g b { return (array 5 y 15 15 r g b) }

defineClass Sketch colorButtons path drawColor needsUpdate drawing lastX lastY mouseX mouseY mouseWasDown allPaths

method setup Sketch {
    openWindow
    addButtons this
    needsUpdate = true
    drawing = false
    mouseWasDown = false
    allPaths = (list)

    b = (first colorButtons)
    drawColor = (color (at b 5) (at b 6) (at b 7))
}

method addButtons Sketch {
  colorButtons = (newArray 12)
  atPut colorButtons 1  (sketchColorButton 5 200 0 0) // red
  atPut colorButtons 2  (sketchColorButton 25 0 200 0) // green
  atPut colorButtons 3  (sketchColorButton 50 0 0 200) // blue
  atPut colorButtons 4  (sketchColorButton 75 200 0 200) // magenta
  atPut colorButtons 5  (sketchColorButton 100 200 200 0) // yellow
  atPut colorButtons 6  (sketchColorButton 125 0 200 200) // cyan
  atPut colorButtons 7  (sketchColorButton 150 255 255 255) // white
  atPut colorButtons 8  (sketchColorButton 175 200 200 200) // light gray
  atPut colorButtons 9  (sketchColorButton 200 150 150 150) // medium light gray
  atPut colorButtons 10 (sketchColorButton 225 100 100 100) // medium dark gray
  atPut colorButtons 11 (sketchColorButton 250 50 50 50) // dark gray
  atPut colorButtons 12 (sketchColorButton 275 0 0 0) // black
}

method drawButtons Sketch {
  for i (count colorButtons) {
    b = (at colorButtons i)
    c = (color (at b 5) (at b 6) (at b 7))
    if (drawColor == c) {
        fillRect nil c ((at b 1) - 5) (at b 2)  (at b 3) (at b 4)
    }
    fillRect nil c (at b 1) (at b 2) (at b 3) (at b 4)
  }
}

method drawPathSegment Sketch x0 y0 x1 y1 {
    if (isNil path){
        return
    }
    (addSegment path x1 y1)
    needsUpdate = true
}

method mouseInButton Sketch btn {
  if (mouseX < (at btn 1)) { return false }
  if (mouseY < (at btn 2)) { return false }
  if (mouseX > ((at btn 1) + (at btn 3))) { return false }
  if (mouseY > ((at btn 2) + (at btn 4))) { return false }
  return true
}

method handleMouseDown Sketch  {
    for i (count colorButtons) {
        b = (at colorButtons i)
        if (mouseInButton this b) {
            prevDrawColor = drawColor

            drawColor = (color (at b 5) (at b 6) (at b 7))
            
            // Quick hack, a toolbar actions as a second click on already selected color...
            if (drawColor == prevDrawColor) {
                // if user selects the first color for a second time it means - clear the image
                if (i == 1) {
                    log (string 10) 'Clearing the canvas'
                    allPaths = (list)
                    path = null
                }  (i == 2) {
                    n = 50
                    log (string 10) 'Adding extra path with' n 'points'
                    // Add debug paths
                    tmpB = (at colorButtons (rand 1 (count colorButtons)))   
                    tmpColor = (color (at tmpB 5) (at tmpB 6) (at tmpB 7))
                    p = (newPath tmpColor 4.0 25 25)
                    for k n {
                        (addSegment p (rand 25 75) (rand 25 75))
                    }
                    (add allPaths p)
                } (i == 3) {
                    log (string 10) 'Dump number of points and paths'
                    pathsCnt = (count allPaths)
                    log '   All paths:' pathsCnt
                    segmentSum = 0
                    for k pathsCnt {
                        segmentSum += (segmentsCount (at allPaths k))
                    }
                    log '   All segments:' segmentSum
                    
                }
            }

            needsUpdate = true
            return
        }
    }
    drawing = true
    strokeWidth = 4.0
    path = (newPath drawColor strokeWidth mouseX mouseY)
    lastX = mouseX
    lastY = mouseY
    needsUpdate = true
}
method handleMouseUp Sketch {
    drawing = false
    if (not (isNil path)){
        (add allPaths path)
    }
    path = nil
    needsUpdate = true
}

method handleUserInput Sketch {
  evt = (nextEvent)
  while (notNil evt) {
    evtType = (at evt 'type')
    //log 'Event:' evtType  (at evt 'x') (at evt 'y')
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
        handleMouseUp this
    }
    if ('quit' == evtType) {
        exit
    }
    evt = (nextEvent)
  }
}

method redraw Sketch {
    for i (count allPaths) {
        p = (at allPaths i)
        (draw p)
    }

    if ( not (isNil path) ){
        (draw path)
    }

    drawButtons this
    flipBuffer
    needsUpdate = false
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
    sleep 5
  }
}

//run (new 'Sketch')

