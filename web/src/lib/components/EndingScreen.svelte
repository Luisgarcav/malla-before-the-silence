<script lang="ts">
	import mallaLogo from '$lib/assets/malla-logo.svg';

	let { onReset }: { onReset: () => void } = $props();
</script>

<main class="ending-screen" aria-labelledby="ending-title">
	<div class="ending-grid" aria-hidden="true"></div>
	<div class="ending-signal" aria-hidden="true">
		<i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i>
	</div>

	<header class="ending-header">
		<span>22:31 / REPEATER 06</span>
		<strong>VISUAL CONTACT CONFIRMED</strong>
	</header>

	<section class="ending-encounter" aria-label="Ellie and Tom reunite">
		<p class="tom">TOM&gt; You made it.</p>
		<p class="ellie">ELLIE&gt; So did you.</p>
	</section>

	<section class="ending-message">
		<span>END OF ACT V / HUSH</span>
		<h1 id="ending-title">THANKS FOR PLAYING</h1>
		<img class="ending-logo" src={mallaLogo} alt="MALLA: Before the Silence" />
		<p>
			The city is still occupied. They did not stop the coup. They kept their promise and reached
			the same place before dawn.
		</p>
	</section>

	<footer class="ending-footer">
		<div>
			<span>PROMISE</span>
			<strong>KEPT</strong>
		</div>
		<div>
			<span>SIGNAL</span>
			<strong>COMPLETE</strong>
		</div>
		<button type="button" onclick={onReset}>PLAY AGAIN</button>
	</footer>
</main>
