// Boolean input slot for blocks

to booleanConstant b { return b }

defineClass BooleanSlot morph contents displayAsElse

to newBooleanSlot defaultValue isElse {
	return (initialize (new 'BooleanSlot') defaultValue isElse)
}

method initialize BooleanSlot defaultValue isElse {
	contents = (true == defaultValue)
	displayAsElse = (true == isElse)
	morph = (newMorph this)
	setExtent morph (23 * (blockScale)) (13 * (blockScale))
	return this
}

method contents BooleanSlot { return contents }

method setContents BooleanSlot newValue {
	if (not (isClass newValue 'Boolean')) { return }
	contents = newValue
	raise morph 'inputChanged' this
	changed morph
}

method toggleState BooleanSlot {
	if displayAsElse { return } // don't toggle when used as 'else' in an if block
	if (not (isClass contents 'Boolean')) { contents = false }
	setContents this (not contents)
}

// drawing

method drawOn BooleanSlot ctx {
	scale = (blockScale)
	if (and displayAsElse contents) {
		// used to display a true boolean slot as 'else' in the final case of an 'if' block
		elseLabel = (labelText (new 'Block') 'else')
		setPosition (morph elseLabel) (left morph) (top morph)
		drawOn elseLabel ctx
		return
	}
	borderWidth = (max 1 (half scale))
	sliderSize = (height morph)
	corner = (8 * scale)
	r = (bounds morph)
	sm = (getShapeMaker ctx)
	if contents {
		c = (color 100 200 100) // green
		offset = ((width morph) - sliderSize)
	} else {
		c = (color 200 100 100) // red
		offset = 0
	}
	if contents { c = (color 0 200 0) }
	r = (bounds morph)
	fillRoundedRect sm r corner c borderWidth (gray 80) (gray 80)
	sliderRect = (rect ((left r) + offset) (top r) sliderSize sliderSize)
	fillRoundedRect sm sliderRect corner (gray 130) borderWidth (gray 80) (gray 80)
}

// replacement rule

method isReplaceableByReporter BooleanSlot {
	if displayAsElse { return false } // not replaceable when used as 'else' in an if block
	owner = (handler (owner morph))
	if (and (isClass owner 'Block') ('booleanConstant' == (primName (expression owner)))) {
		// Don't allow replacing the boolean slot in a boolean constant reporter
		return false
	}
	return true
}

// events

method clicked BooleanSlot aHand { toggleState this; return true }

// keyboard accessibility hooks

method trigger BooleanSlot { clicked this nil }
