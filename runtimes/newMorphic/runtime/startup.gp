
to startup {
    // usefull when used with ./scripts/monitor.js
    setGlobal 'skipQuitConfirmation' true
    defaulProjectEditor
    // emptyWindow 'Hello!? 👋'
    // blockEditorDemo
    // renderBlock
    // openSynopsisWindow
    // openClassBrowser
    // howToCallFunction
}


to openClassBrowser {
    page = (newPage 1000 800)
    tryRetina = true
    setDevMode page true
    setGlobal 'page' page
    open page tryRetina 'Class Browser' 

    cls = (newClassBrowser)
    browse cls (globalBlocksName cls)
    setExtent (morph cls) 1500 1500

    addPart page cls

    startSteppingSafely page false
}

to openSynopsisWindow {
    page = (newPage 1000 800)
    tryRetina = true
    setDevMode page true
    setGlobal 'page' page
    open page tryRetina 'Synopis' 

    syn = (newSynopsis)
    setExtent (morph syn) 1000 800
    addPart page (morph syn)

    startSteppingSafely page false
}

to fakeAction args... {
  result = (list)
  for i (argCount) {
    add result (toString (arg i))
    if (i != (argCount)) {add result ' '}
  }
  log (joinStringArray (toArray result))
}

to renderBlock {
    page = (newPage 1000 800)
    tryRetina = true
    setDevMode page true
    setGlobal 'page' page
    open page tryRetina 'Blocks Editor' 

    // spec described in runtime
    addPart page (blockForSpec  (blockSpecFromStrings 'print' ' ' 'console print _ : _ : ...' 'auto auto auto auto auto auto auto auto auto auto' 'Testing 1, 2, 3') )

    addPart page (blockForSpec  (blockSpecFromStrings 'fakeAction' ' ' 'banch mark _ : foo _ : ...' 'auto auto auto auto auto auto auto auto auto auto' nil) )
    addPart page (blockForSpec  (blockSpecFromStrings 'fakeAction' ' ' 'get data from URL _ : using _' 'str URLConfig' nil) )


    startSteppingSafely page false

}
to blockEditorDemo {
    page = (newPage 1600 800)
    tryRetina = true
    setDevMode page true
    setGlobal 'page' page
    open page tryRetina 'Blocks Editor' 

    scriptEd = (newScriptEditor (width page) (height page - 20))
    setPosition (morph scriptEd ) 0 20
    addPart page scriptEd

    addPart (global 'page') (newBlockSearchBox 400 30)


    //  b = (block 'reporter' (color 230 168 34) nil)
    b = (blockForSpec  (blockSpecFromStrings 'mem' 'r' 'memory usage' '' nil) )

    setPosition (morph b) 10 40
    addPart (morph scriptEd) (morph b)
    addSchedule (global 'page') (newAnimation 0 1000 500 (action 'setLeft' (morph b)))
      

    button = (newButton 'Print Hierarchy' (action  'printHierarchy' (morph page) 4 ))
    addSchedule (global 'page') (newAnimation 0 400 500 (action 'setTop' (morph button)))
 
    addPart  (global 'page') (morph button)

    // runLoop
    startSteppingSafely page false
}


to emptyWindow  title {
    page = (newPage 1000 800)
    tryRetina = true
    setDevMode page true
    setGlobal 'page' page
    open page tryRetina title

    startSteppingSafely page false
}

defineClass URLConfig function arguments



to callGivenFunction fun descr {
    print 'about to call function >' descr '<'
    call fun
}

to howToCallFunction {
    local 'var' (function {
        print 'Testing 1, 2, 3' (msecsSinceStart)
    })
    call var

    callGivenFunction (function {
        print 'Testing 1, 2, 3' (msecsSinceStart)
    }) 'inlined func'

    callGivenFunction var 'local variable'

    v = (function {
        print 'Testing 1, 2, 3' (msecsSinceStart)
    })
    call v
    callGivenFunction v 'regular variable'

}

to defaulProjectEditor {
    tryRetina = true
    useDevMode = true

    print (mem)

    // Customize specs
    specs = (initialize (new 'AuthoringSpecs'))
    addSpecs specs (array
	' *** Custom'
        (array 'r' 'getDataFromURL'   'get data from _ using: _' 'str auto' 'http://localhost:8080/' (dictionary) )
        // process data from URL: with callback using configuration
        // get data from _ then process with _ : using configuration _
        // collect data from _
        (array ' ' 'asyncGetDataFromURL'   'get data from _ then process with _ : using configuration _' 'str str auto' 'http://localhost:8080/' 'func' nil )
        (array ' ' 'customMe'   'forever _' 'cmd')
        (array ' ' 'command'       'funcComm _' 'cmd')
        (array 'h' 'funcH'       'funcHead _' 'cmd')
        (array ' ' 'fun_'       'funcSP _' 'cmd')

    )

    setGlobal 'authoringSpecs' specs
    openProjectEditor tryRetina useDevMode
}

to asyncGetDataFromURL url callback configuration {
        print 'asyncGetDataFromURL' url callback configuration

}
to getDataFromURL url configuration {
    print 'getDataFromURL' url configuration
    return (jsonParse '[{"url":"ss"}, {"url":"other/url"}]')
}
