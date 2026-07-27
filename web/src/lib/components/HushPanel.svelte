<script lang="ts">
	import type { GameSnapshot } from '$lib/game/types';
	import HudFrame from '$lib/components/ui/HudFrame.svelte';

	let { snapshot }: { snapshot: GameSnapshot } = $props();

	let progress = $derived(
		snapshot.stage === 'encounter'
			? 5
			: snapshot.stage === 'hush_approach'
				? 4
				: snapshot.stage === 'hush_dead_zone'
					? 3
					: snapshot.stage === 'hush_loudspeakers'
						? 2
						: snapshot.stage === 'hush_streets'
							? 1
							: 0
	);
	let final = $derived(snapshot.stage === 'encounter');
	let silent = $derived(['hush_dead_zone', 'hush_approach', 'encounter'].includes(snapshot.stage));
	let stateCopy = $derived.by(() => {
		switch (snapshot.stage) {
			case 'hush_streets':
				return {
					status: 'LOCAL TRACE / MOVING',
					title: 'DARK WINDOWS',
					body: 'Shops lowered their shutters. Traffic lights still change for a city that no longer crosses.',
					signal: 'BCNR6 / RECORDED ECHO'
				};
			case 'hush_loudspeakers':
				return {
					status: 'MALLA COVERAGE / FINAL SECTOR',
					title: 'THE LAST ORDER',
					body: 'Loudspeakers repeat the order to return. Ellie keeps walking as the tower appears between buildings.',
					signal: 'MALLA / PUBLIC TRANSMISSION'
				};
			case 'hush_dead_zone':
				return {
					status: 'CENTRAL CARRIER / LOST',
					title: 'BEYOND MALLA',
					body: 'The Junta transmission cuts out mid sentence. Her steps, the REP06 pulse, and a city that no longer knows where she is remain.',
					signal: 'MALLA / OUT OF RANGE'
				};
			case 'hush_approach':
				return {
					status: 'LOCAL TRANSMISSION / NO RESPONSE',
					title: 'THE LONE TRANSMITTER',
					body: 'The door is open. A red light pulses inside and the transmitter repeats its call without knowing who will arrive first.',
					signal: 'BCNR6 / LOCAL TRANSMISSION'
				};
			case 'encounter':
				return {
					status: 'VISUAL CONTACT / CONFIRMED',
					title: 'REUNION',
					body: 'Ellie and Tom reached Repeater 06 in person. The city remains occupied. Their promise survived.',
					signal: 'TOM / PRESENT'
				};
			default:
				return {
					status: 'CHANNEL OPEN / NO RESPONSE',
					title: 'NOTHING ELSE TO SOLVE',
					body: 'The dossier stays behind with the laptop. From here, every action is physical movement toward REP06.',
					signal: 'BCNR6 / RECORDED ECHO'
				};
		}
	});
</script>

<HudFrame className="tech-panel hush-panel" labelledby="hush-title" tone="quiet">
	<h2 id="hush-title" class="panel-title">SIGNAL <span>|</span> HUSH</h2>

	<div class="hush-body">
		<div class:resolved={final} class:silent class="hush-signal" aria-hidden="true">
			<i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i>
		</div>

		<div class="hush-state">
			<span>{stateCopy.status}</span>
			<strong>{stateCopy.title}</strong>
			<p>{stateCopy.body}</p>
		</div>

		<div class="hush-progress" aria-label={`Station ${progress + 1} of 6 on the final route`}>
			{#each ['CORRIDOR', 'STREETS', 'AVENUE', 'BOUNDARY', 'APPROACH', 'REP06'] as stop, index (stop)}
				<div class:reached={index <= progress} class:current={index === progress}>
					<i></i><span>{stop}</span>
				</div>
			{/each}
		</div>

		<div class="hush-location">
			<span>CURRENT POSITION</span>
			<strong>{snapshot.location}</strong>
			<small>{stateCopy.signal}</small>
		</div>

		<div class="hush-rule">
			<span>ACT V</span>
			<p>NO DOSSIERS · NO CHALLENGES · NO TECHNICAL COMMANDS</p>
		</div>
	</div>
</HudFrame>
