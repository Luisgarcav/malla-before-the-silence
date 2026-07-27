<script lang="ts">
	import ChallengeBrief from '$lib/components/ChallengeBrief.svelte';
	import HudFrame from '$lib/components/ui/HudFrame.svelte';
	import {
		createEvidenceDossier,
		evidenceBundleText,
		type CaptureRow,
		type EvidenceDossier
	} from '$lib/game/evidence';
	import type { GameSnapshot } from '$lib/game/types';

	let { snapshot }: { snapshot: GameSnapshot } = $props();

	let copyStatus = $state('');
	let dossier: EvidenceDossier = $derived(createEvidenceDossier(snapshot.evidence));
	let open = $derived(snapshot.stage === 'packet_ready' || snapshot.stage === 'prototype_complete');

	function compactFormula(formula: string): string {
		return formula.replace(/D\[(\d+)]\[j]/g, 'D$1[j]');
	}

	function compactDiagnostic(line: string): string {
		return line.replace(/\s+/g, ' ').replace('seq=', 'SEQ ').replace('record ', '').toUpperCase();
	}

	function statusLabel(status: CaptureRow['status']): string {
		switch (status) {
			case 'RECEIVED':
				return 'RECEIVED';
			case 'ERASURE':
				return 'ERASURE';
			case 'RECOVERY':
				return 'RECOVERY';
		}
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
		const value = evidenceBundleText(dossier.sources);
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
		const blob = new Blob([evidenceBundleText(dossier.sources)], {
			type: 'text/plain;charset=utf-8'
		});
		const url = URL.createObjectURL(blob);
		const link = document.createElement('a');
		link.href = url;
		link.download = `emr06_${snapshot.seed}.txt`;
		link.click();
		URL.revokeObjectURL(url);
	}
</script>

<HudFrame
	className={`tech-panel ${open && dossier.ready ? '' : 'tech-panel--locked'}`}
	labelledby="tech-title"
>
	<h2 id="tech-title" class="panel-title">TECH <span>|</span> EMR06</h2>

	<div class="tech-body">
		{#if open && dossier.ready}
			<div class="evidence-topline">
				<div class="evidence-summary">
					<span>DOSSIER / 4 SOURCES</span>
					<strong>{dossier.erasureCount} ERASURES</strong>
				</div>
				<div class="evidence-tools">
					<button class="copy-everything" type="button" onclick={copyAll}>
						<span>{copyStatus || 'COPY ALL'}</span>
						<small>4 SOURCES</small>
					</button>
					<button class="export-evidence" type="button" onclick={downloadAll}>EXPORT</button>
				</div>
			</div>

			<ChallengeBrief {dossier} />

			<section class="evidence-source capture-source" aria-labelledby="capture-title">
				<header>
					<h3 id="capture-title">01 / RECEIVED CAPTURE</h3>
					<span>HEX OCTETS</span>
				</header>
				<p class="source-explanation">
					Each D row is one message block. Rows marked <b>ERASURE</b> contain X characters because those
					bytes are missing. P and Q are independent recovery syndromes received separately.
				</p>
				<div class="capture-meta">
					<span>{dossier.dataSlots} BLOCKS × {dossier.octetsPerSlot} BYTES</span>
					<span>CAPTURE {dossier.capturedAt}</span>
				</div>
				<div class="capture-rows">
					<div class="capture-columns" aria-hidden="true">
						<span>BLOCK</span>
						<span>SEQ</span>
						<span>STATUS</span>
						<span>HEX DATA</span>
					</div>
					{#each dossier.rows as row (row.slot)}
						<div class:erasure={row.status === 'ERASURE'} class="capture-row">
							<strong>{row.slot}</strong>
							<span>{row.sequence}</span>
							<span>{statusLabel(row.status)}</span>
							<code>{row.data}</code>
						</div>
					{/each}
				</div>
			</section>

			<section class="evidence-source protocol-source" aria-labelledby="protocol-title">
				<header>
					<h3 id="protocol-title">02 / PROTOCOL</h3>
					<span>MESH ER2</span>
				</header>
				<p class="source-explanation">
					The specification defines P and Q for each position <b>j</b>. P uses XOR; Q multiplies
					each data octet by its coefficient in GF(2⁸). Together they separate two unknown blocks.
				</p>
				<code class="protocol-formula">{compactFormula(dossier.formula)}</code>
				<p class="source-footnote">BYTE BY BYTE / TWO RECOVERABLE ERASURES / GF POLY 0x11D</p>
			</section>

			<section class="evidence-source diagnostic-source" aria-labelledby="diagnostic-title">
				<header>
					<h3 id="diagnostic-title">03 / RX LOG</h3>
					<span>CTRL17</span>
				</header>
				<p class="source-explanation">
					This log confirms where the loss occurred and that R was accepted before the controller
					stopped assembly.
				</p>
				{#each dossier.diagnosticLines as line, index (index)}
					<code class:warning={index === 0}>{compactDiagnostic(line)}</code>
				{/each}
			</section>

			<section class="evidence-source integrity-source" aria-labelledby="integrity-title">
				<header>
					<h3 id="integrity-title">04 / INTEGRITY</h3>
					<span>CRC32 / ISO HDLC</span>
				</header>
				<p class="source-explanation">
					The expected CRC verifies all {dossier.dataSlots} original blocks in order. It is calculated
					over real bytes, not characters in hexadecimal text.
				</p>
				<div><span>EXPECTED CRC</span><code>{dossier.integrityExpected}</code></div>
				<div><span>ORDER</span><code>{dossier.integrityScope}</code></div>
				<p class="source-footnote">BINARY BYTES / NO HEX TEXT OR SEPARATORS</p>
			</section>
		{:else}
			<div class="evidence-locked">
				<span>DOSSIER / 4 SOURCES</span>
				<div class="lock-grid" aria-hidden="true">
					<i></i><i></i><i></i><i></i>
				</div>
				<strong>EMR06 LOCKED</strong>
				<p>{snapshot.objective}</p>
				<small>OPEN A LOCAL CTRL17 SESSION, THEN INSPECT EMR06.</small>
			</div>
		{/if}
	</div>
</HudFrame>
