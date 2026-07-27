import type { GameEvent, GameSnapshot, OdinEngine, SnapshotListener } from './types';

const DEFAULT_SEED = 1999n;
const MAX_SEED = (1n << 64n) - 1n;

interface GameExports {
	memory: WebAssembly.Memory;
	_start?: () => void;
	_end?: () => void;
	default_context_ptr: () => number;
	game_init: (seed: bigint, context: number) => void;
	game_dispatch: (context: number) => void;
}

export function parseSeed(value: string | null | undefined): bigint {
	if (!value?.trim()) return DEFAULT_SEED;

	try {
		const seed = BigInt(value);
		return seed >= 0n && seed <= MAX_SEED ? seed : DEFAULT_SEED;
	} catch {
		return DEFAULT_SEED;
	}
}

export async function createOdinEngine(
	wasmUrl: string,
	seed: bigint,
	onSnapshot: SnapshotListener
): Promise<OdinEngine> {
	let memory: WebAssembly.Memory | undefined;
	let pendingCommand = '';
	let exports: GameExports | undefined;
	const encoder = new TextEncoder();
	const decoder = new TextDecoder();

	const readString = (pointer: number, length: number): string => {
		if (!memory || length === 0) return '';
		return decoder.decode(new Uint8Array(memory.buffer, pointer, length));
	};

	const imports: WebAssembly.Imports = {
		odin_env: {
			write: (file: number, pointer: number, length: number) => {
				const message = readString(pointer, length).trimEnd();
				if (!message) return;
				if (file === 2) console.error(`[odin] ${message}`);
				else console.info(`[odin] ${message}`);
			},
			rand_bytes: (pointer: number, length: number) => {
				if (!memory) throw new Error('Odin requested entropy before initializing memory');
				const bytes = new Uint8Array(memory.buffer, pointer, length);
				for (let offset = 0; offset < bytes.length; offset += 65_536) {
					crypto.getRandomValues(bytes.subarray(offset, Math.min(offset + 65_536, bytes.length)));
				}
			}
		},
		game_web: {
			read_command: (pointer: number, capacity: number) => {
				if (!memory) return -1;
				const command = encoder.encode(pendingCommand);
				if (command.length > capacity) return -1;
				new Uint8Array(memory.buffer, pointer, command.length).set(command);
				return command.length;
			},
			publish_state: (
				seedPointer: number,
				seedLength: number,
				window: number,
				running: number,
				captureViewed: number,
				signalReviewed: number,
				locationPointer: number,
				locationLength: number,
				connectionPointer: number,
				connectionLength: number,
				stagePointer: number,
				stageLength: number,
				exposurePointer: number,
				exposureLength: number,
				eventPointer: number,
				eventLength: number,
				objectivePointer: number,
				objectiveLength: number,
				nextCommandPointer: number,
				nextCommandLength: number,
				detailPointer: number,
				detailLength: number,
				evidencePointer: number,
				evidenceLength: number,
				raw: number
			) => {
				onSnapshot({
					seed: readString(seedPointer, seedLength),
					window,
					running: running !== 0,
					captureViewed: captureViewed !== 0,
					signalReviewed: signalReviewed !== 0,
					location: readString(locationPointer, locationLength),
					connection: readString(connectionPointer, connectionLength),
					stage: readString(stagePointer, stageLength) as GameSnapshot['stage'],
					exposure: readString(exposurePointer, exposureLength),
					event: readString(eventPointer, eventLength) as GameEvent,
					objective: readString(objectivePointer, objectiveLength),
					nextCommand: readString(nextCommandPointer, nextCommandLength),
					detail: readString(detailPointer, detailLength),
					evidence: readString(evidencePointer, evidenceLength),
					raw: raw !== 0
				});
			}
		}
	};

	const response = await fetch(wasmUrl);
	if (!response.ok) {
		throw new Error(`The Odin engine could not load (${response.status})`);
	}
	const source = await WebAssembly.instantiate(await response.arrayBuffer(), imports);
	exports = source.instance.exports as unknown as GameExports;
	memory = exports.memory;
	if (!memory || !exports.game_init || !exports.game_dispatch) {
		throw new Error('The WASM module does not expose the expected API');
	}

	exports._start?.();
	const context = exports.default_context_ptr();
	exports.game_init(BigInt.asUintN(64, seed), context);

	return {
		dispatch(command: string) {
			if (!exports) return;
			pendingCommand = command;
			exports.game_dispatch(exports.default_context_ptr());
			pendingCommand = '';
		},
		reset(nextSeed: bigint) {
			if (!exports) return;
			exports.game_init(BigInt.asUintN(64, nextSeed), exports.default_context_ptr());
		},
		destroy() {
			exports?._end?.();
			exports = undefined;
			memory = undefined;
		}
	};
}
