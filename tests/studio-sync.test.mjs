import fs from 'node:fs';
import assert from 'node:assert/strict';
import test from 'node:test';
import {execFileSync} from 'node:child_process';
import {fingerprint, makeBundle, quoteLuau, renderBundle} from '../tools/generate-studio-sync.mjs';

const manifest = JSON.parse(fs.readFileSync('tools/studio-sync-manifest.json', 'utf8'));
const inventory = JSON.parse(execFileSync(process.execPath,
    ['tools/inspect-place.mjs', 'TowerDefense_DoAn.rbxl', '--sources'], {encoding: 'utf8'}));
const readSource = file => fs.readFileSync(file, 'utf8');
const bundle = makeBundle(manifest, inventory, readSource);

test('RBXL inventory identifies the display script and Zombie AnimationContent URIs', () => {
    const idlePath = 'Workspace/CrimsonHero/IdleAnimation';
    const idle = inventory.scripts.find(script => script.path === idlePath);
    assert.equal(idle.className, 'Script');
    const references = inventory.scripts.filter(script => /\b507770000\b/.test(script.source));
    assert.deepEqual(references.map(script => script.path), idle.source.includes('507770000') ? [idlePath] : []);
    if (references.length === 0) {
        assert.equal(idle.source, readSource('src/Workspace/CrimsonHero/IdleAnimation.server.luau').trim());
    }
    assert.ok(inventory.animationJoints.includes('Workspace/CrimsonHero/UpperTorso/Waist'));
    assert.equal(inventory.animations.length, 10);
    assert.equal(inventory.animations.find(animation => animation.path.endsWith('/walk/RunAnim')).animationId,
        'http://www.roblox.com/asset/?id=616168032');
    assert.ok(inventory.animations.every(animation => !animation.animationId?.includes('507770000')));
});

test('an already synchronized RBXL keeps matching modules and rejects conflicting module sources', () => {
    const module = manifest.entries.find(entry => entry.create && entry.className === 'ModuleScript');
    const scripts = inventory.scripts.filter(script => script.path !== module.path);
    const existing = {path: module.path, className: 'ModuleScript', source: readSource(module.source).trim()};
    assert.doesNotThrow(() => makeBundle(manifest, {...inventory, scripts: [...scripts, existing]}, readSource));
    const conflicting = {...existing, source: 'return {} -- unexpected local edit'};
    assert.throws(() => makeBundle(manifest, {...inventory, scripts: [...scripts, conflicting]}, readSource),
        /Unexpected existing module Source/);
});

test('sync manifest agrees with RBXL classes and documented destinations', () => {
    const report = readSource('docs/audit/SOURCE_SYNC_MANIFEST.md');
    assert.equal(bundle.entries.length, 22);
    const idle = bundle.entries.find(entry => entry.path === 'Workspace/CrimsonHero/IdleAnimation');
    assert.equal(idle.className, 'Script');
    assert.ok(idle.baseline);
    assert.equal(idle.create, undefined);
    assert.match(idle.source, /TweenService/);
    assert.doesNotMatch(idle.source, /507770000|LoadAnimation/);
    assert.equal(bundle.entries.filter(entry => entry.create).length, 9);
    assert.equal(bundle.entries.find(entry => entry.path === 'ServerScriptService/PlayerDash').className, 'Script');
    assert.equal(bundle.entries.find(entry => entry.path === 'StarterPlayer/StarterPlayerScripts/PlayerDash').className, 'LocalScript');
    for (const entry of manifest.entries) {
        assert.ok(report.includes('`' + entry.source + '` | `' + entry.path + '`'), entry.path);
        const packaged = bundle.entries.find(item => item.path === entry.path).source;
        assert.equal(packaged, readSource(entry.source).replaceAll('\r\n', '\n'));
    }
    assert.equal(bundle.legacy.path, 'StarterGui/LobbyGui/LobbyController');
    assert.equal(bundle.preserve.path, 'ReplicatedStorage/Modules/WaveData');
    assert.ok(!bundle.entries.some(entry => entry.path === bundle.preserve.path));
    assert.ok(bundle.entries.some(entry => entry.path === 'StarterGui/LobbyUI/LobbyController'));
    assert.equal(makeBundle(manifest, inventory, readSource).id, bundle.id);
});

test('generator rejects duplicate targets, incompatible source type and RBXL asset loss', () => {
    const copy = structuredClone(manifest);
    copy.entries.push(copy.entries[0]);
    assert.throws(() => makeBundle(copy, inventory, readSource), /duplicate destination/);
    const mismatch = structuredClone(manifest);
    mismatch.entries.find(item => item.path.endsWith('/TowerServer')).className = 'LocalScript';
    assert.throws(() => makeBundle(mismatch, inventory, readSource), /class or creation mismatch/);
    const withoutBase = {...inventory, assets: inventory.assets.filter(row => row.path !== 'Workspace/EnemyBase')};
    assert.throws(() => makeBundle(manifest, withoutBase, readSource), /RBXL asset/);
});

test('the v2 bundle blocks active alternate Tower writers and carries the approved migration fingerprints', () => {
    assert.equal(bundle.buildVersion, 'hero-limits-v2');
    const writer = {path: 'ServerScriptService/TowerCombat', className: 'Script', enabled: true};
    assert.throws(() => makeBundle(manifest, {...inventory, scripts: [...inventory.scripts, writer]}, readSource),
        /Conflicting placement script/);
    const target = bundle.entries.find(entry => entry.path === 'ReplicatedStorage/Modules/PlacementRules');
    assert.ok(target.previousSources.includes('4674:2928839212:2342617739'));
    assert.equal(bundle.oneClickFromBuildVersion, 'hero-limits-v2');
    assert.equal(bundle.entries.filter(entry => entry.rcSeedSource).length, 5);
    const placement = bundle.entries.find(entry => entry.path === 'StarterPlayer/StarterPlayerScripts/PlacementClient');
    assert.equal(placement.rcUpdateSource, '26973:1650189876:4180624148');
    const mismatchedRC = {...manifest, entries: manifest.entries.map(entry =>
        entry.path === placement.path ? {...entry, rcUpdateSource: '0:0:0'} : entry)};
    assert.throws(() => makeBundle(mismatchedRC, inventory, readSource), /RC update Source/);
});

test('generator safely escapes Luau control characters and Unicode', () => {
    const input = 'Đ"]==]\\' + String.fromCharCode(0, 10, 13, 31, 127) + '9';
    const literal = quoteLuau(input);
    const slash = String.fromCharCode(92);
    assert.equal(literal, '"Đ' + slash + '"]==]' + slash.repeat(2)
        + ['000', '010', '013', '031', '127'].map(code => slash + code).join('') + '9"');
    assert.equal(fingerprint(' A\r\nB\n'), fingerprint('A\nB'));
    assert.notEqual(fingerprint('A B'), fingerprint('AB'));
    const engine = readSource('tools/studio-sync-engine.luau');
    for (const mode of ['dry-run', 'apply', 'verify', 'rollback', 'diagnostics', 'one-click']) {
        assert.ok(renderBundle(bundle, engine, mode).startsWith('local MODE = "' + mode + '"'));
    }
});
