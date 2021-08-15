// interactively eval GP code in a morphic window

defineClass Workspace morph window textBox textFrame

method initialize Workspace contents {
  scale = (global 'scale')
  if (not (isClass contents 'String')) {contents = ''}
  window = (window 'Workspace')
  morph = (morph window)
  setHandler morph this
  setMinExtent morph (scale * 140) (scale * 50)

  textBox = (newText contents 'Courier' (15 * scale))
  setEditRule textBox 'code' 
  setGrabRule (morph textBox) 'ignore'
  setBorders textBox (border window) (border window)
  textFrame = (scrollFrame textBox (clientColor window))
  addPart morph (morph textFrame)

  setExtent morph (scale * 200) (scale * 120)
}

method fixLayout Workspace {
  fixLayout window
  fixLayout textFrame
  clientArea = (clientArea window)
  setPosition (morph textFrame) (left clientArea) (top clientArea)
  setExtent (morph textFrame) (width clientArea) (height clientArea)
}

method redraw Workspace {
  redraw window
  fixLayout this
}

method setTitle Workspace s {
  setLabelString window s
}

method setFont Workspace fontName fontSize {
  setFont textBox fontName fontSize
}

to openWorkspace page contents {
  ws = (new 'Workspace')
  initialize ws contents
  setPosition (morph ws) (x (hand page)) (y (hand page))
  addPart page ws
  return ws
}
