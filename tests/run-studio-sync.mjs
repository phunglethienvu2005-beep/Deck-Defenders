import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {pathToFileURL} from 'node:url';
import {execFileSync} from 'node:child_process';
import {fingerprint, quoteLuau, renderBundle} from '../tools/generate-studio-sync.mjs';

if (!process.argv[2] || !process.argv[3]) throw new Error('Pass the paths to luau-web/src/index.js and native luau CLI');
const {LuauState} = await import(pathToFileURL(path.resolve(process.argv[2])));
const state = await LuauState.createAsync();
const read = name => fs.readFileSync(name, 'utf8');
try {
    execFileSync(process.execPath, ['tools/generate-studio-sync.mjs'], {stdio: 'inherit'});
    for (const file of fs.readdirSync('tools/generated').filter(name => name.startsWith('studio-') && name.endsWith('.luau'))) {
        state.loadstring(read('tools/generated/' + file), file, true);
    }
    console.log('PASS: compile generated Studio tools including one-click');

    const bundle = {
        id: 'test-bundle', buildVersion: 'hero-limits-v2', assets: [], runtimeEvents: [], runtimeFunctions: [],
        oneClickFromBuildVersion: 'hero-limits-v2',
        blockedPlacementWriters: ['ServerScriptService/TowerCombat'],
        legacy: {path: 'StarterGui/LobbyGui/LobbyController', baseline: fingerprint('return GameOver, GameWin')},
        preserve: {path: 'ReplicatedStorage/Modules/WaveData', baseline: fingerprint('return originalWaves')},
        entries: [
            {path: 'ServerScriptService/GameManager', className: 'Script',
                baseline: fingerprint('return oldManager'), source: 'return "nhân vật ]==] \\ "'},
            {path: 'ServerScriptService/StageResolver', className: 'ModuleScript', create: true,
                previousSources: [fingerprint('return olderStage'), fingerprint('return oldStage')],
                rcSeedSource: fingerprint('return oldStage'), rcUpdateSource: fingerprint('return olderStage'),
                source: 'return "stage"'},
            {path: 'ServerScriptService/PlayerDash', className: 'Script', create: true, source: 'return "dash server"'},
            {path: 'StarterPlayer/StarterPlayerScripts/PlayerDash', className: 'LocalScript', create: true,
                source: 'return "dash client"'},
            {path: 'StarterGui/LobbyUI/LobbyController', className: 'LocalScript',
                baseline: fingerprint('return oldLobby'), source: 'return "lobby"'},
        ],
    };
    const engine = read('tools/studio-sync-engine.luau');
    const mode = (name, action) => 'local function ' + name + '()\n' + renderBundle(bundle, engine, action) + '\nend';
    const chunk = [
        'local mock = (function()\n' + read('tests/studio-sync-mocks.luau') + '\nend)()',
        'local game, Instance, _G = mock.game, mock.Instance, {}',
        mode('dry', 'dry-run'), mode('apply', 'apply'), mode('verify', 'verify'), mode('rollback', 'rollback'),
        mode('oneClick', 'one-click'),
        'local expected = ' + quoteLuau(bundle.entries[0].source),
        `
assert(not pcall(apply))
mock.setRunning(true)
assert(not pcall(dry))
mock.setRunning(false)
game:SetAttribute("DeckSyncCopy", false)
assert(not pcall(dry))
game:SetAttribute("DeckSyncCopy", true)
local legacyWriter = mock.add("ServerScriptService/TowerCombat", "Script")
local legacyOk, legacyError = pcall(dry)
assert(not legacyOk and tostring(legacyError):find("Conflicting legacy placement writer", 1, true))
legacyWriter.Disabled = true
dry()
legacyWriter:Destroy()
local duplicate = mock.add("StarterGui/LobbyUI/LobbyController", "LocalScript")
assert(not pcall(dry))
duplicate:Destroy()
dry()
assert(mock.manager.Source == "return oldManager" and mock.moduleCount() == 0 and not mock.legacy.Disabled)
mock.manager.Source = "return draft"
assert(not pcall(apply))
assert(mock.manager.Source == "return draft")
mock.manager.Source = "return oldManager"
dry()
mock.fail("LobbyController")
local ok, message = pcall(apply)
assert(not ok and tostring(message):find("automatic rollback succeeded", 1, true))
assert(mock.manager.Source == "return oldManager" and mock.moduleCount() == 0)
mock.fail(nil)
dry()
apply()
verify()
assert(mock.manager.Source == expected and mock.moduleCount() == 1 and mock.legacy.Disabled)
assert(not mock.lobby.Disabled and mock.manager:GetAttribute("EnableDDA") == false)
dry()
apply()
assert(mock.moduleCount() == 1)
rollback()
assert(mock.manager.Source == "return oldManager" and mock.moduleCount() == 0 and not mock.legacy.Disabled)
assert(mock.manager:GetAttribute("BuildVersion") == nil)
local existing = mock.add("ServerScriptService/StageResolver", "ModuleScript", "return oldStage")
mock.manager:SetAttribute("BuildVersion", "hero-limits-v2")
mock.manager:SetAttribute("EnableDDA", true)
dry()
apply()
verify()
assert(mock.moduleCount() == 1 and existing.Source == 'return "stage"')
assert(mock.manager:GetAttribute("BuildVersion") == "hero-limits-v2")
assert(mock.manager:GetAttribute("EnableDDA") == true)
rollback()
assert(mock.moduleCount() == 1 and existing.Source == "return oldStage")
assert(mock.manager:GetAttribute("BuildVersion") == "hero-limits-v2")
print("PASS: copy and edit gates, dry run, duplicate and draft detection, rollback on failure, verify, repeat and explicit rollback")

game:SetAttribute("DeckSyncCopy", nil)
game.PlaceId = 123
assert(not pcall(oneClick) and existing.Source == "return oldStage")
game.PlaceId = 0
mock.manager:SetAttribute("BuildVersion", "sync-7a71189a55df")
assert(not pcall(oneClick) and existing.Source == "return oldStage")
mock.manager:SetAttribute("BuildVersion", "hero-limits-v2")
existing.Source = "return unapprovedStage"
assert(not pcall(oneClick) and mock.manager.Source == "return oldManager")
existing.Source = "return oldStage"
mock.lobby.EditorSource = 'return "lobby"'
assert(not pcall(oneClick) and existing.Source == "return oldStage")
mock.lobby.EditorSource = nil
mock.fail("LobbyController")
local applied, failure = pcall(oneClick)
assert(not applied and tostring(failure):find("automatic rollback succeeded", 1, true))
assert(existing.Source == "return oldStage" and mock.manager.Source == "return oldManager")
assert(not mock.starterScripts:FindFirstChildOfClass("LocalScript"))
assert(mock.manager:GetAttribute("BuildVersion") == "hero-limits-v2")
mock.fail(nil)
oneClick()
assert(existing.Source == 'return "stage"' and mock.manager.Source == expected)
assert(mock.starterScripts:FindFirstChildOfClass("LocalScript").Source == 'return "dash client"')
local dashServerCount = 0
for _, instance in ipairs(mock.serverScripts:GetChildren()) do
    if instance.Name == "PlayerDash" and instance.ClassName == "Script" and instance.Source == 'return "dash server"' then
        dashServerCount += 1
    end
end
assert(dashServerCount == 1)
assert(mock.manager:GetAttribute("BuildVersion") == "hero-limits-v2")
oneClick()
-- A separately opened, saved v2 RC has no rollback journal from the previous session.
_G = {}
existing.Source = "return olderStage"
oneClick()
assert(mock.moduleCount() == 1 and existing.Source == 'return "stage"')
oneClick()
print("PASS: one-click rejects published, original, unapproved RC Source and stale editor text; rollback, exact verification and repeat")
`,
    ].join('\n');
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'deck-sync-test-'));
    const filename = path.join(directory, 'studio-sync-mock.luau');
    try {
        fs.writeFileSync(filename, chunk);
        execFileSync(path.resolve(process.argv[3]), [filename], {stdio: 'inherit'});
    } finally {
        fs.unlinkSync(filename);
        fs.rmdirSync(directory);
    }
} finally {
    state.destroy();
}
