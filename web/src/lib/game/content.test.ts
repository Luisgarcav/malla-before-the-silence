import { describe, expect, it } from 'vitest';
import {
	actionsFor,
	appendStoryBeat,
	hudObjectiveFor,
	openingBeat,
	panelActionsFor,
	restartBeatsFor,
	storyBeatFor
} from './content';
import type { GameSnapshot } from './types';

const snapshot = (overrides: Partial<GameSnapshot> = {}): GameSnapshot => ({
	seed: '1999',
	window: 6,
	running: true,
	captureViewed: false,
	signalReviewed: false,
	location: 'OPERATIONS ANNEX',
	connection: 'DISCONNECTED',
	stage: 'evacuation',
	exposure: 'ANONYMOUS',
	event: 'none',
	objective: 'Evacuate the annex',
	nextCommand: 'move workshop',
	detail: '',
	evidence: '',
	raw: false,
	...overrides
});

describe('game content', () => {
	it('keeps the opening and recovered signal as authored story beats', () => {
		expect(openingBeat.lines.some((line) => line.text.includes('Are you still angry?'))).toBe(true);
		expect(
			storyBeatFor('messages_recovered')?.lines.some((line) => line.text.includes('REP06'))
		).toBe(true);
	});

	it('reads the recovered signal before opening act two', () => {
		const completed = snapshot({ stage: 'prototype_complete', event: 'repair_valid' });
		const reviewed = snapshot({
			stage: 'prototype_complete',
			event: 'messages_recovered',
			signalReviewed: true
		});

		expect(panelActionsFor(completed)[0]).toMatchObject({
			label: 'READ SIGNAL',
			command: 'messages'
		});
		expect(panelActionsFor(reviewed)[0]).toMatchObject({
			label: 'BEGIN ACT II',
			command: 'continue'
		});
		expect(hudObjectiveFor(reviewed).title).toBe('The city closes.');
	});

	it('keeps story beats in chronological order without duplicates', () => {
		let history = [openingBeat];
		history = appendStoryBeat(history, 'move_workshop');
		history = appendStoryBeat(history, 'connect_success');
		history = appendStoryBeat(history, 'move_workshop');
		history = appendStoryBeat(history, 'status');

		expect(history.map((beat) => beat.id)).toEqual(['opening', 'workshop', 'controller']);
	});

	it('offers an act restart after failure and rebuilds that act opening', () => {
		const failed = snapshot({ running: false, stage: 'route_ready', event: 'failure' });
		const restarted = snapshot({ stage: 'route_ready', event: 'act_two_begin' });

		expect(panelActionsFor(failed)[0]).toMatchObject({
			label: 'RESTART ACT',
			command: '__restart_act__'
		});
		expect(restartBeatsFor(restarted).map((beat) => beat.id)).toEqual(['city_closes']);
		expect(restartBeatsFor(snapshot()).map((beat) => beat.id)).toEqual(['opening']);
		expect(panelActionsFor(snapshot({ stage: 'encounter' }))[0]?.command).toBe('__reset__');
	});

	it('derives only actions that are legal for the current engine stage', () => {
		expect(actionsFor(snapshot()).map((action) => action.command)).toEqual(['move workshop']);
		expect(
			actionsFor(snapshot({ stage: 'at_workshop', location: 'AUTOMATED WORKSHOP' })).map(
				(action) => action.command
			)
		).toContain('connect controller');
		expect(actionsFor(snapshot({ stage: 'prototype_complete' }))[0]?.command).toBe('messages');
		expect(
			actionsFor(snapshot({ stage: 'prototype_complete', signalReviewed: true }))[0]
		).toMatchObject({
			command: 'continue'
		});
	});

	it('explains the route challenge and preserves every act two scene', () => {
		const route = snapshot({ stage: 'route_ready', event: 'act_two_begin' });
		const crossing = snapshot({
			stage: 'route_in_transit',
			objective: 'Cross the next segment toward MARKET'
		});

		expect(hudObjectiveFor(route).title).toBe('Find a robust route.');
		expect(panelActionsFor(route)[0]?.command).toBe('hint 1');
		expect(hudObjectiveFor(crossing).title).toContain('MARKET');
		expect(storyBeatFor('act_two_begin')?.title).toBe('THE CITY CLOSES');
		expect(storyBeatFor('route_optimal')?.id).toBe('route_locked');
		expect(storyBeatFor('route_market')?.place).toContain('MARKET');
		expect(storyBeatFor('route_arrival')?.place).toContain('INTERCHANGE');
		expect(storyBeatFor('transit_intel_recovered')?.lines.at(-1)?.text).toContain('END OF ACT II');
		expect(actionsFor(crossing)[0]?.command).toBe('advance');
		expect(actionsFor(snapshot({ stage: 'at_interchange' }))[0]?.command).toBe('scan');
		expect(actionsFor(snapshot({ stage: 'interchange_scanned' }))[0]?.command).toBe(
			'connect trn04'
		);
		expect(actionsFor(snapshot({ stage: 'transit_connected' }))[0]?.command).toBe('inspect trn04');
		expect(actionsFor(snapshot({ stage: 'act_two_complete' }))[0]?.command).toBe('continue');
	});

	it('carries act three from the service corridor through the REP06 channel', () => {
		const travel = snapshot({ stage: 'act_three_travel', event: 'act_three_begin' });
		const flow = snapshot({ stage: 'flow_ready', event: 'connect_corridor_success' });
		const complete = snapshot({ stage: 'act_three_complete', event: 'flow_optimal' });

		expect(hudObjectiveFor(travel).title).toBe('Reach the Service Corridor.');
		expect(actionsFor(travel)[0]?.command).toBe('advance');
		expect(actionsFor(snapshot({ stage: 'at_service_corridor' }))[0]?.command).toBe('scan');
		expect(actionsFor(snapshot({ stage: 'corridor_scanned' }))[0]?.command).toBe('connect gwt08');
		expect(hudObjectiveFor(flow).title).toBe('Build minimum-cost failover.');
		expect(panelActionsFor(flow)[0]?.command).toBe('hint 1');
		expect(storyBeatFor('act_three_begin')?.title).toBe('HOSTILE INFRASTRUCTURE');
		expect(storyBeatFor('connect_corridor_success')?.lines.at(-1)?.text).toContain('CAP03');
		expect(storyBeatFor('flow_optimal')?.lines.at(-1)?.text).toContain('END OF ACT III');
		expect(hudObjectiveFor(complete).title).toContain('last carrier');
		expect(actionsFor(complete)[0]?.command).toBe('continue');
	});

	it('separates the fourth challenge from the narrative-only fifth act', () => {
		const carrier = snapshot({ stage: 'carrier_ready', event: 'act_four_begin' });
		const locked = snapshot({ stage: 'carrier_locked', event: 'tune_valid' });
		const hush = snapshot({ stage: 'hush_departure', event: 'hush_begin' });
		const loudspeakers = snapshot({
			stage: 'hush_loudspeakers',
			event: 'hush_loudspeakers'
		});
		const deadZone = snapshot({ stage: 'hush_dead_zone', event: 'hush_dead_zone' });
		const approach = snapshot({ stage: 'hush_approach', event: 'hush_transmitter' });
		const encounter = snapshot({ stage: 'encounter', event: 'reunion' });

		expect(hudObjectiveFor(carrier).title).toContain('final beacon');
		expect(panelActionsFor(carrier)[0]?.command).toBe('hint 1');
		expect(storyBeatFor('act_four_begin')?.title).toBe('LAST CARRIER');
		expect(actionsFor(locked)[0]).toMatchObject({ command: 'continue' });
		expect(actionsFor(locked)[0]?.label).toBe('Begin Act V');
		expect(storyBeatFor('tune_valid')?.lines.at(-1)?.text).toContain('END OF ACT IV');
		expect(actionsFor(hush)[0]).toMatchObject({ command: 'advance' });
		expect(storyBeatFor('hush_begin')?.lines[0]?.text).toBe('ACT V // HUSH');
		expect(panelActionsFor(hush).map((action) => action.command)).not.toContain('hint 1');
		expect(actionsFor(loudspeakers)[0]?.command).toBe('advance');
		expect(storyBeatFor('hush_loudspeakers')?.lines.some((line) => line.tone === 'junta')).toBe(
			true
		);
		expect(actionsFor(deadZone)[0]?.command).toBe('advance');
		expect(hudObjectiveFor(deadZone).title).toBe('Follow the beacon.');
		expect(actionsFor(approach)[0]?.command).toBe('advance');
		expect(storyBeatFor('hush_transmitter')?.lines.some((line) => line.tone === 'junta')).toBe(
			false
		);
		expect(hudObjectiveFor(encounter).title).toBe('Reunion.');
		expect(storyBeatFor('reunion')?.lines.at(-1)?.text).toContain('BEFORE THE SILENCE');
	});
});
