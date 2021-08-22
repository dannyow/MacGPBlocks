const chokidar = require('chokidar');
const { exec } = require('child_process');

const watchedSrcs = './runtimes/anamorphic/**';
// App is copied to .build as post-action in xcode (see post-action-copy-app-for-monitor.sh)
const commandToExecute = '.build/MacGPBlocks.app/Contents/MacOS/MacGPBlocks';

const watcher = chokidar.watch(watchedSrcs, {
    // ignored: /(^|[\/\\])\../, // ignore dotfiles
    persistent: true,
});

process.env.GP_RUNTIME_DIR = `${watchedSrcs.replace(/\*+$/, '')}`;

let command;
const changeObserver = () => {
    // if (stats) console.log(`File ${path} changed size to ${stats.size}`);
    // console.log('path was changed', path);

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
