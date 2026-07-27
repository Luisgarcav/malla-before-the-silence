import { describe, expect, it } from 'vitest';
import { createBeaconDossier } from './beacon';

const bundle = `---BEACON-SOURCE:CONTEXT---
incident_id=BCNR6
receiver=GWT08/REP06
captured_at=22:18:03
frame_octets=16
copy_count=2
carrier_lock=LOST
central_integrity=UNREACHABLE
return_channel=NO_RESPONSE
---BEACON-SOURCE:CAPTURE---
ECHO|ARRIVED_AT|RSSI_DBM|BIT_ERROR_PROB|LLR_X100|FRAME_HEX
E1|22:18:03.108|-52|0.005|530|D3010CFFE252455030360001000000AA
E2|22:18:03.421|-84|0.450|20|D3014CFFE252455030360001000000AA
---BEACON-SOURCE:DIAGNOSTIC---
RSSI_RANGE_DBM|BIT_ERROR_PROBABILITY|LLR_WEIGHT_X100
>=-56|0.005|530
BELOW_-80|0.450|20
---BEACON-SOURCE:PROTOCOL---
FIELD|OCTETS|ENCODING
CHANNEL|2|unsigned
CLOCK_OFFSET_MS|3..4|signed int16, big endian
REPETITION_ID|10..11|unsigned
CRC16|14..15|CRC-16/CCITT-FALSE, big-endian
---BEACON-SOURCE:POLICY---
channel_min=1
channel_max=32
offset_min_ms=-250
offset_max_ms=250
minimum_abs_llr=100`;

describe('beacon dossier', () => {
	it('parses echoes, reliability weights and frame fields', () => {
		const dossier = createBeaconDossier(bundle);

		expect(dossier.ready).toBe(true);
		expect(dossier.incidentId).toBe('BCNR6');
		expect(dossier.echoes).toHaveLength(2);
		expect(dossier.echoes[0]).toMatchObject({
			id: 'E1',
			rssi: -52,
			bitErrorProbability: 0.005,
			llrWeight: 530
		});
		expect(dossier.bands).toEqual([
			{ range: '>=-56', errorRate: 0.005, weight: 530 },
			{ range: 'BELOW_-80', errorRate: 0.45, weight: 20 }
		]);
		expect(dossier.fields.map((field) => field.name)).toEqual([
			'CHANNEL',
			'CLOCK_OFFSET_MS',
			'REPETITION_ID',
			'CRC16'
		]);
		expect(dossier.minimumMargin).toBe(100);
		expect([dossier.channelMin, dossier.channelMax, dossier.offsetMin, dossier.offsetMax]).toEqual([
			1, 32, -250, 250
		]);
	});

	it('does not report readiness when the context and parsed echoes are empty', () => {
		const withoutCopies = bundle.replace('copy_count=2\n', '').replace(/^E\d+\|.*\n?/gm, '');

		expect(createBeaconDossier(withoutCopies).ready).toBe(false);
	});
});
