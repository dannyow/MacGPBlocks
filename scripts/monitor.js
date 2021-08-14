const chokidar = require('chokidar');
const { exec } = require('child_process');

const watchedSrcs = './runtimes/newMorphic/**';
// const watchedSrcs = './runtimes/minimal/**';
const commandToExecute = '/Users/daniel/Library/Developer/Xcode/DerivedData/MacGPBlocks-hjsojqtrcfseoygrklnrdoecdoqj/Build/Products/Debug/MacGPBlocks.app/Contents/MacOS/MacGPBlocks';

const watcher = chokidar.watch(watchedSrcs, {
    // ignored: /(^|[\/\\])\../, // ignore dotfiles
    persistent: true,
});


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
