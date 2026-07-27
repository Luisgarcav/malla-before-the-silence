export type FlowSourceId = 'interfaces' | 'telemetry' | 'reservations' | 'repair' | 'policy';

export interface FlowSources {
	interfaces: string;
	telemetry: string;
	reservations: string;
	repair: string;
	policy: string;
}

export interface FlowLink {
	id: string;
	from: string;
	to: string;
	physical: number;
	observed: number;
	service: string;
	protected: number;
	residual: number;
	headroom: number;
	plannable: number;
	unitCost: number;
}

export interface FlowDossier {
	ready: boolean;
	incidentId: string;
	source: string;
	destination: string;
	nodeCount: number;
	edgeCount: number;
	demand: number;
	nodes: string[];
	links: FlowLink[];
	repairLines: string[];
	policy: string;
	sources: FlowSources;
}

const sourceIds: FlowSourceId[] = ['interfaces', 'telemetry', 'reservations', 'repair', 'policy'];

export function parseFlowSources(bundle: string): FlowSources {
	const sources: FlowSources = {
		interfaces: '',
		telemetry: '',
		reservations: '',
		repair: '',
		policy: ''
	};
	const marker = /^---FLOW-SOURCE:(INTERFACES|TELEMETRY|RESERVATIONS|REPAIR|POLICY)---$/gm;
	const matches = [...bundle.matchAll(marker)];

	for (const [index, match] of matches.entries()) {
		const source = match[1].toLowerCase() as FlowSourceId;
		const start = (match.index ?? 0) + match[0].length;
		const end = matches[index + 1]?.index ?? bundle.length;
		sources[source] = bundle.slice(start, end).trim();
	}

	return sources;
}

function field(source: string, name: string): string {
	return source.match(new RegExp(`^${name}=([^\\n]+)$`, 'm'))?.[1]?.trim() ?? '';
}

function pipeRows(source: string, header: string): string[][] {
	const lines = source.split('\n');
	const headerIndex = lines.findIndex((line) => line.trim() === header);
	if (headerIndex < 0) return [];
	return lines
		.slice(headerIndex + 1)
		.map((line) => line.trim())
		.filter(Boolean)
		.map((line) => line.split('|').map((value) => value.trim()));
}

export function createFlowDossier(bundle: string): FlowDossier {
	const sources = parseFlowSources(bundle);
	const telemetry = new Map(
		pipeRows(sources.telemetry, 'LINK|PHYSICAL|OBSERVED|CAPTURED_AT').map((row) => [row[0], row])
	);
	const reservations = new Map(
		pipeRows(
			sources.reservations,
			'LINK|SERVICE|PROTECTED|RESIDUAL|HEADROOM|PLANNABLE|UNIT_COST'
		).map((row) => [row[0], row])
	);
	const links = pipeRows(sources.interfaces, 'LINK|FROM|TO').map((row) => {
		const capacity = telemetry.get(row[0]) ?? [];
		const reservation = reservations.get(row[0]) ?? [];
		return {
			id: row[0] ?? '',
			from: row[1] ?? '',
			to: row[2] ?? '',
			physical: Number(capacity[1] ?? 0),
			observed: Number(capacity[2] ?? 0),
			service: reservation[1] ?? '',
			protected: Number(reservation[2] ?? 0),
			residual: Number(reservation[3] ?? 0),
			headroom: Number(reservation[4] ?? 0),
			plannable: Number(reservation[5] ?? 0),
			unitCost: Number(reservation[6] ?? 0)
		};
	});
	const nodes = [...new Set(links.flatMap((link) => [link.from, link.to]))];

	return {
		ready: sourceIds.every((source) => sources[source].length > 0) && links.length > 0,
		incidentId: field(sources.interfaces, 'incident_id'),
		source: field(sources.interfaces, 'source'),
		destination: field(sources.interfaces, 'destination'),
		nodeCount: Number(field(sources.interfaces, 'node_count')),
		edgeCount: Number(field(sources.interfaces, 'edge_count')),
		demand: Number(field(sources.policy, 'minimum_demand')),
		nodes,
		links,
		repairLines: sources.repair.split('\n').filter((line) => /^22:/.test(line)),
		policy: sources.policy,
		sources
	};
}

export function flowBundleText(sources: FlowSources): string {
	return sourceIds
		.map((source) => `=== ${source.toUpperCase()} ===\n${sources[source].replaceAll('-', '−')}`)
		.join('\n\n');
}
