<script lang="ts">
	import type { GameSnapshot } from '$lib/game/types';
	import HudFrame from '$lib/components/ui/HudFrame.svelte';

	let { snapshot }: { snapshot: GameSnapshot } = $props();
	type MapPoint = { x: number; y: number };

	function cityPosition(location: string): MapPoint {
		switch (location) {
			case 'MARKET':
				return { x: 85, y: 269 };
			case 'BRIDGE':
				return { x: 121, y: 207 };
			case 'DEPOT':
				return { x: 188, y: 180 };
			case 'TUNNEL':
				return { x: 44, y: 96 };
			case 'PLAZA':
				return { x: 154, y: 70 };
			case 'RAIL':
				return { x: 232, y: 122 };
			case 'TRANSIT INTERCHANGE':
				return { x: 278, y: 70 };
			default:
				return { x: 34, y: 302 };
		}
	}

	let atWorkshop = $derived(snapshot.stage !== 'evacuation');
	let signalRecovered = $derived(snapshot.stage === 'prototype_complete');
	let actTwo = $derived(
		[
			'route_ready',
			'route_in_transit',
			'at_interchange',
			'interchange_scanned',
			'transit_connected',
			'act_two_complete'
		].includes(snapshot.stage)
	);
	let actThree = $derived(
		[
			'act_three_travel',
			'at_service_corridor',
			'corridor_scanned',
			'flow_ready',
			'act_three_complete'
		].includes(snapshot.stage)
	);
	let finalRoute = $derived(
		[
			'carrier_ready',
			'carrier_locked',
			'hush_departure',
			'hush_streets',
			'hush_loudspeakers',
			'hush_dead_zone',
			'hush_approach',
			'encounter'
		].includes(snapshot.stage)
	);
	let activeCity = $derived(cityPosition(snapshot.location));
	let atInterchange = $derived(snapshot.location === 'TRANSIT INTERCHANGE');
	let tomAtSubstation = $derived(snapshot.stage === 'act_two_complete');
	let atCorridor = $derived(snapshot.location === 'SERVICE CORRIDOR');
	let gatewayKnown = $derived(
		['corridor_scanned', 'flow_ready', 'act_three_complete'].includes(snapshot.stage)
	);
	let carrierLocked = $derived(
		[
			'carrier_locked',
			'hush_departure',
			'hush_streets',
			'hush_loudspeakers',
			'hush_dead_zone',
			'hush_approach',
			'encounter'
		].includes(snapshot.stage)
	);
	let hushWalk = $derived(
		[
			'hush_departure',
			'hush_streets',
			'hush_loudspeakers',
			'hush_dead_zone',
			'hush_approach',
			'encounter'
		].includes(snapshot.stage)
	);
	let finalSignalStatus = $derived(
		snapshot.stage === 'encounter'
			? 'VISUAL CONTACT'
			: snapshot.stage === 'hush_loudspeakers'
				? 'FINAL ORDER ACTIVE'
				: ['hush_dead_zone', 'hush_approach'].includes(snapshot.stage)
					? 'MALLA OUT OF RANGE'
					: carrierLocked
						? 'CARRIER OPEN'
						: 'CARRIER LOST'
	);
	let repeaterOnline = $derived(snapshot.stage === 'act_three_complete' || carrierLocked);
	let finalPosition = $derived.by<MapPoint>(() => {
		switch (snapshot.stage) {
			case 'hush_streets':
				return { x: 142, y: 202 };
			case 'hush_loudspeakers':
				return { x: 177, y: 139 };
			case 'hush_dead_zone':
				return { x: 217, y: 99 };
			case 'hush_approach':
				return { x: 257, y: 87 };
			case 'encounter':
				return { x: 277, y: 76 };
			default:
				return { x: 92, y: 250 };
		}
	});
	let echoTime = $derived(
		finalRoute
			? snapshot.stage === 'encounter'
				? '22:31:00'
				: snapshot.stage === 'hush_approach'
					? '22:29:12'
					: snapshot.stage === 'hush_dead_zone'
						? '22:27:04'
						: snapshot.stage === 'hush_loudspeakers'
							? '22:25:31'
							: snapshot.stage === 'hush_streets'
								? '22:23:18'
								: snapshot.stage === 'hush_departure'
									? '22:20:08'
									: carrierLocked
										? '22:19:44'
										: '22:18:05'
			: actThree
				? repeaterOnline
					? '22:17:03'
					: '22:14:52'
				: actTwo
					? tomAtSubstation
						? '22:06:11'
						: '21:58:17'
					: signalRecovered
						? '21:42:00'
						: atWorkshop
							? '00:18:42'
							: 'NO SIGNAL'
	);
</script>

<HudFrame className="map-panel" labelledby="map-title">
	<h2 id="map-title" class="panel-title">
		MAP <span>|</span>
		{finalRoute
			? 'FINAL APPROACH'
			: actThree
				? 'DATA CORRIDOR'
				: actTwo
					? 'CITY ROUTE'
					: 'SECTOR 04'}
	</h2>

	<div class="map-body">
		<svg class="route-map" viewBox="0 0 317 356" role="img" aria-labelledby="route-title">
			<title id="route-title"
				>{finalRoute
					? 'Final walk from the service corridor to Repeater 06'
					: actThree
						? 'Physical access to GWT08 and the data path toward REP06'
						: actTwo
							? 'City overview from the workshop to the transit interchange'
							: 'Route from entry to the last known signal'}</title
			>
			{#if actThree || finalRoute}
				<path class="city-road wide" d="M37 304L92 250L142 202" />
				<path
					class="city-road"
					d="M142 202L177 139L229 176L277 76M142 202L217 99L277 76M177 139L217 99M229 176L277 76"
				/>
				<path class:resolved={gatewayKnown} class="city-vector" d="M37 304L92 250L142 202" />
				<path
					class:resolved={repeaterOnline}
					class="route-signal flow-channel"
					d="M142 202L177 139L217 99L277 76M142 202L229 176L277 76"
				/>

				<circle class="route-node" cx="37" cy="304" r="5" />
				<circle class="route-node" cx="92" cy="250" r="5" />
				<circle class:resolved={gatewayKnown} class="route-node echo" cx="142" cy="202" r="7" />
				<circle class="route-node" cx="177" cy="139" r="5" />
				<circle class="route-node" cx="217" cy="99" r="5" />
				<circle class="route-node" cx="229" cy="176" r="5" />
				<circle class:resolved={repeaterOnline} class="route-node echo" cx="277" cy="76" r="8" />

				<circle
					class="route-node active"
					cx={finalRoute ? finalPosition.x : atCorridor ? 92 : 37}
					cy={finalRoute ? finalPosition.y : atCorridor ? 250 : 304}
					r="10"
				/>
				<text
					class="route-label active-label"
					x={finalRoute ? Math.min(finalPosition.x + 14, 250) : atCorridor ? 108 : 53}
					y={finalRoute ? finalPosition.y - 8 : atCorridor ? 242 : 296}>ELLIE</text
				>

				<circle
					class="tom-node"
					cx={finalRoute && snapshot.stage === 'encounter' ? 277 : 282}
					cy={finalRoute && snapshot.stage === 'encounter' ? 76 : 42}
					r="6"
				/>
				<path class="tom-vector" d="M282 42L277 76" />
				<text class="route-label map-place-label" x="17" y="329">INTERCHANGE</text>
				<text class="route-label map-place-label" x="100" y="224">CORRIDOR</text>
				<text class="route-label echo-label" x="151" y="217">GWT08</text>
				<text class="route-label echo-label" x="239" y="65">REP06</text>
				<text class="route-label tom-label" x="184" y="26"
					>TOM / {finalRoute
						? snapshot.stage === 'encounter'
							? 'REP06'
							: 'NO RESPONSE'
						: 'SUBSTATION'}</text
				>
				<text class="map-warning" x="18" y="54"
					>{finalRoute ? finalSignalStatus : 'UNREGISTERED CHANNEL'}</text
				>
			{:else if actTwo}
				<path class="city-road wide" d="M34 302L85 269L121 207L188 180L232 122L278 70" />
				<path
					class="city-road"
					d="M44 96L85 269M44 96L154 70L232 122M121 207L58 178M121 207L246 270M188 180L278 222M154 70L188 180"
				/>
				<path
					class:resolved={atInterchange}
					class="city-vector"
					d="M34 302L85 269L121 207L188 180L232 122L278 70"
				/>
				<path class="tom-vector" d="M278 70L284 31" />

				<circle class="route-node" cx="34" cy="302" r="5" />
				<circle class="route-node" cx="85" cy="269" r="5" />
				<circle class="route-node" cx="121" cy="207" r="5" />
				<circle class="route-node" cx="188" cy="180" r="5" />
				<circle class="route-node" cx="44" cy="96" r="5" />
				<circle class="route-node" cx="154" cy="70" r="5" />
				<circle class="route-node" cx="232" cy="122" r="5" />
				<circle class="route-node echo resolved" cx="278" cy="70" r="7" />

				<circle class="route-node active" cx={activeCity.x} cy={activeCity.y} r="10" />
				<text
					class="route-label active-label"
					x={Math.min(activeCity.x + 14, 250)}
					y={activeCity.y - 8}>ELLIE</text
				>

				<circle class="tom-node" cx="284" cy={tomAtSubstation ? 31 : 46} r="6" />
				<text class="route-label map-place-label" x="18" y="329">WORKSHOP</text>
				<text class="route-label map-place-label" x="196" y="91">INTERCHANGE</text>
				<text class="route-label tom-label" x="218" y="22"
					>TOM / {tomAtSubstation ? 'SUBSTATION' : 'EST. POSITION'}</text
				>
				<text class="map-warning" x="20" y="48">CLOSURES IN PROGRESS</text>
			{:else}
				<path class="route-bed" d="M36 306L88 244L68 169L156 116L232 157L274 75" />
				<path
					class:resolved={signalRecovered}
					class="route-signal"
					d="M36 306L88 244L68 169L156 116L232 157L274 75"
				/>
				<path class="route-branch" d="M68 169L36 103M156 116L149 46M232 157L277 224" />

				<circle class="route-node entry" cx="36" cy="306" r="8" />
				<circle class="route-node" cx="88" cy="244" r="6" />
				<circle class="route-node" cx="68" cy="169" r="6" />
				<circle class="route-node" cx="232" cy="157" r="6" />
				<circle class:resolved={signalRecovered} class="route-node echo" cx="274" cy="75" r="6" />

				{#if atWorkshop}
					<circle class="route-node active" cx="156" cy="116" r="9" />
					<text class="route-label active-label" x="172" y="107">YOU</text>
				{:else}
					<circle class="route-node active" cx="36" cy="306" r="9" />
					<text class="route-label active-label" x="54" y="300">YOU</text>
				{/if}

				<text class="route-label" x="18" y="335">ENTRY</text>
				<text class="route-label echo-label" x="245" y="58">ECHO</text>
			{/if}
		</svg>

		<div class="map-footer">
			<div>
				<span
					>{hushWalk
						? 'HUSH / LOCAL TIME'
						: finalRoute
							? 'BCNR6 / LAST ECHO'
							: actThree || actTwo
								? 'TOM / LAST ECHO'
								: 'LAST ECHO'}</span
				>
				<strong>{echoTime}</strong>
			</div>
			<div class="map-location">
				<span>POSITION</span>
				<strong>{snapshot.location}</strong>
				<small class:online={snapshot.connection !== 'DISCONNECTED'}>{snapshot.connection}</small>
			</div>
		</div>
	</div>
</HudFrame>
