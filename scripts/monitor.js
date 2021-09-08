const chokidar = require('chokidar');
const { exec } = require('child_process');

let watchedSrcs = './runtimes/anamorphic/**';

// App is copied to .build as post-action in xcode (see post-action-copy-app-for-monitor.sh)
const commandToExecute = '.build/MacGPBlocks.app/Contents/MacOS/MacGPBlocks';

if (process.env.GP_RUNTIME_DIR) {
    watchedSrcs = `${process.env.GP_RUNTIME_DIR}**`;
} else {
    process.env.GP_RUNTIME_DIR = `${watchedSrcs.replace(/\*+$/, '')}`;
}

console.log('\x1b[33m%s\x1b[0m', `Monitoring path: >${watchedSrcs}<`, '\x1b[0m'); // yellow

const watcher = chokidar.watch(watchedSrcs, {
    // ignored: /(^|[\/\\])\../, // ignore dotfiles
    persistent: true,
});


let command;
const changeObserver = () => {
    console.log('\x1b[33m%s\x1b[0m', 'Path was changed, restarting...', '\x1b[0m'); // yellow

    if (command) {
        command.kill();
        process.stdout.write('\u001b[3J\u001b[2J\u001b[1J');
        console.clear();
    }

    command = exec(commandToExecute);

    command.stdout.on('data', data => {
        process.stdout.write(data);
    });
};

changeObserver();
watcher.on('change', changeObserver);
