
to myAction {
  print 'Hello'
}


to appendLog label {
  setText label (join (text label) 'ala' (string 13))
}


to benchmark action {
  start = (msecsSinceStart)
  call action
  stop = (msecsSinceStart)

  print 'Elapsed Time on >' action '< is' (stop - start) 'ms'
}


to benchNewArrayFor10M {
  (newArray 10000000)  
}

to benchLoop1M {
  n = 1000000
  for i n {
    i * 434243
  }
}

to benchLoop1MTrig {
  n = 1000000
  x = 0
  for i n {
    x = ((i * 434243 ) + (sin i) - (cos i))
  }
}

to startup {

  


 gc
//  benchmark 'benchNewArrayFor10M'
//  benchmark 'benchLoop1M'
 benchmark 'benchLoop1MTrig'
// gc
// benchmark 'benchLoop1M'
// gc
// benchmark 'benchLoop1M'
 return

  gc

  start = (msecsSinceStart)
  //(newArray 10000000)  
  n = 100000000
  for i n {
    i * 434243
  }

  stop = (msecsSinceStart)

  print 'Elapsed Time:' (stop - start) 'ms'
}


to demoWindow {

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

    // Text label
    // to newText aString fontName fontSize color alignment shadowColor shadowOffsetX shadowOffsetY borderX borderY editRule bgColor flat {
    plainText = (newText 'I''m a text label (try to drag me)' 'SF Compact Rounded Ultralight' (60 * 2) 'left' (color 255))
    setColor plainText (gray 255) (color 0 255) (color 0 0 255 128)
    setGrabRule (morph plainText) 'handle'

    // wrapLinesToWidth plainText 200

    addPart page plainText
    setPosition (morph plainText) 200 00

    // Add scaled up button that can be dragged with mouse
    // scaledPlainButton = (newButton 'LARGE Click Me' (action  'print' 'Boom from LARGE') )
    scaledPlainButton = (newButton 'LARGE Click Me' (action 'appendLog' plainText) )

    addPart page scaledPlainButton
    setPosition (morph scaledPlainButton) 250 250
    setScale (morph scaledPlainButton) 2.6
    setGrabRule (morph scaledPlainButton) 'handle'

    // Start 'run-loop'
    startSteppingSafely page false
}