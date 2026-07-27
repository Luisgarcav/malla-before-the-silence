export type RouteSourceId = 'edges' | 'closures' | 'reports' | 'policy';

export interface RouteSources {
	edges: string;
	closures: string;
	reports: string;
	policy: string;
}

export interface RouteEdge {
	from: string;
	to: string;
	minutes: number;
	delayMax: number;
	closedFrom: string;
	closedTo: string;
	trace: number;
	confidence: string;
	ageMinutes: number;
}

export interface RouteDossier {
	ready: boolean;
	routeId: string;
	origin: string;
	destination: string;
	clockOrigin: string;
	edgeCount: number;
	edges: RouteEdge[];
	policy: string;
	sources: RouteSources;
}

const sourceIds: RouteSourceId[] = ['edges', 'closures', 'reports', 'policy'];

export function parseRouteSources(bundle: string): RouteSources {
	const sources: RouteSources = { edges: '', closures: '', reports: '', policy: '' };
	const marker = /^---ROUTE-SOURCE:(EDGES|CLOSURES|REPORTS|POLICY)---$/gm;
	const matches = [...bundle.matchAll(marker)];

	for (const [index, match] of matches.entries()) {
		const source = match[1].toLowerCase() as RouteSourceId;
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

export function createRouteDossier(bundle: string): RouteDossier {
	const sources = parseRouteSources(bundle);
	const closures = new Map(
		pipeRows(sources.closures, 'FROM|TO|CLOSED_FROM|CLOSED_TO').map((row) => [
			`${row[0]}>${row[1]}`,
			row
		])
	);
	const reports = new Map(
		pipeRows(sources.reports, 'FROM|TO|TRACE|CONFIDENCE|AGE_MIN|DELAY_MAX').map((row) => [
			`${row[0]}>${row[1]}`,
			row
		])
	);
	const edges = pipeRows(sources.edges, 'FROM|TO|MINUTES').map((row) => {
		const key = `${row[0]}>${row[1]}`;
		const closure = closures.get(key) ?? [];
		const report = reports.get(key) ?? [];
		return {
			from: row[0] ?? '',
			to: row[1] ?? '',
			minutes: Number(row[2] ?? 0),
			delayMax: Number(report[5] ?? 0),
			closedFrom: closure[2] ?? '',
			closedTo: closure[3] ?? '',
			trace: Number(report[2] ?? 0),
			confidence: report[3] ?? '',
			ageMinutes: Number(report[4] ?? 0)
		};
	});

	return {
		ready: sourceIds.every((source) => sources[source].length > 0) && edges.length > 0,
		routeId: field(sources.edges, 'route_id'),
		origin: field(sources.edges, 'origin'),
		destination: field(sources.edges, 'destination'),
		clockOrigin: field(sources.edges, 'clock_origin'),
		edgeCount: Number(field(sources.edges, 'edge_count')),
		edges,
		policy: sources.policy,
		sources
	};
}

export function routeBundleText(sources: RouteSources): string {
	return sourceIds
		.map((source) => `=== ${source.toUpperCase()} ===\n${sources[source].replaceAll('-', '−')}`)
		.join('\n\n');
}
