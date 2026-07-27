<script lang="ts">
	import mallaLogo from '$lib/assets/malla-logo.svg';
	import type { GameSnapshot, GameStage } from '$lib/game/types';

	let { snapshot }: { snapshot: GameSnapshot } = $props();

	function chapterFor(stage: GameStage): string {
		switch (stage) {
			case 'evacuation':
				return 'EVACUATION';
			case 'at_workshop':
				return 'LOCAL ACCESS';
			case 'packet_ready':
				return 'EMR06 RECOVERY';
			case 'prototype_complete':
				return 'SIGNAL RECOVERED';
			case 'route_ready':
				return 'CITY ROUTE';
			case 'route_in_transit':
				return 'CITY CROSSING';
			case 'at_interchange':
				return 'TRANSIT INTERCHANGE';
			case 'interchange_scanned':
				return 'TRN04 DISCOVERED';
			case 'transit_connected':
				return 'TRN04 LOCAL SESSION';
			case 'act_two_complete':
				return 'ACT II COMPLETE';
			case 'act_three_travel':
				return 'SERVICE CORRIDOR';
			case 'at_service_corridor':
				return 'LOCAL ACCESS';
			case 'corridor_scanned':
				return 'GWT08 DISCOVERED';
			case 'flow_ready':
				return 'CAP03 ALLOCATION';
			case 'act_three_complete':
				return 'ACT III COMPLETE';
			case 'carrier_ready':
				return 'LAST CARRIER';
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
				return 'ENCOUNTER';
			default:
				return 'SYNCING';
		}
	}

	let chapter = $derived(chapterFor(snapshot.stage));
	let act = $derived(
		[
			'hush_departure',
			'hush_streets',
			'hush_loudspeakers',
			'hush_dead_zone',
			'hush_approach',
			'encounter'
		].includes(snapshot.stage)
			? '05'
			: ['carrier_ready', 'carrier_locked'].includes(snapshot.stage)
				? '04'
				: [
							'act_three_travel',
							'at_service_corridor',
							'corridor_scanned',
							'flow_ready',
							'act_three_complete'
					  ].includes(snapshot.stage)
					? '03'
					: [
								'route_ready',
								'route_in_transit',
								'at_interchange',
								'interchange_scanned',
								'transit_connected',
								'act_two_complete'
						  ].includes(snapshot.stage)
						? '02'
						: '01'
	);
</script>

<header class="game-header">
	<div class="title-lockup">
		<h1><img class="game-logo" src={mallaLogo} alt="MALLA: Before the Silence" /></h1>
		<p>ACT {act} <span aria-hidden="true">|</span> {chapter}</p>
	</div>
</header>
