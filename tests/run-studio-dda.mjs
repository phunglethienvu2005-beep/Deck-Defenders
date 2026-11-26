import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';

if (!process.argv[2]) throw new Error('Pass the path to luau-web/src/index.js');
const {LuauState} = await import(pathToFileURL(path.resolve(process.argv[2])));
const state = await LuauState.createAsync();
try {
    const source = fs.readFileSync('tools/studio-dda-diagnostics.luau', 'utf8');
    const fixture = fs.readFileSync('tests/studio-dda-diagnostics.spec.luau', 'utf8');
    state.loadstring(source, 'diagnostics syntax', true);
    const [result] = await state.loadstring(
        fixture.replace('-- DIAGNOSTICS_CHUNK', () => source), 'diagnostics fixture', true)();
    console.log(result);
} finally {
    state.destroy();
}
