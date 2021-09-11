
to startup {
    // usefull when used with ./scripts/monitor.js
    setGlobal 'skipQuitConfirmation' true

    //listFunctions
    // defaulProjectEditor
    // emptyWindow 'Hello!? 👋'
    //blockEditorWithAnimationDemo
    // renderBlock
    // renderOnlyPrintBlock
    // openSynopsisWindow
    // openClassBrowser
    // howToCallFunction

    // runHttpFetchTests

    // (run (new 'HTTPFetchTestSuite') 'http://localhost:3117')
    // (run (new 'HTTPFetchTestSuite'))
    projectEditorWithHTTP
}


to projectEditorWithHTTP {
    tryRetina = true
    useDevMode = true

	setGlobal 'verboseHTTPFetch' true

    // Customize specs
    specs = (initialize (new 'AuthoringSpecs'))
    addSpecs specs (array
	' *** HTTP'
        (array 'r' 'httpGET'   'fetch from URL _ : parameters _ : headers _ : timeout _' 'str auto auto num' 'https://jsonplaceholder.typicode.com/users' nil nil nil)
        (array 'r' 'restfulGET'   'fetch JSON from URL _ : parameters _ : headers _ : timeout _' 'str auto auto num' 'https://jsonplaceholder.typicode.com/users' nil nil nil)

        (array 'r' 'httpPOST' 'post to URL _  body _ : headers _ : timeout _' 'str auto auto num' 'https://jsonplaceholder.typicode.com/users' nil nil nil)
        (array ' ' 'httpPOST' 'write to URL _  body _ : headers _ : timeout _' 'str auto auto num' 'https://jsonplaceholder.typicode.com/users' nil nil nil)
    )
    setGlobal 'flatBlocks' true
    setGlobal 'authoringSpecs' specs
    openProjectEditor tryRetina useDevMode
}


to listFunctions {

    // From SystemPallete 
    // List of global methods visible under '<Global Blocks>' in System browser
    fList = (list)
 
	for f (functions (topLevelModule)) {
        //print '>>' (primName f) '<< isNil?' (isNil (specForOp (authoringSpecs) (primName f))) 
        //print '>>' (primName f) '->' (specForOp (authoringSpecs) (primName f))
        if (isNil (specForOp (authoringSpecs) (primName f))) { 
          add fList (primName f) 
        }
	}

    for funcName (sorted fList) {
        print funcName
    }

    //uncalledAndUnimplemented
     
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

to renderOnlyPrintBlock {
    page = (newPage 1000 800)
    tryRetina = true
    setDevMode page true
    setGlobal 'page' page
    open page tryRetina 'Blocks Editor' 

    // spec described in runtime
    block =  (blockForSpec  (blockSpecFromStrings 'print' ' ' 'console print _ : _ : ...' 'auto auto auto auto auto auto auto auto auto auto' 'Testing 1, 2, 3') )
    (expand block)
    (expand block)
    (expand block)
    (expand block)
    (expand block)
    addPart page (morph block)


    startSteppingSafely page false
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
to blockEditorWithAnimationDemo {
    page = (newPage 1600 800)
    tryRetina = true
   
    setDevMode page true
    setGlobal 'page' page
    open page tryRetina 'Blocks Editor' 

    scriptEd = (newScriptEditor (width page) (height page - 20))
    setPosition (morph scriptEd ) 0 20
    addPart page scriptEd

    addPart (global 'page') (newBlockSearchBox 400 30)


    // //  b = (block 'reporter' (color 230 168 34) nil)
    b = (blockForSpec  (blockSpecFromStrings 'mem' 'r' 'memory usage' '' nil) )

    setPosition (morph b) 10 40
    addPart (morph scriptEd) (morph b)
   addSchedule (global 'page') (newAnimation 0 1000 500 (action 'setLeft' (morph b)))
      
    button = (newButton 'Print Hierarchy' (action  'printHierarchy' (morph page) 2 ))
    addSchedule (global 'page') (newAnimation 0 400 500 (action 'setTop' (morph button)))
    
    act = (action 'twirl' (morph button) )
    addSchedule (global 'page') (newAnimation 0 1 500000 act)

    addPart  (global 'page') (morph button)

    // runLoop
    startSteppingSafely page false
}

method twirl Morph {
    rotateAndScale this ((rotation this) + 5) 1
    setPosition this 400 400
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
         (array 'r' 'asyncGetDataFromURL'   'collect data from _ : filter with  _ : start on page _ end on page _' 'str auto num num' 'http://localhost:8080/' '.?' 0 nil)
        (array 'r' 'asyncGetDataFromURL2'   'collect data from URL _ : filter with  _ : use config _ : start on page _ end on page _ page size _' 'auto auto auto num num num' 'http://localhost:8080/' '.?' nil 0 nil nil)
        (array ' ' 'sendWithLimit'   'broadcast _ with _ : using limit of _ req / sec' 'str.listOfThings auto num ' 'event name' nil 1)

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
    setGlobal 'flatBlocks' true
    setGlobal 'authoringSpecs' specs
    openProjectEditor tryRetina useDevMode
}

to asyncGetDataFromURL url callback configuration {
        print 'asyncGetDataFromURL' url callback configuration

}
to sendWithLimit args.. {
    print 'sendWithLimit' args
}
to getDataFromURL url configuration {
    print 'getDataFromURL' url configuration
    return (getObjectFromURL url configuration)
    // return (jsonParse '[
    //     {"id": "firstID", "url":"ss"}, 
    //     {"id": "secondID", "url":"other/url"}
    // ]')
}

to getObjectFromURL url configuration {
    print 'getObjectFromURL' url configuration
    return (jsonParse '
        {"id": "firstID", "url":"ss"}, 
        ')
}


method listOfThings InputSlot {
  menu = (menu nil (action 'setContents' this) true)
  for cl (list 'one' 'two') {

	  addItem menu cl

  }
  return menu
}


to experimentalCode {
    setShared 'configuration' (jsonParse '{
        "pagingTemplate": "page={{pageNumber}}&per_page=100",
        "headers": {
            "Content-Type": "application/json",
            "Authorization": "token BLABLA"
        }
    }')

    print (shared 'configuration')

    data = (getDataFromURL (shared 'apiURL') (shared 'configuration'))

    //https://jqplay.org/
    // https://stackoverflow.com/questions/64684980/jq-process-json-where-an-element-can-be-an-array-or-object
    // >.url? // .[].url?< means get value of the url field from object or array of objects

    // getDataFromURL (shared 'apiURL') usingConfiguration: (shared 'configuration') filterResponseWithJQ: '.url? // .[].url?' startOnPage:1 collectAll: true

    setShared 'clientConfig' (jsonParse '{
        "url": "http://localhost:3112?page={{pageNumber}}&per_page=100",
        "method": "get",
        "headers": {
            "Content-Type": "application/json",
            "Authorization": "token BLABLA"
        }
    }') 
    urls = (collectData (shared 'clientConfig') '.url? // .[].url?' 1  true)
    // collectData clientConfig: (shared 'clientConfig')  filterResponseWithJQ: '.url? // .[].url?' startOnPage:1 collectAll: true
    
    for url ulrs {
        // broadcast command:'go' payload: url  requestsPerSec: (5000/3600) 
       broadcastWithLimit 'go' (url) (5000 / 3600) 
    }


}

to isDirectory aDirectoryOrNil {
  return (isClass aDirectoryOrNil 'Dictionary')
}

