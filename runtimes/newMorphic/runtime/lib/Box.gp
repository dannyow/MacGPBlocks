// morphic box handler, used as mixin in a variety of morphs

defineClass Box morph color corner border isInset hasFrame

to newBox morph color corner border isInset hasFrame {
  result = (initialize (new 'Box'))
  if (notNil morph) {
  	setField result 'morph' morph
  	setHandler morph result
  }
  if (notNil color) { setField result 'color' color }
  if (notNil corner) { setField result 'corner' corner }
  if (notNil border) { setField result 'border' border }
  if (notNil isInset) { setField result 'isInset' isInset }
  if (notNil hasFrame) { setField result 'hasFrame' hasFrame }
  return result
}

method initialize Box {
  scale = (global 'scale')
  morph = (newMorph this)
  color = (color 70 160 180)
  corner = (scale * 4)
  border = 0
  isInset = true
  hasFrame = false
  setExtent morph (60 * scale) (40 * scale)
  return this
}

method color Box {return color}
method setColor Box aColor {color = aColor}
method corner Box {return corner}
method setCorner Box num {corner = num}
method border Box {return border}
method setBorder Box num {border = num}
method isInset Box {return isInset}
method setInset Box bool {isInset = bool}
method setFrame Box bool {hasFrame = bool}

method drawOn Box aContext {
  if (0 == (alpha color)) { return }
  drawButton (getShapeMaker aContext) (left morph) (top morph) (width morph) (height morph) color corner border isInset
}

method redraw Box {
  bm = (newBitmap (width morph) (height morph))
  if (0 == (alpha color)) {return}
  drawButton (newShapeMaker bm) 0 0 (width morph) (height morph) color corner border isInset
  setCostume morph bm
}
