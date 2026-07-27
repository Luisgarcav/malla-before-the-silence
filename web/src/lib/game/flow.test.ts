import { describe, expect, it } from 'vitest';
import { createFlowDossier } from './flow';

const bundle = `---FLOW-SOURCE:INTERFACES---
incident_id=CAP03
source=S
destination=T
node_count=3
edge_count=2

LINK|FROM|TO
L01|S|A
L02|A|T
---FLOW-SOURCE:TELEMETRY---
LINK|PHYSICAL|OBSERVED|CAPTURED_AT
L01|7|2|22:14:52
L02|6|1|22:14:52
---FLOW-SOURCE:RESERVATIONS---
LINK|SERVICE|PROTECTED|RESIDUAL|HEADROOM|PLANNABLE|UNIT_COST
L01|HOSPITAL|2|5|1|4|3
L02|WATER|1|5|1|4|6
---FLOW-SOURCE:REPAIR---
22:14:11  local supply restored
22:14:18  data interface T carrier detected
---FLOW-SOURCE:POLICY---
minimum_demand=4
source=S
destination=T`;

describe('flow dossier', () => {
	it('merges topology, telemetry and protected reservations', () => {
		const dossier = createFlowDossier(bundle);

		expect(dossier.ready).toBe(true);
		expect(dossier.demand).toBe(4);
		expect(dossier.nodes).toEqual(['S', 'A', 'T']);
		expect(dossier.links[0]).toEqual({
			id: 'L01',
			from: 'S',
			to: 'A',
			physical: 7,
			observed: 2,
			service: 'HOSPITAL',
			protected: 2,
			residual: 5,
			headroom: 1,
			plannable: 4,
			unitCost: 3
		});
	});
});
