<script lang="ts">
	import { beaconBundleText, createBeaconDossier } from '$lib/game/beacon';
	import type { GameSnapshot } from '$lib/game/types';
	import HudFrame from '$lib/components/ui/HudFrame.svelte';

	let { snapshot }: { snapshot: GameSnapshot } = $props();

	let copyStatus = $state('');
	let dossier = $derived(createBeaconDossier(snapshot.evidence));
	let carrierStatus = $derived(
		snapshot.stage === 'carrier_locked' ? 'CARRIER LOCKED' : 'NO CARRIER LOCK'
	);

	function technicalNumber(value: number): string {
		return String(value).replace('-', '−');
	}

	function technicalRange(value: string): string {
		return value.replaceAll('-', '−');
	}

	function fallbackCopy(value: string): boolean {
		const textarea = document.createElement('textarea');
		try {
			textarea.value = value;
			textarea.setAttribute('readonly', '');
			textarea.style.position = 'fixed';
			textarea.style.opacity = '0';
			document.body.appendChild(textarea);
			textarea.select();
			return document.execCommand('copy');
		} catch {
			return false;
		} finally {
			textarea.remove();
		}
	}

	async function copyAll() {
		if (!dossier.ready) return;
		const value = beaconBundleText(dossier.sources);
		try {
			if (!navigator.clipboard) throw new Error('Clipboard API unavailable');
			await navigator.clipboard.writeText(value);
			copyStatus = 'COPIED';
		} catch {
			copyStatus = fallbackCopy(value) ? 'COPIED' : 'UNAVAILABLE';
		}
		window.setTimeout(() => (copyStatus = ''), 1800);
	}

	function downloadAll() {
		if (!dossier.ready) return;
		const blob = new Blob([beaconBundleText(dossier.sources)], {
			type: 'text/plain;charset=utf-8'
		});
		const url = URL.createObjectURL(blob);
		const link = document.createElement('a');
		link.href = url;
		link.download = `bcnr6_${snapshot.seed}.txt`;
		link.click();
		URL.revokeObjectURL(url);
	}
</script>

<HudFrame className="tech-panel carrier-panel" labelledby="carrier-tech-title">
	<h2 id="carrier-tech-title" class="panel-title">TECH <span>|</span> BCNR6</h2>

	<div class="tech-body carrier-tech-body">
		{#if dossier.ready}
			<div class="evidence-topline">
				<div class="evidence-summary">
					<span>CARRIER DOSSIER / 5 SOURCES</span>
					<strong>{carrierStatus}</strong>
				</div>
				<div class="evidence-tools">
					<button class="copy-everything" type="button" onclick={copyAll}>
						<span>{copyStatus || 'COPY ALL'}</span>
						<small>5 SOURCES</small>
					</button>
					<button class="export-evidence" type="button" onclick={downloadAll}>EXPORT</button>
				</div>
			</div>

			<section class="route-brief carrier-brief" aria-labelledby="carrier-brief-title">
				<header>
					<span>CHALLENGE 04 / LAST CARRIER / EXPERT</span>
					<strong>{dossier.incidentId} · {dossier.copyCount} ECHOES</strong>
				</header>
				<h3 id="carrier-brief-title">Recover the frame with bit-level likelihoods.</h3>
				<p>
					Weak copies are the majority, but carry less evidence. Reconstruct every <b>bit</b> from signed
					LLR weights, enforce the confidence threshold, then verify CRC‑16.
				</p>

				<div class="flow-facts carrier-facts">
					<div><span>RECEIVER</span><strong>{dossier.receiver}</strong></div>
					<div><span>FRAME</span><strong>{dossier.frameOctets} BYTES</strong></div>
					<div><span>COPIES</span><strong>{dossier.copyCount}</strong></div>
					<div><span>CENTRAL INTEGRITY</span><strong>{dossier.centralIntegrity}</strong></div>
				</div>

				<div class="route-delivery carrier-delivery">
					<strong>WHAT TO SUBMIT</strong>
					<p>Extract CHANNEL, CLOCK_OFFSET_MS, frozen REPETITION_ID, and CRC16.</p>
					<code class="route-example"
						>&lt;CHANNEL&gt; &lt;OFFSET_MS&gt; &lt;REPETITION_ID&gt; &lt;CRC16_HEX&gt;</code
					>
					<small>The interface adds “tune rep06”. CRC uses exactly four hex digits.</small>
				</div>

				<ul class="route-rules carrier-rules">
					<li><b>Use signed evidence.</b> Add +LLR for a 1 and −LLR for a 0 at every bit.</li>
					<li>
						<b>Require confidence.</b> Every absolute LLR sum must reach {dossier.minimumMargin}.
					</li>
					<li><b>Verify locally.</b> CRC‑16/CCITT covers octets 0 through 13.</li>
					<li>
						<b>Decode the fields.</b> Offset is signed int16; repetition ID is unsigned uint16.
					</li>
				</ul>
			</section>

			<section class="route-source carrier-capture" aria-labelledby="carrier-capture-title">
				<header>
					<h3 id="carrier-capture-title">01 / DIVERSITY CAPTURE</h3>
					<span>{dossier.capturedAt} · dBm</span>
				</header>
				<p>
					Every row is a reception of the same frame. A less negative RSSI indicates a stronger
					signal.
				</p>
				<div class="route-table-wrap carrier-table-wrap">
					<table>
						<thead>
							<tr
								><th>ECHO</th><th>ARRIVAL</th><th>RSSI</th><th>BIT p(error)</th><th>LLR×100</th><th
									>FRAME / 16 HEX OCTETS</th
								></tr
							>
						</thead>
						<tbody>
							{#each dossier.echoes as echo (echo.id)}
								<tr>
									<td><strong>{echo.id}</strong></td>
									<td>{echo.arrivedAt}</td>
									<td class:weak-signal={echo.rssi < -80}>{technicalNumber(echo.rssi)} dBm</td>
									<td>{echo.bitErrorProbability.toFixed(3)}</td>
									<td>{echo.llrWeight}</td>
									<td><code>{echo.frame}</code></td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</section>

			<section class="route-source carrier-calibration" aria-labelledby="calibration-title">
				<header>
					<h3 id="calibration-title">02 / RECEIVER CALIBRATION</h3>
					<span>LAST 60 MIN</span>
				</header>
				<p>Convert each hard bit into signed evidence using its receiver error probability.</p>
				<div class="calibration-grid">
					{#each dossier.bands as band (band.range)}
						<div class:discarded={band.weight === 0}>
							<span>{technicalRange(band.range)} dBm</span>
							<strong>LLR×100 {band.weight}</strong>
							<small>BIT ERROR {(band.errorRate * 100).toFixed(1)}%</small>
						</div>
					{/each}
				</div>
			</section>

			<section class="route-source carrier-spec" aria-labelledby="carrier-spec-title">
				<header>
					<h3 id="carrier-spec-title">03 / BCNR6 STRUCTURE</h3>
					<span>BIG ENDIAN</span>
				</header>
				<div class="route-table-wrap carrier-field-wrap">
					<table>
						<thead><tr><th>FIELD</th><th>OCTETS</th><th>ENCODING</th></tr></thead>
						<tbody>
							{#each dossier.fields as field (field.name)}
								<tr
									><td><strong>{field.name}</strong></td><td>{field.octets}</td><td
										>{field.encoding}</td
									></tr
								>
							{/each}
						</tbody>
					</table>
				</div>
				<code class="carrier-lrc">CRC16_CCITT(OCTETS 0..13) = OCTETS 14..15</code>
			</section>

			<section class="route-policy carrier-policy" aria-labelledby="carrier-policy-title">
				<header>
					<h3 id="carrier-policy-title">04 / CARRIER LOCK CONDITION</h3>
					<span>ATTEMPTS LOGGED</span>
				</header>
				<code
					>CHANNEL {dossier.channelMin}..{dossier.channelMax} · OFFSET {technicalNumber(
						dossier.offsetMin
					)}..{technicalNumber(dossier.offsetMax)}
					ms · REPETITION 0..65535</code
				>
				<p>
					A value outside range is rejected at no cost. An incorrect physical value begins a scan,
					consumes window, and leaves trace. CRC16 is a four-digit hexadecimal token from the same
					reconstructed frame.
				</p>
			</section>
		{:else}
			<div class="evidence-locked">
				<span>CARRIER DOSSIER / 5 SOURCES</span>
				<strong>BCNR6 UNAVAILABLE</strong>
				<p>{snapshot.objective}</p>
			</div>
		{/if}
	</div>
</HudFrame>
