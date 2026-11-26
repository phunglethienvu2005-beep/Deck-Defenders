import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const normalize = source => source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
const pathPattern = /^[A-Za-z0-9_]+(\/[A-Za-z0-9_]+)+$/;

export function quoteLuau(value) {
    return '"' + value.replace(/["\\\x00-\x1f\x7f]/g, char => {
        if (char === '"' || char === '\\') return '\\' + char;
        return '\\' + String(char.charCodeAt(0)).padStart(3, '0');
    }) + '"';
}

function toLuau(value) {
    if (typeof value === 'string') return quoteLuau(value);
    if (typeof value === 'boolean' || typeof value === 'number') return String(value);
    if (Array.isArray(value)) return '{' + value.map(toLuau).join(',') + '}';
    return '{' + Object.entries(value).map(([key, item]) =>
        '[' + quoteLuau(key) + ']=' + toLuau(item)).join(',') + '}';
}

export function fingerprint(source) {
    const bytes = Buffer.from(normalize(source).replace(/^[ \t\n\v\f]+|[ \t\n\v\f]+$/g, ''));
    let first = 0;
    let second = 0;
    for (const byte of bytes) {
        first = (first * 131 + byte) % 4294967291;
        second = (second * 257 + byte) % 4294967279;
    }
    return [bytes.length, first, second].join(':');
}

export function makeBundle(manifest, inventory, readSource) {
    if (manifest.buildVersion !== undefined && (typeof manifest.buildVersion !== 'string'
        || !/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(manifest.buildVersion))) {
        throw new Error('Invalid manifest BuildVersion');
    }
    const originals = new Map();
    for (const entry of inventory.scripts) {
        if (originals.has(entry.path)) throw new Error('Duplicate script path in RBXL: ' + entry.path);
        originals.set(entry.path, entry);
    }
    const covered = new Set([manifest.legacy, manifest.preserve]);
    const entries = manifest.entries.map(entry => {
        if (!pathPattern.test(entry.path) || covered.has(entry.path)) throw new Error('Invalid or duplicate destination: ' + entry.path);
        if (!['Script', 'LocalScript', 'ModuleScript'].includes(entry.className)) throw new Error('Invalid class: ' + entry.path);
        if (!/^src\/[A-Za-z0-9_./]+\.luau$/.test(entry.source) || entry.source.split('/').includes('..')) {
            throw new Error('Invalid source path: ' + entry.source);
        }
        covered.add(entry.path);
        const original = originals.get(entry.path);
        const canCreate = entry.className === 'ModuleScript'
            || (entry.className === 'Script' && entry.path === 'ServerScriptService/PlayerDash')
            || (entry.className === 'LocalScript' && entry.path === 'StarterPlayer/StarterPlayerScripts/PlayerDash');
        if (entry.create ? !canCreate || (original && original.className !== entry.className)
            : original?.className !== entry.className) {
            throw new Error('RBXL class or creation mismatch: ' + entry.path);
        }
        const source = normalize(readSource(entry.source));
        if (source.length === 0 || source.charCodeAt(0) === 0xFEFF) throw new Error('Empty or BOM-prefixed source: ' + entry.source);
        const previousSources = entry.previousSources ?? [];
        if (!Array.isArray(previousSources) || previousSources.some(item => typeof item !== 'string' || !/^\d+:\d+:\d+$/.test(item))) {
            throw new Error('Invalid previous Source fingerprint: ' + entry.path);
        }
        if (entry.rcSeedSource !== undefined && !previousSources.includes(entry.rcSeedSource)) {
            throw new Error('RC seed Source must be an approved previous Source: ' + entry.path);
        }
        if (entry.rcUpdateSource !== undefined && (!entry.rcSeedSource || !previousSources.includes(entry.rcUpdateSource))) {
            throw new Error('RC update Source must be an approved previous Source for a pinned RC target: ' + entry.path);
        }
        if (entry.create && original && normalize(original.source) !== source.trim()
            && !previousSources.includes(fingerprint(original.source))) {
            throw new Error('Unexpected existing module Source in RBXL: ' + entry.path);
        }
        return {path: entry.path, className: entry.className, source,
            ...(entry.create ? {create: true} : {baseline: fingerprint(original.source)}),
            ...(previousSources.length ? {previousSources} : {}),
            ...(entry.rcSeedSource ? {rcSeedSource: entry.rcSeedSource} : {}),
            ...(entry.rcUpdateSource ? {rcUpdateSource: entry.rcUpdateSource} : {})};
    });
    const seedVersion = manifest.oneClickFromBuildVersion;
    if (seedVersion !== undefined && (typeof seedVersion !== 'string'
        || !/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(seedVersion) || !manifest.buildVersion
        || !entries.some(entry => entry.rcSeedSource))) {
        throw new Error('Invalid one-click RC seed configuration');
    }

    const legacy = originals.get(manifest.legacy);
    const preserve = originals.get(manifest.preserve);
    if (legacy?.className !== 'LocalScript' || !legacy.source.includes('GameOver') || !legacy.source.includes('GameWin')
        || preserve?.className !== 'ModuleScript') throw new Error('Legacy result script or preserved WaveData differs from expectation');

    const baseParts = new Set(['Part', 'MeshPart', 'UnionOperation', 'SpawnLocation', 'WedgePart']);
    const assets = manifest.assets.map(([destination, className]) => {
        const candidates = inventory.assets.filter(asset => asset.path === destination);
        if (candidates.length !== 1 || !(candidates[0].className === className
            || (className === 'BasePart' && baseParts.has(candidates[0].className)))) {
            throw new Error('Missing, ambiguous, or mismatched RBXL asset: ' + destination);
        }
        return {path: destination, className};
    });
    const blockedPlacementWriters = manifest.blockedPlacementWriters ?? [];
    for (const destination of blockedPlacementWriters) {
        if (!pathPattern.test(destination) || covered.has(destination)) throw new Error('Invalid legacy placement path: ' + destination);
        const original = originals.get(destination);
        if (original && original.enabled !== false) throw new Error('Conflicting placement script in RBXL: ' + destination);
    }
    const payload = {entries, assets, blockedPlacementWriters, legacy: {path: manifest.legacy, baseline: fingerprint(legacy.source)},
        preserve: {path: manifest.preserve, baseline: fingerprint(preserve.source)},
        runtimeEvents: manifest.runtimeEvents, runtimeFunctions: manifest.runtimeFunctions,
        ...(manifest.buildVersion ? {buildVersion: manifest.buildVersion} : {}),
        ...(seedVersion ? {oneClickFromBuildVersion: seedVersion} : {})};
    return {...payload, id: createHash('sha256').update(JSON.stringify(payload)).digest('hex')};
}

export function renderBundle(bundle, engine, mode) {
    return 'local MODE = ' + quoteLuau(mode) + '\n'
        + '-- Generated from the workspace. Use the same bundle for Dry Run, Apply, Verify and Rollback.\n'
        + 'local BUNDLE = ' + toLuau(bundle) + '\n' + engine;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
    const manifest = JSON.parse(fs.readFileSync(path.join(root, 'tools/studio-sync-manifest.json'), 'utf8'));
    const inventory = JSON.parse(execFileSync(process.execPath, ['tools/inspect-place.mjs', 'TowerDefense_DoAn.rbxl', '--sources'],
        {cwd: root, encoding: 'utf8'}));
    const bundle = makeBundle(manifest, inventory, name => fs.readFileSync(path.join(root, name), 'utf8'));
    const out = path.join(root, 'tools/generated');
    const engine = fs.readFileSync(path.join(root, 'tools/studio-sync-engine.luau'), 'utf8');
    fs.mkdirSync(out, {recursive: true});
    for (const [file, mode] of Object.entries({'studio-preflight': 'dry-run', 'studio-sync': 'apply',
        'studio-verify': 'verify', 'studio-rollback': 'rollback', 'studio-diagnostics': 'diagnostics',
        'studio-one-click-sync': 'one-click'})) {
        const payload = mode === 'rollback' ? {id: bundle.id} : mode === 'diagnostics' ? {
            id: bundle.id, assets: bundle.assets, preserve: {path: bundle.preserve.path},
            entries: bundle.entries.map(({path, className}) => ({path, className})),
            runtimeEvents: bundle.runtimeEvents, runtimeFunctions: bundle.runtimeFunctions,
            blockedPlacementWriters: bundle.blockedPlacementWriters,
        } : bundle;
        fs.writeFileSync(path.join(out, file + '.luau'), renderBundle(payload, engine, mode));
    }
    console.log('Generated six local scripts for ' + bundle.entries.length + ' Source targets; bundle ' + bundle.id);
}
