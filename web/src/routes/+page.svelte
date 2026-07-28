<script lang="ts">
	import { base } from '$app/paths';
	import CommandDock from '$lib/components/CommandDock.svelte';
	import CarrierPanel from '$lib/components/CarrierPanel.svelte';
	import EndingScreen from '$lib/components/EndingScreen.svelte';
	import EvidencePanel from '$lib/components/EvidencePanel.svelte';
	import FlowPanel from '$lib/components/FlowPanel.svelte';
	import HushPanel from '$lib/components/HushPanel.svelte';
	import IntroSequence from '$lib/components/IntroSequence.svelte';
	import NetworkMap from '$lib/components/NetworkMap.svelte';
	import RoutePanel from '$lib/components/RoutePanel.svelte';
	import StatusBar from '$lib/components/StatusBar.svelte';
	import StoryFeed from '$lib/components/StoryFeed.svelte';
	import { appendStoryBeat, openingBeat, restartBeatsFor, type StoryBeat } from '$lib/game/content';
	import { createOdinEngine, parseSeed } from '$lib/game/engine';
	import type { GameSnapshot, OdinEngine } from '$lib/game/types';
	import { onMount } from 'svelte';

	let snapshot = $state<GameSnapshot | null>(null);
	let engine = $state<OdinEngine | null>(null);
	let beats = $state<StoryBeat[]>([openingBeat]);
	let engineState = $state<'loading' | 'ready' | 'error'>('loading');
	let engineError = $state('');
	let introVisible = $state(true);
	let replacingActStory = false;
	const hushStages = [
		'hush_departure',
		'hush_streets',
		'hush_loudspeakers',
		'hush_dead_zone',
		'hush_approach',
		'encounter'
	];

	function isHushStage(stage: string) {
		return hushStages.includes(stage);
	}

	function receiveSnapshot(next: GameSnapshot) {
		snapshot = next;
		if (replacingActStory) {
			beats = restartBeatsFor(next);
			replacingActStory = false;
			return;
		}
		beats = appendStoryBeat(beats, next.event);
	}

	function sendCommand(command: string) {
		if (!engine || engineState !== 'ready') return;
		engine.dispatch(command);
	}

	function restartAct() {
		if (!engine || !snapshot || snapshot.running || engineState !== 'ready') return;
		replacingActStory = true;
		engine.dispatch('restart act');
	}

	function resetGame() {
		if (!engine || !snapshot) return;
		replacingActStory = false;
		introVisible = true;
		beats = [openingBeat];
		engine.reset(parseSeed(snapshot.seed));
	}

	function completeIntro() {
		introVisible = false;
	}

	onMount(() => {
		let mounted = true;
		const requestedSeed = parseSeed(new URLSearchParams(window.location.search).get('seed'));

		createOdinEngine(`${base}/game.wasm`, requestedSeed, (next) => {
			if (mounted) receiveSnapshot(next);
		})
			.then((loaded) => {
				if (!mounted) {
					loaded.destroy();
					return;
				}
				engine = loaded;
				engineState = 'ready';
			})
			.catch((error: unknown) => {
				engineError = error instanceof Error ? error.message : 'The engine could not start';
				engineState = 'error';
			});

		return () => {
			mounted = false;
			engine?.destroy();
		};
	});
</script>

<svelte:head>
	<title>MALLA: Before the Silence</title>
	<meta
		name="description"
		content="A political cyberpunk thriller about crossing an occupied city before its civic network goes silent."
	/>
	<meta name="theme-color" content="#03070a" />
</svelte:head>

{#if engineState === 'error'}
	<main class="boot-screen error-screen">
		<div class="boot-logo"><span></span><span></span><span></span></div>
		<p>BOOT FAILURE / WASM</p>
		<h1>CTRL17 DOES NOT RESPOND</h1>
		<pre>{engineError}</pre>
		<p>Run <code>pnpm run wasm:build</code> and reload the page.</p>
	</main>
{:else if !snapshot}
	<main class="boot-screen">
		<div class="boot-logo"><span></span><span></span><span></span></div>
		<p>MALLA FIELD TERMINAL / COLD BOOT</p>
		<h1>RESTORING SIGNAL<span class="blink">_</span></h1>
		<div class="boot-progress"><i></i></div>
		<small>loading game.wasm · verifying CTRL17 · locating REP06</small>
	</main>
{:else if introVisible}
	<IntroSequence onComplete={completeIntro} />
{:else if snapshot.stage === 'encounter'}
	<EndingScreen onReset={resetGame} />
{:else}
	<div
		class:actFour={['carrier_ready', 'carrier_locked'].includes(snapshot.stage)}
		class:hushMode={isHushStage(snapshot.stage)}
		class:hushDeep={['hush_dead_zone', 'hush_approach'].includes(snapshot.stage)}
		class="game-shell"
	>
		<StatusBar {snapshot} />

		<main class="workspace">
			<NetworkMap {snapshot} />
			<StoryFeed
				{beats}
				{snapshot}
				onCommand={sendCommand}
				onRestartAct={restartAct}
				onReset={resetGame}
			/>
			{#if isHushStage(snapshot.stage)}
				<HushPanel {snapshot} />
			{:else if snapshot.stage === 'carrier_ready' || snapshot.stage === 'carrier_locked'}
				<CarrierPanel {snapshot} />
			{:else if snapshot.stage === 'act_three_travel' || snapshot.stage === 'at_service_corridor' || snapshot.stage === 'corridor_scanned' || snapshot.stage === 'flow_ready' || snapshot.stage === 'act_three_complete'}
				<FlowPanel {snapshot} />
			{:else if snapshot.stage === 'route_ready' || snapshot.stage === 'route_in_transit' || snapshot.stage === 'at_interchange' || snapshot.stage === 'interchange_scanned' || snapshot.stage === 'transit_connected' || snapshot.stage === 'act_two_complete'}
				<RoutePanel {snapshot} />
			{:else}
				<EvidencePanel {snapshot} />
			{/if}
		</main>

		{#if !isHushStage(snapshot.stage)}
			<CommandDock
				{snapshot}
				onCommand={sendCommand}
				onRestartAct={restartAct}
				onReset={resetGame}
			/>
		{/if}
	</div>
{/if}
