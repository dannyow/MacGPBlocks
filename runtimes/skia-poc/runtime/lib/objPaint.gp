
defineClass Paint colorButtons drawColor drawing lastX lastY mouseX mouseY mouseWasDown

to colorButton y r g b { return (array 5 y 15 15 r g b) }
  
method addButtons Paint {
  colorButtons = (newArray 12)
  atPut colorButtons 1 (colorButton 5 200 0 0) // red
  atPut colorButtons 2 (colorButton 25 0 200 0) // green
  atPut colorButtons 3 (colorButton 50 0 0 200) // blue
  atPut colorButtons 4 (colorButton 75 200 0 200) // magenta
  atPut colorButtons 5 (colorButton 100 200 200 0) // yellow
  atPut colorButtons 6 (colorButton 125 0 200 200) // cyan
  atPut colorButtons 7 (colorButton 150 255 255 255) // white
  atPut colorButtons 8 (colorButton 175 200 200 200) // light gray
  atPut colorButtons 9 (colorButton 200 150 150 150) // medium light gray
  atPut colorButtons 10 (colorButton 225 100 100 100) // medium dark gray
  atPut colorButtons 11 (colorButton 250 50 50 50) // dark gray
  atPut colorButtons 12 (colorButton 275 0 0 0) // black
}

method drawButtons Paint {
  //clearBuffer (color 240 240 240)
  for i (count colorButtons) {
    b = (at colorButtons i)
    c = (color (at b 5) (at b 6) (at b 7))
    fillRect nil c (at b 1) (at b 2) (at b 3) (at b 4)
  }
  flipBuffer
}

method mouseInButton Paint btn {
  if (mouseX < (at btn 1)) { return false }
  if (mouseY < (at btn 2)) { return false }
  if (mouseX > ((at btn 1) + (at btn 3))) { return false }
  if (mouseY > ((at btn 2) + (at btn 4))) { return false }
  return true
}

method plot Paint x y { fillRect nil drawColor x y 5 5 }

method drawBresenhamLine Paint x0 y0 x1 y1 {
  dx = (abs (x1 - x0))
  dy = (abs (y1 - y0))
  if (x0 < x1) { sx = 1 } else { sx = -1 }
  if (y0 < y1) { sy = 1 } else { sy = -1 }
  err = (dx - dy)
  while true {
	plot this x0 y0
	if (and (x0 == x1) (y0 == y1)) { return }
	e2 = (2 * err)
	if (e2 > (0 - dy)) { 
	  err = (err - dy)
	  x0 = (x0 + sx)
	}
	if (and (x0 == x1) (y0 == y1)) { 
	  plot this x0 y0
	  return
	}
	if (e2 < dx) { 
	  err = (err + dx)
	  y0 = (y0 + sy)
	}
  }
}

method setup Paint {
  closeWindow
  openWindow
  addButtons this
  drawButtons this
  drawButtons this // draw buttons in offline buffer, too
  drawing = false
  mouseWasDown = false 
}

method handleUserInput Paint {
  evt = (nextEvent)
  while (notNil evt) {
    evtType = (at evt 'type')
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
    evt = (nextEvent)
  }
}

method handleMouseDown Paint evt {
  for i (count colorButtons) {
    b = (at colorButtons i)
    if (mouseInButton this b) {
      drawColor = (color (at b 5) (at b 6) (at b 7))
	  return
	}
  }
  drawing = true
  lastX = mouseX
  lastY = mouseY
}

method run Paint {
  setup this
  while true {
    handleUserInput this
	if drawing {
	  x = mouseX
	  y = mouseY
	  drawBresenhamLine this lastX lastY x y
	  flipBuffer
	  drawBresenhamLine this lastX lastY x y // draw in other buffer, too
	  lastX = x
	  lastY = y
	}
    sleep 10
  }
}

// run (new 'Paint')
