import { describe, expect, it } from 'vitest';
import { introChapters } from './intro';

describe('game introduction', () => {
	it('presents a complete and ordered context before the live prologue', () => {
		expect(introChapters).toHaveLength(5);
		expect(new Set(introChapters.map((chapter) => chapter.id)).size).toBe(introChapters.length);
		expect(introChapters.map((chapter) => chapter.id)).toEqual([
			'archive',
			'mesh',
			'coup',
			'two-routes',
			'before-silence'
		]);
		expect(introChapters.at(-1)).toMatchObject({ final: true, time: '21:12' });
	});

	it('explains the civil network, coup, protagonists and access limits', () => {
		const text = introChapters
			.flatMap((chapter) => [
				chapter.title,
				...chapter.body,
				...chapter.facts.map((fact) => fact.value)
			])
			.join(' ');

		expect(text).toContain('MALLA');
		expect(text).toContain('hospitals');
		expect(text).toContain('popular uprising');
		expect(text).toContain('a coup');
		expect(text).toContain('Ellie');
		expect(text).toContain('Tom');
		expect(text).toContain('REP06');
		expect(text).toContain('no global access');
		expect(text).not.toContain('-');
	});

	it('keeps every screen concise and supplies an accessible diagram label', () => {
		for (const chapter of introChapters) {
			expect(chapter.body).toHaveLength(2);
			expect(chapter.facts).toHaveLength(3);
			expect(chapter.diagram.label.length).toBeGreaterThan(20);
		}
	});
});
