// Block
// Handlers for the GP blocks GUI

defineClass Block morph blockSpec type expression labelParts corner rounding dent inset hatWidth border color expansionLevel function isAlternative layoutNeeded

to block type color opName {
  scale = (blockScale (new 'Block'))

  if (isNil opName) {opName = 'foo'}
  if (isNil type) {type = 'command'} // type can be 'command', 'reporter' or 'hat'
  if (isNil color) {color = (gray 150)}
  labelParts = (list (list))
  for i ((argCount) - 2) {add (at labelParts 1) (arg (i + 2))}
  lc = (gray 255)
  fn = 'Verdana Bold'
  fontSize = (11 * scale)
  if (or ('Linux' == (platform)) ('Browser' == (platform))) {
	fn = 'Arial Bold'
	fontSize = (15 * scale)
  }
  if ((count (at labelParts 1)) == 0)  {
    labelParts = (list (list (newText opName fn fontSize lc)))
    op = opName
  } else {
    op = (arg 3)
  }
  group = (at labelParts 1)
  for i (count group) {
    part = (at group i)
    if (isClass part 'String') {
      atPut group i (newText part fn fontSize lc)
    } (isClass part 'Command') {
      inp = (newCommandSlot color)
      atPut group i inp
    }
  }
  argValues = (list op)
  for each group {
    if (isAnyClass each 'InputSlot' 'BooleanSlot' 'ColorSlot' 'CommandSlot' 'MicroBitDisplaySlot') {add argValues (contents each)}
  }
  block = (new 'Block')
  setField block 'type' type
  setField block 'labelParts' labelParts
  setField block 'color' color
  setField block 'corner' 3
  setField block 'rounding' 8
  setField block 'dent' 2
  setField block 'hatWidth' 80
  setField block 'inset' 4
  setField block 'border' 1
  setField block 'expansionLevel' 1
  setField block 'layoutNeeded' true
  morph = (newMorph block)
  if (type == 'command') {
    setField block 'expression' (callWith 'newCommand' (toArray argValues))
  } (type == 'hat') {
    setField block 'expression' (newCommand 'nop')
  } (type == 'reporter') {
    setField block 'expression' (callWith 'newReporter' (toArray argValues))
  }
  setMorph block morph
  setGrabRule morph 'handle'
  setTransparentTouch morph false
  for each group {addPart (morph block) (morph each)}
  layoutChanged block
  fixLayout block
  return block
}

to slot contents isID {
  if (isNil isID) {isID = false}
  if (isAnyClass contents 'Integer' 'Float') {
    inp = (newInputSlot contents 'numerical')
    setGrabRule (morph inp) 'ignore'
    return inp
  } (isClass contents 'String') {
    inp = (newInputSlot contents 'editable')
    setGrabRule (morph inp) 'ignore'
    return inp
  } (isClass contents 'Boolean') {
    inp = (newBooleanSlot contents)
    return inp
  } (isClass contents 'Color') {
    inp = (newColorSlot contents)
    return inp
  } else {
    inp = (newInputSlot contents 'static')
    setID inp isID
    setGrabRule (morph inp) 'defer'
    return inp
  }
}

to blockScale {
  if (isNil (global 'blockScale')) { setGlobal 'blockScale' 1.25 }
  return ((global 'blockScale') * (global 'scale'))
}

method fixLayoutNow Block {
  layoutNeeded = true
  fixLayout this
}

method fixLayout Block {
  if (isNil layoutNeeded) { layoutNeeded = true }
  if (not layoutNeeded) { return }
  scale = (blockScale)
  wasHighlighted = false

  if (and (isClass (handler (owner morph)) 'ScriptEditor') (notNil (getHighlight morph))) {
	removeHighlight morph
	wasHighlighted = true
  }

  // fix layout of parts
  for m (parts morph) {
	if (isClass (handler m) 'Block') { fixLayout (handler m) }
	if (isClass (handler m) 'CommandSlot') {
	  nestedBlock = (nested (handler m))
	  if (notNil nestedBlock) { fixLayout nestedBlock }
	  fixLayout (handler m)
	}
	if (isClass (handler m) 'InputDeclaration') {
	  fixLayout (handler m)
	}
  }

  space = 3
  vSpace = 3

  break = 450
  lineHeights = (list)
  lines = (list)
  lineArgCount = 0

  left = (left morph)
  h = 0
  w = 0

  if (type == 'hat') {
    indentation = (* scale (+ border space space))
  } (type == 'reporter') {
    indentation = (* scale rounding)
  } (type == 'command') {
    indentation = (* scale (+ border space space border))
  }

  // arrange label parts horizontally and break up into lines
  breakLineBeforeFirstArg = ((count (argList expression)) >= 5)
  currentLine = (list)
  for group labelParts {
    for each group {
      if (isVisible (morph each)) {
        if (isClass each 'CommandSlot') {
          if (notEmpty currentLine) {
          	add lines currentLine
          	add lineHeights h
          }
          fastSetLeft (morph each) (+ left (* scale (+ border corner)))
          add lines (list each)
          add lineHeights (height (morph each))
          currentLine = (list)
          w = 0
          h = 0
        } else {
          x = (+ left indentation w)
          w += (width (fullBounds (morph each)))
          w += (space * scale)
          if (and breakLineBeforeFirstArg (not (isClass each 'Text'))) {
			breakLineBeforeFirstArg = false // only do this once
 			lineArgCount = 10 // force a line break before first arg for blocks with >=5 args
		  }
		  if (and ('[display:mbDisplay]' == (primName expression)) (each == (first group))) {
			lineArgCount = 10 // force a line break after first item of block
		  }
		  if ('if' == (primName expression)) { lineArgCount = 0 } // never break 'if' blocks
		  if (and (or (w > (break * scale)) (lineArgCount >= 5)) (notEmpty currentLine)) {
			if (notEmpty currentLine) {
			  add lines currentLine
			  add lineHeights h
			  currentLine = (list)
			}
            h = 0
            x = (+ left indentation)
            w = ((width (fullBounds (morph each))) + (space * scale))
            lineArgCount = 0
          }
          add currentLine each
          h = (max h (height (morph each)))
          fastSetLeft (morph each) x
		  if (not (isClass each 'Text')) { lineArgCount += 1 }
        }
      }
    }
  }

  // add the block drawer, if any
  drawer = (drawer this)
  if (notNil drawer) {
    x = (+ left indentation w)
    w += (width (fullBounds (morph drawer)))
    w += (space * scale)
    if (and (w > (break * scale)) (notEmpty currentLine)) {
      if (notEmpty currentLine) {
		add lines currentLine
		add lineHeights h
		currentLine = (list)
	  }
      h = 0
      x = (+ left indentation)
      w = ((width (fullBounds (morph drawer))) + (space * scale))
    }
    add currentLine drawer
    h = (max h (height (morph drawer)))
    fastSetLeft (morph drawer) x
  }

  // add last line
  if (notEmpty currentLine) {
	add lines currentLine
	add lineHeights h
  }

  // determine blockWidth from line data
  blockWidth = 0
  for each lines {
    if (notEmpty each) {
      elem = (last each)
      if (not (isClass elem 'CommandSlot')) {
        blockWidth = (max blockWidth ((right (fullBounds (morph elem))) - left))
      }
    }
  }
  blockHeight = (callWith + (toArray lineHeights))
  blockHeight += (* (count lines) vSpace scale)

  // arrange label parts vertically
  tp = (+ (top morph) (* 2 scale border))
  if (type == 'hat') {
    tp += (hatHeight this)
  }
  line = 0
  for eachLine lines {
    line += 1
    bottom = (+ tp (at lineHeights line) (vSpace * scale))
    for each eachLine {
      fastSetYCenterWithin (morph each) tp bottom
    }
    tp = bottom
  }

  // add extra space below the bottom-most c-slot
  extraSpace = 0
  if (isClass (last (last labelParts)) 'CommandSlot') {
	// adjust space below last command slot
	if (isNil drawer) {
	  extraSpace = (scale * corner)
	} else {
	  // adjust layout of final block drawer in if-else block
	  blockHeight += (-6 * scale)
	  fastMoveBy (morph drawer) 0 (-5 * scale)
	}
  }

  // adjust block width (i.e. right margin)
  if (type == 'command') {
	blockWidth += (-3 * scale)
  } (type == 'hat') {
	blockWidth += (-2 * scale)
  } (type == 'reporter') {
	blockWidth += (-8 * scale)
  }

  if (type == 'command') {
    setWidth (bounds morph) (max (scale * 50) (+ blockWidth indentation (scale * corner)))
    setHeight (bounds morph) (+ blockHeight (* scale corner) (* scale border 4) extraSpace)
  } (type == 'hat') {
    setWidth (bounds morph) (max (scale * (+ hatWidth 20)) (+ blockWidth indentation (scale * corner)))
    setHeight (bounds morph) (+ blockHeight (* scale corner 2) (* scale border) (hatHeight this) extraSpace)
  } (type == 'reporter') {
    setWidth (bounds morph) (max (scale * 20) (+ blockWidth indentation (scale * rounding)))
    setHeight (bounds morph) (+ blockHeight (* scale border 4) extraSpace)
  }

  if ((localized 'RTL') == 'true') { fixLayoutRTL this }

  nb = (next this)
  if (notNil nb) {
    fastSetPosition (morph nb) (left morph) (- (+ (top morph) (height morph)) (scale * corner))
  }
  rerender morph
  if wasHighlighted { addHighlight morph }
  layoutNeeded = false
}

method drawOn Block ctx {
	scale = (blockScale)
	sm = (getShapeMaker ctx)
	r = (bounds morph)
	if (type == 'command') {
		commandSlots = (commandSlots this)
		if (isEmpty commandSlots) {
			drawBlock sm r color (scale * corner) (scale * dent) (scale * inset)
		} else {
			drawBlockWithCommandSlots sm r commandSlots color (scale * corner) (scale * dent) (scale * inset)
		}
	} (type == 'reporter') {
		clr = color
		if (getAlternative this) { clr = (lighter color 17) }
		drawReporter sm r clr (scale * rounding)
	} (type == 'hat') {
		drawHatBlock sm r (scale * hatWidth) color (scale * corner) (scale * dent) (scale * inset)
	}
}

method commandSlots Block {
	result = (list)
	top = (top morph)
	for m (parts morph) {
		if (isClass (handler m) 'CommandSlot') { add result (list ((top m) - top) (height m)) }
	}
	return result
}

method hatHeight Block {
  scale = (blockScale)
  hw = (scale * hatWidth)
  ru = (hw / (sqrt 2))
  return (truncate (ru - (hw / 2)))
}

// accessing

method type Block {return type}
method corner Block {return corner}
method scale Block {return scale}
method blockSpec Block {return blockSpec}
method function Block {return function}
method isPrototype Block {return (notNil function)}

method bottomLine Block {
  scale = (blockScale)
  return ((bottom morph) - (scale * corner))
}

method blockDefinition Block {
  if (isNil function) {return nil}
  if ((count labelParts) < 1) {return nil}
  def = (first (first labelParts))
  if (not (isClass def 'BlockDefinition')) {return nil}
  return def
}

method editedDefinition Block {
  prot = (editedPrototype this)
  if (notNil prot) {
    return (blockDefinition prot)
  }
  return nil
}

method expression Block className {
  if (isPrototypeHat this) {
    prot = (editedPrototype this)
    parms = (toList (argNames (function prot)))
    body = (next this)
    if (notNil body) {
      body = (expression body)
    }
    if (and (notNil className) (isMethod (function prot))) {
      def = (list 'method' (functionName (function prot)) className)
      removeFirst parms
    } else {
      def = (list 'to' (functionName (function prot)))
    }
    addAll def parms
    add def body
    expr = (callWith 'newCommand' (toArray def))
    return expr
  }
  return expression
}

method isPrototypeHat Block {
  if (type != 'hat') {return false}
  inp = (inputs this)
  if ((count inp) < 1) {return false}
  prot = (first inp)
  if (not (isClass prot 'Block')) {return false}
  return (isPrototype prot)
}

method editedPrototype Block {
  if (type != 'hat') {return nil}
  inp = (inputs this)
  if ((count inp) < 1) {return nil}
  prot = (first inp)
  if (not (isClass prot 'Block')) {return nil}
  if (isPrototype prot) {return prot}
  return nil
}

method contents Block {
  // for compatibility with input slots and command slots
  // in case a 'var' type slot has been renamed by the user
  // we might want to refactor 'expression' to 'contents' at some point
  return expression
}

method inputIndex Block anInput {
  idx = 0
  items = (flattened labelParts)

  // special case for variable assignments
  opName = (primName expression)
  if (or (opName == '=') (opName == '+=')) {
    // transformed assignment blocks represent the variable name as Text,
    // not an InputSlot; in this case, increment the input slot index
    if (and ((count items) > 1) (isClass (at items 2) 'Text')) {idx += 1}
  }

  for each items {
    if (isAnyClass each 'InputSlot' 'BooleanSlot' 'ColorSlot' 'CommandSlot' 'Block' 'MicroBitDisplaySlot') {
      idx += 1
      if (each === anInput) {return idx}
    }
  }
  return nil
}

method inputs Block {
  // disregard variable accessing
  return (filter
    (function each {return (isAnyClass each 'InputSlot' 'BooleanSlot' 'ColorSlot' 'CommandSlot' 'Block' 'MicroBitDisplaySlot')})
    (flattened labelParts)
  )
}

// events

method justDropped Block hand {
  snap this (x hand) (y hand)
}

method snap Block x y {
  scale = (blockScale)
  if (isNil x) {
    fb = (fullBounds morph)
    x = (left fb)
    y = (top fb)
  }
  parent = (handler (owner morph))
  if (isClass parent 'ScriptEditor') {
    b = (targetFor parent this x y)
    if (and (isClass b 'Block') ((type b) != 'reporter')) { // command or hat type targets
      recordDrop parent this b (next b)
      setNext b this
    } (isClass b 'Array') {
      recordDrop parent this b
      b = (at b 1)
      bb = (bottomBlock this)
      setPosition morph (left (morph b)) (+ (scale * corner) ((top (morph b)) - (height (fullBounds (morph this)))))
      setNext bb b
    } (isClass b 'CommandSlot') {
      recordDrop parent this b (nested b)
      setNested b this
    } (notNil b) { // dropped reporter
      tb = (handler (owner (morph b)))
      if (isClass tb 'Block') {
        recordDrop parent this tb nil b
        replaceInput tb b this
      }
    } else { // no snap target, record drop on scripting area
      recordDrop parent this
      if ('reporter' == type) { fixBlockColor this }
    }
    tb = (topBlock this)
    removeStackPart (morph tb)
    removeHighlight (morph tb)
    if (isClass (handler (owner (morph parent))) 'ScrollFrame') {updateSliders (handler (owner (morph parent)))}
  }
}

method aboutToBeGrabbed Block {
  if (isNil (owner morph)) {return}
  tb = (topBlock this)
  se = (ownerThatIsA (morph tb) 'ScriptEditor')
  if (notNil se) {
    stopEditing (handler se)
  }
  removeSignalPart (morph tb)
  removeStackPart (morph tb)
  removeHighlight (morph tb)
  parent = (handler (owner morph))
  if (isClass parent 'Block') {
    if (type == 'reporter') {
      revertToDefaultInput parent this
    } else {
      setNext parent nil
    }
  } (isClass parent 'CommandSlot') {
    setNested parent nil
  }
}

method layoutChanged Block origin {
	changed morph
	layoutNeeded = true
	raise morph 'layoutChanged' origin
}

method inputChanged Block aSlotOrReporter {
  value = (contents aSlotOrReporter)
  if (and (isClass aSlotOrReporter 'Block') ('template' == (grabRule (morph aSlotOrReporter)))) {
    varExpr = (expression aSlotOrReporter)
    if (isOneOf (primName varExpr) 'v' 'my') {
      // this is a 'var' slot; use variable name as input
      value = (first (argList varExpr))
    }
  } else {
    // the user has changed the default value of a formal parameter declaration
    id = (ownerThatIsA (morph aSlotOrReporter) 'InputDeclaration')
    if (notNil id) {
      setDefault (handler id) value
      return
    }
  }
  setArg expression (inputIndex this aSlotOrReporter) value
  raise morph 'scriptChanged' this
}

method expressionChanged Block changedBlock {
  if (isPrototype this) {
    return
  } (or (type == 'reporter') ((type changedBlock) == 'reporter')) {
    idx = (inputIndex this changedBlock)
    if (notNil idx) {
      setArg expression idx (expression changedBlock)
      return
    }
  } (changedBlock == (next this)) {
    setField expression 'nextBlock' (expression changedBlock)
    return
  }
  raise morph 'expressionChanged' changedBlock
}

method clicked Block hand {
  tb = (topBlock this)
  kbd = (keyboard (page hand))
  if (shiftKeyDown kbd) {
    scripts = (ownerThatIsA (owner morph) 'ScriptEditor')
    if (notNil scripts) {
      edit (handler scripts) this
      return
    }
  } (and (devMode) (keyDown kbd 'space')) {
    turnIntoText (topBlock this) hand
    return true
  } (and (devMode) (keyDown kbd 'x')) { // press x on click to remove block
    isInPalette = ('template' == (grabRule (morph tb)))
    if  (not isInPalette) {
      (delete tb)
    }
    return true
  }

  if (and (contains (array 'template' 'defer') (grabRule morph)) (isRenamableVar this)) {
    userRenameVariable this
    return
  } (isPrototype this) {
    def = (blockDefinition this)
    if (notNil def) {
      return (clicked def hand)
    }
    return true
  } (isPrototypeHat this) {
    prot = (editedPrototype this)
    if (notNil prot) {
      return (clicked prot hand)
    }
  } (isClass (handler (owner morph)) 'BlockOp') {
    return
  }

  cmdList = (expression tb)
  // if this block is in a Scripter, run it in the context of the Scriptor's targetObj
  scripter = (ownerThatIsA morph 'Scripter')
  if (notNil scripter) { targetObj = (targetObj (handler scripter)) }

  if (isRunning (page hand) cmdList targetObj) {
    stopRunning (page hand) cmdList targetObj
  } else {
    launch (page hand) cmdList targetObj (action 'showResult' tb)
  }
  return true
}

method doubleClicked Block hand {
  if (isPrototype this) {
    def = (blockDefinition this)
    if (notNil def) {
      closeUnclickedMenu (page hand) this
      return (doubleClicked def hand)
    }
  } (isPrototypeHat this) {
    prot = (editedPrototype this)
    if (notNil prot) {
      return (doubleClicked prot hand)
    }
  }
  return false
}

method showResult Block result {
  if ((type this) == 'reporter') {
	if (isNil result) {result = 'result is missing'}
	showHint morph (printString result) 300
  } (notNil result) {
	showHint morph (printString result) 300
  }
}

method rightClicked Block aHand {
  se = (ownerThatIsA morph 'ScriptEditor')
  if (notNil se) {
    stopEditing (handler se)
  }
  if (isPrototype this) {
    def = (blockDefinition this)
    if (notNil def) {
      return (rightClicked def hand)
    }
  } (isPrototypeHat this) {
    return (rightClicked (editedPrototype this) aHand)
  }
  popUpAtHand (contextMenu this) (page aHand)
  return true
}

method okayToBeDestroyedByUser Block {
  if (isPrototypeHat this) {
	editor = (findProjectEditor)
	if (isNil editor) { return false }
    function = (function (first (inputs this)))
    if (confirm (global 'page') nil 'Are you sure you want to remove this block definition?') {
	  removedUserDefinedBlock (scripter editor) function
      return true
    }
    return false
  }
  return true
}

// stacking

method next Block {
  items = (count (flattened labelParts))
  offset = 1
  if (and (isVariadic this) (not (isPrototype this))) {offset = 2} // because there is also a drawer
  if ((count (parts morph)) > (items + (offset - 1))) {return (handler (at (parts morph) (+ offset items)))}
  return nil
}

method previous Block {
  parent = (ownerThatIsA (owner morph) 'Block')
  if (notNil parent) {return (handler parent)}
  return nil
}

method setNext Block another {
  scale = (blockScale)
  removeHighlight morph
  if (notNil another) {removeHighlight (morph another)}
  n = (next this)
  if (notNil n) {remove (parts morph) (morph n)}
  if (isNil another) {
    setField expression 'nextBlock' nil
  } else {
    setPosition (morph another) (left morph) (- (+ (top morph) (height morph)) (scale * corner))
    addPart morph (morph another)
    setField expression 'nextBlock' (expression another)
    if (notNil n) {setNext (bottomBlock another) n}
  }
  if (isPrototypeHat this) {
    prot = (editedPrototype this)
    func = (function prot)
    cmd = nil
    if (isClass another 'Block') {cmd = (expression another)}
    setField func 'cmdList' cmd
    blockStackChanged this
  } else {
    raise morph 'scriptChanged' this
    raise morph 'blockStackChanged' this
  }
}

method blockStackChanged Block another {
  if (isPrototypeHat this) {
    raise morph 'functionBodyChanged' this
    def = (editedDefinition this)
    if (notNil def) {hideDetails def}
  } else {
    raise morph 'blockStackChanged' this
  }
}

method scriptChanged Block {
  if (isPrototypeHat this) {
    raise morph 'functionBodyChanged' this
    def = (editedDefinition this)
    if (notNil def) {hideDetails def}
  } else {
    raise morph 'scriptChanged' this
  }
}

method bottomBlock Block {
  n = (next this)
  if (isNil n) {return this}
  return (bottomBlock n)
}

method topBlock Block {
  if (isNil (owner morph)) { return this }
  t = (handler (owner morph))
  if (isAnyClass t 'Block' 'CommandSlot') {return (topBlock t)}
  return this
}

method stackList Block {
  stack = (list)
  current = this
  while (notNil current) {
    add stack current
    current = (next current)
  }
  return stack
}

method scriptEditor Block {
  se = (handler (owner (morph (topBlock this))))
  if (isClass se 'ScriptEditor') {return se}
  return nil
}

// nesting (inputs)

method replaceInput Block source target {
  if (notNil (owner (morph target))) {removePart (owner (morph target)) (morph target)}
  idx = (indexOf (parts morph) (morph source))
  if (isNil idx) {  // can happen when call has more parameters than prototype has slots
    print 'skipping extra input'
    return
  }
  replaceLabelPart this source target
  atPut (parts morph) idx (morph target)
  setOwner (morph target) morph
  setOwner (morph source) nil
  if (isClass source 'Block') {
    editor = (scriptEditor this)
    addPart (morph editor) (morph source)
    moveBy (morph source) 20 20
  }
  if (isAnyClass target 'InputSlot' 'BooleanSlot' 'ColorSlot') {
    setArg expression (inputIndex this target) (contents target)
  } (isClass target 'Block') {
    setArg expression (inputIndex this target) (expression target)
  }
  layoutChanged this
  if (isClass target 'Block') { fixBlockColor target }
  raise morph 'scriptChanged' this
}

method replaceLabelPart Block source target {
  // private - helper for replaceInput
  for group labelParts {
    for i (count group) {
      if ((at group i) === source) {
        atPut group i target
        return
      }
    }
  }
  error 'label part not found'
}

method revertToDefaultInput Block aReporter {
  oldX = (left (morph aReporter))
  oldY = (top (morph aReporter))
  if (isNil blockSpec) {
    replaceInput this aReporter (slot 10)
  } else {
    replaceInput this aReporter (inputSlot blockSpec (inputIndex this aReporter) color)  }
  setPosition (morph aReporter) oldX oldY
}

// context menu

method contextMenu Block {
  if (isPrototype this) {return nil}
  menu = (menu nil this)
  isInPalette = ('template' == (grabRule morph))
  addItem menu 'explore result' 'explore'
  if (canShowMonitor this) {
    addItem menu 'monitor' 'addMonitor'
  }
  addLine menu
  if (isVariadic this) {
    if (canExpand this) {addItem menu 'expand' 'expand'}
    if (canCollapse this) {addItem menu 'collapse' 'collapse'}
    addLine menu
  }
  if (and isInPalette (isRenamableVar this)) {
    addItem menu 'rename...' 'userRenameVariable'
    addLine menu
  }
  addItem menu 'duplicate' 'grabDuplicate' 'just this one block'
  if (and ('reporter' != type) (notNil (next this))) {
    addItem menu '...all' 'grabDuplicateAll' 'duplicate including all attached blocks'
  }
  addItem menu 'copy to clipboard' 'copyToClipboard'
  addItem menu 'export as image' 'exportAsImage'
  addLine menu
  addItem menu 'show definition...' 'showDefinition'
  addLine menu
  if isInPalette {
	proj = (project (findProjectEditor))
	if (isUserDefinedBlock proj this) {
	  addLine menu
	  if (showingAnExtensionCategory proj this) {
		addItem menu 'remove from palette' (action 'removeFromCurrentCategory' proj this)
	  } else {
		addItem menu 'export to palette...' (action 'exportToExtensionCategory' proj this)
	  }
	}
  }
  if (devMode) {
    addLine menu
    addItem menu 'implementations...' 'browseImplementors'
    addItem menu 'text code...' 'editAsText'
  }
  if (not isInPalette) {
    addLine menu
    addItem menu 'delete' 'delete'
  }
  return menu
}

method grabDuplicate Block {
  dup = (duplicate this)
  if (notNil (next dup)) {setNext dup nil}
  grabCentered morph dup
}

method grabDuplicateAll Block {
  grabCentered morph (duplicate this)
}

method duplicate Block {
  def = (blockDefinition this)
  if (notNil def) {
    op = (op def)
    spec = (specForOp (authoringSpecs) op)
    if (isNil spec) {spec = (blockSpecFor function)}
    return (blockForSpec spec) spec
  }

  if (notNil blockSpec) {
    dup = (new 'Block')
    initializeForSpec dup blockSpec true
    initializeForNode dup (copy expression)
  } else {
    dup = (toBlock (copy expression))
  }
  setPosition (morph dup) (left morph) (top morph)
  return dup
}

method copyToClipboard Block {
  result = (list 'GP Script' (newline))
  pp = (new 'PrettyPrinter')
  add result (join 'script nil 10 10 ')
  if (isClass expression 'Reporter') {
	if (isOneOf (primName expression) 'v') {
	  add result (join '(v ' (first (argList expression)) ')')
	} else {
	  add result (join '(' (prettyPrint pp expression) ')')
	}
	add result (newline)
  } else {
	add result (join '{' (newline))
	add result (prettyPrintList pp expression)
	add result (join '}' (newline))
  }
  add result (newline)
  setClipboard (joinStrings result)
}

method exportAsImage Block { exportAsImageScaled this 2 }

method exportAsImageScaled Block scale result {
  // Save a PNG picture of the given script at the given scale.
  // If result is not nil, include a speech bubble showing the result.

  // if block is a function definition hat use its prototype block
  if (isPrototypeHat this) {
	proto = (editedPrototype this)
	if (notNil proto) { this = proto }
  }

  // draw script and bubble at high resolution
  oldScale = (global 'scale')
  setGlobal 'scale' scale // change global scale temporarily to ensure retina resolution
  if (notNil (function this)) {
	scaledScript = (scriptForFunction (function this))
  } else {
    scaledScript = (toBlock (expression this))
  }
  bnds = (fullBounds (morph scaledScript))
  scriptW = (width bnds)
  scriptH = (height bnds)

  // draw the result bubble, if any
  if (notNil result) {
	scaledBubble = (newBubble result 200 'right')
	bubbleW = (width (fullBounds (morph scaledBubble)))
	bubbleH = (height (fullBounds (morph scaledBubble)))
	bubbleInsetX = (5 * scale)
	bubbleInsetY = (5 * scale)
	if ('hat' == type) { bubbleInsetY = ((half (height morph)) + (3 * scale)) }
  } else {
	bubbleW = 0
	bubbleH = 0
	bubbleInsetX = 0
	bubbleInsetY = 0
  }

  // combine the morph and result bubble, if any
  bm = (newBitmap (+ scriptW bubbleW (- bubbleInsetX)) (+ scriptH bubbleH (- bubbleInsetY)))
  ctx = (newGraphicContextOn bm)
  setOffset ctx 0 (bubbleH - bubbleInsetY)
  fullDrawOn (morph scaledScript) ctx
  if (notNil scaledBubble) {
	topMorphWidth = (width (morph scaledScript))
	setOffset ctx (topMorphWidth - bubbleInsetX) 0
	fullDrawOn (morph scaledBubble) ctx
  }
  setGlobal 'scale' oldScale // revert to old scale

  // save result as a PNG file
  pngData = (encodePNG bm)
  if ('Browser' == (platform)) {
	browserWriteFile pngData (join 'scriptImage' (msecsSinceStart) '.png') 'scriptImage'
  } else {
	fName = (fileToWrite (join 'scriptImage' (msecsSinceStart) '.png'))
	if ('' == fName) { return false }
	writeFile fName pngData
  }
}

method delete Block {
  if ('reporter' != type) { // hat or command
    nxt = (next this)
    if (and (notNil nxt) (notNil (owner morph))) {
      prev = (ownerThatIsA (owner morph) 'Block')
      cslot = (ownerThatIsA (owner morph) 'CommandSlot')
      scripts = (ownerThatIsA (owner morph) 'ScriptEditor')
      if (and (notNil prev) (=== this (next (handler prev)))) {
        setNext this nil
        setNext (handler prev) nxt
      } (and (notNil cslot) (=== this (nested (handler cslot)))) {
        setNext this nil
        setNested (handler cslot) nxt
      } (notNil scripts) {
        addPart scripts (morph nxt)
      }
    }
  }
  aboutToBeGrabbed this
  removeFromOwner morph
}

method editAsText Block {
  openWorkspace (page morph) (toTextCode this)
}

method turnIntoText Block hand {
  scale = (blockScale)
  owner = (owner morph)
  if (or (isNil owner) (not (isClass (handler owner) 'ScriptEditor'))) {return}
  code = (toTextCode this)
  x = (left morph)
  y = (top morph)
  txt = (newText code 'Arial' ((global 'scale') * 14) (color))
  setEditRule txt 'code'
  setGrabRule (morph txt) 'ignore'
  addSchedule (global 'page') (newAnimation 1.0 0.7 200 (action 'setScaleAround' morph (left morph) (top morph)) (action 'swapTextForBlock' (handler owner) txt this hand) true)
}

method toTextCode Block {
  scripter = (ownerThatIsA morph 'Scripter')
  if (notNil scripter) {
    className = (className (classOf (getField (handler scripter) 'targetObj')))
  }
  pp = (new 'PrettyPrinter')
  code = ''
  nb = (expression this className)
  useBrackets = (and (isClass nb 'Command') (not (isControlStructure nb)))
  if useBrackets { code = (join '{' (newline)) }
  while (notNil nb) {
    code = (join code (prettyPrint pp nb) (newline))
    nb = (nextBlock nb)
  }
  if useBrackets {
  	code = (join code '}')
  } (type == 'reporter') {
	code = (substring code 1 ((count code) - 1)) // remove line break
	code = (join '(' code ')')
  }
  return code
}

method browseImplementors Block {
  name = (primName expression)
  implementors = (implementors name)
  menu = (menu (join 'implementations of' (newline) name) (action 'openClassBrowser' this) true) // reverse call
  for each implementors {
    addItem menu (join each '...') each
  }
  popUpAtHand menu (global 'page')
}

method openClassBrowser Block className {
  if ('<generic>' == className) {
	page = (global 'page')
	brs = (newClassBrowser)
	setPosition (morph brs) (x (hand page)) (y (hand page))
	addPart page brs
    browse brs (globalBlocksName brs) (functionNamed (primName expression) (topLevelModule))
    return
  }
  editor = (ownerThatIsA morph 'ProjectEditor')
  if (notNil editor) {
	cl = (classNamed (module (project (handler editor))) className)
  }
  if (isNil cl) { cl = (class className) }
  browseClass cl (primName expression)
}

method showDefinition Block {
  pe = (findProjectEditor)
  if (isNil pe) { return }
  scripter = (scripter pe)
  targetClass = (targetClass scripter)
  if (isNil targetClass) { return }
  calledFunction = (primName expression)

  if (not (isShowingDefinition this targetClass calledFunction)) {
	if (notNil (methodNamed targetClass calledFunction)) {
	  ref = (newCommand 'method' calledFunction (className targetClass))
	} else {
	  f = (functionNamed (module (project pe)) calledFunction)
	  if (isNil f) { return } // shouldn't happen
	  ref = (newCommand 'to' calledFunction)
	}

	// add the method/function definition to the scripts for targetClass
	entry = (array (rand 50 200) (rand 50 200) ref)
	setScripts targetClass (join (array entry) (scripts targetClass))
	restoreScripts scripter
  }
  scrollToDefinitionOf scripter calledFunction
}

method isShowingDefinition Block aClass calledFunction {
  if (isNil (scripts aClass)) { return false }
  for entry (scripts aClass) {
	cmd = (at entry 3) // third item of entry is command
	if (isOneOf (primName cmd) 'method' 'to') {
	  if (calledFunction == (first (argList cmd))) { return true }
	}
  }
  return false // not found
}

// monitors

method canShowMonitor Block {
  if (or ('reporter' != type) (isPrototype this)) { return false }
  op = (primName expression)
  if (and (isOneOf op 'v' 'my') (notNil (ownerThatIsA morph 'Scripter'))) {
	// can only show monitors on instance variables (not locals)
	varName = (first (argList expression))
	scripter = (ownerThatIsA morph 'Scripter')
	return (and (notNil scripter) (hasField (targetObj (handler scripter)) varName))
  }
  if (isOneOf op 'global' 'shared') { return true }
  return ((count (argList expression)) == 0)
}

method addMonitor Block {
  monitor = (makeMonitor this)
  if (isNil monitor) { return }
  step monitor
  setCenter (morph monitor) (handX) (handY)
  grab (hand (global 'page')) monitor
}

method makeMonitor Block {
  targetObj = nil
  scripter = (ownerThatIsA morph 'Scripter')
  if (isNil scripter) { scripter = (ownerThatIsA morph 'MicroBlocksScripter') }
  if (notNil scripter) { targetObj = (targetObj (handler scripter)) }
  op = (primName expression)
  monitorColor = (blockColorForOp (authoringSpecs) op)
  if (isOneOf op 'v' 'my') {
	varName = (at (argList expression) 1)
	if (and ('this' == varName) (notNil targetObj)) {
	  getter = (action 'id' targetObj)
	  return (newMonitor varName getter monitorColor)
	} (hasField targetObj varName) {
	  getter = (action 'getFieldOrNil' targetObj varName)
	  return (newMonitor (join 'my ' varName) getter monitorColor)
	}
  } ('shared' == op) {
	mod = nil
	if (notNil scripter) { mod = (targetModule (handler scripter)) }
	varName = (at (argList expression) 1)
	getter = (action 'shared' varName mod)
	return (newMonitor varName getter monitorColor)
  } ('global' == op) {
	varName = (at (argList expression) 1)
	getter = (action 'global' varName)
	return (newMonitor varName getter monitorColor)
  } (beginsWith op 'self_') {
	if (isNil targetObj) { return nil }
	getter = (action 'eval' op targetObj)
	label = (first (specs (blockSpec this)))
	return (newMonitor label getter monitorColor)
  } else {
	label = (first (specs (blockSpec this)))
	return (newMonitor label (action op) monitorColor)
  }
  return nil
}

method explore Block {
  page = (global 'page')
  targetObj = nil
  scripter = (ownerThatIsA morph 'Scripter')
  if (notNil scripter) { targetObj = (targetObj (handler scripter)) }

  op = (primName expression)
  if (isOneOf op 'v' 'my') {
	varName = (at (argList expression) 1)
	if (and ('this' == varName) (notNil targetObj)) {
	  obj = targetObj
	} (hasField targetObj varName) {
	  obj = (call 'getField' targetObj varName)
	}
	openExplorer obj
  } else {
	// evaluate as a task so errors give debugger
	cmd = (expression (topBlock this))
	launch page cmd targetObj (action 'openExplorer')
  }
}

// renaming variable getters

method isRenamableVar Block {
  return (and
    (notNil expression)
    ('reporter' == type)
    (isOneOf (primName expression) 'v' 'my')
    (or
      (== 'handle' (grabRule morph))
      (and
        (contains (array 'template' 'defer') (grabRule morph))
        (isAnyClass (handler (owner morph)) 'Block' 'BlockSectionDefinition' 'InputDeclaration')
      )
    )
  )
}

method isReceiverSlotTemplate Block {
  sec = (owner morph)
  if (isClass (handler sec) 'BlockSectionDefinition') {
    def = (owner sec)
    if (isClass (handler def) 'BlockDefinition') {
      if (1 == (indexOf (parts def) sec)) {
        func = (function (handler (owner def)))
        if (not (isMethod func)) {
          return false
        }
        return (2 == (indexOf (parts sec) morph))
      }
    }
  }
  return false
}

method userRenameVariable Block {
  if  (or (not (isRenamableVar this)) (isReceiverSlotTemplate this)) {return}
  prompt (page morph) 'Variable Name?' (at (argList expression) 1) 'line' (action 'renameVariableTo' this)
}

method renameVariableTo Block varName {
  if (or (isNil varName) (== '' varName) (not (isRenamableVar this))) {return}
  oldName = (at (argList expression) 1)
  setArg expression 1 varName
  setText (at (at labelParts 1) 1) varName
  layoutChanged this

  if (notNil (ownerThatIsA morph 'BlockSectionDefinition')) {
    raise morph 'updateBlockDefinition'
    return
  }

  raise morph 'inputChanged' this

  // update the function
  if (notNil (owner morph)) {func = (function (handler (owner morph)))}
  if (isNil func) {return}
  idx = (indexOf (argNames func) oldName)
  atPut (argNames func) idx varName
}

// constructing blocks from commands and reporters

to toBlock commandOrReporter {
  block = (new 'Block')
  initialize block commandOrReporter
  layoutChanged block
  fixLayout block
  return block
}

method labelText Block aString { return (blockLabelText aString) }

to blockLabelText aString {
  scale = (blockScale)
  fontName =  'Verdana Bold'
  fontSize = (11 * scale)
  if (isOneOf aString '=' '+' '/' '×' '−' '≠') { // last three: unicode multiply, minus, not equals
  	fontSize = (13 * scale)
  }
  if ('Linux' == (platform)) {
	fontName = 'Sans Bold'
	fontSize = (round (0.85 * fontSize))
  }
  if ('Browser' == (platform)) {
	fontName = 'Arial Bold'
	fontSize = (fontSize + (2 * scale))
  }
  labelColor = (global 'blockTextColor')
  if (isNil labelColor) { labelColor = (gray 255) }
  if ('comment' == aString) { labelColor = (gray 80) }
  return (newText aString fontName fontSize labelColor)
}

method rawInitialize Block commandOrReporter {
  // disregard any block spec, e.g. if none is found

  scale = (blockScale)
  cslots = (list)
  expression = commandOrReporter
  op = (primName expression)
  type = 'command'
  if (isClass expression 'Reporter') { type = 'reporter' }
  setBlockColor this (primName expression)

  morph = (newMorph this)
  setGrabRule morph 'handle'
  setTransparentTouch morph false
  labelParts = (list (list (labelText this (primName expression))))
  group = (at labelParts 1)
  corner = 3
  rounding = 8
  dent = 2
  inset = 4
  hatWidth = 80
  border = 1
  expansionLevel = 1

  for each (argList expression) {
    if (isClass each 'Command') {
      element = (newCommandSlot color (toBlock each))
      add cslots element
    } (isClass each 'Reporter') {
      element = (toBlock each)
    } else {
      element = (slot each)
    }
    add group element
  }

  // special cases for variables and assignment
  if (isOneOf op 'v' 'my') {
    s = (at (argList expression) 1)
    if ('my' == op) { s = (join 'my ' s) }
    labelParts = (list (list (labelText this s)))
    group = (at labelParts 1)
  }
  if (isOneOf op '=' '+=') {
    varName = (at (argList expression) 1)
    if ('=' == op) {
      labelParts = (list (list (labelText this 'set') (labelText this varName) (labelText this 'to')))
    } else {
      labelParts = (list (list (labelText this 'increase') (labelText this varName) (labelText this 'by')))
    }
    group = (at labelParts 1)
    rhs = (at (argList expression) 2)
    if (isClass rhs 'Reporter') {
      add group (toBlock rhs)
    } else {
      add group (slot rhs)
    }
  }

  for p group { addPart morph (morph p) }
  if (and (type != 'reporter') (notNil (nextBlock expression))) {
    addPart morph (morph (toBlock (nextBlock expression)))
  }
}

method initializeForNode Block commandOrReporter {
  expandTo this (count (argList commandOrReporter)) true
  slots = (inputs this)
  idx = 0
  for each (argList commandOrReporter) {
    idx += 1
	if (idx <= (count slots)) {
	  slot = (at slots idx)
	} else {
	  slot = (newInputSlot each 'auto')
	}
    if (isClass each 'Command') {
      if (isClass slot 'CommandSlot') {
        setNested slot (toBlock each)
      } else {
        // perhaps we should somehow warn the user here
        replaceInput this slot (newCommandSlot color (toBlock each)) false
      }
    } (isClass each 'Reporter') {
      if (and ('colorSwatch' == (primName each)) (isClass slot 'ColorSlot')) {
        setContents slot (eval each)
      } else {
        replaceInput this slot (toBlock each) false
      }
    } else {
      if (isAnyClass slot 'InputSlot' 'BooleanSlot' 'ColorSlot' 'MicroBitDisplaySlot') {
        setContents slot each
      } (and (isClass slot 'Block') (isRenamableVar slot)) {
        renameVariableTo slot each
      } (notNil each) {
        error 'cannot set contents of' slot
      }
    }
  }

  // special case for variables
  if (isOneOf (primName commandOrReporter) 'v' 'my') {
    s = (at (argList commandOrReporter) 1)
    if ('my' == op) { s = (join 'my ' s) }
    labelParts = (list (list (labelText this s)))
    removeAllParts morph
    addPart morph (morph (at (at labelParts 1) 1))
  }

  if (and (type != 'reporter') (notNil (nextBlock commandOrReporter))) {
    addPart morph (morph (toBlock (nextBlock commandOrReporter)))
  }
  expression = commandOrReporter
  layoutChanged this
}

method initialize Block commandOrReporter {
  op = (primName commandOrReporter)
  // special case for variables
  if (isOneOf (primName commandOrReporter) 'v' 'my') {
    rawInitialize this commandOrReporter
    s = (at (argList commandOrReporter) 1)
	if ('my' == op) { s = (join 'my ' s) }
    labelParts = (list (list (labelText this s)))
    removeAllParts morph
    addPart morph (morph (at (at labelParts 1) 1))
    expression = commandOrReporter
    layoutChanged this
    return
  }

  spec = (specForOp (authoringSpecs) op commandOrReporter)
  if (and (notNil spec) ((slotCount spec) < (count (argList commandOrReporter))) (not (repeatLastSpec spec))) {
    spec = nil // ignore bad spec: not enough input slots and not expandable
  }
  if (isNil spec) {
    rawInitialize this commandOrReporter
    layoutChanged this
    return
  }
  initializeForSpec this spec true true
  initializeForNode this commandOrReporter
}

to blockForFunction aFunction {
  spec = (specForOp (authoringSpecs) (primName aFunction))
  if (isNil spec) {
	cl = nil
	if ((classIndex aFunction) > 0) { cl = (class (classIndex aFunction)) }
	spec = (blockSpecFor aFunction)
  }
  return (blockForSpec spec)
}

to blockForSpec spec {
  block = (new 'Block')
  spec = (translateToCurrentLanguage (authoringSpecs) spec)
  initializeForSpec block spec

  fixLayout block 
  return block
}

to scriptForFunction aFunction {
  if (isNil aFunction) { return nil }
  hatLabel = 'define'
  if (isMethod aFunction) { hatLabel = 'method' }
  block = (block 'hat' (color 140 0 140) hatLabel (blockPrototypeForFunction aFunction))
  if (notNil (cmdList aFunction)) {
	setNext block (toBlock (cmdList aFunction))
  }
  return block
}

to blockPrototypeForFunction aFunction {
  spec = (specForOp (authoringSpecs) (primName aFunction))
  if (isNil spec) {
	spec = (blockSpecFor aFunction)
  }
  clr = (blockColorForOp (authoringSpecs) (primName aFunction))
  block = (block (blockType (blockType spec)) clr (newBlockDefinition spec (argNames aFunction) (not (isMethod aFunction))))
  setField block 'function' aFunction
  setGrabRule (morph block) 'template'
  return block
}

method initializeForSpec Block spec suppressExpansion {
  scale = (blockScale)

  blockSpec = spec
  type = 'command'
  if (isHat spec) { type = 'hat' }
  if (isReporter spec) { type = 'reporter' }
  setBlockColor this (blockOp blockSpec)

  morph = (newMorph this)
  setGrabRule morph 'handle'
  setTransparentTouch morph false

  corner = 3
  rounding = 8
  dent = 2
  inset = 4
  hatWidth = 80
  border = 1
  expansionLevel = 1

  // create the base label parts
  group = (labelGroup this 1)
  for p group {
    addPart morph (morph p)
  }
  labelParts = (list group)
  addAllLabelParts this

  // hack: make the font bigger in comment blocks
  if ('comment' == (blockOp spec)) {
	setFont (getField (last (first labelParts)) 'text') nil (13 * scale)
  }

  // expand to the first input slot, if any
  if suppressExpansion {return}
  if (and (repeatLastSpec blockSpec) (== 0 (countInputSlots blockSpec (at (specs blockSpec) 1)))) {
    expand this
  }
}

method labelGroup Block index {
  max = (count (specs blockSpec))
  if (index <= max) {
    specString = (at (specs blockSpec) index)
  } else {
    specString = (at (specs blockSpec) max)
  }
  slotIndex = 1
  for i (index - 1) {
    if (i > max) {
      slotIndex += (countInputSlots blockSpec (at (specs blockSpec) max))
    } else {
      slotIndex += (countInputSlots blockSpec (at (specs blockSpec) i))
    }
  }
  if (isPrototype this) {argNames = (argNames function)}
  group = (list)
  for w (words specString) {
    if ('_' == w) {
      add group (inputSlot blockSpec slotIndex color (isPrototype this) argNames)
      slotIndex += 1
    } else {
      add group (labelText this w)
    }
  }
  if (isEmpty group) {return (list (labelText this ''))}
  return group
}

method setBlockColor Block op {
    color = (blockColorForOp (authoringSpecs) op)
}

// expanding and collapsing

method drawer Block {
  if (and (isVariadic this) (not (isPrototype this))) {
    items = (count (flattened labelParts))
    return (handler (at (parts morph) (+ 1 items)))
  }
  return nil
}

method isVariadic Block {
  return (and (notNil blockSpec) (or (repeatLastSpec blockSpec) (> (count (specs blockSpec)) 1)))
}

method canExpand Block {
  return (and (notNil blockSpec) (or (repeatLastSpec blockSpec) (> (count (specs blockSpec)) expansionLevel)))
}

method canCollapse Block {
  return (and (notNil blockSpec) (expansionLevel > 1))
}

method expand Block {
  nb = (next this)
  removeAllParts morph
  expansionLevel += 1
  if ('if' == (primName expression)) {
	lastGroup = (last labelParts)
	if (and
		((count lastGroup) == 2)
		(isClass (first lastGroup) 'BooleanSlot')) {
		  oldSlot = (last lastGroup)
		  removeLast labelParts
		  add labelParts (list
		    (labelText this 'else')
		    (labelText this 'if')
		    (newBooleanSlot true)
		    oldSlot)
	}
    add labelParts (list (newBooleanSlot true true) (newCommandSlot color))
  } else {
    add labelParts (labelGroup this expansionLevel)
  }
  addAllLabelParts this
  setNext this nb
  if ('template' == (grabRule morph)) { comeToFront morph } // ensure collapse arrow not covered
}

method expandTo Block numberOfInputs {
  // helper method for initializeForNode
  // expands the blocks so it can accomodate at least the given
  // number of inputs
  nb = (next this)
  removeAllParts morph
  while (and ((count (inputs this)) < numberOfInputs) (canExpand this)) {
    expansionLevel += 1
    add labelParts (labelGroup this expansionLevel)
  }
  addAllLabelParts this
  setNext this nb
}

method collapse Block {
  nb = (next this)
  old = (at labelParts expansionLevel)
  removeAt labelParts expansionLevel
  if ('if' == (primName expression)) {
    lastGroup = (last labelParts)
	if (and
	  ((count lastGroup) == 4)
	  ('else' == (text (first lastGroup)))
	  (isClass (at lastGroup 3) 'BooleanSlot')
	  (true == (contents (at lastGroup 3)))) {
		oldSlot = (last lastGroup)
		removeLast labelParts
		add labelParts (list (newBooleanSlot true true) oldSlot)
	}
  }
  removeAllParts morph
  expansionLevel += -1
  addAllLabelParts this
  setNext this nb

  // preserve old embedded blocks, if any
  editor = (scriptEditor this)
  if (isNil editor) {return}
  for slot old {
    keep = nil
    if (and (isClass slot 'Block') (!= 'template' (grabRule (morph slot)))) {
      keep = (morph slot)
    } (and (isClass slot 'CommandSlot') (notNil (nested slot))) {
      keep = (morph (nested slot))
    }
    if (notNil keep) {
      addPart (morph editor) keep
      moveBy keep 20 20
    }
  }
}

method addAllLabelParts Block {
  allParts = (flattened labelParts)
  for p allParts {addPart morph (morph p)}
  if (and (isVariadic this) (not (isPrototype this))) {addPart morph (morph (newBlockDrawer this))}

  // create a new expression with the matching number of empty argument slots
  cmdAndArgs = (list (blockOp blockSpec))
  for p allParts {
    if (isAnyClass p 'InputSlot' 'BooleanSlot' 'ColorSlot' 'CommandSlot' 'Block' 'MicroBitDisplaySlot') {
      add cmdAndArgs nil
    }
  }

  cmdAndArgs = (toArray cmdAndArgs)
  if (isReporter blockSpec) {
    expression = (callWith 'newReporter' cmdAndArgs)
  } else {
    expression = (callWith 'newCommand' cmdAndArgs)
  }

  // update the expression's arguments' values with the actual input values
  // since these could have changed in the meantime (e.g. if the user typed
  // in something different)
  if (not (isPrototype this)) {
    for p allParts {
      if (isAnyClass p 'InputSlot' 'BooleanSlot' 'ColorSlot' 'CommandSlot' 'Block' 'MicroBitDisplaySlot') {
        inputChanged this p
      }
    }
  }
  layoutChanged this
  if (not (isPrototype this)) {
    raise morph 'expressionChanged' this
  }
}

// editing block prototypes (function definitions)

method updateBlockDefinition Block aBlockDefinition {
  if (isRenamableVar this) {
    raise morph 'updateBlockDefinition'
    return
  }

  if (isNil function) {return} // to do: raise an error

  // update the function
  setField function 'argNames' (inputNames aBlockDefinition)

  // update the block spec
  sp = (callWith 'blockSpecFromStrings' (specArray aBlockDefinition))
  recordBlockSpec (authoringSpecs) (primName function) sp

  // notify interested editors
  raise morph 'blockPrototypeChanged' this
}

method containsPrim Block aPrimName {
  for each (allMorphs morph) {
    hdl = (handler each)
    if (and (isClass hdl 'Block') (== aPrimName (primName (expression hdl)))) {
      return true
    }
  }
  return false
}

method setContents Block obj {nop} // only used for 'var' type input slots

// zebra-coloring for reporter blocks

method color Block {return color}

method getAlternative Block {
  if (isNil isAlternative) {isAlternative = false}
  return isAlternative
}

method fixBlockColor Block {
  if (and (type == 'reporter') (notNil (owner morph))) {
    parent = (handler (owner morph))
    oldAlternative = isAlternative
    if (and (isClass parent 'Block') ((color parent) == color)) {
      isAlternative = (not (getAlternative parent))
    } else {
      isAlternative = false
    }
    if (isAlternative != oldAlternative) {
      changed morph
      fixPartColors this
    }
  }
}

method fixPartColors Block {
  for m (parts morph) {
    if (isClass (handler m) 'Block') {
      fixBlockColor (handler m)
    }
  }
}

// keyboard accessibility hooks

method trigger Block {
  if (and ('template' == (grabRule morph)) (isRenamableVar this)) {
    userRenameVariable this
  }
}
