export type BeaconSourceId = 'context' | 'capture' | 'diagnostic' | 'protocol' | 'policy';

export interface BeaconSources {
	context: string;
	capture: string;
	diagnostic: string;
	protocol: string;
	policy: string;
}

export interface BeaconEcho {
	id: string;
	arrivedAt: string;
	rssi: number;
	bitErrorProbability: number;
	llrWeight: number;
	frame: string;
}

export interface ReliabilityBand {
	range: string;
	errorRate: number;
	weight: number;
}

export interface BeaconField {
	name: string;
	octets: string;
	encoding: string;
}

export interface BeaconDossier {
	ready: boolean;
	incidentId: string;
	receiver: string;
	capturedAt: string;
	frameOctets: number;
	copyCount: number;
	carrierLock: string;
	centralIntegrity: string;
	returnChannel: string;
	echoes: BeaconEcho[];
	bands: ReliabilityBand[];
	fields: BeaconField[];
	channelMin: number;
	channelMax: number;
	offsetMin: number;
	offsetMax: number;
	minimumMargin: number;
	sources: BeaconSources;
}

const sourceIds: BeaconSourceId[] = ['context', 'capture', 'diagnostic', 'protocol', 'policy'];

export function parseBeaconSources(bundle: string): BeaconSources {
	const sources: BeaconSources = {
		context: '',
		capture: '',
		diagnostic: '',
		protocol: '',
		policy: ''
	};
	const marker = /^---BEACON-SOURCE:(CONTEXT|CAPTURE|DIAGNOSTIC|PROTOCOL|POLICY)---$/gm;
	const matches = [...bundle.matchAll(marker)];

	for (const [index, match] of matches.entries()) {
		const source = match[1].toLowerCase() as BeaconSourceId;
		const start = (match.index ?? 0) + match[0].length;
		const end = matches[index + 1]?.index ?? bundle.length;
		sources[source] = bundle.slice(start, end).trim();
	}

	return sources;
}

function field(source: string, name: string): string {
	return source.match(new RegExp(`^${name}=([^\n]+)$`, 'm'))?.[1]?.trim() ?? '';
}

function pipeRows(source: string, header: string): string[][] {
	const lines = source.split('\n');
	const headerIndex = lines.findIndex((line) => line.trim() === header);
	if (headerIndex < 0) return [];
	return lines
		.slice(headerIndex + 1)
		.map((line) => line.trim())
		.filter((line) => line.includes('|'))
		.map((line) => line.split('|').map((value) => value.trim()));
}

export function createBeaconDossier(bundle: string): BeaconDossier {
	const sources = parseBeaconSources(bundle);
	const echoes = pipeRows(
		sources.capture,
		'ECHO|ARRIVED_AT|RSSI_DBM|BIT_ERROR_PROB|LLR_X100|FRAME_HEX'
	).map((row) => ({
		id: row[0] ?? '',
		arrivedAt: row[1] ?? '',
		rssi: Number(row[2] ?? 0),
		bitErrorProbability: Number(row[3] ?? 0),
		llrWeight: Number(row[4] ?? 0),
		frame: row[5] ?? ''
	}));
	const bands = pipeRows(
		sources.diagnostic,
		'RSSI_RANGE_DBM|BIT_ERROR_PROBABILITY|LLR_WEIGHT_X100'
	).map((row) => ({
		range: row[0] ?? '',
		errorRate: Number(row[1] ?? 0),
		weight: Number(row[2] ?? 0)
	}));
	const fields = pipeRows(sources.protocol, 'FIELD|OCTETS|ENCODING').map((row) => ({
		name: row[0] ?? '',
		octets: row[1] ?? '',
		encoding: row[2] ?? ''
	}));

	return {
		ready:
			sourceIds.every((source) => sources[source].length > 0) &&
			echoes.length > 0 &&
			echoes.length === Number(field(sources.context, 'copy_count')),
		incidentId: field(sources.context, 'incident_id'),
		receiver: field(sources.context, 'receiver'),
		capturedAt: field(sources.context, 'captured_at'),
		frameOctets: Number(field(sources.context, 'frame_octets')),
		copyCount: Number(field(sources.context, 'copy_count')),
		carrierLock: field(sources.context, 'carrier_lock'),
		centralIntegrity: field(sources.context, 'central_integrity'),
		returnChannel: field(sources.context, 'return_channel'),
		echoes,
		bands,
		fields,
		channelMin: Number(field(sources.policy, 'channel_min')),
		channelMax: Number(field(sources.policy, 'channel_max')),
		offsetMin: Number(field(sources.policy, 'offset_min_ms')),
		offsetMax: Number(field(sources.policy, 'offset_max_ms')),
		minimumMargin: Number(field(sources.policy, 'minimum_abs_llr')),
		sources
	};
}

export function beaconBundleText(sources: BeaconSources): string {
	return sourceIds
		.map((source) => `=== ${source.toUpperCase()} ===\n${sources[source].replaceAll('-', '−')}`)
		.join('\n\n');
}
