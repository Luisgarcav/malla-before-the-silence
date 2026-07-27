import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const endingSource = readFileSync(
	new URL('../components/EndingScreen.svelte', import.meta.url),
	'utf8'
);
const pageSource = readFileSync(new URL('../../routes/+page.svelte', import.meta.url), 'utf8');

describe('game ending', () => {
	it('shows a dedicated closing screen after the reunion', () => {
		expect(endingSource).toContain('THANKS FOR PLAYING');
		expect(endingSource).toContain('TOM&gt; You made it.');
		expect(endingSource).toContain('PLAY AGAIN');
		expect(pageSource).toContain("snapshot.stage === 'encounter'");
		expect(pageSource).toContain('<EndingScreen onReset={resetGame} />');
	});
});
