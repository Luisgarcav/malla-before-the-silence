import type { GameEvent, GameSnapshot, GameStage } from './types';

export type LineTone = 'ellie' | 'tom' | 'junta' | 'system' | 'plain';

export interface StoryLine {
	text: string;
	tone: LineTone;
}

export interface StoryBeat {
	id: string;
	time: string;
	place: string;
	title: string;
	lines: StoryLine[];
}

export interface ActionDefinition {
	label: string;
	command: string;
	kind?: 'primary' | 'quiet';
}

export interface HudObjective {
	title: string;
	body: string;
}

export const openingBeat: StoryBeat = {
	id: 'opening',
	time: '21:13',
	place: 'OPERATIONS ANNEX',
	title: 'BEFORE THE SILENCE',
	lines: [
		{ text: 'TOM> Are you still angry?', tone: 'tom' },
		{ text: 'ELLIE> Get to the six. We will talk there.', tone: 'ellie' },
		{ text: 'TOM> I am going. Do not wait for...', tone: 'tom' },
		{ text: '[SIGNAL LOST]', tone: 'system' },
		{ text: 'The locks turn red. Your credential ceases to exist.', tone: 'plain' },
		{ text: 'JUNTA> REMAIN IN YOUR SECTOR', tone: 'junta' }
	]
};

const storyByEvent: Partial<Record<GameEvent, StoryBeat>> = {
	move_workshop: {
		id: 'workshop',
		time: '21:40',
		place: 'AUTOMATED WORKSHOP',
		title: 'TWENTY SEVEN MINUTES LATER',
		lines: [
			{ text: 'The annex gate locks behind you.', tone: 'plain' },
			{ text: 'A loudspeaker repeats names. Yours has not appeared yet.', tone: 'system' },
			{ text: 'CTRL17 keeps one green light behind the shutter.', tone: 'ellie' },
			{ text: 'TOM> [T_M>A_OT... R_TA _AC_A R_P0_.O_!]', tone: 'tom' }
		]
	},
	connect_success: {
		id: 'controller',
		time: '21:41',
		place: 'CTRL17 / LEGACY PORT',
		title: 'LOCAL SESSION',
		lines: [
			{ text: 'The physical key still answers to an old regional authority.', tone: 'ellie' },
			{ text: 'SOURCE // TXTOM04', tone: 'system' },
			{ text: 'You recognize the transmitter you repaired with Tom.', tone: 'tom' }
		]
	},
	inspect_success: {
		id: 'emr06',
		time: '21:41:08',
		place: 'EMR06 RECORD',
		title: 'TWO MISSING SLOTS',
		lines: [
			{ text: 'The capture contains twelve data slots and RAID-6 P/Q syndromes.', tone: 'system' },
			{ text: "Two parts of Tom's signal never arrived.", tone: 'tom' },
			{ text: 'The controller will accept only a verifiable repair.', tone: 'ellie' }
		]
	},
	evidence_diagnostic: {
		id: 'diagnostic',
		time: '21:41:09',
		place: 'RETURN CHANNEL',
		title: 'NO CARRIER',
		lines: [
			{ text: 'The loss happened during reception, not afterward.', tone: 'system' },
			{ text: 'Tom does not know whether you heard him.', tone: 'tom' }
		]
	},
	repair_valid: {
		id: 'signal_recovered',
		time: '21:42',
		place: 'CTRL17 / EMR06',
		title: 'REPAIR ACCEPTED',
		lines: [
			{ text: 'RAID-6 P/Q AND CRC32 VERIFIED', tone: 'system' },
			{ text: 'CTRL17 rebuilds the packet and moves it to the secure tray.', tone: 'plain' },
			{ text: 'A readable transmission from Tom is waiting to be opened.', tone: 'tom' }
		]
	},
	messages_recovered: {
		id: 'route_confirmed',
		time: '21:42:03',
		place: 'CTRL17 / RECOVERED CHANNEL',
		title: 'SHARED ROUTE',
		lines: [
			{ text: 'TOM> ROOFTOP. ROUTE TO REP06. OK!', tone: 'tom' },
			{ text: 'ELLIE> Received. I am going to the six.', tone: 'ellie' },
			{ text: '[RETURN CHANNEL HAS NO CARRIER]', tone: 'system' },
			{ text: 'He cannot hear her. Both routes still point to the same place.', tone: 'plain' },
			{ text: 'END OF ACT I // ROUTE TO THE SIX CONFIRMED', tone: 'system' }
		]
	},
	act_two_begin: {
		id: 'city_closes',
		time: '21:45',
		place: 'AUTOMATED WORKSHOP / NORTH EXIT',
		title: 'THE CITY CLOSES',
		lines: [
			{
				text: 'Ellie removes the physical key. CTRL17 shuts down without a farewell.',
				tone: 'plain'
			},
			{ text: 'JUNTA> RESTRICTED MOBILITY PROTOCOL IN EFFECT', tone: 'junta' },
			{
				text: 'The avenues are no longer streets. They are permissions that expire.',
				tone: 'plain'
			},
			{
				text: 'The latest city dump marks one node still free at the Interchange.',
				tone: 'system'
			},
			{ text: 'TOM> [REP06 BEACON // MOVING TOWARD SUBSTATION]', tone: 'tom' },
			{ text: 'ELLIE> Hold on. I will find a route.', tone: 'ellie' }
		]
	},
	route_optimal: {
		id: 'route_locked',
		time: '21:46',
		place: 'AUTOMATED WORKSHOP / NORTH EXIT',
		title: 'WINDOW FOUND',
		lines: [
			{ text: 'CR02 certifies the itinerary across every modeled arrival bound.', tone: 'system' },
			{ text: 'Ellie saves the itinerary and turns off the laptop screen.', tone: 'plain' },
			{ text: 'ELLIE> One street at a time.', tone: 'ellie' },
			{ text: '[PHYSICAL ROUTE READY]', tone: 'system' }
		]
	},
	route_market: {
		id: 'route_market',
		time: 'IN TRANSIT',
		place: 'MARKET / SUPPLY CORRIDOR',
		title: 'A LINE WITH NOTHING TO BUY',
		lines: [
			{ text: 'The stalls are closed. The line continues anyway.', tone: 'plain' },
			{ text: 'JUNTA> PRESENT IDENTIFICATION TO RECEIVE YOUR RATION', tone: 'junta' },
			{
				text: 'Ellie crosses the loading bays while a vendor argues over a list.',
				tone: 'ellie'
			}
		]
	},
	route_bridge: {
		id: 'route_bridge',
		time: 'IN TRANSIT',
		place: 'BRIDGE / MOBILE CHECKPOINT',
		title: 'THE RIVER AS A BORDER',
		lines: [
			{
				text: 'Two buses block the lanes. Their passengers wait beside the wall.',
				tone: 'plain'
			},
			{ text: '[LICENSE SCAN DRONE // SWEEPING WEST]', tone: 'system' },
			{ text: 'Ellie crosses beneath the structure before the sweep returns.', tone: 'ellie' }
		]
	},
	route_depot: {
		id: 'route_depot',
		time: 'IN TRANSIT',
		place: 'AUTOMATED DEPOT',
		title: 'HUMAN INVENTORY',
		lines: [
			{
				text: 'Loading arms keep working in a yard without supervisors.',
				tone: 'plain'
			},
			{ text: 'Every civil vehicle now receives a detention tag.', tone: 'system' },
			{ text: 'ELLIE> The network still obeys. Only its master changed.', tone: 'ellie' }
		]
	},
	route_tunnel: {
		id: 'route_tunnel',
		time: 'IN TRANSIT',
		place: 'SERVICE TUNNEL',
		title: 'NINETY SECONDS OF DARKNESS',
		lines: [
			{
				text: 'Coverage disappears. For the first time, the orders disappear too.',
				tone: 'plain'
			},
			{ text: 'TOM> [REP06 BEACON // ALTITUDE DROPPING]', tone: 'tom' },
			{ text: 'The signal returns before Ellie can answer.', tone: 'system' }
		]
	},
	route_plaza: {
		id: 'route_plaza',
		time: 'IN TRANSIT',
		place: 'CIVIC PLAZA',
		title: 'THE LARGEST SCREEN',
		lines: [
			{ text: 'Evacuation panels show portraits instead of routes.', tone: 'plain' },
			{ text: 'JUNTA> NORMALITY HAS BEEN RESTORED', tone: 'junta' },
			{ text: 'Below the screen, someone writes an erased name again.', tone: 'ellie' }
		]
	},
	route_rail: {
		id: 'route_rail',
		time: 'IN TRANSIT',
		place: 'RAIL CORRIDOR',
		title: 'SPECIAL SERVICE',
		lines: [
			{ text: 'Civil schedules remain posted. No train stops.', tone: 'plain' },
			{ text: '[UNIDENTIFIED CONVOY // CENTRAL PRIORITY]', tone: 'system' },
			{ text: 'Ellie waits for the last car and crosses the tracks.', tone: 'ellie' }
		]
	},
	route_arrival: {
		id: 'interchange_arrival',
		time: '22:03',
		place: 'TRANSIT INTERCHANGE',
		title: 'THE EMPTY PLATFORMS',
		lines: [
			{ text: 'The final segment closes behind Ellie.', tone: 'system' },
			{
				text: 'The platforms were turned into improvised identity checkpoints.',
				tone: 'plain'
			},
			{ text: 'A maintenance box retains one local light.', tone: 'ellie' },
			{ text: '[NO ACTIVE SESSION // SCAN REQUIRED]', tone: 'system' }
		]
	},
	scan_interchange: {
		id: 'interchange_scan',
		time: '22:04',
		place: 'INTERCHANGE / TECHNICAL ROOM',
		title: 'TRN04',
		lines: [
			{
				text: 'The junta occupies the trunk. The local controller is isolated.',
				tone: 'system'
			},
			{
				text: 'The same regional authority that opened CTRL17 is still listed as valid.',
				tone: 'ellie'
			},
			{ text: 'TRN04 retains unsynchronized emergency movements.', tone: 'plain' }
		]
	},
	connect_transit_success: {
		id: 'interchange_session',
		time: '22:05',
		place: 'TRN04 / LOCAL SESSION',
		title: 'WHAT THE CENTER CANNOT SEE',
		lines: [
			{
				text: 'The session cannot reach the trunk. It cannot receive new revocations either.',
				tone: 'system'
			},
			{
				text: 'An update signed by REP06 appears among the pending movements.',
				tone: 'tom'
			},
			{ text: 'ELLIE> Show me where you are.', tone: 'ellie' }
		]
	},
	transit_intel_recovered: {
		id: 'act_two_complete',
		time: '22:06',
		place: 'TRN04 / EMERGENCY MOVEMENTS',
		title: 'SUBSTATION',
		lines: [
			{
				text: 'TOM> I LEFT THE LINK. SECONDARY SUBSTATION. REP06 HAS NO POWER.',
				tone: 'tom'
			},
			{
				text: 'Tom is no longer on the rooftop. He crossed his side of the city alone.',
				tone: 'plain'
			},
			{ text: 'ELLIE> Restore power. I will open a data route.', tone: 'ellie' },
			{ text: '[SHARED DESTINATION // REPEATER 06]', tone: 'system' },
			{ text: 'END OF ACT II // THE CITY CLOSES', tone: 'system' }
		]
	},
	act_three_begin: {
		id: 'hostile_infrastructure',
		time: '22:08',
		place: 'INTERCHANGE / MAINTENANCE EXIT',
		title: 'HOSTILE INFRASTRUCTURE',
		lines: [
			{ text: 'Ellie closes TRN04. The local session will not survive movement.', tone: 'plain' },
			{
				text: 'REP06 has pending power. It still has no data route.',
				tone: 'system'
			},
			{ text: 'TOM> [SUBSTATION // REPAIR IN PROGRESS]', tone: 'tom' },
			{ text: 'The nearest cabinet is beneath the Service Corridor.', tone: 'ellie' }
		]
	},
	service_corridor_arrival: {
		id: 'service_corridor',
		time: '22:12',
		place: 'SERVICE CORRIDOR',
		title: 'BENEATH THE CITY',
		lines: [
			{ text: 'Pipes conceal the sound of vehicles on the avenue above.', tone: 'plain' },
			{
				text: 'A mechanical gate retains the regional maintenance seal.',
				tone: 'ellie'
			},
			{ text: '[CABINET POWERED // NO ACTIVE SESSION]', tone: 'system' }
		]
	},
	scan_corridor: {
		id: 'corridor_scan',
		time: '22:13',
		place: 'CORRIDOR / DATA CABINET',
		title: 'GWT08',
		lines: [
			{
				text: 'The central gateway was reconfigured. Its local interface was left behind.',
				tone: 'system'
			},
			{ text: 'GWT08 still trusts the same regional chain as CTRL17.', tone: 'ellie' },
			{ text: 'JUNTA> EVERY UNREGISTERED CHANNEL WILL BE CORRELATED', tone: 'junta' }
		]
	},
	connect_corridor_success: {
		id: 'capacity_dossier',
		time: '22:14',
		place: 'GWT08 / LOCAL SESSION',
		title: 'CARRIER AT REP06',
		lines: [
			{
				text: 'Repeater interface T appears in the topology for the first time.',
				tone: 'system'
			},
			{ text: 'TOM> POWER RESTORED. NO CHANNEL.', tone: 'tom' },
			{
				text: 'Tom solved the physical problem. Ellie still has to find capacity.',
				tone: 'plain'
			},
			{ text: '[CAP03 DOSSIER AVAILABLE]', tone: 'ellie' }
		]
	},
	flow_optimal: {
		id: 'act_three_complete',
		time: '22:17',
		place: 'GWT08 / REP06 CHANNEL',
		title: 'SURVIVABLE CHANNEL',
		lines: [
			{
				text: 'Primary and backup carry full demand on disjoint links at minimum cost.',
				tone: 'system'
			},
			{
				text: 'Civil reserves and link headroom remain intact. The junta can now recognize the pattern.',
				tone: 'plain'
			},
			{ text: 'TOM> ELLIE. I SEE YOU ON THE ROUTE.', tone: 'tom' },
			{ text: 'ELLIE> I am coming to you.', tone: 'ellie' },
			{ text: 'END OF ACT III // HOSTILE INFRASTRUCTURE', tone: 'system' }
		]
	},
	act_four_begin: {
		id: 'last_carrier',
		time: '22:18',
		place: 'GWT08 / REP06 CHANNEL',
		title: 'LAST CARRIER',
		lines: [
			{ text: 'The data route remains open. Final link synchronization does not.', tone: 'plain' },
			{ text: 'TOM> ELLIE, THE REPEATER CHANGED...', tone: 'tom' },
			{ text: '[CARRIER LOST // NO RETURN CHANNEL]', tone: 'system' },
			{
				text: "Nine copies of Tom's final beacon remain suspended in the receiver.",
				tone: 'ellie'
			},
			{ text: '[BCNR6 DOSSIER AVAILABLE]', tone: 'system' }
		]
	},
	tune_valid: {
		id: 'carrier_locked',
		time: '22:19',
		place: 'GWT08 / DEGRADED RECEIVER',
		title: 'CHANNEL INTO SILENCE',
		lines: [
			{ text: 'BCNR6 matches: channel, offset, repetition ID, and CRC-16.', tone: 'system' },
			{ text: 'The carrier locks. Nobody answers on the other side.', tone: 'plain' },
			{ text: 'ELLIE> Tom.', tone: 'ellie' },
			{ text: '[CHANNEL OPEN // NO RESPONSE]', tone: 'system' },
			{ text: 'END OF ACT IV // LAST CARRIER', tone: 'system' }
		]
	},
	carrier_failure: {
		id: 'carrier_interception',
		time: '22:19',
		place: 'GWT08 / DEGRADED RECEIVER',
		title: 'INTERCEPTION',
		lines: [
			{ text: "The final scan exposes Ellie's regional signature.", tone: 'system' },
			{ text: 'JUNTA> SESSION LOCATED. SECURE THE CABINET.', tone: 'junta' },
			{ text: '[CARRIER LOST // SESSION CUT]', tone: 'system' }
		]
	},
	hush_begin: {
		id: 'hush_departure',
		time: '22:20',
		place: 'SERVICE CORRIDOR',
		title: 'HUSH',
		lines: [
			{ text: 'ACT V // HUSH', tone: 'system' },
			{ text: 'Ellie closes GWT08 and pockets the physical key.', tone: 'plain' },
			{ text: 'No dossiers remain. No parameters remain to correct.', tone: 'system' },
			{ text: 'The final route can only be crossed on foot.', tone: 'ellie' }
		]
	},
	hush_streets: {
		id: 'empty_streets',
		time: '22:23',
		place: 'STREETS UNDER CURFEW',
		title: 'DARK WINDOWS',
		lines: [
			{ text: 'The shutters are down. Crossings turn green for nobody.', tone: 'plain' },
			{
				text: 'A bicycle rests against the curb with its wheel still turning.',
				tone: 'plain'
			},
			{ text: "In Ellie's pocket, the beacon keeps repeating the same frame.", tone: 'tom' }
		]
	},
	hush_loudspeakers: {
		id: 'last_order',
		time: '22:25',
		place: 'CIVIC AVENUE',
		title: 'THE LAST ORDER',
		lines: [
			{ text: 'MALLA> REGIONAL SIGNATURE LOCATED. SECTOR 06 LOCKDOWN NOW.', tone: 'junta' },
			{ text: 'The loudspeakers repeat the order a few seconds apart.', tone: 'system' },
			{ text: 'Ellie keeps walking. The REP06 tower fits between two buildings.', tone: 'ellie' }
		]
	},
	hush_dead_zone: {
		id: 'mesh_boundary',
		time: '22:27',
		place: 'MESH BOUNDARY',
		title: 'BEYOND MALLA',
		lines: [
			{ text: 'JUNTA> NEAREST UNIT, INTERCEPT', tone: 'junta' },
			{ text: '[CENTRAL CARRIER LOST]', tone: 'system' },
			{ text: 'The order cuts out. Only her steps and the recorded beacon remain.', tone: 'plain' },
			{
				text: 'For the first time since the annex, MALLA does not know where she is.',
				tone: 'ellie'
			}
		]
	},
	hush_transmitter: {
		id: 'repeater_approach',
		time: '22:29',
		place: 'REPEATER 06 APPROACH',
		title: 'THE LONE TRANSMITTER',
		lines: [
			{
				text: 'The service door was left open. A red light pulses in the cabinet.',
				tone: 'plain'
			},
			{ text: '[BCNR6 // LOCAL TRANSMISSION]', tone: 'system' },
			{
				text: "Above, Tom's transmitter sounds alone inside the open cabinet.",
				tone: 'tom'
			}
		]
	},
	reunion: {
		id: 'reunion',
		time: '22:31',
		place: 'REPEATER 06',
		title: 'REUNION',
		lines: [
			{
				text: 'Tom steps out from behind the cabinet, grease on his hands and radio on his shoulder.',
				tone: 'plain'
			},
			{ text: 'TOM> You made it.', tone: 'tom' },
			{ text: 'ELLIE> So did you.', tone: 'ellie' },
			{ text: 'The city is still occupied. Their promise is not.', tone: 'plain' },
			{ text: 'END // MALLA: BEFORE THE SILENCE', tone: 'system' }
		]
	},
	failure: {
		id: 'interception',
		time: '21:42',
		place: 'CTRL17',
		title: 'INTERCEPTION',
		lines: [
			{ text: 'The controller cuts the session.', tone: 'junta' },
			{ text: 'A detention order prints the signature of your physical key.', tone: 'system' }
		]
	}
};

const feedbackTitles: Partial<Record<GameEvent, string>> = {
	none: 'Odin engine connected',
	move_workshop: 'Route completed',
	connect_success: 'Local session open',
	inspect_success: 'EMR06 dossier available',
	evidence_capture: 'Binary capture',
	evidence_protocol: 'MESH ER2 protocol',
	evidence_diagnostic: 'Reception diagnostics',
	evidence_integrity: 'Integrity profile',
	hint_menu: 'Optional guidance',
	hint_one: 'Hint 1',
	hint_two: 'Hint 2',
	hint_three: 'Hint 3',
	hint_four: 'Hint 4',
	hint_five: 'Hint 5',
	repair_valid: 'Repair accepted',
	messages_recovered: 'Recovered signal read',
	act_two_begin: 'CR02 city dossier available',
	route_hint_menu: 'CR02 guidance',
	route_hint_one: 'Hint 1',
	route_hint_two: 'Hint 2',
	route_hint_three: 'Hint 3',
	route_hint_four: 'Hint 4',
	route_hint_five: 'Hint 5',
	route_format_invalid: 'Invalid route format',
	route_impossible: 'Route rejected',
	route_suboptimal: 'Route outside robust margin',
	route_optimal: 'Robust route applied',
	route_market: 'Market crossed',
	route_bridge: 'Bridge crossed',
	route_depot: 'Depot crossed',
	route_tunnel: 'Tunnel crossed',
	route_plaza: 'Plaza crossed',
	route_rail: 'Rail corridor crossed',
	route_arrival: 'Interchange reached',
	scan_interchange: 'TRN04 located',
	connect_transit_need_scan: 'Scan required',
	connect_transit_success: 'TRN04 session open',
	transit_intel_recovered: 'Tom position recovered',
	act_three_begin: 'Service Corridor route open',
	service_corridor_arrival: 'Service Corridor reached',
	scan_corridor: 'GWT08 located',
	connect_corridor_need_scan: 'Scan required',
	connect_corridor_success: 'CAP03 dossier available',
	flow_format_invalid: 'Invalid allocation format',
	flow_impossible: 'Allocation rejected',
	flow_insufficient: 'Insufficient capacity',
	flow_suboptimal: 'Failover cost is not minimal',
	flow_optimal: 'REP06 survivable channel open',
	flow_hint_menu: 'CAP03 guidance',
	flow_hint_one: 'Hint 1',
	flow_hint_two: 'Hint 2',
	flow_hint_three: 'Hint 3',
	flow_hint_four: 'Hint 4',
	flow_hint_five: 'Hint 5',
	act_four_begin: 'BCNR6 dossier available',
	connect_carrier_success: 'GWT08 session reopened',
	beacon_evidence_context: 'Carrier context',
	beacon_evidence_capture: 'Nine BCNR6 echoes',
	beacon_evidence_diagnostic: 'Bit-likelihood calibration',
	beacon_evidence_protocol: 'BCNR6 specification',
	beacon_evidence_policy: 'Carrier lock policy',
	beacon_hint_menu: 'BCNR6 guidance',
	beacon_hint_one: 'Hint 1',
	beacon_hint_two: 'Hint 2',
	beacon_hint_three: 'Hint 3',
	beacon_hint_four: 'Hint 4',
	beacon_hint_five: 'Hint 5',
	tune_format_invalid: 'Invalid tuning format',
	tune_impossible: 'Scan without lock',
	tune_valid: 'Carrier locked',
	carrier_failure: 'Interception at GWT08',
	hush_begin: 'HUSH',
	hush_streets: 'Streets crossed',
	hush_loudspeakers: 'Final MALLA order',
	hush_dead_zone: 'Beyond coverage',
	hush_transmitter: 'Repeater reached',
	reunion: 'Reunion',
	repair_format_invalid: 'Invalid format',
	repair_impossible: 'Repair rejected',
	failure: 'Interception',
	unknown_command: 'Unknown command',
	internal_error: 'Engine error'
};

export function storyBeatFor(event: GameEvent): StoryBeat | undefined {
	return storyByEvent[event];
}

export function appendStoryBeat(history: StoryBeat[], event: GameEvent): StoryBeat[] {
	const beat = storyBeatFor(event);
	if (!beat || history.some((entry) => entry.id === beat.id)) return history;
	return [...history, beat];
}

export function restartBeatsFor(snapshot: GameSnapshot): StoryBeat[] {
	if (snapshot.stage === 'evacuation') return [openingBeat];
	const opening = storyBeatFor(snapshot.event);
	return opening ? [opening] : [];
}

export function feedbackTitle(event: GameEvent): string {
	return feedbackTitles[event] ?? event.replaceAll('_', ' ').toUpperCase();
}

export function actionsFor(snapshot: GameSnapshot): ActionDefinition[] {
	if (!snapshot.running) return [];
	if (snapshot.stage === 'prototype_complete') {
		return snapshot.signalReviewed
			? [{ label: 'Begin Act II', command: 'continue', kind: 'primary' }]
			: [{ label: 'Read signal', command: 'messages', kind: 'primary' }];
	}

	if (snapshot.stage === 'evacuation') {
		return [{ label: 'Evacuate to Workshop', command: 'move workshop', kind: 'primary' }];
	}
	if (snapshot.stage === 'at_workshop' && snapshot.connection === 'DISCONNECTED') {
		return [
			{ label: 'Scan interfaces', command: 'scan', kind: 'quiet' },
			{ label: 'Open CTRL17', command: 'connect controller', kind: 'primary' }
		];
	}
	if (snapshot.stage === 'at_workshop') {
		return [{ label: 'Open EMR06 dossier', command: 'inspect emr06', kind: 'primary' }];
	}
	if (snapshot.stage === 'route_in_transit') {
		return [{ label: 'Cross next segment', command: 'advance', kind: 'primary' }];
	}
	if (snapshot.stage === 'at_interchange') {
		return [{ label: 'Scan interfaces', command: 'scan', kind: 'primary' }];
	}
	if (snapshot.stage === 'interchange_scanned') {
		return [{ label: 'Open TRN04', command: 'connect trn04', kind: 'primary' }];
	}
	if (snapshot.stage === 'transit_connected') {
		return [{ label: 'Open movements', command: 'inspect trn04', kind: 'primary' }];
	}
	if (snapshot.stage === 'act_two_complete') {
		return [{ label: 'Begin Act III', command: 'continue', kind: 'primary' }];
	}
	if (snapshot.stage === 'act_three_travel') {
		return [{ label: 'Go to the Corridor', command: 'advance', kind: 'primary' }];
	}
	if (snapshot.stage === 'at_service_corridor') {
		return [{ label: 'Scan cabinet', command: 'scan', kind: 'primary' }];
	}
	if (snapshot.stage === 'corridor_scanned') {
		return [{ label: 'Open GWT08', command: 'connect gwt08', kind: 'primary' }];
	}
	if (snapshot.stage === 'act_three_complete') {
		return [{ label: 'Begin Act IV', command: 'continue', kind: 'primary' }];
	}
	if (snapshot.stage === 'carrier_locked') {
		return [{ label: 'Begin Act V', command: 'continue', kind: 'primary' }];
	}
	if (snapshot.stage === 'hush_departure') {
		return [{ label: 'Leave the Corridor', command: 'advance', kind: 'primary' }];
	}
	if (snapshot.stage === 'hush_streets') {
		return [{ label: 'Cross the avenue', command: 'advance', kind: 'primary' }];
	}
	if (snapshot.stage === 'hush_loudspeakers') {
		return [{ label: 'Leave the loudspeakers', command: 'advance', kind: 'primary' }];
	}
	if (snapshot.stage === 'hush_dead_zone') {
		return [{ label: 'Follow the beacon', command: 'advance', kind: 'primary' }];
	}
	if (snapshot.stage === 'hush_approach') {
		return [{ label: 'Enter REP06', command: 'advance', kind: 'primary' }];
	}
	return [];
}

export function hudObjectiveFor(snapshot: GameSnapshot): HudObjective {
	switch (snapshot.stage) {
		case 'evacuation':
			return {
				title: 'Leave before lockdown.',
				body: 'The annex is sealing behind you. Reach the Workshop while the route remains open.'
			};
		case 'at_workshop':
			return snapshot.connection === 'DISCONNECTED'
				? {
						title: 'Open a local route.',
						body: 'An old controller survived the takeover. Connect before its authority is revoked.'
					}
				: {
						title: 'Find the lost signal.',
						body: "CTRL17 retains a damaged emergency record from Tom's transmitter."
					};
		case 'packet_ready':
			return {
				title: 'Recover the lost signal.',
				body: 'Two of twelve opaque blocks are missing. Solve the RAID-6 P/Q systems and verify the full record.'
			};
		case 'prototype_complete':
			return snapshot.signalReviewed
				? {
						title: 'The city closes.',
						body: 'Tom is alive and moving toward Repeater 06. Disconnect CTRL17 and leave the Workshop.'
					}
				: {
						title: 'Read the recovered signal.',
						body: "CTRL17 rebuilt the packet. Open the transmission to confirm Tom's route."
					};
		case 'route_ready':
			return {
				title: 'Find a robust route.',
				body: 'Propagate arrival intervals, avoid every possible closure overlap, and stay within the minimax tolerance.'
			};
		case 'route_in_transit':
			return {
				title: `${snapshot.objective}.`,
				body: 'The itinerary is locked. Move physically before the next closure window changes.'
			};
		case 'at_interchange':
			return {
				title: 'Find local access.',
				body: 'You reached the Interchange without an active session. Scan the interfaces that survived lockdown.'
			};
		case 'interchange_scanned':
			return {
				title: 'Open TRN04.',
				body: 'The transit controller is isolated from the center and still accepts your regional authority.'
			};
		case 'transit_connected':
			return {
				title: 'Locate Tom.',
				body: 'TRN04 retains a REP06 update among its pending emergency movements.'
			};
		case 'act_two_complete':
			return {
				title: 'Hostile infrastructure.',
				body: 'Tom reached the Substation. Close TRN04 and find a data route to REP06 from the Service Corridor.'
			};
		case 'act_three_travel':
			return {
				title: 'Reach the Service Corridor.',
				body: 'The transit session is behind you. The next access requires reaching the cabinet beneath the avenue.'
			};
		case 'at_service_corridor':
			return {
				title: 'Find the local gateway.',
				body: 'The cabinet has power, but you do not know which interfaces survived central reconfiguration.'
			};
		case 'corridor_scanned':
			return {
				title: 'Open GWT08.',
				body: 'The maintenance interface accepts your regional certificate and retains a degraded route to REP06.'
			};
		case 'flow_ready':
			return {
				title: 'Build minimum-cost failover.',
				body: 'Reserve disjoint primary and backup flows. Each must carry full demand without consuming headroom.'
			};
		case 'act_three_complete':
			return {
				title: 'The last carrier.',
				body: 'The data channel is open. Enter Act IV before final synchronization is lost.'
			};
		case 'carrier_ready':
			return {
				title: 'Reconstruct the final beacon.',
				body: 'Combine bit-level likelihoods, enforce confidence, and recover channel, offset, repetition ID and CRC16.'
			};
		case 'carrier_locked':
			return {
				title: 'The channel is open.',
				body: 'The intervention worked. Tom does not answer. Close the session and begin Act V with no more technical work.'
			};
		case 'hush_departure':
			return {
				title: 'Leave the cabinet.',
				body: 'The laptop returns to the bag. Follow the newly recovered carrier on foot.'
			};
		case 'hush_streets':
			return {
				title: 'Cross the empty streets.',
				body: 'Civic Avenue is the final segment where MALLA loudspeakers still have coverage.'
			};
		case 'hush_loudspeakers':
			return {
				title: 'Leave the final order behind.',
				body: 'MALLA has correlated your regional signature. The coverage boundary is a few streets ahead.'
			};
		case 'hush_dead_zone':
			return {
				title: 'Follow the beacon.',
				body: "The voice of the junta has cut out. Only Tom's recorded frame continues to mark the way."
			};
		case 'hush_approach':
			return {
				title: 'Enter the repeater.',
				body: "MALLA is behind you. Tom's transmitter still sounds inside the open cabinet."
			};
		case 'encounter':
			return {
				title: 'Reunion.',
				body: 'They did not stop the coup. They reached the same place before dawn.'
			};
		default:
			return { title: 'Hold the signal.', body: snapshot.objective };
	}
}

export function panelActionsFor(snapshot: GameSnapshot): ActionDefinition[] {
	if (!snapshot.running)
		return [{ label: 'RESTART ACT', command: '__restart_act__', kind: 'primary' }];

	switch (snapshot.stage) {
		case 'evacuation':
			return [
				{ label: 'GO TO WORKSHOP', command: 'move workshop', kind: 'primary' },
				{ label: 'SCAN SECTOR', command: 'scan', kind: 'quiet' }
			];
		case 'at_workshop':
			return snapshot.connection === 'DISCONNECTED'
				? [
						{ label: 'OPEN CTRL17', command: 'connect controller', kind: 'primary' },
						{ label: 'SCAN INTERFACES', command: 'scan', kind: 'quiet' }
					]
				: [
						{ label: 'OPEN EMR06', command: 'inspect emr06', kind: 'primary' },
						{ label: 'READ MESSAGES', command: 'messages', kind: 'quiet' }
					];
		case 'packet_ready':
			return [
				{ label: 'OPEN HINT', command: 'hint 1', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'prototype_complete':
			return snapshot.signalReviewed
				? [
						{ label: 'BEGIN ACT II', command: 'continue', kind: 'primary' },
						{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
					]
				: [
						{ label: 'READ SIGNAL', command: 'messages', kind: 'primary' },
						{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
					];
		case 'route_ready':
			return [
				{ label: 'OPEN HINT', command: 'hint 1', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'route_in_transit':
			return [
				{ label: 'CROSS NEXT SEGMENT', command: 'advance', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'at_interchange':
			return [
				{ label: 'SCAN INTERFACES', command: 'scan', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'interchange_scanned':
			return [
				{ label: 'OPEN TRN04', command: 'connect trn04', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'transit_connected':
			return [
				{ label: 'OPEN MOVEMENTS', command: 'inspect trn04', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'act_two_complete':
			return [
				{ label: 'BEGIN ACT III', command: 'continue', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'act_three_travel':
			return [
				{ label: 'GO TO CORRIDOR', command: 'advance', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'at_service_corridor':
			return [
				{ label: 'SCAN CABINET', command: 'scan', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'corridor_scanned':
			return [
				{ label: 'OPEN GWT08', command: 'connect gwt08', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'flow_ready':
			return [
				{ label: 'OPEN HINT', command: 'hint 1', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'act_three_complete':
			return [
				{ label: 'BEGIN ACT IV', command: 'continue', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'carrier_ready':
			return [
				{ label: 'OPEN HINT', command: 'hint 1', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'carrier_locked':
			return [
				{ label: 'BEGIN ACT V', command: 'continue', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'hush_departure':
			return [
				{ label: 'LEAVE THE CORRIDOR', command: 'advance', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'hush_streets':
			return [
				{ label: 'CROSS THE AVENUE', command: 'advance', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'hush_loudspeakers':
			return [
				{ label: 'LEAVE THE LOUDSPEAKERS', command: 'advance', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'hush_dead_zone':
			return [
				{ label: 'FOLLOW THE BEACON', command: 'advance', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'hush_approach':
			return [
				{ label: 'ENTER REP06', command: 'advance', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		case 'encounter':
			return [
				{ label: 'RESTART GAME', command: '__reset__', kind: 'primary' },
				{ label: 'VIEW LOG', command: 'log', kind: 'quiet' }
			];
		default:
			return [];
	}
}

export function stageLabel(stage: GameStage): string {
	switch (stage) {
		case 'evacuation':
			return 'PROLOGUE';
		case 'at_workshop':
			return 'LOCAL ACCESS';
		case 'packet_ready':
			return 'EMR06 OPERATION';
		case 'prototype_complete':
			return 'SIGNAL RECOVERED';
		case 'route_ready':
			return 'CR02 CITY ROUTE';
		case 'route_in_transit':
			return 'CITY CROSSING';
		case 'at_interchange':
			return 'INTERCHANGE';
		case 'interchange_scanned':
			return 'TRN04 INTERFACE';
		case 'transit_connected':
			return 'TRN04 SESSION';
		case 'act_two_complete':
			return 'TRN04 INTERCHANGE';
		case 'act_three_travel':
			return 'CORRIDOR TRANSIT';
		case 'at_service_corridor':
			return 'SERVICE CORRIDOR';
		case 'corridor_scanned':
			return 'GWT08 INTERFACE';
		case 'flow_ready':
			return 'CAP03 CAPACITY';
		case 'act_three_complete':
			return 'REP06 CHANNEL';
		case 'carrier_ready':
			return 'BCNR6 LAST CARRIER';
		case 'carrier_locked':
			return 'CARRIER LOCKED';
		case 'hush_departure':
			return 'HUSH / DEPARTURE';
		case 'hush_streets':
			return 'HUSH / EMPTY STREETS';
		case 'hush_loudspeakers':
			return 'HUSH / LAST ORDER';
		case 'hush_dead_zone':
			return 'HUSH / OUT OF RANGE';
		case 'hush_approach':
			return 'HUSH / REP06';
		case 'encounter':
			return 'REUNION';
		default:
			return 'SYNCING';
	}
}
