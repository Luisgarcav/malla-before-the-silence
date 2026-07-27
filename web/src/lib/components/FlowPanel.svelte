<script lang="ts">
	import { createFlowDossier, flowBundleText } from '$lib/game/flow';
	import type { GameSnapshot } from '$lib/game/types';
	import HudFrame from '$lib/components/ui/HudFrame.svelte';

	let { snapshot }: { snapshot: GameSnapshot } = $props();

	let copyStatus = $state('');
	let dossier = $derived(createFlowDossier(snapshot.evidence));
	let flowStatus = $derived(
		snapshot.stage === 'act_three_complete' ? 'REP06 CHANNEL OPEN' : 'ALLOCATION PENDING'
	);

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
		const value = flowBundleText(dossier.sources);
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
		const blob = new Blob([flowBundleText(dossier.sources)], {
			type: 'text/plain;charset=utf-8'
		});
		const url = URL.createObjectURL(blob);
		const link = document.createElement('a');
		link.href = url;
		link.download = `cap03_${snapshot.seed}.txt`;
		link.click();
		URL.revokeObjectURL(url);
	}
</script>

<HudFrame className="tech-panel flow-panel" labelledby="flow-tech-title">
	<h2 id="flow-tech-title" class="panel-title">TECH <span>|</span> CAP03</h2>

	<div class="tech-body flow-tech-body">
		{#if dossier.ready}
			<div class="evidence-topline">
				<div class="evidence-summary">
					<span>CAPACITY DOSSIER / 5 SOURCES</span>
					<strong>{flowStatus}</strong>
				</div>
				<div class="evidence-tools">
					<button class="copy-everything" type="button" onclick={copyAll}>
						<span>{copyStatus || 'COPY ALL'}</span>
						<small>5 SOURCES</small>
					</button>
					<button class="export-evidence" type="button" onclick={downloadAll}>EXPORT</button>
				</div>
			</div>

			<section class="route-brief flow-brief" aria-labelledby="flow-brief-title">
				<header>
					<span>CHALLENGE 03 / SURVIVABLE MIN-COST FLOW / EXPERT</span>
					<strong>{dossier.incidentId} · {dossier.edgeCount} LINKS</strong>
				</header>
				<h3 id="flow-brief-title">Reserve primary and failover flows at minimum cost.</h3>
				<p>
					Build two link-disjoint plans from <b>{dossier.source}</b> to
					<b>{dossier.destination}</b>. Each must carry <b>{dossier.demand} units</b>, preserve
					headroom, and the pair must minimize total unit cost.
				</p>

				<div class="flow-facts">
					<div><span>SOURCE</span><strong>{dossier.source}</strong></div>
					<div><span>DESTINATION</span><strong>{dossier.destination}</strong></div>
					<div><span>DEMAND / PLAN</span><strong>{dossier.demand}</strong></div>
					<div><span>NODES</span><strong>{dossier.nodeCount}</strong></div>
				</div>

				<div class="route-delivery flow-delivery">
					<strong>WHAT TO SUBMIT</strong>
					<p>
						Prefix the primary plan with <code>P:</code>, the backup with <code>B:</code>, and
						separate them with a semicolon. Use commas within each plan.
					</p>
					<code class="route-example"
						>P:S&gt;A=&lt;N&gt;,A&gt;B=&lt;N&gt;,...;B:S&gt;C=&lt;N&gt;,C&gt;D=&lt;N&gt;,...</code
					>
					<small>The interface adds “allocate rep06”. Do not declare the total or zero links.</small
					>
				</div>

				<ul class="route-rules flow-rules">
					<li><b>Use PLANNABLE.</b> Protected traffic and headroom are unavailable.</li>
					<li><b>Survive one failure.</b> P and B may not share a directed link.</li>
					<li><b>Minimize cost.</b> Sum allocation × unit cost across both complete plans.</li>
				</ul>
			</section>

			<section class="route-source flow-source" aria-labelledby="flow-table-title">
				<header>
					<h3 id="flow-table-title">CONSOLIDATED DATA NETWORK</h3>
					<span>S → T / DIRECTED</span>
				</header>
				<p>
					PHYSICAL includes civil traffic. RESIDUAL removes it; PLANNABLE also preserves mandatory
					HEADROOM. UNIT COST applies to every reserved unit in either plan.
				</p>
				<div class="route-table-wrap flow-table-wrap">
					<table>
						<thead>
							<tr>
								<th>LINK</th>
								<th>PATH</th>
								<th>PHYSICAL</th>
								<th>PROTECTED</th>
								<th>RESIDUAL</th>
								<th>HEADROOM</th>
								<th>PLANNABLE</th>
								<th>COST/U</th>
							</tr>
						</thead>
						<tbody>
							{#each dossier.links as link (link.id)}
								<tr>
									<td>{link.id}</td>
									<td><strong>{link.from}</strong><i>→</i><strong>{link.to}</strong></td>
									<td>{link.physical}</td>
									<td>{link.service} / {link.protected}</td>
									<td>{link.residual}</td>
									<td>{link.headroom}</td>
									<td class="residual-value">{link.plannable}</td>
									<td>{link.unitCost}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</section>

			<section class="flow-repair" aria-labelledby="repair-log-title">
				<header>
					<h3 id="repair-log-title">TOM PHYSICAL REPAIR</h3>
					<span>REP06 / TXTOM04</span>
				</header>
				<p>
					Power is restored. This challenge distributes communications traffic and does not model
					the electrical network.
				</p>
				<div>
					{#each dossier.repairLines as line (line)}
						<code>{line}</code>
					{/each}
				</div>
			</section>

			<section class="route-policy flow-policy" aria-labelledby="flow-policy-title">
				<header>
					<h3 id="flow-policy-title">CONTROLLER RULES</h3>
					<span>REP06 / DEMAND {dossier.demand}</span>
				</header>
				<code>P ∩ B = ∅ · FLOW(P) ≥ DEMAND · FLOW(B) ≥ DEMAND</code>
				<p>
					Conservation applies separately to both plans. GWT08 derives throughput and total cost;
					only a minimum-cost N−1 reservation opens the channel.
				</p>
			</section>
		{:else}
			<div class="evidence-locked">
				<span>CAPACITY DOSSIER / 5 SOURCES</span>
				<strong>CAP03 UNAVAILABLE</strong>
				<p>{snapshot.objective}</p>
			</div>
		{/if}
	</div>
</HudFrame>
