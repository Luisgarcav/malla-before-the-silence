<script lang="ts">
	import { createRouteDossier, routeBundleText, type RouteEdge } from '$lib/game/route';
	import type { GameSnapshot } from '$lib/game/types';
	import HudFrame from '$lib/components/ui/HudFrame.svelte';

	let { snapshot }: { snapshot: GameSnapshot } = $props();

	let copyStatus = $state('');
	let dossier = $derived(createRouteDossier(snapshot.evidence));
	let routeStatus = $derived.by(() => {
		switch (snapshot.stage) {
			case 'route_ready':
				return 'ROUTE PENDING';
			case 'route_in_transit':
				return 'CROSSING ACTIVE';
			case 'at_interchange':
			case 'interchange_scanned':
			case 'transit_connected':
				return 'DESTINATION REACHED';
			case 'act_two_complete':
				return 'ACT II COMPLETE';
			default:
				return 'ROUTE APPLIED';
		}
	});

	function closureLabel(edge: RouteEdge): string {
		if (edge.closedFrom === 'OPEN') return 'OPEN';
		return `${edge.closedFrom} TO ${edge.closedTo}`;
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
		const value = routeBundleText(dossier.sources);
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
		const blob = new Blob([routeBundleText(dossier.sources)], {
			type: 'text/plain;charset=utf-8'
		});
		const url = URL.createObjectURL(blob);
		const link = document.createElement('a');
		link.href = url;
		link.download = `route_cr02_${snapshot.seed}.txt`;
		link.click();
		URL.revokeObjectURL(url);
	}
</script>

<HudFrame className="tech-panel route-panel" labelledby="route-tech-title">
	<h2 id="route-tech-title" class="panel-title">TECH <span>|</span> CR02</h2>

	<div class="tech-body route-tech-body">
		{#if dossier.ready}
			<div class="evidence-topline">
				<div class="evidence-summary">
					<span>CITY DOSSIER / 4 SOURCES</span>
					<strong>{routeStatus}</strong>
				</div>
				<div class="evidence-tools">
					<button class="copy-everything" type="button" onclick={copyAll}>
						<span>{copyStatus || 'COPY ALL'}</span>
						<small>4 SOURCES</small>
					</button>
					<button class="export-evidence" type="button" onclick={downloadAll}>EXPORT</button>
				</div>
			</div>

			<section class="route-brief" aria-labelledby="route-brief-title">
				<header>
					<span>CHALLENGE 02 / MOBILITY / EXPERT</span>
					<strong>{dossier.routeId} · {dossier.edgeCount} SEGMENTS</strong>
				</header>
				<h3 id="route-brief-title">Find a route robust to uncertain travel time.</h3>
				<p>
					Choose connected segments from <b>{dossier.origin}</b> to
					<b>{dossier.destination}</b>. The clock begins at <b>{dossier.clockOrigin}</b> and advances
					through an interval for every segment you cross.
				</p>

				<div class="route-facts">
					<div><span>START</span><strong>{dossier.origin}</strong></div>
					<div><span>DESTINATION</span><strong>{dossier.destination}</strong></div>
					<div><span>CLOCK</span><strong>{dossier.clockOrigin}</strong></div>
				</div>

				<div class="route-delivery">
					<strong>WHAT TO SUBMIT</strong>
					<p>
						Write only node names, in order, separated by <code>&gt;</code>.
					</p>
					<code class="route-example">WORKSHOP&gt;MARKET&gt;INTERCHANGE</code>
					<small>The interface adds “route ellie”. Do not enter minutes, costs, or commas.</small>
				</div>

				<ul class="route-rules">
					<li><b>Segments are directed.</b> WORKSHOP→MARKET does not authorize MARKET→WORKSHOP.</li>
					<li><b>Check closure at departure.</b> First add the minutes already traveled.</li>
					<li>
						<b>Optimize the worst case.</b> Routes within the published minimax margin advance.
					</li>
				</ul>
			</section>

			<section class="route-source" aria-labelledby="route-table-title">
				<header>
					<h3 id="route-table-title">CONSOLIDATED NETWORK</h3>
					<span>DIRECTED EDGES</span>
				</header>
				<p>
					Each row is an allowed segment. TIME is the modeled duration interval. A route is unsafe
					if any possible departure overlaps a closure.
				</p>
				<div class="route-table-wrap">
					<table>
						<thead>
							<tr>
								<th>SEGMENT</th>
								<th>TIME RANGE</th>
								<th>CLOSURE</th>
								<th>TRACE</th>
								<th>CONFIDENCE</th>
								<th>AGE</th>
							</tr>
						</thead>
						<tbody>
							{#each dossier.edges as edge (`${edge.from}>${edge.to}`)}
								<tr class:scheduled={edge.closedFrom !== 'OPEN'}>
									<td><strong>{edge.from}</strong><i>→</i><strong>{edge.to}</strong></td>
									<td>{edge.minutes}..{edge.minutes + edge.delayMax}</td>
									<td>{closureLabel(edge)}</td>
									<td>{edge.trace}</td>
									<td>{edge.confidence.replace('_', ' ')}</td>
									<td>{edge.ageMinutes}m</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</section>

			<section class="route-policy" aria-labelledby="route-policy-title">
				<header>
					<h3 id="route-policy-title">HOW COST IS CALCULATED</h3>
					<span>POLICY 3.1</span>
				</header>
				<code>ROBUST COST = WORST-CASE ARRIVAL + 4 × TRACE</code>
				<div>
					<span>CONFIRMED <b>+0</b></span>
					<span>PROBABLE <b>+3</b></span>
					<span>UNVERIFIED <b>+8</b></span>
				</div>
				<p>
					Confidence and age determine DELAY_MAX. Propagate earliest/latest arrival and reject any
					path whose departure interval can touch a closure; code is recommended.
				</p>
			</section>
		{:else}
			<div class="evidence-locked">
				<span>CITY DOSSIER / 4 SOURCES</span>
				<strong>CR02 UNAVAILABLE</strong>
				<p>{snapshot.objective}</p>
			</div>
		{/if}
	</div>
</HudFrame>
