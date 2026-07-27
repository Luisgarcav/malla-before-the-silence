<script lang="ts">
	import mallaLogo from '$lib/assets/malla-logo.svg';
	import { introChapters } from '$lib/game/intro';
	import { tick } from 'svelte';

	let { onComplete }: { onComplete: () => void } = $props();

	let index = $state(0);
	let headingElement = $state<HTMLHeadingElement>();
	let current = $derived(introChapters[index]);
	let isLast = $derived(index === introChapters.length - 1);

	function goTo(nextIndex: number) {
		index = Math.max(0, Math.min(nextIndex, introChapters.length - 1));
	}

	function next() {
		if (isLast) onComplete();
		else goTo(index + 1);
	}

	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'ArrowRight') {
			event.preventDefault();
			next();
		}
		if (event.key === 'ArrowLeft') {
			event.preventDefault();
			goTo(index - 1);
		}
	}

	$effect(() => {
		const activeIndex = index;
		void tick().then(() => {
			if (activeIndex === index) headingElement?.focus({ preventScroll: true });
		});
	});
</script>

<svelte:window onkeydown={handleKeydown} />

<section class={`intro-screen intro-${current.tone}`} aria-labelledby="intro-title">
	<div class="intro-grid" aria-hidden="true"></div>
	<div class="intro-scan" aria-hidden="true"></div>

	<header class="intro-header">
		<div class="intro-brand">
			<img class="intro-logo" src={mallaLogo} alt="MALLA: Before the Silence" />
			<span>CONTEXT ARCHIVE / READ ONLY</span>
		</div>
		<button type="button" class="intro-skip" onclick={onComplete}>SKIP INTRO</button>
	</header>

	<div class="intro-layout">
		{#key current.id}
			<article class="intro-copy">
				<div class="intro-meta">
					<span>{current.eyebrow}</span>
					<time>{current.time}</time>
				</div>
				<h1 id="intro-title" bind:this={headingElement} tabindex="-1">{current.title}</h1>
				<div class="intro-text">
					{#each current.body as paragraph (paragraph)}
						<p>{paragraph}</p>
					{/each}
				</div>

				<dl class="intro-facts">
					{#each current.facts as fact (fact.label)}
						<div>
							<dt>{fact.label}</dt>
							<dd>{fact.value}</dd>
						</div>
					{/each}
				</dl>
			</article>

			<aside class="intro-visual" aria-label={current.diagram.label}>
				<div class="intro-visual-heading">
					<span>TOPOLOGY / CONTEXT</span>
					<strong>{String(index + 1).padStart(2, '0')}</strong>
				</div>
				<svg viewBox="0 0 520 360" role="img" aria-label={current.diagram.label}>
					<path
						class="intro-grid-line"
						d="M30 60H490M30 120H490M30 180H490M30 240H490M30 300H490"
					/>
					<path
						class="intro-grid-line"
						d="M80 30V330M170 30V330M260 30V330M350 30V330M440 30V330"
					/>
					<path class="intro-route underlay" d="M82 248L260 112L438 248" />
					<path class="intro-route signal" d="M82 248L260 112L438 248" />
					<circle class="intro-node secondary" cx="82" cy="248" r="13" />
					<circle class="intro-node primary" cx="260" cy="112" r="18" />
					<circle class="intro-node secondary" cx="438" cy="248" r="13" />
					<circle class="intro-pulse" cx="260" cy="112" r="32" />
					<text x="45" y="284">{current.diagram.left}</text>
					<text class="center" x="260" y="70">{current.diagram.center}</text>
					<text class="right" x="475" y="284">{current.diagram.right}</text>
					<text class="coordinates" x="30" y="337">SOURCE / PARTIAL</text>
					<text class="coordinates right" x="490" y="337">ROUTE / UNCONFIRMED</text>
				</svg>
				<div class="intro-readout">
					<i></i>
					<span>{current.final ? 'LIVE SIGNAL PENDING' : 'ARCHIVE FRAGMENT RECOVERED'}</span>
				</div>
			</aside>
		{/key}
	</div>

	<footer class="intro-footer">
		<div
			class="intro-progress"
			aria-label={`Introduction: part ${index + 1} of ${introChapters.length}`}
		>
			<span
				>{String(index + 1).padStart(2, '0')} / {String(introChapters.length).padStart(
					2,
					'0'
				)}</span
			>
			<div>
				{#each introChapters as chapter, chapterIndex (chapter.id)}
					<button
						type="button"
						class:active={chapterIndex === index}
						class:read={chapterIndex < index}
						onclick={() => goTo(chapterIndex)}
						aria-label={`Go to part ${chapterIndex + 1}: ${chapter.title}`}
						aria-current={chapterIndex === index ? 'step' : undefined}
					></button>
				{/each}
			</div>
		</div>

		<div class="intro-nav">
			<button
				type="button"
				class="intro-back"
				onclick={() => goTo(index - 1)}
				disabled={index === 0}
			>
				BACK
			</button>
			<button type="button" class="intro-next" onclick={next}>
				<span>{isLast ? 'OPEN TERMINAL' : 'CONTINUE'}</span>
				<i aria-hidden="true">→</i>
			</button>
		</div>
	</footer>
</section>
