import type { GameEvent, GameSnapshot, GameStage } from './types';

const hintStages = new Set<GameStage>([
	'packet_ready',
	'route_ready',
	'flow_ready',
	'carrier_ready'
]);

const hintLevels: Partial<Record<GameEvent, number>> = {
	hint_one: 1,
	hint_two: 2,
	hint_three: 3,
	hint_four: 4,
	hint_five: 5,
	route_hint_one: 1,
	route_hint_two: 2,
	route_hint_three: 3,
	route_hint_four: 4,
	route_hint_five: 5,
	flow_hint_one: 1,
	flow_hint_two: 2,
	flow_hint_three: 3,
	flow_hint_four: 4,
	flow_hint_five: 5,
	beacon_hint_one: 1,
	beacon_hint_two: 2,
	beacon_hint_three: 3,
	beacon_hint_four: 4,
	beacon_hint_five: 5
};

const hintMenuEvents = new Set<GameEvent>([
	'hint_menu',
	'route_hint_menu',
	'flow_hint_menu',
	'beacon_hint_menu'
]);

const exposureLives: Record<string, number> = {
	ANONYMOUS: 3,
	CORRELATED: 2,
	LOCATED: 1,
	INTERCEPTION: 0
};

export interface FieldIntelMessage {
	title: string;
	body: string;
	isHint: boolean;
}

export function hasHintAccess(stage: GameStage): boolean {
	return hintStages.has(stage);
}

export function hintLevelFor(event: GameEvent): number | null {
	return hintLevels[event] ?? null;
}

export function isHintEvent(event: GameEvent): boolean {
	return hintMenuEvents.has(event) || hintLevelFor(event) !== null;
}

export function livesRemaining(exposure: string): number {
	return exposureLives[exposure.toUpperCase()] ?? 0;
}

export function fieldIntelMessageFor(
	snapshot: GameSnapshot,
	fallbackTitle: string
): FieldIntelMessage | null {
	const detail = snapshot.detail.trim();
	if (!detail) return null;

	const isHint = isHintEvent(snapshot.event);
	const shouldShowValidation =
		/^(repair|route|flow|tune)_/.test(snapshot.event) ||
		['failure', 'carrier_failure', 'unknown_command', 'internal_error'].includes(snapshot.event);

	if (!isHint && !shouldShowValidation) return null;

	const sections = detail.split(/\n\s*\n/);
	if (sections.length === 1) {
		return { title: fallbackTitle, body: sections[0], isHint };
	}

	return {
		title: sections[0].replaceAll(' // ', ' / '),
		body: sections.slice(1).join('\n\n'),
		isHint
	};
}
