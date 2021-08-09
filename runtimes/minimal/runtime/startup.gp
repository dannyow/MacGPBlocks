to startup {

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
