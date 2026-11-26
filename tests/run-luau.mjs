import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';

const compiler = process.argv[2];
if (!compiler) {
    throw new Error('Pass the path to luau-web/src/index.js');
}

const { LuauState } = await import(pathToFileURL(path.resolve(compiler)));
const state = await LuauState.createAsync();
const roots = ['ReplicatedStorage', 'ServerScriptService', 'src', 'tests'];

try {
    let compiled = 0;
    for (const root of roots) {
        for (const file of fs.readdirSync(root, { recursive: true })) {
            if (!file.endsWith('.luau')) continue;
            const filename = path.join(root, file);
            state.loadstring(fs.readFileSync(filename, 'utf8'), filename, true);
            compiled += 1;
        }
    }

    console.log(`Luau files compiled: ${compiled}`);
    const controller = fs.readFileSync('src/ServerScriptService/DifficultyController.luau', 'utf8');
    const spec = fs.readFileSync('tests/DifficultyController.spec.luau', 'utf8');
    const chunk = [
        'local controller = (function()',
        controller,
        'end)()',
        'local test = (function()',
        spec,
        'end)()',
        'return test(controller)',
    ].join('\n');
    const [result] = await state.loadstring(chunk, 'DifficultyController.spec', true)();
    console.log(result);
    const source = name => fs.readFileSync(name, 'utf8');
    const wrap = (name, filename) => 'local ' + name + ' = (function()\n' + source(filename) + '\nend)()';
    const context = [
        wrap('mock', 'tests/roblox-value-mocks.luau'),
        'local game, Color3, Vector3 = mock.game, mock.Color3, mock.Vector3',
        'local modules = {}',
        wrap('StageData', 'src/ReplicatedStorage/Modules/StageData.luau'),
        wrap('WaveData', 'src/ReplicatedStorage/Modules/WaveData.luau'),
        'modules.StageData, modules.WaveData = StageData, WaveData',
        'local function require(name) return assert(modules[name]) end',
        wrap('StageResolver', 'src/ServerScriptService/StageResolver.luau'),
        wrap('PlacementRules', 'src/ReplicatedStorage/Modules/PlacementRules.luau'),
        wrap('MatchResult', 'src/ReplicatedStorage/Modules/MatchResult.luau'),
        wrap('DDA', 'src/ServerScriptService/DifficultyController.luau'),
        wrap('phase2', 'tests/Phase2.spec.luau'),
        'return phase2(StageResolver, PlacementRules, MatchResult, DDA, Vector3)',
    ].join('\n');
    const [simulation] = await state.loadstring(context, 'Phase2.spec', true)();
    console.log('PASS: StageResolver, placement geometry and membership, result deduplication, DDA invalid inputs');
    console.log(simulation);

    const server = source('src/ServerScriptService/TowerServer_server.luau');
    const section = (start, end) => {
        const first = server.indexOf(start);
        const last = server.indexOf(end, first);
        if (first === -1 || last === -1) throw new Error('Missing TowerServer test entry point');
        return server.slice(first, last);
    };
    const heroTest = [
        wrap('mock', 'tests/roblox-value-mocks.luau'),
        'local Vector3 = mock.Vector3',
        'local RaycastParams = {new = function() return {} end}',
        wrap('PlacementRules', 'src/ReplicatedStorage/Modules/PlacementRules.luau'),
        wrap('UnitLoadout', 'src/ReplicatedStorage/Modules/UnitLoadout.luau'),
        source('tests/HeroPlacement.spec.luau').replace('-- SERVER_HANDLERS', () =>
            section('local requestTimes = {}', '-- UPGRADE / SELL / TARGET MODE REMOTES') + '\n' +
            section('local function getUpgradeCost', 'RE_SetTargetMode.OnServerEvent:Connect')),
    ].join('\n');
    const [heroResult] = await state.loadstring(heroTest, 'HeroPlacement.spec', true)();
    console.log(heroResult);

    const loadoutTest = [
        wrap('UnitLoadout', 'src/ReplicatedStorage/Modules/UnitLoadout.luau'),
        'local slots = table.clone(UnitLoadout.starters)',
        'local owned = {IceHero = 1, CrimsonHero = 1}',
        'assert(not UnitLoadout.change(slots, owned, "Equip", "IceHero"))',
        'assert(UnitLoadout.change(slots, owned, "Unequip", "IceHero"))',
        'assert(table.concat(slots, "|") == "|CrimsonHero")',
        'assert(not UnitLoadout.change(slots, {CrimsonHero = 1}, "Equip", "IceHero"))',
        'assert(UnitLoadout.change(slots, owned, "Equip", "IceHero"))',
        'assert(#slots == 2 and UnitLoadout.contains(table.concat(slots, "|"), "IceHero"))',
        'assert(UnitLoadout.change(slots, owned, "UnequipAll"))',
        'assert(not UnitLoadout.hasUnits(table.concat(slots, "|")) and owned.IceHero == 1 and owned.CrimsonHero == 1)',
        'assert(not UnitLoadout.contains("||IceHero", "IceHero"))',
        'return "PASS: loadout ownership, duplicate prevention, slot retention, locked slots and Unequip All"',
    ].join('\n');
    const [loadoutResult] = await state.loadstring(loadoutTest, 'UnitLoadout.spec', true)();
    console.log(loadoutResult);

    const dashTest = source('tests/PlayerDash.spec.luau').replace('-- DASH_SERVER', () =>
        source('src/ServerScriptService/PlayerDash.server.luau'));
    const [dashResult] = await state.loadstring(dashTest, 'PlayerDash.spec', true)();
    console.log(dashResult);

    const original = JSON.parse(execFileSync(process.execPath,
        ['tools/inspect-place.mjs', 'TowerDefense_DoAn.rbxl', '--sources'], {encoding: 'utf8'}));
    for (const entry of original.scripts) state.loadstring(entry.source, entry.path, true);
    const paths = new Set(original.assets.map(entry => entry.path));
    for (const asset of ['Workspace/EnemySpawn', 'Workspace/EnemyBase', 'Workspace/Waypoints/WP1',
        'Workspace/Waypoints/WP8', 'Workspace/BattleSpawn', 'ReplicatedStorage/Towers/IceHero',
        'ReplicatedStorage/Towers/CrimsonHero', 'ReplicatedStorage/Enemies/Zombie', 'ReplicatedStorage/VFX']) {
        if (!paths.has(asset)) throw new Error('Missing original place asset: ' + asset);
    }
    console.log('RBXL sources compiled: ' + original.scripts.length + '; required asset paths found');
} finally {
    state.destroy();
}
