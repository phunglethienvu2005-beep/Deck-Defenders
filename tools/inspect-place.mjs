import fs from 'node:fs';
import { zstdDecompressSync } from 'node:zlib';
import { createHash } from 'node:crypto';

const file = process.argv[2] ?? 'TowerDefense_DoAn.rbxl';
const bytes = fs.readFileSync(file);
if (bytes.toString('ascii', 0, 8) !== '<roblox!') throw new Error('Expected a binary Roblox place');

function readString(buffer, start) {
    const end = start + 4 + buffer.readUInt32LE(start);
    if (end > buffer.length) throw new Error('Truncated string');
    return [buffer.toString('utf8', start + 4, end), end];
}

function references(buffer, offset, count, cumulative = true) {
    const result = [];
    let previous = 0;
    for (let index = 0; index < count; index++) {
        let value = 0;
        for (let lane = 0; lane < 4; lane++) value = value * 256 + buffer.readUInt8(offset + lane * count + index);
        const signed = (value >>> 1) ^ -(value & 1);
        previous = cumulative ? previous + signed : signed;
        result.push(previous);
    }
    return result;
}

const classes = new Map();
const objects = new Map();
const pendingProperties = [];
const parents = new Map();
for (let offset = 32; offset + 16 <= bytes.length;) {
    const tag = bytes.toString('ascii', offset, offset + 4);
    const size = bytes.readUInt32LE(offset + 4);
    const raw = bytes.readUInt32LE(offset + 8);
    const begin = offset + 16;
    offset = begin + (size || raw);
    if (offset > bytes.length) throw new Error('Truncated chunk');
    if (tag === 'END\0') break;
    if (!['INST', 'PROP', 'PRNT'].includes(tag)) continue;
    const data = size ? zstdDecompressSync(bytes.subarray(begin, offset)) : bytes.subarray(begin, offset);
    if (data.length !== raw) throw new Error('Unexpected decompressed length');
    if (tag === 'INST') {
        const id = data.readUInt32LE(0);
        const [className, end] = readString(data, 4);
        const count = data.readUInt32LE(end + 1);
        const members = references(data, end + 5, count);
        classes.set(id, members);
        for (const member of members) objects.set(member, {className});
    } else if (tag === 'PROP') {
        const [property, end] = readString(data, 4);
        if (['Name', 'Source', 'Disabled', 'AnimationId', 'AnimationContent'].includes(property)) {
            pendingProperties.push({id: data.readUInt32LE(0), property, end, data});
        }
    } else if (tag === 'PRNT') {
        const count = data.readUInt32LE(1);
        const children = references(data, 5, count);
        const ancestor = references(data, 5 + 4 * count, count);
        children.forEach((id, index) => parents.set(id, ancestor[index]));
    }
}

for (const {id, property, end, data} of pendingProperties) {
    let position = end + 1;
    const members = classes.get(id);
    if (property === 'AnimationContent') {
        if (data.readUInt8(end) !== 0x22) throw new Error('Unsupported AnimationContent type');
        const kinds = references(data, position, members.length, false);
        position += 4 * members.length;
        const uriCount = data.readUInt32LE(position);
        position += 4;
        const uris = [];
        for (let index = 0; index < uriCount; index++) {
            const [uri, next] = readString(data, position);
            uris.push(uri);
            position = next;
        }
        let nextUri = 0;
        for (const [index, member] of members.entries()) {
            if (kinds[index] === 1) objects.get(member).animationContent = uris[nextUri++];
        }
        if (nextUri !== uris.length) throw new Error('AnimationContent URI count mismatch');
        continue;
    }
    for (const member of members) {
        const object = objects.get(member);
        if (property === 'Disabled') {
            object.disabled = Boolean(data.readUInt8(position++));
        } else {
            const [value, next] = readString(data, position);
            const field = {Name: 'name', Source: 'source', AnimationId: 'animationId'}[property];
            object[field] = value;
            position = next;
        }
    }
}

function instancePath(id) {
    const names = [];
    const visited = new Set();
    while (objects.has(id) && !visited.has(id)) {
        visited.add(id);
        const object = objects.get(id);
        names.unshift(object.name || object.className);
        id = parents.get(id);
    }
    return names.join('/');
}

const scripts = [];
const assets = [];
const remotes = [];
const animations = [];
const animationJoints = [];
const watched = new Set(['Waypoints', 'EnemyBase', 'EnemySpawn', 'BattleSpawn', 'Map', 'Towers',
    'Enemies', 'IceHero', 'CrimsonHero', 'Zombie', 'VFX', 'GameUI', 'BattleStartGui', 'The Void', 'MainLobby', 'LobbyGui', 'HumanoidRootPart', 'Modules', 'Remotes', 'StarterPlayerScripts', 'AnimePlayMenuUI', 'LobbyUI']);
for (const [id, object] of objects) {
    const path = instancePath(id);
    const {className, name} = object;
    if (['Script', 'LocalScript', 'ModuleScript'].includes(className)) {
        const source = (object.source ?? '').replaceAll('\r\n', '\n').trim();
        const entry = {path, className, enabled: className === 'ModuleScript' ? null : !object.disabled,
            sourceHash: createHash('sha256').update(source).digest('hex')};
        if (process.argv.includes('--sources')) entry.source = source;
        scripts.push(entry);
    }
    if (watched.has(name) || path.startsWith('Workspace/Waypoints/')) assets.push({path, className});
    if (className === 'RemoteEvent' || className === 'RemoteFunction') remotes.push({path, className});
    if (className === 'Animation') animations.push({path, animationId: object.animationContent ?? object.animationId ?? null});
    if (className === 'Motor6D' && path.startsWith('Workspace/CrimsonHero/')) animationJoints.push(path);
}
console.log(JSON.stringify({scripts, assets, remotes, animations, animationJoints}, null, 2));
