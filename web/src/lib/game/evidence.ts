export type EvidenceSourceId = 'capture' | 'protocol' | 'diagnostic' | 'integrity';

export interface EvidenceSources {
	capture: string;
	protocol: string;
	diagnostic: string;
	integrity: string;
}

export interface CaptureRow {
	slot: string;
	sequence: string;
	status: 'RECEIVED' | 'ERASURE' | 'RECOVERY';
	data: string;
}

export interface EvidenceDossier {
	ready: boolean;
	missingSlot: string;
	missingSlots: string[];
	capturedAt: string;
	dataSlots: string;
	octetsPerSlot: string;
	erasureCount: string;
	rows: CaptureRow[];
	formula: string;
	diagnosticLines: string[];
	integrityExpected: string;
	integrityScope: string;
	sources: EvidenceSources;
}

const sourceIds: EvidenceSourceId[] = ['capture', 'protocol', 'diagnostic', 'integrity'];

export function parseEvidenceSources(bundle: string): EvidenceSources {
	const sources: EvidenceSources = { capture: '', protocol: '', diagnostic: '', integrity: '' };
	const marker = /^---EMR-SOURCE:(CAPTURE|PROTOCOL|DIAGNOSTIC|INTEGRITY)---$/gm;
	const matches = [...bundle.matchAll(marker)];

	for (const [index, match] of matches.entries()) {
		const source = match[1].toLowerCase() as EvidenceSourceId;
		const start = (match.index ?? 0) + match[0].length;
		const end = matches[index + 1]?.index ?? bundle.length;
		sources[source] = bundle.slice(start, end).trim();
	}

	return sources;
}

function captureRows(capture: string): CaptureRow[] {
	const rows: CaptureRow[] = [];
	const dataPattern = /D\[(\d+)]\s+seq=(\d+)\s+status=(RECEIVED|ERASURE)\s+data=([0-9A-FX]+)/g;

	for (const match of capture.matchAll(dataPattern)) {
		rows.push({
			slot: `D${match[1]}`,
			sequence: match[2],
			status: match[3] as CaptureRow['status'],
			data: match[4]
		});
	}

	for (const recovery of capture.matchAll(
		/([PQ])\s+seq=(\d+)\s+status=RECEIVED\s+data=([0-9A-F]+)/g
	)) {
		rows.push({
			slot: recovery[1],
			sequence: recovery[2],
			status: 'RECOVERY',
			data: recovery[3]
		});
	}

	return rows;
}

function field(source: string, name: string): string {
	return source.match(new RegExp(`^${name}=([^\\n]+)$`, 'm'))?.[1]?.trim() ?? '';
}

export function createEvidenceDossier(bundle: string): EvidenceDossier {
	const sources = parseEvidenceSources(bundle);
	const rows = captureRows(sources.capture);
	const formulas = [...sources.protocol.matchAll(/^[PQ]\[j]\s*=\s*[^\n]+$/gm)].map(
		(match) => match[0]
	);
	const missingSlots = rows.filter((row) => row.status === 'ERASURE').map((row) => row.slot);
	const scope = sources.integrity.match(/binary concatenation ([^,]+),/i)?.[1]?.trim() ?? '';
	const diagnosticLines = sources.diagnostic
		.split('\n')
		.filter((line) => /CARRIER|SYNDROME|ASSEMBLY/.test(line));

	return {
		ready: sourceIds.every((source) => sources[source].length > 0) && rows.length > 0,
		missingSlot: missingSlots.join(' + '),
		missingSlots,
		capturedAt: field(sources.capture, 'captured_at'),
		dataSlots: field(sources.capture, 'data_slots'),
		octetsPerSlot: field(sources.capture, 'octets_per_slot'),
		erasureCount: field(sources.capture, 'erasure_count'),
		rows,
		formula: formulas.join('\n'),
		diagnosticLines,
		integrityExpected: field(sources.integrity, 'expected'),
		integrityScope: scope,
		sources
	};
}

export function evidenceBundleText(sources: EvidenceSources): string {
	return sourceIds
		.map((source) => `=== ${source.toUpperCase()} ===\n${sources[source].replaceAll('-', '−')}`)
		.join('\n\n');
}
