<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLButtonAttributes } from 'svelte/elements';

	let {
		children,
		variant = 'ghost',
		class: className = '',
		...buttonProps
	}: HTMLButtonAttributes & {
		children: Snippet;
		variant?: 'ghost' | 'primary' | 'quiet';
	} = $props();
</script>

<button {...buttonProps} class={`hud-button hud-button--${variant} ${className}`}>
	<span class="hud-button__edge" aria-hidden="true"></span>
	{@render children()}
</button>
