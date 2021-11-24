

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

