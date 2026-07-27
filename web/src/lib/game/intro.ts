export type IntroTone = 'archive' | 'civil' | 'coup' | 'human' | 'live';

export interface IntroFact {
	label: string;
	value: string;
}

export interface IntroChapter {
	id: string;
	tone: IntroTone;
	time: string;
	eyebrow: string;
	title: string;
	body: string[];
	facts: IntroFact[];
	diagram: {
		label: string;
		left: string;
		center: string;
		right: string;
	};
	final?: boolean;
}

export const introChapters: IntroChapter[] = [
	{
		id: 'archive',
		tone: 'archive',
		time: 'BEFORE',
		eyebrow: 'CONTEXT ARCHIVE // 00',
		title: 'MALLA: BEFORE THE SILENCE',
		body: [
			'A nameless city learned to sustain itself through a network of machines repaired too many times.',
			'This is not a story about saving it in one night. It is the story of two people trying to cross it while someone decides who is allowed to move.'
		],
		facts: [
			{ label: 'PLACE', value: 'NOT RECORDED' },
			{ label: 'NETWORK', value: 'CIVIC MALLA' },
			{ label: 'DESTINATION', value: 'REPEATER 06' }
		],
		diagram: {
			label: 'A city connected to a civic network and Repeater 06',
			left: 'CITY',
			center: 'MALLA',
			right: 'REP06'
		}
	},
	{
		id: 'mesh',
		tone: 'civil',
		time: 'YEARS EARLIER',
		eyebrow: 'CIVIL INFRASTRUCTURE // 01',
		title: 'A NETWORK BUILT TO KEEP THE CITY ALIVE',
		body: [
			'MALLA was built to coordinate power, hospitals, food, workshops, transit, and emergency communications.',
			'Its local nodes and backup routes were designed to survive disasters. That same resilience will prevent one authority from controlling every machine at once.'
		],
		facts: [
			{ label: 'DESIGN', value: 'DISTRIBUTED' },
			{ label: 'NODES', value: 'LOCAL AUTONOMY' },
			{ label: 'PURPOSE', value: 'CIVIL COORDINATION' }
		],
		diagram: {
			label: 'Hospitals, power, and transit coordinated by MALLA',
			left: 'HOSPITALS',
			center: 'MALLA',
			right: 'POWER + ROUTES'
		}
	},
	{
		id: 'coup',
		tone: 'coup',
		time: 'RECENT WEEKS',
		eyebrow: 'AUTHORITY SHIFT // 02',
		title: 'THE UPRISING IS NOT THE COUP',
		body: [
			'A popular uprising has occupied factories and streets for weeks. For months, a military and corporate alliance prepared something different: a coup.',
			'Tonight it seizes central identity, gateways, and broadcasters. The new junta turns civil routes into checkpoints, imposes curfew, and begins correlating names.'
		],
		facts: [
			{ label: 'CENTER', value: 'CAPTURED' },
			{ label: 'LOCAL NODES', value: 'PARTIAL CONTROL' },
			{ label: 'ORDER', value: 'REMAIN IN YOUR SECTOR' }
		],
		diagram: {
			label: 'The junta captures central authority while some local nodes resist',
			left: 'LOCAL NODES',
			center: 'AUTHORITY',
			right: 'JUNTA'
		}
	},
	{
		id: 'two-routes',
		tone: 'human',
		time: 'THAT MORNING',
		eyebrow: 'TWO ROUTES // 03',
		title: 'ELLIE AND TOM',
		body: [
			'Ellie maintains MALLA. Tom repairs radios at a community station. They argued: he wanted to leave the city; she chose to finish a shift that still sustained essential services.',
			'They agreed to meet at REP06, a small analog repeater outside the modern network. Tom is not waiting to be rescued. He will advance from the other side and change the route physically.'
		],
		facts: [
			{ label: 'ELLIE', value: 'OPERATIONS ANNEX' },
			{ label: 'TOM', value: 'COMMUNITY STATION' },
			{ label: 'PROMISE', value: 'REACH THE SIX' }
		],
		diagram: {
			label: 'Ellie and Tom advance along separate routes toward REP06',
			left: 'ELLIE',
			center: 'REP06',
			right: 'TOM'
		}
	},
	{
		id: 'before-silence',
		tone: 'live',
		time: '21:12',
		eyebrow: 'LIVE // 04',
		title: 'BEFORE THE SILENCE',
		body: [
			'Ellie has an industrial laptop, a physical key, a limited regional certificate, and an incomplete copy of the topology. She has no global access and must reach every node in person.',
			'Tom is still on air. Public channels have just changed programming. In one minute, an ordinary conversation will become the last clean signal of the night.'
		],
		facts: [
			{ label: 'SESSION', value: 'LOCAL / LOGGED' },
			{ label: 'WINDOW', value: 'CLOSING' },
			{ label: 'OBJECTIVE', value: 'FIND TOM' }
		],
		diagram: {
			label: 'One final signal connects the annex, REP06, and the station',
			left: 'ANNEX',
			center: 'REP06',
			right: 'STATION'
		},
		final: true
	}
];
