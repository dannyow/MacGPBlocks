

defineClass SkiaRect morph left top width height color index

to newSkiaRect x y w h c {
  return (initialize (new 'SkiaRect') x y w h c)
}
method initialize SkiaRect x y w h c {
  morph = (newMorph this)
  setPosition morph x y
  setExtent morph w h
  color = c
  return this
}
method setIndex SkiaRect i {
  index = i
}

method moveBy SkiaRect xDelta yDelta {
  // left = (left + xDelta)
  // top = (top + yDelta)
  //log 'movingBy' xDelta yDelta
  (moveBy (morph this) xDelta yDelta )
}

method redraw SkiaRect {
  //setCostume morph (newBitmap (width (bounds morph)) (height (bounds morph)) (color))
  m = (morph this)
  r = (bounds m)
  //log 'redraw' index 'bounds:' (toString (bounds m))
 // drawSkiaImage
 drawRect (left r) (top r) (width r) (height r) color
}

method pixelARGB Color {
  return (+ (a << 24) ((r & 255) << 16) ((g & 255) << 8) (b & 255))
}

to startup {
  // page = (newPage 600 400)
  // open page

  // r = (newSkiaRect (rand 1 500) (rand 1 400) (rand 10 100) (rand 10 100) (randomColor))
  // // (redraw r)
  // // (moveBy r (rand -5 5) (rand -5 5))
  // // (redraw r)
  // addSchedule page (schedule (action 'moveBy' r (rand -5 5) (rand -5 5)) (rand 0 100) -1)

  // addPart (morph page) (morph r)
  // startStepping page

  // return;

  page = (newPage 600 400)
  open page
  for i 250 {
    r = (newSkiaRect (rand 1 500) (rand 1 400) (rand 10 100) (rand 10 100) (pixelARGB (randomColor)))
    (setIndex r  i)
    addSchedule page (schedule (action 'moveBy' r (rand -5 5) (rand -5 5)) (rand 0 100) -1)
    addPart (morph page) (morph r)
  }
  startStepping page
}

defineClass SkiaTest morph

method init SkiaTest {
  morph = (newMorph this)
  setExtent morph 150 100
}

method redraw SkiaTest {
  //setCostume morph (newBitmap (width (bounds morph)) (height (bounds morph)) (color))
  log 'redraw'
  drawSkiaImage
}


to startup00 {
  
// primRef called ->applyMask
// primRef called ->drawBitmap
// primRef called ->drawString
// primRef called ->fillArray
// primRef called ->fillPixelsRGBA
// primRef called ->fillRect
// primRef called ->flipBuffer
// primRef called ->fontAscent
// primRef called ->fontDescent

// primRef called ->nextEvent

// primRef called ->openWindow

// primRef called ->showKeyboard

// primRef called ->stringWidth

// primRef called ->windowSize


    page = (newPage 1000 800)
    tryRetina = true
    setDevMode page true
    setGlobal 'page' page

    open page tryRetina 'Minimal Morphic Example' 

bl = (new 'SkiaTest')
  init bl
  setCenter (morph bl) 250 150
  addPart page bl

    //drawSkiaImage
// plainButton = (newButton 'Click Me' (action  'print' 'Boom') )
// addPart page plainButton

// // Button without handler acts as a toggle button
// toggleButton = (newButton 'Toggle Me' nil )
// addPart page toggleButton
// setPosition (morph toggleButton) 10 50

// // Add scaled up button that can be dragged with mouse
// scaledPlainButton = (newButton 'LARGE Click Me' (action  'print' 'Boom from LARGE') )
// addPart page scaledPlainButton
// setPosition (morph scaledPlainButton) 250 250
// setScale (morph scaledPlainButton) 2.6
// setGrabRule (morph scaledPlainButton) 'handle'

//        // Text label
//        // to newText aString fontName fontSize color alignment shadowColor shadowOffsetX shadowOffsetY borderX borderY editRule bgColor flat {
//        plainText = (newText 'I''m a text label (try to drag me)' 'SF Compact Rounded Ultralight' (60 * 2) 'left' (color 255))
//        // setColor plainText (gray 255) (color 0 255) (color 0 0 255 128)
//        // setGrabRule (morph plainText) 'handle'
//        setEditRule plainText 'editable'
//        addPart page plainText
//        // setPosition (morph plainText) 200 00

    // Start 'run-loop'
    startSteppingSafely page false

}

// 




to startupSDL {
  page = (newPage 600 400)
  open page
  for i 250 {
    m = (newMorph)
    setCostume m (newBitmap (rand 10 100) (rand 10 100) (randomColor))
    setPosition m (rand 1 500) (rand 1 400)
    // addSchedule page (schedule (action 'moveBy' m (rand -5 5) (rand -5 5)) (rand 0 100) -1)
    addSchedule page (schedule (action 'moveBy' m (rand -5 5) (rand -5 5)) (rand 0 100) -1)
    addPart (morph page) m
  }
  startStepping page
}





defineClass Blinker morph

method init Blinker {
  morph = (newMorph this)
  setExtent morph 150 100
}

method redraw Blinker {
  setCostume morph (newBitmap (width (bounds morph)) (height (bounds morph)) (color))
}

method step Blinker {
  if (isVisible morph) {
    hide morph
  } else {
    show morph
  }
}

to fpsDemo {
  page = (newPage 500 300)
  open page

  bl = (new 'Blinker')
  init bl
  setCenter (morph bl) 250 150
  addPart page bl

  th = (newText 'value')
  setPosition (morph th) 240 50
  addPart page th

  //sh = (slider 'horizontal' 400 (array (action 'setText' th) (action 'setFPS' (morph bl))))
  //setPosition (morph sh) 50 20
  //addPart page sh

  startStepping page
}
to startup3 {
fpsDemo

}


to startup2 {

    page = (newPage 1000 800)
    tryRetina = true
    setDevMode page true
    setGlobal 'page' page

    open page tryRetina 'Minimal Morphic Example' 
    plainButton = (newButton 'Click Me' (action  'print' 'Boom') )
    addPart page plainButton

    // Button without handler acts as a toggle button
    toggleButton = (newButton 'Toggle Me' nil )
    addPart page toggleButton
    setPosition (morph toggleButton) 10 50

    // Add scaled up button that can be dragged with mouse
    scaledPlainButton = (newButton 'LARGE Click Me' (action  'print' 'Boom from LARGE') )
    addPart page scaledPlainButton
    setPosition (morph scaledPlainButton) 250 250
    setScale (morph scaledPlainButton) 2.6
    setGrabRule (morph scaledPlainButton) 'handle'

    // Text label
    // to newText aString fontName fontSize color alignment shadowColor shadowOffsetX shadowOffsetY borderX borderY editRule bgColor flat {
    plainText = (newText 'I''m a text label (try to drag me)' 'SF Compact Rounded Ultralight' (60 * 2) 'left' (color 255))
    setColor plainText (gray 255) (color 0 255) (color 0 0 255 128)
    setGrabRule (morph plainText) 'handle'
    addPart page plainText
    setPosition (morph plainText) 200 00

    // Start 'run-loop'
    startSteppingSafely page false

}

// primRef called ->fillRect
// primRef called ->flipBuffer
// primRef called ->nextEvent
// primRef called ->openWindow
// primRef called ->windowSize

// full example
// primRef called ->applyMask
// primRef called ->drawBitmap
// primRef called ->drawString
// primRef called ->fillPixelsRGBA
// primRef called ->fillRect
// primRef called ->flipBuffer
// primRef called ->fontAscent
// primRef called ->fontDescent
// primRef called ->nextEvent
// primRef called ->openWindow
// primRef called ->setCursor
// primRef called ->setFont
// primRef called ->showKeyboard

// primRef called ->sleep
// primRef called ->stringWidth

// primRef called ->vectorFillPath
// primRef called ->vectorStrokePath
// primRef called ->warpBitmap
// primRef called ->windowSize
