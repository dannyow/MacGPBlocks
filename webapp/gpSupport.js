/* eslint-disable no-use-before-define */
// The following code decides whether to use WebAssembly or asm.js
//
// Note: In iOS 11.2.6 Safari, GP WebAssembly did not work on John's iPad Pro.
// Seemed to be an iOS Safari bug:
//   https://github.com/kripken/emscripten/issues/6042
// A fix was expected in iOS 11.3, which came out in March 2018.
// WebAssembly seems to be working in iOS 12, so workaround was removed.

if (typeof WebAssembly === 'object') {
    const script = document.createElement('script');
    script.src = './gp_wasm.js';
    document.head.appendChild(script);
} else {
    console.log('No WebAssembly');
    const script = document.createElement('script');
    script.src = './gp_js.js';
    document.head.appendChild(script);
}

// Handlers are ignored in gp.html when running as a Chrome App so must be added here:

function addGPHandlers() {
    const kbdButton = document.getElementById('KeyboardButton');
    const backspaceButton = document.getElementById('BackspaceButton');
    const fullscreenButton = document.getElementById('FullscreenButton');
    const enableMicrophoneButton = document.getElementById('EnableMicrophoneButton');
    const uploadButton = document.getElementById('UploadButton');
    const seeInsideButton = document.getElementById('SeeInsideButton');
    const presentButton = document.getElementById('PresentButton');
    const goButton = document.getElementById('GoButton');
    const stopButton = document.getElementById('StopButton');
    const fileUploader = document.getElementById('FileUploader');
    const canvas = document.getElementById('canvas');

    kbdButton.onclick = function (evt) { GP.clipboard.focus(); };
    backspaceButton.onclick = function (evt) { GP_backspace(); };
    fullscreenButton.onclick = function (evt) { GP_toggleFullscreen(); };
    uploadButton.onclick = function (evt) { GP_UploadFiles(); };
    enableMicrophoneButton.onclick = function (evt) { GP_startAudioInput(1024, 22050); };
    seeInsideButton.onclick = function (evt) { queueGPMessage('seeInside'); };
    presentButton.onclick = function (evt) { queueGPMessage('present'); };
    goButton.onclick = function (evt) { queueGPMessage('go'); };
    stopButton.onclick = function (evt) { queueGPMessage('stop'); };
    fileUploader.onchange = function (evt) { uploadFiles(fileUploader.files); };
    canvas.oncontextmenu = function (evt) { evt.preventDefault(); };
}
addGPHandlers();

// GP variables

let GP = {
    events: [],
    isRetina: false,

    shadowColor: null,
    shadowOffset: 0,
    shadowBlur: 0,

    clipboard: null,
    clipboardBytes: [],
    droppedTextBytes: [],
    droppedFiles: [],
    lastSavedFileName: null,
    messages: [],

    audioOutBuffer: null,
    audioOutIsStereo: false,
    audioOutReady: false,

    audioInBuffer: null,
    audioInDownsampling: false,
    audioInReady: false,
    audioInSource: null,
    audioInCapture: null,
};

// Add the following to the meta tags in the header to suppress scaling of the GP canvas
// <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />

// Clipboard Support
//	Chrome: works on HTTPS pages
//	Firefox: does not support clipboard.readText except in extensions
//	Safari: navigator.clipboard exists since 13.1 but is blocked for security reasons

GP.clipboard = document.createElement('textarea');
GP.clipboard.style.position = 'absolute';
GP.clipboard.style.right = '101%'; // placed just out of view
GP.clipboard.style.top = '0px';
document.body.appendChild(GP.clipboard);

function setGPClipboard(s) {
    // Called by GP's setClipboard primitive

    GP.clipboardBytes = toUTF8Array(s);
    GP.clipboard.value = s;
    if (navigator.clipboard.writeText) {
        navigator.clipboard.writeText(s).catch(() => {});
    } else if (chrome && chrome.clipboard) {
        chrome.clipboard.data = s;
        chrome.clipboard.type = 'textPlain';
    }
}

async function readGPClipboard(s) {
    if (navigator.clipboard.readText) {
        var s = await navigator.clipboard.readText().catch(() => '');
        if (s) {
            GP.clipboard.value = s;
            GP.clipboardBytes = toUTF8Array(s);
        }
    } else if (chrome && chrome.clipboard && (typeof chrome.clipboard.data === 'string')) {
        GP.clipboard.value = chrome.clipboard.data;
        GP.clipboardBytes = toUTF8Array(chrome.clipboard.data);
    }
    return GP.clipboardBytes.length;
}

function toUTF8Array(str) {
    // Convert a Javascript string into an array of UTF8 bytes that can be read by GP.
    const utf8 = [];
    for (let i = 0; i < str.length; i++) {
        /* eslint-disable no-bitwise */
        const charcode = str.charCodeAt(i);
        if (charcode < 0x80) utf8.push(charcode);
        else if (charcode < 0x800) {
            utf8.push(

                0xc0 | (charcode >> 6),
                0x80 | (charcode & 0x3f)
            );
        } else if (charcode < 0x10000) {
            utf8.push(
                0xe0 | (charcode >> 12),
                0x80 | ((charcode >> 6) & 0x3f),
                0x80 | (charcode & 0x3f)
            );
        } else if (charcode <= 0x10FFFF) {
            utf8.push(
                0xf0 | (charcode >> 18),
                0x80 | ((charcode >> 12) & 0x3f),
                0x80 | ((charcode >> 6) & 0x3f),
                0x80 | (charcode & 0x3f)
            );
        }
        /* eslint-enable no-bitwise */
    }
    return utf8;
}

// events

function initGPEventHandlers() {
    const MOUSE_DOWN = 1;
    const MOUSE_UP = 2;
    const MOUSE_MOVE = 3;
    const MOUSE_WHEEL = 4;
    const KEY_DOWN = 5;
    const KEY_UP = 6;
    const TEXTINPUT = 7;
    const TOUCH_DOWN = 8;
    const TOUCH_UP = 9;
    const TOUCH_MOVE = 10;

    function localPoint(x, y) {
        const r = canvas.getBoundingClientRect();
        x = (x - r.left) | 0;
        y = (y - r.top) | 0;
        if (x < 0) x = 0;
        if (y < 0) y = 0;
        if (GP.isRetina) {
            x = 2 * x;
            y = 2 * y;
        }
        return [x, y];
    }
    function modifierBits(evt) {
        const modifiers = ( // SDL modifier flags (for left-side versions of those keys)
            (evt.shiftKey ? 1 : 0)
		| (evt.ctrKey ? 2 : 0)
		| (evt.altKey ? 4 : 0)
		| (evt.metaKey ? 8 : 0));
        return modifiers;
    }
    function keyEvent(evtType, evt) {
        let { keyCode } = evt;
        let charCode = 0;
        if (evt.keyIdentifier) { // Safari
            if (evt.keyIdentifier.startsWith('U+')) {
                charCode = parseInt(evt.keyIdentifier.substring(2), 16);
            }
        } else if (evt.key && evt.key.charCodeAt) { // Chrome, Firefox
            if (evt.key.length == 1) {
                charCode = evt.key.charCodeAt(0);
            }
        }
        if (charCode == 0) {
            if (evt.keyCode == 8) charCode = 8; // delete
            if (evt.keyCode == 9) charCode = 9; // tab
            if (evt.keyCode == 13) charCode = 13; // enter
            if (evt.keyCode == 27) charCode = 27; // escape
        }
        if ((charCode >= 65) && (charCode <= 90) && !evt.shiftKey) charCode += 32; // lowercase

        // make Firefox keycodes the same as Chrome/Safari:
        if ((keyCode == 59) && (charCode == 59)) keyCode = 186;
        if ((keyCode == 61) && (charCode == 61)) keyCode = 187;
        if ((keyCode == 173) && (charCode == 45)) keyCode = 189;
        if (keyCode == 224) keyCode = 91;

        const modifiers = ( // SDL modifier flags (for left-side versions of those keys)
            (evt.shiftKey ? 1 : 0)
			| (evt.ctrlKey ? 2 : 0)
			| (evt.altKey ? 4 : 0)
			| (evt.metaKey ? 8 : 0));

        return [evtType, keyCode, charCode, modifiers];
    }

    var canvas = document.getElementById('canvas');

    canvas.onmousedown = function (evt) {
        const p = localPoint(evt.clientX, evt.clientY);
        GP.events.push([MOUSE_DOWN, p[0], p[1], evt.button, modifierBits(evt)]);
    };
    canvas.onmouseup = function (evt) {
        const p = localPoint(evt.clientX, evt.clientY);
        GP.events.push([MOUSE_UP, p[0], p[1], evt.button, modifierBits(evt)]);
    };
    canvas.onmousemove = function (evt) {
        const p = localPoint(evt.clientX, evt.clientY);
        GP.events.push([MOUSE_MOVE, p[0], p[1]]);
    };
    document.onkeydown = function (evt) {
        const key = evt.which;
        if ((key == 13) && (/Android/i.test(navigator.userAgent))) {
            // On Android, generate text input events for entire string when the enter key is pressed
            const s = GP.clipboard.value;
            for (let i = 0; i < s.length; i++) GP.events.push([TEXTINPUT, s.charCodeAt(i)]);
            if (s.length == 0) GP.events.push([TEXTINPUT, 13]); // insert newline if no other characters
            GP.clipboard.value = '';
            evt.preventDefault();
            return;
        }
        const eventRecord = keyEvent(KEY_DOWN, evt);
        GP.events.push(eventRecord);
        // suppress browser's default behavior for various keys
        if ((key == 9) || (key == 32)) { // tab or space
            GP.events.push([TEXTINPUT, key]); // suppress, but do generate a textinput event
            evt.preventDefault();
        }
        if (key == 8) evt.preventDefault(); // delete
        if ((evt.which >= 33) && (evt.which <= 36)) evt.preventDefault(); // home, end, page up/down keys
        if ((evt.which >= 37) && (evt.which <= 40)) evt.preventDefault(); // arrow keys
        if ((evt.which >= 112) && (evt.which <= 123)) evt.preventDefault(); // function keys
        if (evt.ctrlKey || evt.metaKey) {
            // disable browser's handling of ctrl/cmd-X, ctrl/cmd-C, and ctrl/cmd-V
            if ((evt.keyCode == 88) || (evt.keyCode == 67) || (evt.keyCode == 86)) evt.preventDefault();
        }
    };
    document.onkeyup = function (evt) {
        GP.events.push(keyEvent(KEY_UP, evt));
    };
    document.onkeypress = function (evt) {
        let { charCode } = evt;
        if (evt.char && (evt.char.length == 1)) charCode = evt.char.charCodeAt(0);
        GP.events.push([TEXTINPUT, charCode]);
    };
    canvas.onwheel = function (evt) {
        if (evt.shiftKey || evt.ctrlKey) { return; } // default behavior (browser zoom)
        const dx = evt.wheelDeltaX;
        const dy = evt.wheelDeltaY;
        GP.events.push([MOUSE_WHEEL, dx, dy]);
        evt.preventDefault();
    };
    canvas.ontouchstart = function (evt) {
        const touch = evt.touches[evt.touches.length - 1];
        if (touch) {
            const button = (evt.touches.length == 2) ? 3 : 0;
            const p = localPoint(touch.clientX, touch.clientY);
            GP.events.push([TOUCH_DOWN, p[0], p[1], button]);
        }
        evt.preventDefault();
    };
    canvas.ontouchend = function (evt) {
        GP.events.push([TOUCH_UP, 0, 0, 0]);
        evt.preventDefault();
    };
    canvas.ontouchmove = function (evt) {
        const touch = evt.touches[evt.touches.length - 1];
        if (touch) {
            const p = localPoint(touch.clientX, touch.clientY);
            GP.events.push([TOUCH_MOVE, p[0], p[1], 0]);
        }
        evt.preventDefault();
    };
}
initGPEventHandlers();

function GP_backspace() {
    // Simulate the backspace/delete key on Android.
    const KEY_DOWN = 5;
    const KEY_UP = 6;
    GP.events.push([KEY_DOWN, 8, 8, 0]);
    GP.events.push([KEY_UP, 8, 8, 0]);
}

// drag-n-drop events

window.addEventListener(
    'dragover',
    evt => {
        evt.preventDefault();
    },
    false
);

window.addEventListener(
    'drop',
    evt => {
        evt.preventDefault();
        const files = evt.target.files || evt.dataTransfer.files;
        if (files && files.length) {
            uploadFiles(files);
        } else if (evt.dataTransfer) {
            // Dropping a text clipping or URL can be used as workaround for paste
            const s = evt.dataTransfer.getData('text/plain');
            if (s) GP.droppedTextBytes = toUTF8Array(s);
            const url = evt.dataTransfer.getData('URL');
            if (url) GP.droppedTextBytes = toUTF8Array(`${url}\n`);
        }
    },
    false
);

// message handling

function queueGPMessage(s) {
    // Queue a message that can be read by GP with the 'browserGetMessage' primitive
    // This mechanism is currently used by HTML buttons for 'go', 'stop', and 'see inside'.

    GP.messages.push(toUTF8Array(s));
}

function handleMessage(evt) {
    // Handle a message sent by the JavaScript postMessage() function.
    // This is used to control button visibility or to queue a message to GP.

    const msg = evt.data;
    if (msg.startsWith('showButton ')) {
        var btn = document.getElementById(msg.substring(11));
        if (btn) btn.style.display = 'inline';
    } else if (msg.startsWith('hideButton ')) {
        var btn = document.getElementById(msg.substring(11));
        if (btn) btn.style.display = 'none';
    } else {
        queueGPMessage(msg);
    }
}

window.addEventListener('message', handleMessage, false);

// file upload support

function GP_UploadFiles(evt) {
    // Upload using "Upload" button
    const inp = document.getElementById('FileUploader'); // use the hidden file input element
    if (inp) inp.click();
}

function uploadFiles(files) {
    // Upload files. Initiated from either FileUploader click or drag-and-drop.

    function recordFile(f) {
        reader = new FileReader();
        reader.onloadend = function () {
            if (reader.result) {
                GP.droppedFiles.push({ name: f.name, contents: reader.result });
            }
            if (todo.length) recordFile(todo.shift());
        };
        reader.readAsArrayBuffer(f);
    }
    var todo = [];
    if (files && files.length) {
        for (let i = 0; i < files.length; i++) todo.push(files[i]);
	    recordFile(todo.shift());
    }
}

function adjustButtonVisibility() {
    // Show the appropriate buttons in a mobile or non-mobile browser.
    const kbdButton = document.getElementById('KeyboardButton');
    const bsButton = document.getElementById('BackspaceButton');
    const fsButton = document.getElementById('FullscreenButton');
    const { userAgent } = navigator;
    const isKindle = /Kindle|Silk|KFAPW|KFARWI|KFASWI|KFFOWI|KFJW|KFMEWI|KFOT|KFS‌​AW|KFSOWI|KFTBW|KFTH‌​W|KFTT|WFFOWI/i.test(userAgent);
    const isOtherMobile = /Android|webOS|iPhone|iPad|iPod|CriOS|BlackBerry|IEMobile|Opera Mini/i.test(userAgent);
    if (isKindle || isOtherMobile) {
        kbdButton.style.display = 'inline';
    } else {
        kbdButton.style.display = 'none';
    }
    if (isKindle || /Android/i.test(navigator.userAgent)) {
        bsButton.style.display = 'inline';
    } else {
        bsButton.style.display = 'none';
    }
    if (/iPhone|iPad|iPod|CriOS/i.test(userAgent)) {
        fsButton.style.display = 'none';
    } else {
        fsButton.style.display = 'inline';
    }

    if (window.parent === window) {
        document.getElementById('EnableMicrophoneButton').style.display = 'none';
    }

    // adjust buttons when opened with 'go.html' URL
    if ((typeof window !== 'undefined') && (window.location.href.includes('go.html'))) {
        document.getElementById('SeeInsideButton').style.display = 'inline';
        document.getElementById('PresentButton').style.display = 'none';
    } else if ((typeof window !== 'undefined') && (window.location.href.includes('microblocks.html'))) {
        document.getElementById('controls').style.display = 'none';
    } else {
        document.getElementById('SeeInsideButton').style.display = 'none';
        document.getElementById('PresentButton').style.display = 'inline';
    }
}
adjustButtonVisibility();

// Canvas shadow effects

function setContextShadow(ctx) {
    if (!GP.shadowColor) return;
    ctx.shadowColor = GP.shadowColor;
    ctx.shadowOffsetX = GP.shadowOffset;
    ctx.shadowOffsetY = GP.shadowOffset;
    ctx.shadowBlur = GP.shadowBlur;
}

function setShadow(red, green, blue, alpha, offset, blur) {
    GP.shadowColor = `rgba(${red}, ${green}, ${blue}, ${alpha})`;
    GP.shadowOffset = offset;
    GP.shadowBlur = blur;
}

function clearShadow() {
    GP.shadowColor = null;
    GP.shadowOffset = 0;
    GP.shadowBlur = 0;
}

// audio input and output support

function GP_audioContext() {
    // Note: Cache the audio context because browsers only allow you to create a few of them.
    if (GP.cachedAudioContext) return GP.cachedAudioContext;

    function unsuspendAudioContext() {
        // On iOS, the audio context is suspended until resumed by a touch event.
        if (GP.cachedAudioContext && (GP.cachedAudioContext.state === 'suspended')) {
            GP.cachedAudioContext.resume();
        }
    }
    const AudioContextClass = (window.AudioContext || window.webkitAudioContext
		|| window.mozAudioContext || window.msAudioContext || window.oAudioContext);
    if (!AudioContextClass) {
        console.warn('This browser does not support audio');
        return null;
    }
    GP.cachedAudioContext = new AudioContextClass();
    document.body.addEventListener('touchend', unsuspendAudioContext, false);
    return GP.cachedAudioContext;
}

// iOS hack -- create the audio context at startup so a touch event
// can unsuspend the audio context before we actually need it:
// Still needed? Commented out for now... (April, 2020)
// GP_audioContext();

function GP_startAudioInput(inputSampleCount, sampleRate) {
    if (GP.audioInCapture && GP.audioInSource) return; // already open

    function doSoundInput(evt) {
        const buf = evt.inputBuffer.getChannelData(0);
        if (GP.audioInDownsampling) {
            for (i = 0; i < buf.length; i += 2) {
                const n = ((buf[i] + buf[i + 1]) * 16383) | 0; // average two samples and convert to signed int (16383 is 32767 / 2)
                GP.audioInBuffer[i / 2] = n;
            }
        } else {
            for (i = 0; i < buf.length; i++) {
                GP.audioInBuffer[i] = (buf[i] * 32767) | 0; // convert to signed int
            }
        }
        GP.audioInReady = true;
    }
    function openAudioInput(stream) {
        const rawSampleCount = GP.audioInDownsampling ? (2 * inputSampleCount) : inputSampleCount;
        GP.audioInSource = audioContext.createMediaStreamSource(stream);
        GP.audioInCapture = audioContext.createScriptProcessor(rawSampleCount, 1); // will down-sample to 22050
        GP.audioInCapture.onaudioprocess = doSoundInput;
        GP.audioInSource.connect(GP.audioInCapture);
        GP.audioInCapture.connect(audioContext.destination);
    }
    function openAudioInputFailed(e) {
        console.warn(`Could not open audio input: ${e}`);
    }

    audioContext = GP_audioContext();
    if (!audioContext) return;

    const data = new ArrayBuffer(2 * inputSampleCount); // two-bytes per sample
    GP.audioInBuffer = new Int16Array(data);
    GP.audioInDownsampling = (sampleRate < audioContext.sampleRate);
    GP.audioInReady = false;

    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia
		|| navigator.mozGetUserMedia || navigator.msGetUserMedia || navigator.oGetUserMedia;
    if (navigator.getUserMedia) {
        navigator.getUserMedia({ audio: true }, openAudioInput, openAudioInputFailed);
    } else {
        console.warn('Audio input is not supported by this browser');
    }
}

function GP_stopAudioInput() {
    if (GP.audioInSource) GP.audioInSource.disconnect();
    if (GP.audioInCapture) GP.audioInCapture.disconnect();
    GP.audioInSource = null;
    GP.audioInCapture = null;
    GP.audioInReady = false;
}

function GP_startAudioOutput(frameCount, isStereo) {
    if (GP.callbackID) return; // already open

    audioContext = GP_audioContext();
    if (!audioContext) return;

    function soundProcess() {
        if (!GP.callbackID) return; // audio output closed
        if (audioContext.currentTime <= GP.audioOutFlipTime) {
            GP.callbackID = requestAnimationFrame(soundProcess);
            return;
        }

        // select the buffer to fill and swap buffers
        const buf = GP.audioOutBuffers[GP.audioOutBufferIndex];
        GP.audioOutBufferIndex = (GP.audioOutBufferIndex + 1) % 2;

        if (GP.audioOutReady) {
            if (GP.audioOutIsStereo) { // stereo
                const left = buf.getChannelData(0);
                const right = buf.getChannelData(1);
                for (var i = 0; i < left.length; i++) {
                    left[i] = GP.audioOutBuffer[2 * i];
                    right[i] = GP.audioOutBuffer[(2 * i) + 1];
                }
            } else { // mono
                var samples = buf.getChannelData(0);
                for (var i = 0; i < samples.length; i++) samples[i] = GP.audioOutBuffer[i];
            }
        } else { // no GP audio data available; fill all channels with silence
            for (let chan = 0; chan < buf.numberOfChannels; chan++) {
                var samples = buf.getChannelData(chan);
                for (var i = 0; i < samples.length; i++) samples[i] = 0;
            }
        }
        GP.audioOutReady = false;

        let startTime = GP.audioOutFlipTime + buf.duration;
        if (audioContext.currentTime > startTime) startTime = audioContext.currentTime;
        const source = audioContext.createBufferSource();
        source.buffer = buf;
        source.start(startTime);
        source.connect(audioContext.destination);
        GP.audioOutFlipTime = startTime; // when this buffer starts playing, GP can fill the other one
        GP.callbackID = requestAnimationFrame(soundProcess);
    }

    const channelCount = isStereo ? 2 : 1;
    const data = new ArrayBuffer(4 * frameCount * channelCount); // four-bytes per sample (Float32's)
    GP.audioOutBuffer = new Float32Array(data);
    GP.audioOutIsStereo = isStereo;
    GP.audioOutReady = false;

    GP.audioOutBuffers = [];
    GP.audioOutBuffers.push(audioContext.createBuffer(channelCount, frameCount, 22050));
    GP.audioOutBuffers.push(audioContext.createBuffer(channelCount, frameCount, 22050));
    GP.audioOutBufferIndex = 0;
    GP.audioOutFlipTime = -1;

    GP.callbackID = requestAnimationFrame(soundProcess);
}

function GP_stopAudioOutput() {
    if (!GP.callbackID) cancelAnimationFrame(GP.callbackID);
    GP.callbackID = null;
}

function GP_toggleFullscreen() {
    const doc = window.document;
    const docEl = doc.documentElement;

    const requestFullScreen = docEl.requestFullscreen || docEl.mozRequestFullScreen || docEl.webkitRequestFullScreen || docEl.msRequestFullscreen;
    const cancelFullScreen = doc.exitFullscreen || doc.mozCancelFullScreen || doc.webkitExitFullscreen || doc.msExitFullscreen;

    if (!doc.fullscreenElement && !doc.mozFullScreenElement && !doc.webkitFullscreenElement && !doc.msFullscreenElement) {
        requestFullScreen.call(docEl);
    } else {
        cancelFullScreen.call(doc);
    }
}

// Serial Ports (supported in Chrome OS and Chromium-based browsers only)
// Only one serial port can be open at a time.

function hasChromeSerial() {
    return ((typeof chrome !== 'undefined') && (typeof chrome.serial !== 'undefined'));
}

function hasWebSerial() {
    if (hasChromeSerial()) return false; // Chrome OS has a different serial API
    return (typeof navigator.serial !== 'undefined');
}

// WebSerial support for Chrome browser (navigator.serial API)

GP_webSerialPort = null;
GP_webSerialReader = null;

function webSerialIsConnected() {
    return !(!GP_webSerialPort || !GP_webSerialReader);
}

async function webSerialConnect() {
    // Prompt user to choose a serial port and open the one selected.

    const vendorIDs = [
        { usbVendorId: 0x0403 },		// FTDI
        { usbVendorId: 0x0d28 },		// micro:bit, Calliope
        { usbVendorId: 0x10c4 },		// Silicon Laboratories, Inc. (CP210x)
        { usbVendorId: 0x1a86 },		// CH340
        { usbVendorId: 0x239a },		// AdaFruit
        { usbVendorId: 0x2a03 },		// Arduino
        { usbVendorId: 0x2341 },		// Arduino MKR Zero
        { usbVendorId: 0x03eb },		// Atmel Corporation
        { usbVendorId: 0x1366 },		// SEGGER Calliope mini
        { usbVendorId: 0x16c0 },		// Teensy
    ];
    webSerialDisconnect();
    GP_webSerialPort = await navigator.serial.requestPort({ filters: vendorIDs }).catch(e => { console.log(e); });
    if (!GP_webSerialPort) return; // no serial port selected
    await GP_webSerialPort.open({ baudRate: 115200 });
    GP_webSerialReader = await GP_webSerialPort.readable.getReader();
    webSerialReadLoop();
}

async function webSerialDisconnect() {
    if (GP_webSerialReader) await GP_webSerialReader.cancel();
    if (GP_webSerialPort) await GP_webSerialPort.close().catch(() => {});
    GP_webSerialReader = null;
    GP_webSerialPort = null;
}

async function webSerialReadLoop() {
    try {
        while (true) {
            const { value, done } = await GP_webSerialReader.read();
            if (value) {
                GP_serialInputBuffers.push(value);
            }
            if (done) { // happens when GP_webSerialReader.cancel() is called by disconnect
                GP_webSerialReader.releaseLock();
                return;
            }
        }
    } catch (e) { // happens when board is unplugged
        console.log(e);
        await GP_webSerialPort.close().catch(() => {});
        GP_webSerialPort = null;
        GP_webSerialReader = null;
        console.log('Connection closed.');
    }
}

function webSerialWrite(data) {
    if (!GP_webSerialPort || !GP_webSerialPort.writable) return 0; // port not open
    const w = GP_webSerialPort.writable.getWriter();
    w.write(data.buffer);
    w.releaseLock();
    return data.buffer.byteLength;
}

// Variables used by Chromebook App Serial (chrome.serial API)

GP_serialPortNames = [];
GP_serialPortID = -1;
GP_serialInputBuffers = [];
GP_serialPortListenersAdded = false;

// Serial support for both WebSerial and Chromebook App

function GP_getSerialPorts() {
    // Request an update to the serial port list, GP_serialPortNames. Since this call
    // is asynchronous, the result is not available in GP_serialPortNames immediately.
    // The caller should call this, wait a bit, then read GP_serialPortNames.

    function listPorts(ports) {
        GP_serialPortNames = [];
        for (let i = 0; i < ports.length; i++) {
            GP_serialPortNames.push(toUTF8Array(ports[i].path));
        }
    }
    if (hasChromeSerial()) chrome.serial.getDevices(listPorts);
}

function GP_openSerialPort(id, path, baud) {
    function serialPortError(info) {
        console.log(`Serial port error: ${info.error}`);
        GP_closeSerialPort();
    }
    function serialPortDataReceived(info) {
        GP_serialInputBuffers.push(new Uint8Array(info.data));
    }
    function portOpened(connectionInfo) {
        if (!connectionInfo || chrome.runtime.lastError) {
            let reason = '';
            if (chrome.runtime.lastError) reason = chrome.runtime.lastError.message;
        	console.log(`Port open failed ${reason}`);
        	GP_serialPortID = -1;
        	return; // failed to open port
    	}
        GP_serialPortID = connectionInfo.connectionId;
        GP_serialInputBuffers = [];
        if (!GP_serialPortListenersAdded) {
            // Listeners only need to be added once.
            chrome.serial.onReceiveError.addListener(serialPortError);
            chrome.serial.onReceive.addListener(serialPortDataReceived);
            GP_serialPortListenersAdded = true;
        }
    }
    if (hasChromeSerial()) {
        if (GP_serialPortID >= 0) return 1; // already open (not an error)
        chrome.serial.connect(path, { persistent: true, bitrate: baud }, portOpened);
    } else if (hasWebSerial()) {
        webSerialConnect();
    }
    return 1; // connect is asynchronous, but assume it will succeed
}

function GP_isOpenSerialPort() {
    if (hasWebSerial()) return webSerialIsConnected();
    if (hasChromeSerial()) return (GP_serialPortID >= 0);
    return false;
}

function GP_closeSerialPort() {
    function portClosed(ignored) { }
    if (GP_serialPortID > 0) {
        chrome.serial.disconnect(GP_serialPortID, portClosed);
    } else if (hasWebSerial()) {
        webSerialDisconnect();
    }
    GP_serialPortID = -1;
    GP_serialInputBuffers = [];
}

function GP_readSerialPort(maxBytes) {
    if (GP_serialInputBuffers.length == 0) {
        return new Uint8Array(new ArrayBuffer(0)); // no data available
    }
    let count = 0;
    for (var i = 0; i < GP_serialInputBuffers.length; i++) {
        count += GP_serialInputBuffers[i].byteLength;
    }
    let result = new Uint8Array(new ArrayBuffer(count));
    let dst = 0;
    for (var i = 0; i < GP_serialInputBuffers.length; i++) {
        const buf = GP_serialInputBuffers[i];
        result.set(GP_serialInputBuffers[i], dst);
        dst += GP_serialInputBuffers[i].byteLength;
    }
    if (result.byteLength <= maxBytes) {
        GP_serialInputBuffers = [];
    } else {
        GP_serialInputBuffers = [result.slice(maxBytes)];
        result = result.slice(0, maxBytes);
    }
    return result;
}

function GP_writeSerialPort(data) {
    function dataSent(ignored) { }
    if (hasWebSerial()) {
        return webSerialWrite(data);
    }
    if (GP_serialPortID < 0) return -1; // port not open
    chrome.serial.send(GP_serialPortID, data.buffer, dataSent);
    return data.buffer.byteLength;
}

async function GP_setSerialPortDTR(flag) {
    function ignore(result) {}
    if (hasChromeSerial()) {
        flag = !!(flag);
        chrome.serial.setControlSignals(GP_serialPortID, { dtr: flag }, ignore);
    } else if (hasWebSerial()) {
        if (!GP_webSerialPort) return; // port not open
        await GP_webSerialPort.setSignals({ dtr: flag, dataTerminalReady: flag }).catch(() => {});
    }
}

async function GP_setSerialPortRTS(flag) {
    function ignore(result) {}
    if (hasChromeSerial()) {
        flag = !!(flag);
        chrome.serial.setControlSignals(GP_serialPortID, { rts: flag }, ignore);
    } else if (hasWebSerial()) {
        if (!GP_webSerialPort) return; // port not open
        await GP_webSerialPort.setSignals({ rts: flag, requestToSend: flag }).catch(() => {});
    }
}

// File read/write

function hasChromeFilesystem() {
    return ((typeof chrome !== 'undefined') && (typeof chrome.fileSystem !== 'undefined'));
}

async function GP_ReadFile(ext) {
    // Upload using Native File API.

    function onFileSelected(entry) {
        void chrome.runtime.lastError; // suppress error message
        if (!entry) return; // no file selected
        entry.file(file => {
            const reader = new FileReader();
            reader.onload = function (evt) {
                GP.droppedFiles.push({ name: file.name, contents: evt.target.result });
            };
            reader.readAsArrayBuffer(file);
        });
    }

    if (ext == '') ext = 'txt';
    if (hasChromeFilesystem()) {
        const options = {
            type: 'openFile',
            accepts: [{ description: 'MicroBlocks', extensions: [ext] }],
        };
        chrome.fileSystem.chooseEntry(options, onFileSelected);
    } else if (typeof window.showOpenFilePicker !== 'undefined') { // Native Filesystem API
        const options = { types: [{ description: 'MicroBlocks', accept: { 'text/plain': [`.${ext}`] } }] };
        const files = await window.showOpenFilePicker(options).catch(e => { console.log(e); });
        if (!files || (files.length == 0) || !files[0].getFile) return; // no file selected
        const file = await files[0].getFile();
        const contents = await file.arrayBuffer();
        GP.droppedFiles.push({ name: file.name, contents });
    } else {
        GP_UploadFiles();
    }
}

function download(filename, text) {
    // from https://stackoverflow.com/questions/2897619/using-html5-javascript-to-generate-and-save-a-file

    const pom = document.createElement('a');
    pom.setAttribute('href', `data:text/plain;charset=utf-8,${encodeURIComponent(text)}`);
    pom.setAttribute('download', filename);

    if (document.createEvent) {
        const event = document.createEvent('MouseEvents');
        event.initEvent('click', true, true);
        pom.dispatchEvent(event);
    } else {
        pom.click();
    }
}

async function GP_writeFile(data, fName, id) {
    // Write the given data to the given file. fName should including an extension.
    // id is hint for the operation type (e.g. 'project' for saving a project file.
    // The browser remembers the folder for the last save with that id.

    function onFileSelected(entry) {
        void chrome.runtime.lastError; // suppress error message
        if (entry) {
            entry.createWriter(writer => {
                GP.lastSavedFileName = entry.name;
                writer.write(new Blob([data], { type: 'text/plain' }));
            });
        }
    }

    i = fName.lastIndexOf('.');
    ext = (i >= 0) ? fName.substr(i + 1) : '';

    i = fName.indexOf('.');
    if (i > 0) fName = fName.substr(0, i);
    if (i == 0) fName = 'Untitled';

    if (hasChromeFilesystem()) {
        // extract the extension from fName
        const options = {
            type: 'saveFile',
            suggestedName: `${fName}.${ext}`,
            accepts: [{ description: 'MicroBlocks', extensions: [ext] }],
        };
        chrome.fileSystem.chooseEntry(options, onFileSelected);
    } else if (typeof window.showSaveFilePicker !== 'undefined') { // Native Filesystem API
        if (/(CrOS)/.test(navigator.userAgent)) {
            // On Chromebooks, the extension is not automatically appended.
            fName = `${fName}.${ext}`;
        }
        options = { suggestedName: fName, id };
        if (ext != '') {
            if (ext[0] != '.') ext = `.${ext}`;
            if ((ext == '.hex') || (ext == '.uf2')) {
                options.types = [{ accept: { 'application/octet-stream': [ext] } }];
            } else {
                options.types = [{ accept: { 'text/plain': [ext] } }];
            }
        }

        const fileHandle = await window.showSaveFilePicker(options).catch(e => { console.log(e); });
        if (!fileHandle) {
            GP.lastSavedFileName = '_no_file_selected_';
            return; // no file selected
        }
        const writable = await fileHandle.createWritable();
        await writable.write(new Blob([data]));
        await writable.close();
        GP.lastSavedFileName = fileHandle.name;
    } else {
        saveAs(new Blob([data]), `${fName}.${ext}`);
    }
}

// On ChromeOS, read the file opened to launch the application, if any

function GP_ChromebookLaunch(bgPage) {
    if (bgPage.launchFileEntry) {
        const fName = bgPage.launchFileEntry.fullPath;
        bgPage.launchFileEntry.file(file => {
            const reader = new FileReader();
            reader.onload = function (evt) {
                GP.droppedFiles.push({ name: fName, contents: evt.target.result });
            };
            reader.readAsArrayBuffer(file);
        });
    }
}

if ((typeof chrome !== 'undefined')
	&& (typeof chrome.runtime !== 'undefined')
	&& (typeof chrome.runtime.getBackgroundPage !== 'undefined')) {
    chrome.runtime.getBackgroundPage(GP_ChromebookLaunch);
}

// warn before leaving page

window.onbeforeunload = function () {
    return 'Leave this page? (changes will be lost)';
};

// progressive web app service worker

// window.onload = function() {
//   if (('serviceWorker' in navigator) && !hasChromeFilesystem()) {
//     navigator.serviceWorker.register('sw.js');
//   }
// }
//
