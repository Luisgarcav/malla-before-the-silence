import { describe, expect, it } from 'vitest';
import { parseSeed } from './engine';

describe('parseSeed', () => {
	it('accepts the full unsigned 64-bit range', () => {
		expect(parseSeed('0')).toBe(0n);
		expect(parseSeed('18446744073709551615')).toBe(18_446_744_073_709_551_615n);
	});

	it('falls back for malformed or out-of-range values', () => {
		expect(parseSeed('not-a-seed')).toBe(1999n);
		expect(parseSeed('-1')).toBe(1999n);
		expect(parseSeed('18446744073709551616')).toBe(1999n);
	});
});
