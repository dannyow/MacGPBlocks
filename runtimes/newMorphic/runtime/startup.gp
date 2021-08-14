
to startup {
    tryRetina = true
    useDevMode = true
    // usefull when used with ./scripts/monitor.js
    setGlobal 'skipQuitConfirmation' true

    print (mem)
    openProjectEditor tryRetina useDevMode
}
