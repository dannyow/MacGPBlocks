defineClass ShapeMaker pen

method pen ShapeMaker { return pen }

to newShapeMaker bitmap {
  return (initialize (new 'ShapeMaker') bitmap)
}

method initialize ShapeMaker aBitmap {
  if (isNil aBitmap) {
	pen = (newVectorPenOnScreen)
  } else {
	pen = (newVectorPen aBitmap)
  }
  return this
}

// shapes

method fillRectangle ShapeMaker rect fillColor {
  beginPath pen (left rect) (bottom rect)
  roundedRectPath this rect 0
  fill pen fillColor
}

method outlineRectangle ShapeMaker rect border borderColor {
  if (border <= 0) { return }
  beginPath pen (left rect) (bottom rect)
  roundedRectPath this rect 0
  stroke pen borderColor border
}

method fillRoundedRect ShapeMaker rect radius color border borderColorTop borderColorBottom {
  if (isNil border) {border = 0}
  if (border > 0) {
    if (isNil borderColorTop) {borderColorTop = (darker color)}
    if (isNil borderColorBottom) {borderBolorBottom = borderColorTop}
    rect = (insetBy rect (border / 2))
  }
  if (or ((width rect) <= 0) ((height rect) <= 0)) { return }

  radius = (min radius ((height rect) / 2) ((width rect) / 2))
  beginPath pen (left rect) ((bottom rect) - radius)
  roundedRectPath this rect radius
  fill pen color

  if (border > 0) {
    beginPath pen (left rect) ((bottom rect) - radius)
    setHeading pen 270
    roundedRectHalfPath this rect radius
    stroke pen borderColorTop border

    beginPath pen (right rect) ((top rect) + radius)
    setHeading pen 90
    roundedRectHalfPath this rect radius
    stroke pen borderColorBottom border
  }
}

method roundedRectPath ShapeMaker rect radius {
  setHeading pen 270
  if (0 == radius) {
	w = (width rect)
	h = (height rect)
	repeat 2 {
	  forward pen h
	  turn pen 90
	  forward pen w
	  turn pen 90
	}
  } else {
	repeat 2 {
	  roundedRectHalfPath this rect radius
	}
  }
}

method roundedRectHalfPath ShapeMaker rect radius {
  radius = (min radius ((height rect) / 2) ((width rect) / 2))
  w = ((width rect) - (radius * 2))
  h = ((height rect) - (radius * 2))
  corner = (sqrt ((radius * radius) * 2))
  forward pen h
  turn pen 45
  forward pen corner 50
  turn pen 45
  forward pen w
  turn pen 45
  forward pen corner 50
  turn pen 45
}

method drawCircle ShapeMaker centerX centerY radius color border borderColor {
  // Draw a circle with an optional border. If color is nil or transparent,
  // the circle is not filled.

  if (isNil border) {border = 0}
  startY = (centerY - radius)
  beginPath pen centerX startY
  turn pen 360 radius
  if (and (notNil color) ((alpha color) > 0)) {
    fill pen color
  }
  if (border > 0) {
    if (isNil borderColor) {borderColor = (gray 0)}
    stroke pen borderColor border
  }
}

method fillArrow ShapeMaker rect orientation fillColor {
  if (isNil fillColor) { fillColor = (gray 0) }
  if (orientation == 'right') {
    baseLength = (height rect)
    ak = (width rect)
    beginPath pen (left rect) (bottom rect)
    setHeading pen 270
  } (orientation == 'left') {
    baseLength = (height rect)
    ak = (width rect)
    beginPath pen (right rect) (top rect)
    setHeading pen 90
  } (orientation == 'up') {
    baseLength = (width rect)
    ak = (height rect)
    beginPath pen (right rect) (bottom rect)
    setHeading pen 180
  } (orientation == 'down') {
    baseLength = (width rect)
    ak = (height rect)
    beginPath pen (left rect) (top rect)
    setHeading pen 0
  } else {
    error (join 'unsupported orientation "' orientation '"')
  }
  gk = (baseLength / 2)
  tipLength = (sqrt ((gk * gk) + (ak * ak)))
  tipAngle = (90 + (atan gk ak))
  forward pen baseLength
  turn pen tipAngle
  forward pen tipLength
  fill pen fillColor
}

method drawLine ShapeMaker x0 y0 x1 y1 thickness color joint cap {
  beginPath pen x0 y0
  lineTo pen x1 y1
  stroke pen color thickness joint cap
}

// Tab

method drawTab ShapeMaker rect radius border color {
  radius = (min radius ((height rect) / 2) ((width rect) / 4))
  if (isNil border) {border = 0}
  halfBorder = (border / 2)
  rect = (rect ((left rect) + halfBorder) (top rect) ((width rect) - border) ((height rect) - halfBorder))

  // start at bottom right and draw base first (helps filling heuristic when simulating vector primitives)
  beginPath pen (right rect) (bottom rect)
  tabPath this rect radius
  fill pen color
  if (border > 0) {
    stroke pen (lighter color) border
  }
}

method tabPath ShapeMaker rect radius {
  w = ((width rect) - (radius * 4))
  h = ((height rect) - (radius * 2))
  corner = (sqrt ((radius * radius) * 2))

  // start at bottom right and draw base first (helps filling heuristic when simulating vector primitives)
  beginPath pen (right rect) (bottom rect)
  setHeading pen 180
  forward pen (width rect)

  setHeading pen 0
  turn pen -45
  forward pen corner -50
  turn pen -45
  forward pen h
  turn pen 45
  forward pen corner 50
  turn pen 45
  forward pen w
  turn pen 45
  forward pen corner 50
  turn pen 45

  setHeading pen 90
  forward pen h
  turn pen -45
  forward pen corner -50
  turn pen -45
}

// Speech bubble

method drawSpeechBubble ShapeMaker rect scale direction fillColor borderColor {
  if (isNil direction) { direction = 'left' }
  if (isNil fillColor) { fillColor = (gray 250) }
  if (isNil borderColor) { borderColor = (gray 140) }

  border = (2 * scale)
  radius = (5 * scale)
  tailH = (8 * scale) // height of tail
  tailW = (4 * scale) // width of tail base
  indent = (8 * scale) // horizontal distance from edge to tail

  r = (insetBy rect border)
  w = ((width r) - (2 * radius))
  h = (((height r) - tailH) - (2 * radius))

  beginPath pen (left r) ((top r) + (h + radius))
  setHeading pen 270
  forward pen h
  turn pen 90 radius
  forward pen w
  turn pen 90 radius
  forward pen h
  turn pen 90 radius
  if ('left' == direction) {
	forward pen (indent - radius)
	lineTo pen (right r) (bottom r)
	lineTo pen ((right r) - (+ indent tailW radius)) ((bottom r) - tailH)
  } ('right' == direction) {
	forward pen (w - (indent + tailW))
	lineTo pen (left r) (bottom r)
	lineTo pen ((left r) + indent) ((bottom r) - tailH)
  }
  lineTo pen ((left r) + radius) ((bottom r) - tailH)
  turn pen 90 radius

  fill pen fillColor
  stroke pen borderColor border
}

// Grips

method circleWithCrosshairs ShapeMaker size circleRadius color {
  center = (size / 2)
  circleBorder = (size / 6)
  drawCircle this center center circleRadius nil circleBorder color
  fillRectangle this (rect 0 (center - 1) size 2) color
  fillRectangle this (rect (center - 1) 0 2 size) color
}

method drawRotationHandle ShapeMaker size circleRadius color {
  center = (size / 2)
  circleBorder = (size / 6)
  drawCircle this center center circleRadius nil circleBorder color
}

method drawResizer ShapeMaker x y width height orientation isInset {
  right = (x + width)
  if ('horizontal' == orientation) { right = x }
  off = 0
  if isInset { off = 2 }
  w = 0.8
  c = (gray 130)
  space = (truncate (width / 3))
  if ('vertical' == orientation) {
	for i (width / space) {
	  baseY = (+ y ((i - 1) * space) off)
	  drawLine this x (baseY + (w * 1)) right (baseY + (w * 1)) w c
	  drawLine this x (baseY + (w * 2)) right (baseY + (w * 2)) w c
	  drawLine this x (baseY + (w * 3)) right (baseY + (w * 3)) w c
	}
  } else { // 'horizontal' or 'free'
	bottom = (y + height)
	for i (width / space) {
	  baseLeft = (+ x ((i - 1) * space) off)
	  baseRight = (+ right ((i - 1) * space) off)
	  drawLine this (baseLeft + (w * 1)) bottom (baseRight + (w * 1)) y w c
	  drawLine this (baseLeft + (w * 2)) bottom (baseRight + (w * 2)) y w c
	  drawLine this (baseLeft + (w * 3)) bottom (baseRight + (w * 3)) y w c
	}
  }
}

// Button

method drawButton ShapeMaker x y width height buttonColor corner border isInset {
  if (isNil isInset) {isInset = false}
  if isInset {
    topColor = (darker buttonColor)
    bottomColor = (lighter buttonColor)
  } else {
    topColor = (lighter buttonColor)
    bottomColor = (darker buttonColor)
  }
  fillRoundedRect this (rect x y width height) corner buttonColor border topColor bottomColor
}

// Blocks

method drawReporter ShapeMaker rect blockColor radius {
  fillRoundedRect this rect radius blockColor (blockBorder this) (topColor this blockColor) (darker blockColor)
}

method drawBlock ShapeMaker rect blockColor radius dent inset {
  // fill the block
  beginPath pen (left rect) ((bottom rect) - (radius * 2))
  blockTopPath this rect radius dent inset
  blockBottomPath this rect radius dent inset
  fill pen blockColor

  // add outline
  rect = (insetBy rect (blockBorderInset this)) // draw highlight/shadow lines inset by half the border

  beginPath pen (left rect) ((bottom rect) - (radius * 2))
  blockTopPath this rect radius dent inset
  stroke pen (topColor this blockColor) (blockBorder this)

  beginPath pen (right rect) ((top rect) + radius)
  blockBottomPath this rect radius dent inset
  stroke pen (darker blockColor) (blockBorder this)
}

method drawHatBlock ShapeMaker rect hatWidth blockColor radius dent inset {
  hatHeight = ((hatWidth / (sqrt 2)) - (hatWidth / 2))

  // fill the block
  beginPath pen (left rect) ((bottom rect) - (radius * 2))
  hatBlockTopPath this rect radius dent inset hatWidth
  blockBottomPath this rect radius dent inset
  fill pen blockColor

  // add outline
  rect = (insetBy rect (blockBorderInset this)) // draw highlight/shadow lines inset by half the border

  beginPath pen (left rect) ((bottom rect) - (radius * 2))
  hatBlockTopPath this rect radius dent inset hatWidth
  stroke pen (topColor this blockColor) (blockBorder this)

  beginPath pen (right rect) (+ (top rect) hatHeight radius)
  setHeading pen 90
  blockBottomPath this rect radius dent inset
  stroke pen (darker blockColor) (blockBorder this)
}

method drawBlockWithCommandSlots ShapeMaker rect commandSlots blockColor radius dent inset {
  scale = (blockScale)

  // contruct and fill a path including command slots
  beginPath pen (left rect) ((bottom rect) - (radius * 2))
  blockTopPath this rect radius dent inset
  for cslot commandSlots {
	slotTopPath this cslot rect radius dent inset
	slotBottomPath this cslot rect radius dent inset
  }
  blockBottomPath this rect radius dent inset
  fill pen blockColor

  // add outline
  rect = (insetBy rect (blockBorderInset this)) // draw highlight/shadow lines inset by half the border

  beginPath pen (left rect) ((bottom rect) - (radius * 2))
  blockTopPath this rect radius dent inset
  stroke pen (topColor this blockColor) (blockBorder this)
  for cslot commandSlots {
    beginPathFromCurrentPostion pen
    slotTopPath this cslot rect radius dent inset
    stroke pen (darker blockColor) (blockBorder this)

    beginPathFromCurrentPostion pen
    slotBottomPath this cslot rect radius dent inset
    stroke pen (topColor this blockColor) (blockBorder this)
  }
  beginPathFromCurrentPostion pen
  blockBottomPath this rect radius dent inset
  stroke pen (darker blockColor) (blockBorder this)
}

method slotTopPath ShapeMaker cslot rect radius dent inset {
  scale = (blockScale)

  slotTop = (((at cslot 1) - (2 * scale)) - 1)
  slotH = (((at cslot 2) - (12 * scale)) + 1)
  upperIndentInset = ((24 * scale) + 1)

  setHeading pen 90 // down
  lineTo pen (right rect) ((top rect) + slotTop)

  turn pen 90 radius

  // top slot edge to notch
  forward pen ((width rect) - upperIndentInset)

  // top notch
  blockNotch this radius (dent + 0.5) -1

  // top edge inset
  forward pen (1.5 * scale)

  // inner left of slot
  turn pen -90 radius
  forward pen slotH
}

method slotBottomPath ShapeMaker cslot rect radius dent inset {
  // bottom edge of slot and corner
  turn pen -90 radius
  lineTo pen ((right rect) - radius) (y pen)
  turn pen 90 radius
}

method blockTopPath ShapeMaker rect radius dent inset {
  dent += 2 // increase width of top indentation
  halfExtraDent = 1

  // left side
  setHeading pen 270
  forward pen ((height rect) - (radius * 3))

  // top left corner
  roundedCorner this radius 1

  // upper inset
  forward pen ((inset - radius) - halfExtraDent)

  // upper notch
  blockNotch this radius dent 1

  // top edge
  forward pen ((width rect) - (+ inset dent (radius * 3)))
  forward pen halfExtraDent

  // upper right corner
  roundedCorner this radius 1
}

method blockBottomPath ShapeMaker rect radius dent inset {
  // right side
  setHeading pen 90
  lineTo pen (x pen) ((bottom rect) - (radius * 2))

  // bottom right corner
  roundedCorner this radius 1

  // bottom edge
  forward pen ((width rect) - (+ inset dent (radius * 3)))

  // bottom notch
  blockNotch this radius dent -1

  // bottom inset
  forward pen (inset - radius)

  // bottom left corner
  roundedCorner this radius 1
}

method hatBlockTopPath ShapeMaker rect radius dent inset hatWidth {
  hatHeight = ((hatWidth / (sqrt 2)) - (hatWidth / 2))

  // left side
  setHeading pen 270
  forward pen ((height rect) - (+ hatHeight (radius * 2)))

  // top hat-curve
  turn pen 90
  forward pen hatWidth 40
  forward pen ((width rect) - (hatWidth + radius))

  // upper right corner
  roundedCorner this radius 1
}

method roundedCorner ShapeMaker radius dir {
  // Turn by 90 degrees with rounding.
  // dir is 1 for a right turn, -1 for a left turn.

  turn pen (dir * 45)
  forward pen (sqrt ((radius * radius) * 2)) (dir * 50)
  turn pen (dir * 45)
}

method blockNotch ShapeMaker radius dent dir {
  // Draw a block notch.
  // dir is 1 if notch starts with a right turn, -1 if it starts with left turn.

  diagonal = (sqrt ((radius * radius) * 2))
  turn pen (dir * 45)
  forward pen diagonal
  turn pen (dir * -45)
  forward pen dent
  turn pen (dir * -45)
  forward pen diagonal
  turn pen (dir * 45)
}

method topColor ShapeMaker blockColor {
  if (global 'flatBlocks') { return (darker blockColor) }
  return (lighter blockColor)
}

method blockBorder ShapeMaker { return (max 1 (half (blockScale))) }
method blockBorderInset ShapeMaker { return ((blockBorder this) / 2) }
