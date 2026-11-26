import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
import { isDeepStrictEqual } from 'node:util';

const prefix = '[DeckTelemetry]';
const outcomes = ['Victory', 'Defeat', 'Abandoned', 'Invalid'];
const shared = ['matchId', 'timestamp', 'buildVersion', 'worldId', 'actId', 'stageId', 'mode',
    'totalWaves', 'participantCount', 'baseHealth', 'maxBaseHealth', 'wave'];
const required = {
    match_start: ['roster'],
    wave_end: ['spawned', 'killed', 'escaped', 'removed', 'multiplier', 'nextMultiplier',
        'elapsed', 'complete', 'smoothedPerformanceScore'],
    participant_left: ['participantId'],
    match_end: ['outcome', 'duration'],
};

export function analyze(log, actId = 3, worldId = 'world_1') {
    const sessions = new Map();
    const diagnostics = [];
    const lines = log.split(/\r?\n/);
    for (const [index, line] of lines.entries()) {
        const marker = line.indexOf(prefix);
        if (marker === -1 && !line.trimStart().startsWith('{')) continue;
        const payload = (marker === -1 ? line : line.slice(marker + prefix.length)).trim();
        const report = (problem) => diagnostics.push({line: index + 1, problem});
        let row;
        try {
            row = JSON.parse(payload.slice(0, payload.lastIndexOf('}') + 1));
        } catch {
            report('invalid JSON');
            continue;
        }
        if (!row || !Object.hasOwn(required, row.event)) {
            report('unknown event');
            continue;
        }
        const missing = [...shared, ...required[row.event]].filter(key => row[key] == null);
        if (missing.length) {
            report('missing ' + missing.join(', '));
            continue;
        }
        if (row.worldId !== worldId || row.actId !== actId) continue;
        if (!['Fixed', 'DDA'].includes(row.mode) || row.stageId !== worldId + '.act_' + actId
            || typeof row.buildVersion !== 'string' || !row.buildVersion
            || typeof row.matchId !== 'string' || !row.matchId || !Number.isFinite(row.timestamp)
            || !Number.isInteger(row.wave) || row.wave < 0 || !Number.isInteger(row.totalWaves)
            || row.totalWaves < 1 || row.totalWaves > 999 || !Number.isInteger(row.participantCount)
            || row.participantCount < 0 || (actId === 3 && worldId === 'world_1' && row.totalWaves !== 15)
            || (row.event === 'match_end' && (!outcomes.includes(row.outcome)
                || !Number.isFinite(row.duration) || row.duration < 0))) {
            report('invalid stage, mode, build, or outcome');
            continue;
        }

        if (row.event === 'wave_end') {
            const counts = [row.spawned, row.killed, row.escaped, row.removed];
            if (row.wave < 1 || (row.totalWaves < 999 && row.wave > row.totalWaves)
                || !Number.isFinite(row.multiplier) || row.multiplier <= 0
                || !Number.isFinite(row.nextMultiplier) || row.nextMultiplier <= 0
                || counts.some(value => !Number.isInteger(value) || value < 0)
                || row.killed + row.escaped + row.removed > row.spawned
                || !Number.isFinite(row.elapsed) || row.elapsed < 0 || typeof row.complete !== 'boolean'
                || (row.complete && row.spawned !== row.killed + row.escaped + row.removed)) {
                report('invalid wave measurements');
                continue;
            }
        }

        let session = sessions.get(row.matchId);
        if (!session) {
            session = {events: new Map(), row, conflict: false};
            sessions.set(row.matchId, session);
        }
        const original = session.row;
        const signature = ['worldId', 'actId', 'stageId', 'mode', 'buildVersion', 'stageDifficulty', 'baseline', 'totalWaves'];
        if (signature.some(key => row[key] !== original[key])) {
            report('conflicting match metadata');
            session.conflict = true;
            continue;
        }
        const suffix = row.event === 'wave_end' ? row.wave : row.event === 'participant_left' ? row.participantId : '';
        const key = row.event + ':' + suffix;
        const previous = session.events.get(key);
        if (previous) {
            report('duplicate ' + key);
            if (!isDeepStrictEqual(previous, row)) session.conflict = true;
            continue;
        }
        session.events.set(key, row);
    }

    const groups = new Map();
    for (const [matchId, session] of sessions) {
        if (session.conflict) {
            diagnostics.push({matchId, problem: 'conflicting records'});
            continue;
        }
        const start = session.events.get('match_start:');
        const end = session.events.get('match_end:');
        if (!start || !end || !Array.isArray(start.roster)) {
            diagnostics.push({matchId, problem: 'missing match start, end, or roster'});
            continue;
        }
        const roster = new Set(start.roster.map(entry => entry?.participantId));
        if (roster.size !== start.roster.length || roster.size !== start.participantCount || !roster.size
            || [...roster].some(id => !Number.isInteger(id) || id < 1) || end.timestamp < start.timestamp) {
            diagnostics.push({matchId, problem: 'invalid roster or timestamps'});
            continue;
        }
        const departures = new Set();
        const completed = new Map();
        for (const event of session.events.values()) {
            if (event.timestamp < start.timestamp || event.timestamp > end.timestamp) continue;
            if (event.event === 'participant_left' && roster.has(event.participantId)) departures.add(event.participantId);
            if (event.event === 'wave_end' && event.complete === true && event.wave <= end.wave) {
                completed.set(event.wave, event.multiplier);
            }
        }
        if (end.outcome === 'Victory' && (end.wave !== start.totalWaves
            || !Array.from({length: start.totalWaves}, (_, index) => index + 1).every(index => completed.has(index)))) {
            diagnostics.push({matchId, problem: 'Victory missing completed waves'});
            continue;
        }
        const priorWaves = Math.max(0, end.wave - 1);
        if (end.outcome !== 'Invalid' && (completed.size < priorWaves
            || Array.from({length: priorWaves}, (_, index) => index + 1).some(index => !completed.has(index)))) {
            diagnostics.push({matchId, problem: 'missing earlier completed waves'});
            continue;
        }
        const key = JSON.stringify([start.buildVersion, start.mode, start.stageDifficulty ?? 'Unspecified', start.baseline ?? 'Unspecified']);
        if (!groups.has(key)) {
            groups.set(key, {
                buildVersion: start.buildVersion, worldId, actId, stageId: start.stageId, mode: start.mode,
                stageDifficulty: start.stageDifficulty ?? 'Unspecified', baseline: start.baseline ?? 'Unspecified',
                Victory: 0, Defeat: 0, Abandoned: 0, Invalid: 0, valid: 0,
                participantSessions: 0, departures: 0, totalDuration: 0, completedWaveSamples: 0, totalAppliedMultiplier: 0,
            });
        }
        const group = groups.get(key);
        group[end.outcome]++;
        if (end.outcome === 'Invalid') continue;
        group.valid++;
        group.participantSessions += roster.size;
        group.departures += departures.size;
        group.totalDuration += end.duration;
        group.completedWaveSamples += completed.size;
        for (const multiplier of completed.values()) group.totalAppliedMultiplier += multiplier;
    }
    const rows = [...groups.values()].map(({totalDuration, totalAppliedMultiplier, ...group}) => ({
        ...group,
        winRatePercent: group.valid ? 100 * group.Victory / group.valid : null,
        leaveRatePercent: group.participantSessions ? 100 * group.departures / group.participantSessions : null,
        averageMatchSeconds: group.valid ? totalDuration / group.valid : null,
        averageCompletedWaves: group.valid ? group.completedWaveSamples / group.valid : null,
        averageAppliedMultiplier: group.completedWaveSamples ? totalAppliedMultiplier / group.completedWaveSamples : null,
    }));
    return {rows, diagnostics};
}

export function csv(rows) {
    const columns = ['buildVersion','worldId','actId','stageId','mode','stageDifficulty','baseline',
        'Victory','Defeat','Abandoned','Invalid','valid','participantSessions','departures',
        'winRatePercent','leaveRatePercent','averageMatchSeconds','completedWaveSamples',
        'averageCompletedWaves','averageAppliedMultiplier'];
    const encode = value => {
        if (value == null) return '';
        const text = String(value);
        const guarded = typeof value === 'string' && /^[=+@\t\r-]/.test(text) ? "'" + text : text;
        return '"' + guarded.replaceAll('"', '""') + '"';
    };
    return [columns.join(','), ...rows.map(row => columns.map(key => encode(row[key])).join(','))].join('\r\n') + '\r\n';
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
    const [, , input, output, act = '3', world = 'world_1'] = process.argv;
    if (!input || !output || !/^\d+$/.test(act)) {
        console.error('Usage: node tools/analyze-telemetry.mjs input.log output.csv [actId] [worldId]');
        process.exitCode = 1;
    } else {
        const {rows, diagnostics} = analyze(fs.readFileSync(input, 'utf8'), Number(act), world);
        fs.writeFileSync(output, '\uFEFF' + csv(rows));
        console.log(JSON.stringify({rows, diagnostics}, null, 2));
    }
}
