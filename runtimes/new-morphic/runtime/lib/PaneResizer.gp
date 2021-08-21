defineClass PaneResizer morph target orientation isHighlit offsetX offsetY

to newPaneResizer aMorph orientationType {
	return (initialize (new 'PaneResizer') aMorph orientationType)
}

method initialize PaneResizer targetMorph orientationType {
	if (isNil orientationType) { orientationType = 'horizontal' }
	morph = (newMorph this)
	setGrabRule morph 'ignore'
	target = targetMorph
	orientation = orientationType
	isHighlit = false
	offsetX = 0
	offsetY = 0
	return this
}

method drawOn PaneResizer ctx {
	if isHighlit {
		c = (color 180 180 255 150)
		fillRect ctx c (left morph) (top morph) (width morph) (height morph)
	}
}

method handEnter PaneResizer aHand {
	if (orientation == 'horizontal') {
		setCursor 'ew-resize'
	} (orientation == 'vertical') {
		setCursor 'ns-resize'
	}
	isHighlit = true
	changed morph
}
method handLeave PaneResizer aHand {
	setCursor 'normal'
	isHighlit = false
	changed morph
}

method clicked PaneResizer { return true }
method rightClicked PaneResizer { return true }

method handDownOn PaneResizer aHand {
	focusOn aHand this
	offsetX = ((x aHand) - (left morph))
	offsetY = ((y aHand) - (top morph))

	scripter = (ownerThatIsA morph 'MicroBlocksScripter')
	if (notNil scripter) { hideScrollbars (handler scripter) }
	return true
}

method handUpOn PaneResizer aHand {
	scripter = (ownerThatIsA morph 'MicroBlocksScripter')
	if (notNil scripter) { showScrollbars (handler scripter) }
	return true
}

method handMoveFocus PaneResizer aHand {
	newX = ((x aHand) - offsetX)
	newY = ((y aHand) - offsetY)
	owner = (owner morph)
	if (notNil owner) { newX = (clamp newX (left owner) (right owner)) }
	if (notNil owner) { newY = (clamp newY (top owner) (bottom owner)) }

	if (orientation == 'horizontal') {
		fastSetLeft morph newX
		if (notNil target) { setWidthToRight target morph }
	} (orientation == 'vertical') {
		fastSetTop morph newY
		if (notNil target) { setHeightToBottom target morph }
	}
}
