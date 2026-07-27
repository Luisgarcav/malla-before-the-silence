import { describe, expect, it } from 'vitest';
import {
	fieldIntelMessageFor,
	hasHintAccess,
	hintLevelFor,
	isHintEvent,
	livesRemaining
} from './fieldIntel';
import type { GameSnapshot } from './types';

const snapshot = (overrides: Partial<GameSnapshot> = {}): GameSnapshot => ({
	seed: '1999',
	window: 5,
	running: true,
	captureViewed: true,
	signalReviewed: false,
	location: 'AUTOMATED WORKSHOP',
	connection: 'CTRL17 / LEGACY PORT',
	stage: 'packet_ready',
	exposure: 'ANONYMOUS',
	event: 'none',
	objective: 'Reconstruct both missing fragments',
	nextCommand: 'evidence capture',
	detail: '',
	evidence: '',
	raw: false,
	...overrides
});

describe('field intel', () => {
	it('turns exposure into remaining lives before interception', () => {
		expect(livesRemaining('ANONYMOUS')).toBe(3);
		expect(livesRemaining('CORRELATED')).toBe(2);
		expect(livesRemaining('LOCATED')).toBe(1);
		expect(livesRemaining('INTERCEPTION')).toBe(0);
	});

	it('recognizes every challenge hint as guidance', () => {
		expect(hasHintAccess('packet_ready')).toBe(true);
		expect(hasHintAccess('route_ready')).toBe(true);
		expect(hasHintAccess('evacuation')).toBe(false);
		expect(isHintEvent('flow_hint_menu')).toBe(true);
		expect(hintLevelFor('beacon_hint_four')).toBe(4);
		expect(hintLevelFor('repair_valid')).toBeNull();
	});

	it('separates the hint heading from its useful content', () => {
		const message = fieldIntelMessageFor(
			snapshot({
				event: 'hint_one',
				detail: 'HINT 1 // TARGET\n\nTrust the octet capture.\nP and Q are syndromes.'
			}),
			'Hint 1'
		);

		expect(message).toEqual({
			title: 'HINT 1 / TARGET',
			body: 'Trust the octet capture.\nP and Q are syndromes.',
			isHint: true
		});
	});

	it('keeps non-action dossier text out of the compact status panel', () => {
		expect(
			fieldIntelMessageFor(
				snapshot({ event: 'evidence_capture', detail: 'A very large raw capture' }),
				'Binary capture'
			)
		).toBeNull();
	});
});
