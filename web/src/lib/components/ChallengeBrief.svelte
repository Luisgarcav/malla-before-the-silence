<script lang="ts">
	import type { EvidenceDossier } from '$lib/game/evidence';

	let { dossier }: { dossier: EvidenceDossier } = $props();

	let missingSlots = $derived(dossier.missingSlots.length ? dossier.missingSlots : ['D?', 'D?']);
	let missingLabel = $derived(missingSlots.join(' + '));
	let octets = $derived(dossier.octetsPerSlot || '16');
	let blockCount = $derived(Number(dossier.dataSlots) || 12);
	let finalBlock = $derived(`D${blockCount - 1}`);
	let hexDigits = $derived((Number(octets) || 16) * 2);
</script>

<section class="challenge-brief" aria-labelledby="challenge-brief-title">
	<header class="challenge-brief-header">
		<span>ACTIVE CHALLENGE · EXPERT / CODE RECOMMENDED</span>
		<strong>DATA RECOVERY / EMR06</strong>
	</header>

	<h3 id="challenge-brief-title">Recover blocks {missingLabel}.</h3>
	<p class="challenge-summary">
		The opaque record was split into {blockCount} blocks, D0 through {finalBlock}, with {octets}
		bytes each.
		<strong>{missingLabel} did not arrive.</strong> Syndromes P and Q did arrive and contain RAID-6 recovery
		data. Neither is part of the original message.
	</p>

	<div class="challenge-facts" aria-label="Problem summary">
		<div>
			<span>MISSING DATA</span>
			<strong>{missingLabel}</strong>
			<small>{octets} bytes each</small>
		</div>
		<div>
			<span>RECOVERY DATA</span>
			<strong>P + Q</strong>
			<small>GF(2⁸) syndromes</small>
		</div>
		<div>
			<span>SUBMISSION</span>
			<strong>{hexDigits * 2} HEX</strong>
			<small>no separators</small>
		</div>
	</div>

	<div class="delivery-spec">
		<strong>WHAT TO SUBMIT</strong>
		<p>
			The two reconstructed blocks concatenated as <b>{hexDigits * 2} hexadecimal digits</b>:
			{missingSlots[0]} first, then {missingSlots[1]}. Do not submit P/Q, ASCII text, a
			<code>0x</code> prefix, spaces, or separators.
		</p>
	</div>

	<div class="source-guide" aria-label="How to read the sources">
		<strong>HOW TO READ THE DOSSIER</strong>
		<ol>
			<li>
				<b>Capture:</b> identifies which blocks arrived and which one is marked ERASURE.
			</li>
			<li><b>Protocol:</b> documents the P/Q equations over GF(2⁸), byte by byte.</li>
			<li><b>RX log:</b> confirms that data was lost during reception.</li>
			<li><b>Integrity:</b> verifies the complete reconstructed record.</li>
		</ol>
	</div>

	<p class="external-work-note">
		You can copy or export all four sources and work outside the game with any tool you prefer. The
		game only needs the two recovered blocks. This requires solving {octets} finite-field systems; a script
		is the intended tool.
	</p>
	<span class="sources-next" aria-hidden="true">↓ TECHNICAL SOURCES BELOW</span>
</section>
