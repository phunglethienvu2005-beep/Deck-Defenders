import test from 'node:test';
import assert from 'node:assert/strict';
import { analyze, csv } from '../tools/analyze-telemetry.mjs';

const record = (id, event, fields = {}) => ({
    matchId: id, event, timestamp: 100, wave: 1, buildVersion: 'test-only', worldId: 'world_1',
    actId: 3, stageId: 'world_1.act_3', totalWaves: 15, mode: 'Fixed', participantCount: 2,
    baseHealth: 20, maxBaseHealth: 20, ...fields,
});
const start = (id, fields) => record(id, 'match_start', {wave: 0,
    roster: [{participantId: 1},{participantId: 2}], ...fields});
const wave = (id, number) => record(id, 'wave_end', {
    wave: number, spawned: 10, killed: 10, escaped: 0, removed: 0, multiplier: 1,
    nextMultiplier: 1, elapsed: 10, smoothedPerformanceScore: 0.75, complete: true,
});
const end = (id, outcome, fields) => record(id, 'match_end', {outcome, duration: 60, ...fields});
const log = (...rows) => rows.map(row => '  [DeckTelemetry] ' + JSON.stringify(row) + ' - Server').join('\n');

test('deduplicates the same JSON record with reordered fields but rejects conflicting records', () => {
    const finish = end('same', 'Defeat');
    const reordered = Object.fromEntries(Object.entries(finish).reverse());
    const {rows, diagnostics} = analyze(log(start('same'), finish, reordered,
        start('conflict'), end('conflict', 'Defeat'), end('conflict', 'Defeat', {duration: 61})));
    assert.equal(rows[0]?.valid, 1);
    assert.equal(rows[0]?.Defeat, 1);
    assert.deepEqual(diagnostics.filter(item => item.matchId).map(item => item.matchId), ['conflict']);
});

test('aggregates all outcomes, deduplicates departures and separates control and DDA', () => {
    const left = record('abandoned', 'participant_left', {participantId: 1});
    const data = log(start('win'), ...Array.from({length: 15}, (_, i) => wave('win', i + 1)),
        end('win', 'Victory', {wave: 15}),
        start('loss'), end('loss', 'Defeat'),
        start('abandoned'), left, left, end('abandoned', 'Abandoned'),
        start('invalid'), end('invalid', 'Invalid'),
        start('dda', {mode: 'DDA'}), end('dda', 'Defeat', {mode: 'DDA', duration: 120}));
    const {rows, diagnostics} = analyze(data);
    assert.equal(rows.length, 2);
    const [fixed, dda] = rows;
    assert.equal(fixed.Victory, 1);
    assert.equal(fixed.Defeat, 1);
    assert.equal(fixed.Abandoned, 1);
    assert.equal(fixed.Invalid, 1);
    assert.equal(fixed.valid, 3);
    assert.equal(fixed.winRatePercent, 100 / 3);
    assert.equal(fixed.leaveRatePercent, 100 / 6);
    assert.equal(fixed.averageMatchSeconds, 60);
    assert.equal(fixed.completedWaveSamples, 15);
    assert.equal(fixed.averageCompletedWaves, 5);
    assert.equal(fixed.averageAppliedMultiplier, 1);
    assert.equal(dda.averageMatchSeconds, 120);
    assert.equal(dda.averageCompletedWaves, 0);
    assert.equal(dda.averageAppliedMultiplier, null);
    assert.match(diagnostics[0].problem, /duplicate/);
    assert.match(csv(rows), /"Fixed"/);
    assert.match(csv(rows), /averageCompletedWaves,averageAppliedMultiplier/);
});

test('averages applied multipliers over completed waves and excludes interrupted waves and missing history', () => {
    const dda = {mode: 'DDA'};
    const first = {...wave('valid', 1), ...dda, multiplier: 1, nextMultiplier: 1.05};
    const second = {...wave('valid', 2), ...dda, multiplier: 1.05, nextMultiplier: 1.1};
    const interrupted = {...wave('valid', 3), ...dda, multiplier: 1.1, nextMultiplier: 1.1, complete: false};
    const data = log(start('valid', dda), first, second, interrupted, end('valid', 'Abandoned', {...dda, wave: 3}),
        start('lost', dda), {...wave('lost', 2), ...dda}, end('lost', 'Defeat', {...dda, wave: 2}));
    const {rows, diagnostics} = analyze(data);
    assert.equal(rows[0].valid, 1);
    assert.equal(rows[0].averageCompletedWaves, 2);
    assert.equal(rows[0].averageAppliedMultiplier, 1.025);
    assert.deepEqual(diagnostics, [{matchId: 'lost', problem: 'missing earlier completed waves'}]);
});

test('omits other acts, flags incomplete sessions and excludes false victories', () => {
    const data = log(start('act1', {actId: 1, stageId: 'world_1.act_1'}),
        end('incomplete', 'Defeat'), start('short'), end('short', 'Victory', {wave: 15}),
        {event: 'match_end'});
    const {rows, diagnostics} = analyze(data + '\n[DeckTelemetry] {broken');
    assert.deepEqual(rows, []);
    assert.equal(diagnostics.length, 4);
});
