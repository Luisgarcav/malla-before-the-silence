import { describe, expect, it } from 'vitest';
import { createEvidenceDossier } from './evidence';

const bundle = `---EMR-SOURCE:CAPTURE---
captured_at=21:41:08.442
data_slots=12
octets_per_slot=16
erasure_count=2
D[0]   seq=184  status=RECEIVED  data=00112233445566778899AABBCCDDEEFF
D[3]   seq=187  status=ERASURE   data=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
D[11]  seq=195  status=ERASURE   data=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
P      seq=196  status=RECEIVED  data=FFEEDDCCBBAA99887766554433221100
Q      seq=197  status=RECEIVED  data=0123456789ABCDEFFEDCBA9876543210
---EMR-SOURCE:PROTOCOL---
P[j] = D[0][j] XOR D[1][j] XOR D[2][j] XOR D[3][j] XOR D[4][j] XOR D[5][j] XOR D[6][j] XOR D[7][j] XOR D[8][j] XOR D[9][j] XOR D[10][j] XOR D[11][j]
Q[j] = α^0·D[0][j] XOR α^1·D[1][j] XOR α^2·D[2][j] XOR α^3·D[3][j]
---EMR-SOURCE:DIAGNOSTIC---
21:41:08.463  seq=187  CARRIER   lost after header
21:41:08.519  seq=195  CARRIER   lost after header
21:41:08.531  seq=196  P-SYNDROME  accepted
21:41:08.532  seq=197  Q-SYNDROME  accepted
21:41:08.533  record   ASSEMBLY  deferred: erasures at D[3],D[11]
---EMR-SOURCE:INTEGRITY---
expected=D91D56E0
binary concatenation D[0] || D[1] || D[2] || D[3] || D[4] || D[5] || D[6] || D[7] || D[8] || D[9] || D[10] || D[11], without separators.`;

describe('evidence dossier', () => {
	it('parses the authoritative EMR06 bundle into display rows', () => {
		const dossier = createEvidenceDossier(bundle);

		expect(dossier.ready).toBe(true);
		expect(dossier.missingSlot).toBe('D3 + D11');
		expect(dossier.missingSlots).toEqual(['D3', 'D11']);
		expect(dossier.rows).toEqual([
			{
				slot: 'D0',
				sequence: '184',
				status: 'RECEIVED',
				data: '00112233445566778899AABBCCDDEEFF'
			},
			{
				slot: 'D3',
				sequence: '187',
				status: 'ERASURE',
				data: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
			},
			{
				slot: 'D11',
				sequence: '195',
				status: 'ERASURE',
				data: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
			},
			{
				slot: 'P',
				sequence: '196',
				status: 'RECOVERY',
				data: 'FFEEDDCCBBAA99887766554433221100'
			},
			{
				slot: 'Q',
				sequence: '197',
				status: 'RECOVERY',
				data: '0123456789ABCDEFFEDCBA9876543210'
			}
		]);
		expect(dossier.formula).toContain('XOR');
		expect(dossier.integrityExpected).toBe('D91D56E0');
		expect(dossier.integrityScope).toContain('D[10] || D[11]');
	});

	it('does not report readiness when the capture has no parseable rows', () => {
		const withoutRows = bundle.replace(/^(?:D\[\d+\]|P\s|Q\s).*\n?/gm, '');

		expect(createEvidenceDossier(withoutRows).ready).toBe(false);
	});
});
