

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
//  drawRect ((top r) - 10) ((left r) - 10)  ((width r) + 20) ((height r) + 20) color
//  drawRect  ((left r) - 10) ((top r) - 10) ((width r) + 20) ((height r) + 20) color
//  drawRect  ((left r) - 9) ((top r) - 9) ((width r) + 18) ((height r) + 18) color
//  drawRect  ((left r) - 8) ((top r) - 8) ((width r) + 16) ((height r) + 16) color
//  drawRect  ((left r) - 7) ((top r) - 7) ((width r) + 14) ((height r) + 14) color
//  drawRect  ((left r) - 6) ((top r) - 6) ((width r) + 12) ((height r) + 12) color
//  drawRect ((left r)+5) ((top r)+5) (width r) (height r) color
//  drawRect 0 ((top r)+20) (width r) (height r) color
//  drawRect (left r)+3 (top r)+3 (width r) (height r) color
//  drawRect (left r)+4 (top r)+4 (width r) (height r) color
//  drawRect (left r)+5 (top r)+5 (width r) (height r) color
//  drawRect (left r)+6 (top r)+6 (width r) (height r) color
}

method pixelARGB Color {
  return (+ (a << 24) ((r & 255) << 16) ((g & 255) << 8) (b & 255))
}
 
to myFunc arg {
  log 'My Func!!' (msecsSinceStart) 'Arg: ' arg
}

to startup {
  // act = (action 'myFunc' 1)
  // (call act)
  // callFunction act
  // return;
  page = (newPage 600 400)
  open page

  for i 250 {
    r = (newSkiaRect (rand 1 500) (rand 1 400) (rand 10 100) (rand 10 100) (pixelARGB (randomColor)))
    (setIndex r  i)
    //if (or (i == 10) (i == 30) ) {
      addSchedule page (schedule (action 'moveBy' r (rand -5 5) (rand -5 5)) (rand 0 100) -1)
    //}
    
    addPart (morph page) (morph r)
  }
  startStepping page
}

