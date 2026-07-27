import { describe, expect, it } from 'vitest';
import { createRouteDossier } from './route';

const bundle = `---ROUTE-SOURCE:EDGES---
route_id=CR02
origin=WORKSHOP
destination=INTERCHANGE
clock_origin=t+00
edge_count=2

FROM|TO|MINUTES
WORKSHOP|MARKET|8
MARKET|INTERCHANGE|12
---ROUTE-SOURCE:CLOSURES---
FROM|TO|CLOSED_FROM|CLOSED_TO
WORKSHOP|MARKET|OPEN|OPEN
MARKET|INTERCHANGE|t+25|t+40
---ROUTE-SOURCE:REPORTS---
FROM|TO|TRACE|CONFIDENCE|AGE_MIN|DELAY_MAX
WORKSHOP|MARKET|0|CONFIRMED|4|0
MARKET|INTERCHANGE|1|PROBABLE|21|5
---ROUTE-SOURCE:POLICY---
cost = arrival_minutes + 4 * total_trace + total_uncertainty`;

describe('route dossier', () => {
	it('merges edges, closures and reports into a readable route table', () => {
		const dossier = createRouteDossier(bundle);

		expect(dossier.ready).toBe(true);
		expect(dossier.origin).toBe('WORKSHOP');
		expect(dossier.destination).toBe('INTERCHANGE');
		expect(dossier.edgeCount).toBe(2);
		expect(dossier.edges[1]).toEqual({
			from: 'MARKET',
			to: 'INTERCHANGE',
			minutes: 12,
			delayMax: 5,
			closedFrom: 't+25',
			closedTo: 't+40',
			trace: 1,
			confidence: 'PROBABLE',
			ageMinutes: 21
		});
	});
});
