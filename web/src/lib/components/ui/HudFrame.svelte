<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		children,
		className = '',
		labelledby,
		tone = 'system'
	}: {
		children: Snippet;
		className?: string;
		labelledby: string;
		tone?: 'system' | 'focus' | 'quiet';
	} = $props();
</script>

<section class={`hud-frame hud-panel hud-frame--${tone} ${className}`} aria-labelledby={labelledby}>
	<div class="hud-frame__rail hud-frame__rail--top" aria-hidden="true"><i></i><i></i></div>
	<div class="hud-frame__rail hud-frame__rail--bottom" aria-hidden="true"><i></i><i></i></div>
	<span class="hud-frame__corner hud-frame__corner--top-left" aria-hidden="true"></span>
	<span class="hud-frame__corner hud-frame__corner--top-right" aria-hidden="true"></span>
	<span class="hud-frame__corner hud-frame__corner--bottom-left" aria-hidden="true"></span>
	<span class="hud-frame__corner hud-frame__corner--bottom-right" aria-hidden="true"></span>
	{@render children()}
</section>
