<script lang="ts">
	import { hudObjectiveFor, panelActionsFor, type StoryBeat } from '$lib/game/content';
	import type { GameSnapshot } from '$lib/game/types';
	import HudFrame from '$lib/components/ui/HudFrame.svelte';
	import HudButton from '$lib/components/ui/HudButton.svelte';
	import { tick } from 'svelte';

	let {
		beats,
		snapshot,
		onCommand,
		onRestartAct,
		onReset
	}: {
		beats: StoryBeat[];
		snapshot: GameSnapshot;
		onCommand: (command: string) => void;
		onRestartAct: () => void;
		onReset: () => void;
	} = $props();

	let historyElement: HTMLDivElement | undefined;
	let objective = $derived(hudObjectiveFor(snapshot));
	let actions = $derived(panelActionsFor(snapshot));

	function runAction(command: string) {
		if (command === '__restart_act__') onRestartAct();
		else if (command === '__reset__') onReset();
		else onCommand(command);
	}

	$effect(() => {
		const historyLength = beats.length;
		if (!historyElement || historyLength === 0) return;

		void tick().then(() => {
			const latestEntry = historyElement?.lastElementChild;
			if (historyElement && latestEntry instanceof HTMLElement) {
				historyElement.scrollTop = latestEntry.offsetTop;
			}
		});
	});
</script>

<HudFrame className="narrative-panel" labelledby="narrative-title" tone="focus">
	<h2 id="narrative-title" class="panel-title narrative-title">NARRATIVE</h2>

	<div class="narrative-body">
		<div class="current-objective">
			<div class="objective-label"><i></i><span>CURRENT OBJECTIVE</span></div>
			<h3>{objective.title}</h3>
			<p>{objective.body}</p>
		</div>

		<div class="story-history-heading">
			<span>STORY LOG</span>
			<strong>{beats.length} {beats.length === 1 ? 'SCENE' : 'SCENES'}</strong>
		</div>

		<div
			class="story-history"
			bind:this={historyElement}
			role="log"
			aria-label="Complete story history"
			aria-live="polite"
			aria-relevant="additions"
		>
			{#each beats as beat, index (beat.id)}
				<article class:latest={index === beats.length - 1} class="story-entry">
					<header>
						<time>{beat.time}</time>
						<div>
							<span>{beat.place}</span>
							<strong>{beat.title}</strong>
						</div>
						<small>{String(index + 1).padStart(2, '0')}</small>
					</header>

					<div class="story-lines">
						{#each beat.lines as line, lineIndex (`${beat.id}-${lineIndex}`)}
							<p class={line.tone}>{line.text}</p>
						{/each}
					</div>
				</article>
			{/each}
		</div>

		{#if actions.length > 0}
			<div class="narrative-actions" aria-label="Actions for the current scene">
				{#each actions as action, index (action.command)}
					<HudButton
						type="button"
						variant={index === 0 ? 'primary' : 'ghost'}
						onclick={() => runAction(action.command)}
					>
						<small>{index === 0 ? 'A / PRIMARY' : 'B / OPTION'}</small>
						<strong>{action.label}</strong>
					</HudButton>
				{/each}
			</div>
		{/if}
	</div>
</HudFrame>
