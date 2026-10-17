import {rmSync, cpSync} from 'node:fs';

rmSync('dist', {recursive: true, force: true});
cpSync('src', 'dist', {recursive: true});
console.log('built dist/');
