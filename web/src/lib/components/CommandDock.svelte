<script lang="ts">
	import { actionsFor, feedbackTitle, type ActionDefinition } from '$lib/game/content';
	import {
		fieldIntelMessageFor,
		hasHintAccess,
		hintLevelFor,
		livesRemaining
	} from '$lib/game/fieldIntel';
	import type { GameSnapshot } from '$lib/game/types';
	import HudButton from '$lib/components/ui/HudButton.svelte';
	import { tick } from 'svelte';

	let {
		snapshot,
		onCommand,
		onRestartAct,
		onReset
	}: {
		snapshot: GameSnapshot;
		onCommand: (command: string) => void;
		onRestartAct: () => void;
		onReset: () => void;
	} = $props();

	let command = $state('');
	let isRepair = $derived(snapshot.stage === 'packet_ready');
	let isRoute = $derived(snapshot.stage === 'route_ready');
	let isFlow = $derived(snapshot.stage === 'flow_ready');
	let isTune = $derived(snapshot.stage === 'carrier_ready');
	let routeContext = $derived(snapshot.stage === 'route_ready');
	let flowContext = $derived(
		snapshot.stage === 'flow_ready' || snapshot.stage === 'act_three_complete'
	);
	let carrierContext = $derived(
		snapshot.stage === 'carrier_ready' || snapshot.stage === 'carrier_locked'
	);
	let hushContext = $derived(
		[
			'hush_departure',
			'hush_streets',
			'hush_loudspeakers',
			'hush_dead_zone',
			'hush_approach',
			'encounter'
		].includes(snapshot.stage)
	);
	let commandDisabled = $derived(
		!snapshot.running ||
			snapshot.stage === 'prototype_complete' ||
			snapshot.stage === 'act_two_complete' ||
			snapshot.stage === 'act_three_complete' ||
			snapshot.stage === 'carrier_locked' ||
			[
				'hush_departure',
				'hush_streets',
				'hush_loudspeakers',
				'hush_dead_zone',
				'hush_approach',
				'encounter'
			].includes(snapshot.stage)
	);
	let quickActions = $derived(quickActionsFor(snapshot));
	let validation = $derived(validationFor(snapshot));
	let intelMessage = $derived(fieldIntelMessageFor(snapshot, validation.label));
	let hintLevel = $derived(hintLevelFor(snapshot.event));
	let hintsAvailable = $derived(hasHintAccess(snapshot.stage));
	let lives = $derived(snapshot.running ? livesRemaining(snapshot.exposure) : 0);
	let copyStatus = $state('');
	const hintLevels = [1, 2, 3, 4, 5];

	function quickActionsFor(state: GameSnapshot): ActionDefinition[] {
		if (!state.running) {
			return [{ label: 'restart act', command: '__restart_act__' }];
		}
		const stageActions = actionsFor(state);
		if (stageActions.length > 0) return stageActions;
		if (state.stage === 'packet_ready') {
			return [
				{ label: 'evidence', command: 'evidence capture' },
				{ label: 'hint', command: 'hint' },
				{ label: 'log', command: 'log' },
				{ label: 'disconnect', command: 'disconnect' }
			];
		}
		if (state.stage === 'route_ready') {
			return [
				{ label: 'hint', command: 'hint' },
				{ label: 'log', command: 'log' }
			];
		}
		if (state.stage === 'flow_ready') {
			return [
				{ label: 'hint', command: 'hint' },
				{ label: 'log', command: 'log' },
				{ label: 'disconnect', command: 'disconnect' }
			];
		}
		if (state.stage === 'carrier_ready') {
			return [
				{ label: 'evidence', command: 'evidence capture' },
				{ label: 'hint', command: 'hint' },
				{ label: 'log', command: 'log' },
				{ label: 'disconnect', command: 'disconnect' }
			];
		}
		return [
			{ label: 'log', command: 'log' },
			{ label: 'reset', command: '__reset__' }
		];
	}

	function validationFor(state: GameSnapshot): {
		label: string;
		tone: 'idle' | 'success' | 'warning' | 'danger';
	} {
		if (!state.running || state.event === 'failure')
			return { label: 'INTERCEPTED', tone: 'danger' };
		if (state.event === 'repair_valid' || state.stage === 'prototype_complete') {
			return { label: 'FRAGMENT VERIFIED', tone: 'success' };
		}
		if (state.event === 'repair_format_invalid') return { label: 'FORMAT ERROR', tone: 'warning' };
		if (state.event === 'repair_impossible') return { label: 'DATA REJECTED', tone: 'danger' };
		if (state.event === 'route_format_invalid') return { label: 'FORMAT ERROR', tone: 'warning' };
		if (state.event === 'route_impossible') return { label: 'ROUTE REJECTED', tone: 'danger' };
		if (state.event === 'route_suboptimal')
			return { label: 'OUTSIDE ROBUST MARGIN', tone: 'danger' };
		if (state.stage === 'act_two_complete') return { label: 'ACT II COMPLETE', tone: 'success' };
		if (state.event === 'route_optimal') {
			return { label: 'ROUTE APPLIED', tone: 'success' };
		}
		if (state.stage === 'route_ready') return { label: 'AWAITING ROUTE', tone: 'idle' };
		if (state.event === 'flow_format_invalid') return { label: 'FORMAT ERROR', tone: 'warning' };
		if (state.event === 'flow_impossible') return { label: 'FLOW REJECTED', tone: 'danger' };
		if (state.event === 'flow_insufficient') return { label: 'INSUFFICIENT', tone: 'warning' };
		if (state.event === 'flow_suboptimal') return { label: 'COST NOT MINIMAL', tone: 'danger' };
		if (state.event === 'flow_optimal' || state.stage === 'act_three_complete') {
			return { label: 'ACT III COMPLETE', tone: 'success' };
		}
		if (state.stage === 'flow_ready') return { label: 'AWAITING ALLOCATION', tone: 'idle' };
		if (state.event === 'tune_format_invalid') return { label: 'FORMAT ERROR', tone: 'warning' };
		if (state.event === 'tune_impossible') return { label: 'NO CARRIER LOCK', tone: 'danger' };
		if (state.event === 'tune_valid' || state.stage === 'carrier_locked') {
			return { label: 'CARRIER LOCKED', tone: 'success' };
		}
		if (state.stage === 'carrier_ready') return { label: 'AWAITING TUNE', tone: 'idle' };
		if (state.stage === 'encounter') return { label: 'ENCOUNTER', tone: 'success' };
		if (
			[
				'hush_departure',
				'hush_streets',
				'hush_loudspeakers',
				'hush_dead_zone',
				'hush_approach'
			].includes(state.stage)
		) {
			return { label: 'HUSH / NO TECH INPUT', tone: 'idle' };
		}
		if (state.stage === 'packet_ready') return { label: 'AWAITING FRAGMENT', tone: 'idle' };
		return { label: feedbackTitle(state.event), tone: 'idle' };
	}

	function runQuickAction(action: ActionDefinition) {
		if (action.command === '__restart_act__') onRestartAct();
		else if (action.command === '__reset__') onReset();
		else onCommand(action.command);
	}

	async function copyIntel() {
		if (!intelMessage) return;
		const value = `${intelMessage.title}\n\n${intelMessage.body}`;
		try {
			await navigator.clipboard.writeText(value);
			copyStatus = 'COPIED';
		} catch {
			copyStatus = 'COPY FAILED';
		}
		window.setTimeout(() => (copyStatus = ''), 1800);
	}

	async function submit(event: SubmitEvent) {
		event.preventDefault();
		const value = command.trim();
		if (!value || commandDisabled) return;

		const routeSubmission = isRoute;
		const flowSubmission = isFlow;
		const tuneSubmission = isTune;
		onCommand(
			isRepair
				? `repair emr06 ${value}`
				: isRoute
					? `route ellie ${value}`
					: isFlow
						? `allocate rep06 ${value}`
						: isTune
							? `tune rep06 ${value}`
							: value
		);
		await tick();
		if (
			!isRepair &&
			(!routeSubmission || snapshot.stage !== 'route_ready') &&
			(!flowSubmission || snapshot.stage !== 'flow_ready') &&
			(!tuneSubmission || snapshot.stage !== 'carrier_ready')
		) {
			command = '';
		}
	}
</script>

<footer class="challenge-workbench">
	<form class="repair-command" onsubmit={submit}>
		<div class="command-heading">
			<span
				>{isRepair
					? 'COMMAND / ANSWER'
					: routeContext
						? 'COMMAND / ROUTE'
						: flowContext
							? 'COMMAND / ALLOCATION'
							: carrierContext
								? 'COMMAND / TUNING'
								: hushContext
									? 'MOVEMENT / NARRATIVE'
									: 'COMMAND / ACTION'}</span
			>
			<strong
				>{isRepair
					? '64 HEX REQUIRED'
					: routeContext
						? 'NODE CHAIN REQUIRED'
						: flowContext
							? 'POSITIVE LINK ASSIGNMENTS'
							: carrierContext
								? 'CHANNEL + OFFSET + REPEAT ID + CRC16'
								: hushContext
									? 'TECHNICAL INPUT DISABLED'
									: snapshot.objective}</strong
			>
		</div>

		<div class="command-row">
			<label for="game-command"
				>{isRepair
					? 'repair emr06'
					: routeContext
						? 'route ellie'
						: flowContext
							? 'allocate rep06'
							: carrierContext
								? 'tune rep06'
								: hushContext
									? 'field / walk'
									: 'malla / run'}</label
			>
			<input
				id="game-command"
				bind:value={command}
				maxlength={isRepair ? 64 : 256}
				placeholder={isRepair
					? '0000000000000000000000000000000000000000000000000000000000000000'
					: routeContext
						? 'WORKSHOP>...>INTERCHANGE'
						: flowContext
							? 'P:S>A=...,A>B=...,...;B:S>C=...,C>D=...,...'
							: carrierContext
								? 'CHANNEL OFFSET_MS REPETITION_ID CRC16_HEX'
								: hushContext
									? 'NO TECHNICAL INPUT'
									: snapshot.nextCommand || 'command'}
				autocomplete="off"
				spellcheck="false"
				disabled={commandDisabled}
			/>
			<HudButton type="submit" variant="primary" disabled={commandDisabled}>
				{isRepair
					? 'VALIDATE'
					: routeContext
						? 'APPLY ROUTE'
						: flowContext
							? 'ALLOCATE'
							: carrierContext
								? 'TUNE'
								: hushContext
									? 'LOCKED'
									: 'EXECUTE'}
			</HudButton>
		</div>

		<div class="quick-commands">
			<span>QUICK:</span>
			{#each quickActions as action (action.command)}
				<button type="button" onclick={() => runQuickAction(action)}>{action.label}</button>
			{/each}
		</div>
	</form>

	<aside
		class:success={validation.tone === 'success'}
		class:warning={validation.tone === 'warning'}
		class:danger={validation.tone === 'danger'}
		class:showing-hint={intelMessage?.isHint}
		class="field-intel"
		aria-live="polite"
	>
		<div class="intel-topline">
			<span>{intelMessage?.isHint ? 'GUIDANCE / NO COST' : 'FIELD STATUS'}</span>
			<small title={snapshot.connection}>{snapshot.connection}</small>
		</div>

		<div class="resource-grid" aria-label="Remaining game resources">
			<div class:critical={snapshot.window <= 1}>
				<span>TIME LEFT</span>
				<strong>{Math.max(0, snapshot.window)} <small>TURNS</small></strong>
			</div>
			<div class:critical={lives <= 1}>
				<span>LIVES</span>
				<strong>{lives} <small>/ 3</small></strong>
			</div>
			<div>
				<span>EXPOSURE</span>
				<strong>{snapshot.exposure}</strong>
			</div>
		</div>

		{#if intelMessage}
			<section class:hint-message={intelMessage.isHint} class="intel-message">
				<header>
					<div class="validation-state"><i></i><strong>{intelMessage.title}</strong></div>
					{#if intelMessage.isHint}
						<button type="button" onclick={copyIntel}>{copyStatus || 'COPY'}</button>
					{/if}
				</header>
				<p>{intelMessage.body}</p>
			</section>
		{:else}
			<div class="next-action">
				<span>NEXT ACTION</span>
				<code>{snapshot.nextCommand || 'NO ACTION REQUIRED'}</code>
			</div>
		{/if}

		{#if hintsAvailable}
			<nav class="hint-levels" aria-label="Open a hint level">
				<span>HINT LEVEL</span>
				{#each hintLevels as level (level)}
					<button
						type="button"
						class:active={hintLevel === level}
						onclick={() => onCommand(`hint ${level}`)}
						aria-label={`Open hint ${level}`}>{level}</button
					>
				{/each}
			</nav>
		{/if}
	</aside>
</footer>
