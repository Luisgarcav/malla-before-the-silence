import { readFile } from 'node:fs/promises';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { createOdinEngine } from './engine';
import { createBeaconDossier } from './beacon';
import { createFlowDossier } from './flow';
import { createRouteDossier } from './route';
import type { GameSnapshot } from './types';

const originalFetch = globalThis.fetch;

beforeAll(async () => {
	const wasm = await readFile(new URL('../../../static/game.wasm', import.meta.url));
	vi.stubGlobal(
		'fetch',
		vi.fn(async () => new Response(new Uint8Array(wasm), { status: 200 }))
	);
});

afterAll(() => {
	vi.stubGlobal('fetch', originalFetch);
});

describe('Odin WebAssembly bridge', () => {
	it('runs the complete EMR06 vertical through the authoritative engine', async () => {
		const snapshots: GameSnapshot[] = [];
		const engine = await createOdinEngine('/game.wasm', 1999n, (state) => snapshots.push(state));

		expect(snapshots.at(-1)).toMatchObject({
			stage: 'evacuation',
			nextCommand: 'move workshop',
			seed: '1999'
		});

		engine.dispatch('move workshop');
		engine.dispatch('connect controller');
		engine.dispatch('inspect emr06');
		engine.dispatch('evidence capture');

		const capture = snapshots.at(-1);
		expect(capture).toMatchObject({ stage: 'packet_ready', event: 'evidence_capture' });
		expect(capture?.detail).toContain('ERASURE');

		engine.dispatch('hint 5');
		const solution = snapshots.at(-1)?.detail.match(/repair emr06 ([0-9A-F]{64})/)?.[1];
		expect(solution).toMatch(/^[0-9A-F]{64}$/);

		engine.dispatch(`repair emr06 ${solution}`);
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'prototype_complete',
			event: 'repair_valid',
			signalReviewed: false,
			nextCommand: 'messages'
		});

		engine.dispatch('messages');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'prototype_complete',
			event: 'messages_recovered',
			signalReviewed: true,
			nextCommand: 'continue'
		});

		engine.dispatch('continue');
		const routeState = snapshots.at(-1);
		expect(routeState).toMatchObject({
			stage: 'route_ready',
			event: 'act_two_begin',
			connection: 'DISCONNECTED',
			nextCommand: 'route ellie'
		});

		const route = createRouteDossier(routeState?.evidence ?? '');
		expect(route.ready).toBe(true);
		expect(route.edges).toHaveLength(18);
		engine.dispatch('hint 5');
		const optimalPath = snapshots.at(-1)?.detail.match(/route ellie ([A-Z>]+)/)?.[1];
		expect(optimalPath).toMatch(/^WORKSHOP>.+>INTERCHANGE$/);
		engine.dispatch(`route ellie ${optimalPath}`);

		expect(snapshots.at(-1)?.stage).toBe('route_in_transit');
		expect(snapshots.at(-1)?.event).toBe('route_optimal');

		const traversedEvents: string[] = [];
		while (snapshots.at(-1)?.stage === 'route_in_transit') {
			engine.dispatch('advance');
			traversedEvents.push(snapshots.at(-1)?.event ?? '');
		}
		expect(traversedEvents.length).toBeGreaterThanOrEqual(2);
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'at_interchange',
			location: 'TRANSIT INTERCHANGE',
			connection: 'DISCONNECTED',
			event: 'route_arrival',
			nextCommand: 'scan'
		});

		engine.dispatch('connect trn04');
		expect(snapshots.at(-1)?.event).toBe('connect_transit_need_scan');
		engine.dispatch('scan');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'interchange_scanned',
			event: 'scan_interchange',
			nextCommand: 'connect trn04'
		});
		engine.dispatch('connect trn04');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'transit_connected',
			event: 'connect_transit_success',
			connection: 'TRN04 / LOCAL NODE',
			nextCommand: 'inspect trn04'
		});
		engine.dispatch('inspect trn04');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'act_two_complete',
			event: 'transit_intel_recovered',
			objective: 'Leave TRN04 and move to the Service Corridor',
			nextCommand: 'continue'
		});

		engine.dispatch('continue');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'act_three_travel',
			event: 'act_three_begin',
			connection: 'DISCONNECTED',
			nextCommand: 'advance'
		});

		engine.dispatch('advance');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'at_service_corridor',
			event: 'service_corridor_arrival',
			location: 'SERVICE CORRIDOR',
			nextCommand: 'scan'
		});

		engine.dispatch('connect gwt08');
		expect(snapshots.at(-1)?.event).toBe('connect_corridor_need_scan');
		engine.dispatch('scan');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'corridor_scanned',
			event: 'scan_corridor',
			nextCommand: 'connect gwt08'
		});
		engine.dispatch('connect gwt08');

		const flowState = snapshots.at(-1);
		expect(flowState).toMatchObject({
			stage: 'flow_ready',
			event: 'connect_corridor_success',
			connection: 'GWT08 / LOCAL GATEWAY',
			nextCommand: 'allocate rep06'
		});
		const flow = createFlowDossier(flowState?.evidence ?? '');
		expect(flow.ready).toBe(true);
		expect(flow.nodeCount).toBe(6);
		expect(flow.edgeCount).toBe(12);
		expect(flow.links.length).toBe(flow.edgeCount);
		expect(flow.links.every((link) => link.physical === link.protected + link.residual)).toBe(true);
		expect(flow.links.every((link) => link.residual === link.headroom + link.plannable)).toBe(true);
		expect(flow.links.some((link) => !['S', 'T'].includes(link.from) && link.to !== 'T')).toBe(
			true
		);

		engine.dispatch('hint 5');
		const allocation = snapshots.at(-1)?.detail.match(/allocate rep06 (P:[^\n]+;B:[^\n]+)/)?.[1];
		expect(allocation).toMatch(/^P:.+;B:.+/);
		engine.dispatch(`allocate rep06 ${allocation}`);
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'act_three_complete',
			event: 'flow_optimal',
			objective: 'Begin the final movement toward REP06',
			nextCommand: 'continue'
		});
		expect(snapshots.at(-1)?.detail).toContain('REP06 SURVIVABLE CHANNEL OPEN');
		expect(createFlowDossier(snapshots.at(-1)?.evidence ?? '').ready).toBe(true);

		engine.dispatch('continue');
		const carrierState = snapshots.at(-1);
		expect(carrierState).toMatchObject({
			stage: 'carrier_ready',
			event: 'act_four_begin',
			connection: 'GWT08 / LOCAL GATEWAY',
			nextCommand: 'tune rep06'
		});
		const beacon = createBeaconDossier(carrierState?.evidence ?? '');
		expect(beacon.ready).toBe(true);
		expect(beacon.echoes).toHaveLength(9);
		expect(beacon.echoes.every((echo) => /^[0-9A-F]{32}$/.test(echo.frame))).toBe(true);
		expect(beacon.echoes.map((echo) => echo.rssi)).toEqual(
			[...beacon.echoes.map((echo) => echo.rssi)].sort((left, right) => right - left)
		);

		engine.dispatch('hint 5');
		const tune = snapshots.at(-1)?.detail.match(/tune rep06 (\d+ -?\d+ \d+ [0-9A-F]{4})/)?.[1];
		expect(tune).toMatch(/^\d+ -?\d+ \d+ [0-9A-F]{4}$/);
		engine.dispatch(`tune rep06 ${tune}`);
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'carrier_locked',
			event: 'tune_valid',
			objective: 'Begin Act V: HUSH; the channel is open and nobody answers',
			nextCommand: 'continue'
		});

		engine.dispatch('continue');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'hush_departure',
			event: 'hush_begin',
			connection: 'DISCONNECTED',
			nextCommand: 'advance',
			evidence: ''
		});
		expect(snapshots.at(-1)?.detail).toContain('ACT V // HUSH');
		engine.dispatch('advance');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'hush_streets',
			event: 'hush_streets',
			location: 'CURFEW STREETS'
		});
		engine.dispatch('advance');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'hush_loudspeakers',
			event: 'hush_loudspeakers',
			location: 'CIVIC AVENUE',
			evidence: ''
		});
		engine.dispatch('advance');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'hush_dead_zone',
			event: 'hush_dead_zone',
			location: 'MESH BOUNDARY',
			connection: 'DISCONNECTED',
			evidence: ''
		});
		engine.dispatch('advance');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'hush_approach',
			event: 'hush_transmitter',
			location: 'REPEATER 06 APPROACH'
		});
		engine.dispatch('advance');
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'encounter',
			event: 'reunion',
			location: 'REPEATER 06',
			objective: 'Reunited',
			nextCommand: ''
		});

		engine.destroy();
	});

	it('restarts a failed act from its deterministic checkpoint', async () => {
		const snapshots: GameSnapshot[] = [];
		const engine = await createOdinEngine('/game.wasm', 4242n, (state) => snapshots.push(state));

		engine.dispatch('move workshop');
		engine.dispatch('connect controller');
		engine.dispatch('inspect emr06');
		engine.dispatch('hint 5');
		const solution = snapshots.at(-1)?.detail.match(/repair emr06 ([0-9A-F]{64})/)?.[1];
		expect(solution).toMatch(/^[0-9A-F]{64}$/);
		engine.dispatch(`repair emr06 ${solution}`);
		engine.dispatch('messages');
		engine.dispatch('continue');

		const checkpoint = snapshots.at(-1);
		expect(checkpoint).toMatchObject({
			seed: '4242',
			stage: 'route_ready',
			event: 'act_two_begin',
			running: true
		});
		const checkpointEvidence = checkpoint?.evidence;
		for (let cost = 0; cost < (checkpoint?.window ?? 0); cost += 1) {
			engine.dispatch('wait');
		}
		expect(snapshots.at(-1)).toMatchObject({
			stage: 'route_ready',
			event: 'failure',
			running: false,
			window: 0,
			nextCommand: 'restart act'
		});

		engine.dispatch('restart act');
		expect(snapshots.at(-1)).toMatchObject({
			seed: '4242',
			stage: 'route_ready',
			event: 'act_two_begin',
			running: true,
			window: checkpoint?.window,
			exposure: checkpoint?.exposure
		});
		expect(snapshots.at(-1)?.evidence).toBe(checkpointEvidence);

		engine.destroy();
	});
});
