package main

import "core:fmt"
import "core:hash"
import "core:strconv"
import "core:strings"

// Instancias, generadores y validadores de los cuatro incidentes canónicos.
// Reglas comunes del plan (§6): datos deterministas a partir de la semilla,
// instancias solubles y acotadas, validación por propiedades (no por cadena
// rígida) y solvers de referencia que jamás se exponen durante la partida.

Submission_Result :: enum {
	Format_Invalid,
	Impossible,
	Valid,
}

Validation_Result :: enum {
	Format_Invalid,
	Impossible,
	Insufficient,
	Viable,
	Optimal,
}

HEX_DIGITS :: "0123456789ABCDEF"

bytes_to_hex :: proc(data: []u8) -> string {
	hex_digits := HEX_DIGITS
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	for value in data {
		_ = strings.write_byte(&builder, hex_digits[value >> 4])
		_ = strings.write_byte(&builder, hex_digits[value & 0x0F])
	}
	return strings.to_string(builder)
}

hex_u32 :: proc(value: u32) -> string {
	bytes := [4]u8{u8(value >> 24), u8(value >> 16), u8(value >> 8), u8(value)}
	return bytes_to_hex(bytes[:])
}

hex_u16 :: proc(value: u16) -> string {
	bytes := [2]u8{u8(value >> 8), u8(value)}
	return bytes_to_hex(bytes[:])
}

hex_nibble :: proc(value: u8) -> (u8, bool) {
	switch value {
	case '0'..='9':
		return value - '0', true
	case 'a'..='f':
		return value - 'a' + 10, true
	case 'A'..='F':
		return value - 'A' + 10, true
	}
	return 0, false
}

parse_hex_u16 :: proc(value: string) -> (u16, bool) {
	if len(value) != 4 {
		return 0, false
	}
	result := u16(0)
	for index in 0..<4 {
		nibble, ok := hex_nibble(value[index])
		if !ok {
			return 0, false
		}
		result = result << 4 | u16(nibble)
	}
	return result, true
}

PACKET_DATA_SLOT_COUNT :: 12
PACKET_SLOT_SIZE :: 16
PACKET_PAYLOAD_SIZE :: PACKET_DATA_SLOT_COUNT * PACKET_SLOT_SIZE
PACKET_ERASURE_COUNT :: 2
PACKET_REPAIR_HEX_SIZE :: PACKET_ERASURE_COUNT * PACKET_SLOT_SIZE * 2

decode_fragment :: proc(value: string) -> (result: [PACKET_SLOT_SIZE]u8, ok: bool) {
	if len(value) != PACKET_SLOT_SIZE * 2 {
		return {}, false
	}

	for index in 0..<PACKET_SLOT_SIZE {
		high, high_ok := hex_nibble(value[index * 2])
		low, low_ok := hex_nibble(value[index * 2 + 1])
		if !high_ok || !low_ok {
			return {}, false
		}
		result[index] = high << 4 | low
	}
	return result, true
}

decode_packet_repair :: proc(
	value: string,
) -> (result: [PACKET_ERASURE_COUNT][PACKET_SLOT_SIZE]u8, ok: bool) {
	if len(value) != PACKET_REPAIR_HEX_SIZE {
		return {}, false
	}
	for index in 0..<PACKET_ERASURE_COUNT {
		start := index * PACKET_SLOT_SIZE * 2
		fragment, fragment_ok := decode_fragment(value[start:start + PACKET_SLOT_SIZE * 2])
		if !fragment_ok {
			return {}, false
		}
		result[index] = fragment
	}
	return result, true
}

// GF(2^8), primitive polynomial x^8+x^4+x^3+x^2+1 (0x11D). This is the
// finite field used by the P/Q erasure code below; addition is XOR.
gf256_mul :: proc(left, right: u8) -> u8 {
	a := left
	b := right
	result := u8(0)
	for _ in 0..<8 {
		if b & 1 != 0 {
			result ~= a
		}
		high := a & 0x80
		a <<= 1
		if high != 0 {
			a ~= 0x1D
		}
		b >>= 1
	}
	return result
}

gf256_pow :: proc(base: u8, exponent: int) -> u8 {
	result := u8(1)
	factor := base
	power := exponent
	for power > 0 {
		if power & 1 != 0 {
			result = gf256_mul(result, factor)
		}
		factor = gf256_mul(factor, factor)
		power >>= 1
	}
	return result
}

gf256_inverse :: proc(value: u8) -> u8 {
	if value == 0 {
		return 0
	}
	return gf256_pow(value, 254)
}

packet_q_coefficient :: proc(index: int) -> u8 {
	return gf256_pow(2, index)
}

// ---------------------------------------------------------------------------
// Incidente 1 // REGISTRO EMR-06
// La carga binaria opaca, dos slots perdidos, los síndromes P/Q y el CRC se
// derivan de la semilla. P es paridad XOR y Q es paridad Reed-Solomon sobre
// GF(2^8), el esquema clásico de doble erasure empleado por RAID-6.
// ---------------------------------------------------------------------------

Packet_Instance :: struct {
	blocks: [PACKET_DATA_SLOT_COUNT][PACKET_SLOT_SIZE]u8, // verdad de referencia
	erased: [PACKET_ERASURE_COUNT]int,
	p:      [PACKET_SLOT_SIZE]u8,
	q:      [PACKET_SLOT_SIZE]u8,
	crc:    u32,
	seed:   u64,
}

packet_slot_is_erased :: proc(instance: ^Packet_Instance, index: int) -> bool {
	for erased in instance.erased {
		if erased == index {
			return true
		}
	}
	return false
}

generate_packet_instance :: proc(seed: u64) -> Packet_Instance {
	instance: Packet_Instance
	instance.seed = seed
	state := seed
	instance.erased[0] = rng_below(&state, PACKET_DATA_SLOT_COUNT)
	instance.erased[1] = rng_below(&state, PACKET_DATA_SLOT_COUNT - 1)
	if instance.erased[1] >= instance.erased[0] {
		instance.erased[1] += 1
	}
	if instance.erased[1] < instance.erased[0] {
		instance.erased[0], instance.erased[1] = instance.erased[1], instance.erased[0]
	}

	payload_state := seed ~ 0x454D523036504159
	for index in 0..<PACKET_PAYLOAD_SIZE {
		instance.blocks[index / PACKET_SLOT_SIZE][index % PACKET_SLOT_SIZE] =
			u8(rng_below(&payload_state, 0x100))
	}
	for byte_index in 0..<PACKET_SLOT_SIZE {
		p := u8(0)
		q := u8(0)
		for block_index in 0..<PACKET_DATA_SLOT_COUNT {
			value := instance.blocks[block_index][byte_index]
			p ~= value
			q ~= gf256_mul(packet_q_coefficient(block_index), value)
		}
		instance.p[byte_index] = p
		instance.q[byte_index] = q
	}
	message_bytes := packet_message_bytes(&instance)
	instance.crc = hash.crc32(message_bytes[:])
	return instance
}

packet_message_bytes :: proc(instance: ^Packet_Instance) -> [PACKET_PAYLOAD_SIZE]u8 {
	result: [PACKET_PAYLOAD_SIZE]u8
	for block, block_index in instance.blocks {
		for value, byte_index in block {
			result[block_index * PACKET_SLOT_SIZE + byte_index] = value
		}
	}
	return result
}

// Solver de referencia: sólo para generación, pistas y pruebas. Para cada
// posición resuelve A XOR B = p' y ca*A XOR cb*B = q' en GF(2^8).
packet_recover_erased :: proc(
	instance: ^Packet_Instance,
) -> [PACKET_ERASURE_COUNT][PACKET_SLOT_SIZE]u8 {
	result: [PACKET_ERASURE_COUNT][PACKET_SLOT_SIZE]u8
	a_index := instance.erased[0]
	b_index := instance.erased[1]
	ca := packet_q_coefficient(a_index)
	cb := packet_q_coefficient(b_index)
	denominator_inverse := gf256_inverse(ca ~ cb)
	for byte_index in 0..<PACKET_SLOT_SIZE {
		p_syndrome := instance.p[byte_index]
		q_syndrome := instance.q[byte_index]
		for block_index in 0..<PACKET_DATA_SLOT_COUNT {
			if packet_slot_is_erased(instance, block_index) {
				continue
			}
			value := instance.blocks[block_index][byte_index]
			p_syndrome ~= value
			q_syndrome ~= gf256_mul(packet_q_coefficient(block_index), value)
		}
		a := gf256_mul(denominator_inverse, q_syndrome ~ gf256_mul(cb, p_syndrome))
		result[0][byte_index] = a
		result[1][byte_index] = p_syndrome ~ a
	}
	return result
}

packet_solution_hex :: proc(instance: ^Packet_Instance) -> string {
	solution := packet_recover_erased(instance)
	return fmt.tprintf("%s%s", bytes_to_hex(solution[0][:]), bytes_to_hex(solution[1][:]))
}

packet_other_slots :: proc(instance: ^Packet_Instance) -> [PACKET_DATA_SLOT_COUNT - PACKET_ERASURE_COUNT]int {
	result: [PACKET_DATA_SLOT_COUNT - PACKET_ERASURE_COUNT]int
	count := 0
	for index in 0..<PACKET_DATA_SLOT_COUNT {
		if packet_slot_is_erased(instance, index) {
			continue
		}
		result[count] = index
		count += 1
	}
	return result
}

packet_p_equation_text :: proc() -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(&builder, "P[j] = ")
	for index in 0..<PACKET_DATA_SLOT_COUNT {
		if index > 0 {
			_ = strings.write_string(&builder, " XOR ")
		}
		_ = strings.write_string(&builder, fmt.tprintf("D[%d][j]", index))
	}
	return strings.to_string(builder)
}

packet_q_equation_text :: proc() -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(&builder, "Q[j] = ")
	for index in 0..<PACKET_DATA_SLOT_COUNT {
		if index > 0 {
			_ = strings.write_string(&builder, " XOR ")
		}
		_ = strings.write_string(&builder, fmt.tprintf("α^%d·D[%d][j]", index, index))
	}
	return strings.to_string(builder)
}

packet_recovery_equation_text :: proc(instance: ^Packet_Instance) -> string {
	a := instance.erased[0]
	b := instance.erased[1]
	return fmt.tprintf(
		"A = (α^%d XOR α^%d)^-1 · (q' XOR α^%d·p'); B = p' XOR A",
		a,
		b,
		b,
	)
}

packet_integrity_scope_text :: proc() -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	for index in 0..<PACKET_DATA_SLOT_COUNT {
		if index > 0 {
			_ = strings.write_string(&builder, " || ")
		}
		_ = strings.write_string(&builder, fmt.tprintf("D[%d]", index))
	}
	return strings.to_string(builder)
}

validate_packet_repair :: proc(
	instance: ^Packet_Instance,
	fragment_text: string,
) -> Submission_Result {
	fragments, fragments_ok := decode_packet_repair(strings.trim_space(fragment_text))
	if !fragments_ok {
		return .Format_Invalid
	}

	message := packet_message_bytes(instance)
	for erased, repair_index in instance.erased {
		for byte_index in 0..<PACKET_SLOT_SIZE {
			message[erased * PACKET_SLOT_SIZE + byte_index] = fragments[repair_index][byte_index]
		}
	}
	for byte_index in 0..<PACKET_SLOT_SIZE {
		p := u8(0)
		q := u8(0)
		for block_index in 0..<PACKET_DATA_SLOT_COUNT {
			value := message[block_index * PACKET_SLOT_SIZE + byte_index]
			p ~= value
			q ~= gf256_mul(packet_q_coefficient(block_index), value)
		}
		if p != instance.p[byte_index] || q != instance.q[byte_index] {
			return .Impossible
		}
	}
	if hash.crc32(message[:]) != instance.crc {
		return .Impossible
	}
	return .Valid
}

// Textos del expediente derivados de la instancia.

packet_slot_hex :: proc(instance: ^Packet_Instance, index: int) -> string {
	if packet_slot_is_erased(instance, index) {
		return "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	}
	block := instance.blocks[index]
	return bytes_to_hex(block[:])
}

packet_capture_text :: proc(instance: ^Packet_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(&builder, fmt.tprintf(`MESH ER2 RECEIVE RECORD // EMR06
record_id=EMR06
captured_at=21:41:08.442
encoding=octets/hex
data_slots=%d
octets_per_slot=%d
erasure_count=%d

`, PACKET_DATA_SLOT_COUNT, PACKET_SLOT_SIZE, PACKET_ERASURE_COUNT))
	for index in 0..<PACKET_DATA_SLOT_COUNT {
		status := "ERASURE  " if packet_slot_is_erased(instance, index) else "RECEIVED "
		_ = strings.write_string(
			&builder,
			fmt.tprintf(
				"D[%d]  seq=%d  status=%s data=%s\n",
				index,
				184 + index,
				status,
				packet_slot_hex(instance, index),
			),
		)
	}
	_ = strings.write_string(
		&builder,
		fmt.tprintf(
			"P     seq=%d  status=RECEIVED  data=%s\n",
			184 + PACKET_DATA_SLOT_COUNT,
			bytes_to_hex(instance.p[:]),
		),
	)
	_ = strings.write_string(
		&builder,
		fmt.tprintf(
			"Q     seq=%d  status=RECEIVED  data=%s\n",
			185 + PACKET_DATA_SLOT_COUNT,
			bytes_to_hex(instance.q[:]),
		),
	)
	_ = strings.write_string(
		&builder,
		fmt.tprintf(`
integrity_profile=CRC32/ISO HDLC
integrity_scope=%s
integrity_expected=%s`, packet_integrity_scope_text(), hex_u32(instance.crc)),
	)
	return strings.to_string(builder)
}

packet_diagnostic_text :: proc(instance: ^Packet_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(&builder, "CTRL17 // RX DIAGNOSTIC // EMR06\n")
	for index in 0..<PACKET_DATA_SLOT_COUNT {
		millisecond := 442 + index * 7
		if packet_slot_is_erased(instance, index) {
			_ = strings.write_string(
				&builder,
				fmt.tprintf("21:41:08.%03d  seq=%d  CARRIER   lost after header\n", millisecond, 184 + index),
			)
		} else {
			_ = strings.write_string(
				&builder,
				fmt.tprintf("21:41:08.%03d  seq=%d  DATA      accepted\n", millisecond, 184 + index),
			)
		}
	}
	_ = strings.write_string(
		&builder,
		fmt.tprintf(
			"21:41:08.531  seq=%d  P-SYNDROME  accepted\n",
			184 + PACKET_DATA_SLOT_COUNT,
		),
	)
	_ = strings.write_string(
		&builder,
		fmt.tprintf(
			"21:41:08.532  seq=%d  Q-SYNDROME  accepted\n",
			185 + PACKET_DATA_SLOT_COUNT,
		),
	)
	_ = strings.write_string(
		&builder,
		fmt.tprintf(
			"21:41:08.533  record   ASSEMBLY  deferred: erasures at D[%d],D[%d]\n",
			instance.erased[0],
			instance.erased[1],
		),
	)
	_ = strings.write_string(&builder, "21:41:08.533  record   FORWARD   blocked until integrity check")
	return strings.to_string(builder)
}

packet_partial_result_text :: proc(
	instance: ^Packet_Instance,
	repair_index: int,
) -> (hex_text, ascii_text: string) {
	solution := packet_recover_erased(instance)
	hex_digits := HEX_DIGITS
	hex_builder: strings.Builder
	_ = strings.builder_init(&hex_builder, context.temp_allocator)
	ascii_builder: strings.Builder
	_ = strings.builder_init(&ascii_builder, context.temp_allocator)
	for index in 0..<4 {
		if index > 0 {
			_ = strings.write_byte(&hex_builder, ' ')
		}
		_ = strings.write_byte(&hex_builder, hex_digits[solution[repair_index][index] >> 4])
		_ = strings.write_byte(&hex_builder, hex_digits[solution[repair_index][index] & 0x0F])
		ascii := solution[repair_index][index]
		if ascii < 0x20 || ascii > 0x7E {
			ascii = '.'
		}
		_ = strings.write_byte(&ascii_builder, ascii)
	}
	return strings.to_string(hex_builder), strings.to_string(ascii_builder)
}

packet_overview_text :: proc(instance: ^Packet_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(&builder, "EMR06 // CAPTURE\n")
	for index in 0..<PACKET_DATA_SLOT_COUNT {
		suffix := "  ERASURE" if packet_slot_is_erased(instance, index) else ""
		_ = strings.write_string(
			&builder,
			fmt.tprintf("D%d  %s%s\n", index, packet_slot_hex(instance, index), suffix),
		)
	}
	_ = strings.write_string(&builder, fmt.tprintf("P   %s\n", bytes_to_hex(instance.p[:])))
	_ = strings.write_string(&builder, fmt.tprintf("Q   %s\n", bytes_to_hex(instance.q[:])))
	_ = strings.write_string(&builder, fmt.tprintf("CRC %s\n", hex_u32(instance.crc)))
	_ = strings.write_string(&builder, "\nrepair emr06 <64 hex: lower erased index, then higher>")
	return strings.to_string(builder)
}

// ---------------------------------------------------------------------------
// Incidente 2 // CIUDAD CERRADA
// Grafo dirigido con ventanas de cierre, rastro y confianza por reporte.
// ---------------------------------------------------------------------------

MAX_ROUTE_NODES :: 8
MAX_ROUTE_EDGES :: 18
MAX_ROUTE_SUBMISSION_NODES :: 12
ROUTE_ACCEPTANCE_MARGIN :: 3

ROUTE_NODE_NAMES :: [MAX_ROUTE_NODES]string {
	"WORKSHOP", "MARKET", "BRIDGE", "DEPOT",
	"TUNNEL", "PLAZA", "RAIL", "INTERCHANGE",
}

Confidence :: enum {
	Confirmed,
	Probable,
	Unverified,
}

confidence_penalty :: proc(confidence: Confidence) -> int {
	switch confidence {
	case .Confirmed:
		return 0
	case .Probable:
		return 3
	case .Unverified:
		return 8
	}
	return 0
}

confidence_name :: proc(confidence: Confidence) -> string {
	switch confidence {
	case .Confirmed:
		return "CONFIRMED"
	case .Probable:
		return "PROBABLE"
	case .Unverified:
		return "UNVERIFIED"
	}
	return "UNKNOWN"
}

Route_Edge :: struct {
	from, to:    int,
	minutes:     int, // duración nominal / cota inferior
	delay_max:   int, // demora adicional acotada por calidad y antigüedad
	closed_from: int, // -1 = sin cierre
	closed_to:   int,
	trace:       int,
	confidence:  Confidence,
	report_age:  int, // minutos desde el último reporte
}

Route_Instance :: struct {
	node_count: int,
	edge_count: int,
	edges:      [MAX_ROUTE_EDGES]Route_Edge,
	start:      int,
	goal:       int,
	seed:       u64,
}

route_node_name :: proc(index: int) -> string {
	names := ROUTE_NODE_NAMES
	return names[index]
}

route_node_index :: proc(instance: ^Route_Instance, name: string) -> (int, bool) {
	names := ROUTE_NODE_NAMES
	for index in 0..<instance.node_count {
		if strings.equal_fold(name, names[index]) {
			return index, true
		}
	}
	return 0, false
}

route_find_edge :: proc(instance: ^Route_Instance, from, to: int) -> (Route_Edge, bool) {
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		if edge.from == from && edge.to == to {
			return edge, true
		}
	}
	return {}, false
}

route_add_edge :: proc(
	instance: ^Route_Instance,
	used: ^[MAX_ROUTE_NODES][MAX_ROUTE_NODES]bool,
	edge: Route_Edge,
) -> bool {
	if instance.edge_count >= MAX_ROUTE_EDGES {
		return false
	}
	if edge.from == edge.to || used[edge.from][edge.to] {
		return false
	}
	used[edge.from][edge.to] = true
	instance.edges[instance.edge_count] = edge
	instance.edge_count += 1
	return true
}

route_generated_edge :: proc(state: ^u64, from, to: int, force_open: bool) -> Route_Edge {
	closed_from := -1
	closed_to := -1
	if !force_open && rng_below(state, 2) == 0 {
		closed_from = 6 + rng_below(state, 38)
		closed_to = closed_from + 8 + rng_below(state, 25)
	}
	confidence := Confidence(rng_below(state, 3))
	report_age := rng_below(state, 50)
	return Route_Edge {
		from        = from,
		to          = to,
		minutes     = 6 + rng_below(state, 13),
		delay_max   = confidence_penalty(confidence) + report_age / 10,
		closed_from = closed_from,
		closed_to   = closed_to,
		trace       = rng_below(state, 4),
		confidence  = confidence,
		report_age  = report_age,
	}
}

// Tres capas de dos nodos producen varias rutas completas de cuatro tramos.
// Seis enlaces laterales permiten cambiar de reporte dentro de una capa. Una
// columna vertebral queda abierta para garantizar solubilidad, pero las 18
// aristas se barajan y sus costes varían: la ruta segura ya no queda expuesta
// por el orden del expediente.
generate_route_instance :: proc(seed: u64) -> Route_Instance {
	instance: Route_Instance
	instance.seed = seed
	state := seed
	instance.node_count = MAX_ROUTE_NODES
	instance.start = 0
	instance.goal = instance.node_count - 1
	used: [MAX_ROUTE_NODES][MAX_ROUTE_NODES]bool

	middle := [6]int{1, 2, 3, 4, 5, 6}
	for index in 0..<len(middle) {
		swap_index := index + rng_below(&state, len(middle) - index)
		middle[index], middle[swap_index] = middle[swap_index], middle[index]
	}
	layers := [3][2]int {
		{middle[0], middle[1]},
		{middle[2], middle[3]},
		{middle[4], middle[5]},
	}

	for to in layers[0] {
		_ = route_add_edge(
			&instance,
			&used,
			route_generated_edge(&state, instance.start, to, to == layers[0][0]),
		)
	}
	for from in layers[0] {
		for to in layers[1] {
			force_open := from == layers[0][0] && to == layers[1][0]
			_ = route_add_edge(&instance, &used, route_generated_edge(&state, from, to, force_open))
		}
	}
	for from in layers[1] {
		for to in layers[2] {
			force_open := from == layers[1][0] && to == layers[2][0]
			_ = route_add_edge(&instance, &used, route_generated_edge(&state, from, to, force_open))
		}
	}
	for from in layers[2] {
		_ = route_add_edge(
			&instance,
			&used,
			route_generated_edge(&state, from, instance.goal, from == layers[2][0]),
		)
	}
	for layer in layers {
		_ = route_add_edge(
			&instance,
			&used,
			route_generated_edge(&state, layer[0], layer[1], false),
		)
		_ = route_add_edge(
			&instance,
			&used,
			route_generated_edge(&state, layer[1], layer[0], false),
		)
	}

	// Fisher-Yates hacia delante: evita que el camino garantizado ocupe las
	// primeras filas del expediente y siga funcionando como pista accidental.
	for index in 0..<instance.edge_count {
		swap_index := index + rng_below(&state, instance.edge_count - index)
		instance.edges[index], instance.edges[swap_index] = instance.edges[swap_index], instance.edges[index]
	}
	return instance
}

parse_route_nodes :: proc(
	instance: ^Route_Instance,
	text: string,
	nodes: ^[MAX_ROUTE_SUBMISSION_NODES]int,
) -> (count: int, ok: bool) {
	trimmed := strings.trim_space(text)
	if len(trimmed) == 0 {
		return 0, false
	}

	remaining := trimmed
	for token in strings.split_iterator(&remaining, ">") {
		name := strings.trim_space(token)
		index, index_ok := route_node_index(instance, name)
		if !index_ok || count >= MAX_ROUTE_SUBMISSION_NODES {
			return 0, false
		}
		nodes[count] = index
		count += 1
	}
	return count, count >= 2
}

// Validador robusto: propaga una ventana [llegada temprana, llegada tardía].
// Una arista sólo es admisible si toda la ventana de salida evita su cierre.
// Se acepta la banda operativa minimax, no una única ruta de coste puntual.
validate_route_submission :: proc(
	instance: ^Route_Instance,
	text: string,
) -> (result: Validation_Result, cost: int) {
	nodes: [MAX_ROUTE_SUBMISSION_NODES]int
	count, parse_ok := parse_route_nodes(instance, text, &nodes)
	if !parse_ok {
		return .Format_Invalid, 0
	}
	if nodes[0] != instance.start || nodes[count - 1] != instance.goal {
		return .Impossible, 0
	}
	visited: [MAX_ROUTE_NODES]bool
	for index in 0..<count {
		if visited[nodes[index]] {
			return .Impossible, 0
		}
		visited[nodes[index]] = true
	}

	earliest := 0
	latest := 0
	total := 0
	for step in 0..<count - 1 {
		edge, found := route_find_edge(instance, nodes[step], nodes[step + 1])
		if !found {
			return .Impossible, 0
		}
		if !route_edge_robust_open(edge, earliest, latest) {
			return .Impossible, 0
		}
		earliest += edge.minutes
		latest += edge.minutes + edge.delay_max
		total += route_edge_cost(edge)
	}

	reference := solve_route(instance)
	if !reference.found {
		return .Viable, total
	}
	if total <= reference.cost + ROUTE_ACCEPTANCE_MARGIN {
		return .Optimal, total
	}
	return .Viable, total
}

route_solution_text :: proc(instance: ^Route_Instance, solution: ^Route_Solution) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	for index in 0..<solution.length {
		if index > 0 {
			_ = strings.write_byte(&builder, '>')
		}
		_ = strings.write_string(&builder, route_node_name(solution.path[index]))
	}
	return strings.to_string(builder)
}

// ---------------------------------------------------------------------------
// Incidente 3 // CAPACIDAD SOBREVIVIBLE
// Dos reservas de flujo disjuntas y de costo mínimo; las capacidades
// planificables descuentan tráfico civil y headroom operativo.
// ---------------------------------------------------------------------------

MAX_FLOW_NODES :: 6
MAX_FLOW_EDGES :: 12

FLOW_MIDDLE_NAMES :: [4]string{"A", "B", "C", "D"}

Flow_Edge :: struct {
	from, to: int,
	capacity: int,
	reserve:  int,
	cost:     int,
}

Flow_Instance :: struct {
	node_count: int,
	edge_count: int,
	edges:      [MAX_FLOW_EDGES]Flow_Edge,
	source:     int,
	sink:       int,
	demand:     int,
	optimal_cost: int,
	seed:       u64,
}

Flow_Plan :: struct {
	amounts: [MAX_FLOW_EDGES]int,
	total:   int,
	cost:    int,
}

Flow_Resilient_Solution :: struct {
	found:   bool,
	cost:    int,
	primary: Flow_Plan,
	backup:  Flow_Plan,
}

flow_node_name :: proc(instance: ^Flow_Instance, index: int) -> string {
	if index == instance.source {
		return "S"
	}
	if index == instance.sink {
		return "T"
	}
	names := FLOW_MIDDLE_NAMES
	return names[index - 1]
}

flow_node_index :: proc(instance: ^Flow_Instance, name: string) -> (int, bool) {
	if strings.equal_fold(name, "S") {
		return instance.source, true
	}
	if strings.equal_fold(name, "T") {
		return instance.sink, true
	}
	names := FLOW_MIDDLE_NAMES
	for index in 1..<instance.node_count - 1 {
		if strings.equal_fold(name, names[index - 1]) {
			return index, true
		}
	}
	return 0, false
}

flow_edge_capacity :: proc(instance: ^Flow_Instance, from, to: int) -> (int, bool) {
	total := 0
	found := false
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		if edge.from == from && edge.to == to {
			total += edge.capacity
			found = true
		}
	}
	return total, found
}

flow_edge_index :: proc(instance: ^Flow_Instance, from, to: int) -> (int, bool) {
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		if edge.from == from && edge.to == to {
			return index, true
		}
	}
	return 0, false
}

flow_plannable_capacity :: proc(edge: Flow_Edge) -> int {
	return max(0, edge.capacity - edge.reserve)
}

flow_add_edge :: proc(instance: ^Flow_Instance, from, to, capacity: int) {
	if instance.edge_count >= MAX_FLOW_EDGES {
		return
	}
	instance.edges[instance.edge_count] = Flow_Edge{
		from = from, to = to, capacity = capacity, reserve = 0, cost = 1,
	}
	instance.edge_count += 1
}

flow_add_resilient_edge :: proc(
	instance: ^Flow_Instance,
	from, to, plannable, reserve, cost: int,
) {
	if instance.edge_count >= MAX_FLOW_EDGES {
		return
	}
	instance.edges[instance.edge_count] = Flow_Edge{
		from = from,
		to = to,
		capacity = plannable + reserve,
		reserve = reserve,
		cost = cost,
	}
	instance.edge_count += 1
}

flow_add_generated_edge :: proc(
	instance: ^Flow_Instance,
	state: ^u64,
	from, to, plannable: int,
) {
	flow_add_resilient_edge(instance, from, to, plannable, 1, 1 + rng_below(state, 9))
}

// La topología experta contiene dos pares de origen/destino desbalanceados.
// Cada plan necesita un enlace cruzado; dos planes tolerantes a un fallo deben
// usar conjuntos de aristas disjuntos. La reserva por enlace queda fuera de la
// capacidad planificable, por lo que ninguna solución satura el medio físico.
flow_candidate :: proc(state: ^u64, seed: u64) -> Flow_Instance {
	instance: Flow_Instance
	instance.seed = seed
	middle_count := 4
	instance.node_count = middle_count + 2
	instance.source = 0
	instance.sink = instance.node_count - 1

	low := 2 + rng_below(state, 3)
	surplus := 2 + rng_below(state, 4)
	high := low + surplus
	instance.demand = low + high

	flow_add_generated_edge(&instance, state, instance.source, 1, high) // S>A
	flow_add_generated_edge(&instance, state, 1, instance.sink, low)    // A>T
	flow_add_generated_edge(&instance, state, instance.source, 2, low)  // S>B
	flow_add_generated_edge(&instance, state, 2, instance.sink, high)   // B>T
	flow_add_generated_edge(&instance, state, instance.source, 3, high) // S>C
	flow_add_generated_edge(&instance, state, 3, instance.sink, low)    // C>T
	flow_add_generated_edge(&instance, state, instance.source, 4, low)  // S>D
	flow_add_generated_edge(&instance, state, 4, instance.sink, high)   // D>T
	flow_add_generated_edge(&instance, state, 1, 2, surplus)            // A>B
	flow_add_generated_edge(&instance, state, 1, 4, surplus)            // A>D
	flow_add_generated_edge(&instance, state, 3, 2, surplus)            // C>B
	flow_add_generated_edge(&instance, state, 3, 4, surplus)            // C>D

	for index in 0..<instance.edge_count {
		swap_index := index + rng_below(state, instance.edge_count - index)
		instance.edges[index], instance.edges[swap_index] = instance.edges[swap_index], instance.edges[index]
	}
	return instance
}

generate_flow_instance :: proc(seed: u64) -> Flow_Instance {
	state := seed
	instance := flow_candidate(&state, seed)
	solution := flow_resilient_solution(&instance)
	instance.optimal_cost = solution.cost
	return instance
}

Flow_Entry :: struct {
	edge, amount: int,
}

flow_parse_plan :: proc(
	instance: ^Flow_Instance,
	text: string,
	amounts: ^[MAX_FLOW_EDGES]int,
) -> Submission_Result {
	trimmed := strings.trim_space(text)
	if len(trimmed) == 0 {
		return .Format_Invalid
	}
	count := 0
	remaining := trimmed
	for raw_entry in strings.split_iterator(&remaining, ",") {
		entry := strings.trim_space(raw_entry)
		equals := strings.index_byte(entry, '=')
		if equals <= 0 || equals >= len(entry) - 1 {
			return .Format_Invalid
		}
		pair := entry[:equals]
		amount_text := strings.trim_space(entry[equals + 1:])
		separator := strings.index_byte(pair, '>')
		if separator < 0 {
			separator = strings.index_byte(pair, '-')
		}
		if separator <= 0 || separator >= len(pair) - 1 {
			return .Format_Invalid
		}
		from, from_ok := flow_node_index(instance, strings.trim_space(pair[:separator]))
		to, to_ok := flow_node_index(instance, strings.trim_space(pair[separator + 1:]))
		amount, amount_ok := strconv.parse_int(amount_text)
		if !from_ok || !to_ok || !amount_ok || amount <= 0 {
			return .Format_Invalid
		}
		edge_index, exists := flow_edge_index(instance, from, to)
		if !exists {
			return .Impossible
		}
		if amounts[edge_index] != 0 {
			return .Format_Invalid
		}
		amounts[edge_index] = amount
		count += 1
	}
	return .Valid if count > 0 else .Format_Invalid
}

flow_plan_metrics :: proc(
	instance: ^Flow_Instance,
	amounts: ^[MAX_FLOW_EDGES]int,
) -> (result: Submission_Result, total, cost: int) {
	inflow: [MAX_FLOW_NODES]int
	outflow: [MAX_FLOW_NODES]int
	for index in 0..<instance.edge_count {
		amount := amounts[index]
		if amount == 0 {
			continue
		}
		edge := instance.edges[index]
		if amount > flow_plannable_capacity(edge) {
			return .Impossible, 0, 0
		}
		outflow[edge.from] += amount
		inflow[edge.to] += amount
		cost += amount * edge.cost
	}
	for node in 0..<instance.node_count {
		if node == instance.source || node == instance.sink {
			continue
		}
		if inflow[node] != outflow[node] {
			return .Impossible, 0, 0
		}
	}
	if inflow[instance.source] != 0 || outflow[instance.sink] != 0 {
		return .Impossible, 0, 0
	}
	total = outflow[instance.source]
	if total != inflow[instance.sink] {
		return .Impossible, total, cost
	}
	return .Valid, total, cost
}

flow_plan_label :: proc(text: string) -> (plan: int, payload: string, ok: bool) {
	colon := strings.index_byte(text, ':')
	if colon <= 0 || colon >= len(text) - 1 {
		return 0, "", false
	}
	label := strings.trim_space(text[:colon])
	if argument_matches(label, "P", "PRIMARY", "PRIMARIO") {
		return 0, strings.trim_space(text[colon + 1:]), true
	}
	if argument_matches(label, "B", "BACKUP", "RESPALDO") {
		return 1, strings.trim_space(text[colon + 1:]), true
	}
	return 0, "", false
}

// Valida dos reservas de flujo completas, disjuntas y de coste mínimo.
validate_flow_submission :: proc(
	instance: ^Flow_Instance,
	text: string,
) -> (result: Validation_Result, total, cost: int) {
	trimmed := strings.trim_space(text)
	if len(trimmed) == 0 {
		return .Format_Invalid, 0, 0
	}
	semicolon := strings.index_byte(trimmed, ';')
	if semicolon <= 0 || semicolon >= len(trimmed) - 1 ||
	   strings.index_byte(trimmed[semicolon + 1:], ';') >= 0 {
		return .Format_Invalid, 0, 0
	}
	first_plan, first_payload, first_ok := flow_plan_label(strings.trim_space(trimmed[:semicolon]))
	second_plan, second_payload, second_ok := flow_plan_label(strings.trim_space(trimmed[semicolon + 1:]))
	if !first_ok || !second_ok || first_plan == second_plan {
		return .Format_Invalid, 0, 0
	}
	plans: [2][MAX_FLOW_EDGES]int
	first_result := flow_parse_plan(instance, first_payload, &plans[first_plan])
	second_result := flow_parse_plan(instance, second_payload, &plans[second_plan])
	if first_result == .Format_Invalid || second_result == .Format_Invalid {
		return .Format_Invalid, 0, 0
	}
	if first_result == .Impossible || second_result == .Impossible {
		return .Impossible, 0, 0
	}
	for index in 0..<instance.edge_count {
		if plans[0][index] > 0 && plans[1][index] > 0 {
			return .Impossible, 0, 0
		}
	}
	primary_result, primary_total, primary_cost := flow_plan_metrics(instance, &plans[0])
	backup_result, backup_total, backup_cost := flow_plan_metrics(instance, &plans[1])
	if primary_result != .Valid || backup_result != .Valid {
		return .Impossible, 0, 0
	}
	total = min(primary_total, backup_total)
	cost = primary_cost + backup_cost
	if primary_total < instance.demand || backup_total < instance.demand {
		return .Insufficient, total, cost
	}
	if primary_total == instance.demand && backup_total == instance.demand &&
	   cost <= instance.optimal_cost {
		return .Optimal, total, cost
	}
	return .Viable, total, cost
}

flow_plan_set :: proc(
	instance: ^Flow_Instance,
	plan: ^Flow_Plan,
	from, to, amount: int,
) -> bool {
	index, found := flow_edge_index(instance, from, to)
	if !found || amount <= 0 || amount > flow_plannable_capacity(instance.edges[index]) {
		return false
	}
	plan.amounts[index] = amount
	plan.cost += amount * instance.edges[index].cost
	return true
}

flow_pair_plan :: proc(instance: ^Flow_Instance, surplus_node, deficit_node: int) -> (Flow_Plan, bool) {
	plan: Flow_Plan
	source_high_index, source_high_ok := flow_edge_index(instance, instance.source, surplus_node)
	sink_low_index, sink_low_ok := flow_edge_index(instance, surplus_node, instance.sink)
	source_low_index, source_low_ok := flow_edge_index(instance, instance.source, deficit_node)
	sink_high_index, sink_high_ok := flow_edge_index(instance, deficit_node, instance.sink)
	if !source_high_ok || !sink_low_ok || !source_low_ok || !sink_high_ok {
		return {}, false
	}
	high := flow_plannable_capacity(instance.edges[source_high_index])
	low := flow_plannable_capacity(instance.edges[sink_low_index])
	deficit_in := flow_plannable_capacity(instance.edges[source_low_index])
	deficit_out := flow_plannable_capacity(instance.edges[sink_high_index])
	surplus := high - low
	if high + deficit_in != instance.demand || low + deficit_out != instance.demand ||
	   surplus <= 0 || deficit_out - deficit_in != surplus {
		return {}, false
	}
	ok := flow_plan_set(instance, &plan, instance.source, surplus_node, high) &&
	      flow_plan_set(instance, &plan, surplus_node, instance.sink, low) &&
	      flow_plan_set(instance, &plan, instance.source, deficit_node, deficit_in) &&
	      flow_plan_set(instance, &plan, deficit_node, instance.sink, deficit_out) &&
	      flow_plan_set(instance, &plan, surplus_node, deficit_node, surplus)
	plan.total = instance.demand
	return plan, ok
}

flow_resilient_solution :: proc(instance: ^Flow_Instance) -> Flow_Resilient_Solution {
	first_primary, first_primary_ok := flow_pair_plan(instance, 1, 2)
	first_backup, first_backup_ok := flow_pair_plan(instance, 3, 4)
	second_primary, second_primary_ok := flow_pair_plan(instance, 1, 4)
	second_backup, second_backup_ok := flow_pair_plan(instance, 3, 2)
	first_cost := first_primary.cost + first_backup.cost
	second_cost := second_primary.cost + second_backup.cost
	if first_primary_ok && first_backup_ok && (!second_primary_ok || !second_backup_ok || first_cost <= second_cost) {
		return {
			found = true, cost = first_cost, primary = first_primary, backup = first_backup,
		}
	}
	if second_primary_ok && second_backup_ok {
		return {
			found = true, cost = second_cost, primary = second_primary, backup = second_backup,
		}
	}
	return {}
}

flow_plan_text :: proc(instance: ^Flow_Instance, plan: ^Flow_Plan) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	first := true
	for index in 0..<instance.edge_count {
		amount := plan.amounts[index]
		if amount <= 0 {
			continue
		}
		if !first {
			_ = strings.write_byte(&builder, ',')
		}
		edge := instance.edges[index]
		_ = strings.write_string(&builder, flow_node_name(instance, edge.from))
		_ = strings.write_byte(&builder, '>')
		_ = strings.write_string(&builder, flow_node_name(instance, edge.to))
		_ = strings.write_byte(&builder, '=')
		_ = strings.write_int(&builder, amount)
		first = false
	}
	return strings.to_string(builder)
}

// Asignación redundante de referencia; sólo para pistas y pruebas.
flow_assignment_text :: proc(instance: ^Flow_Instance) -> string {
	solution := flow_resilient_solution(instance)
	return fmt.tprintf(
		"P:%s;B:%s",
		flow_plan_text(instance, &solution.primary),
		flow_plan_text(instance, &solution.backup),
	)
}

// ---------------------------------------------------------------------------
// Incidente 4 // ÚLTIMA PORTADORA
// Nueve recepciones de una misma trama con calidad decreciente. La mayoría de
// bits falla en campos críticos; la suma de log-verosimilitudes por bit recupera
// la trama, que se autentica localmente con CRC-16/CCITT-FALSE.
// ---------------------------------------------------------------------------

BEACON_FRAME_SIZE :: 16
BEACON_COPY_COUNT :: 9
BEACON_CHANNEL_MIN :: 1
BEACON_CHANNEL_MAX :: 32
BEACON_OFFSET_MIN :: -250
BEACON_OFFSET_MAX :: 250
BEACON_MIN_LLR_MARGIN :: 100

Beacon_Copy :: struct {
	data:       [BEACON_FRAME_SIZE]u8,
	signal_dbm: int,
	bit_error_ppm: int,
	llr_weight: int,
	error_count: int,
}

Beacon_Instance :: struct {
	frame:                  [BEACON_FRAME_SIZE]u8,
	copies:                 [BEACON_COPY_COUNT]Beacon_Copy,
	channel:                int,
	offset_ms:              int,
	repetition_id:          int,
	crc16:                  u16,
	min_llr_margin:         int,
	majority_failure_count: int,
	seed:                   u64,
}

beacon_signal_weight :: proc(signal_dbm: int) -> int {
	if signal_dbm >= -56 {
		return 530
	}
	if signal_dbm >= -63 {
		return 389
	}
	if signal_dbm >= -71 {
		return 220
	}
	if signal_dbm >= -80 {
		return 85
	}
	return 20
}

beacon_bit_error_ppm :: proc(signal_dbm: int) -> int {
	if signal_dbm >= -56 {
		return 5_000
	}
	if signal_dbm >= -63 {
		return 20_000
	}
	if signal_dbm >= -71 {
		return 100_000
	}
	if signal_dbm >= -80 {
		return 300_000
	}
	return 450_000
}

beacon_crc16 :: proc(data: []u8) -> u16 {
	crc := u16(0xFFFF)
	for byte in data {
		crc ~= u16(byte) << 8
		for _ in 0..<8 {
			if crc & 0x8000 != 0 {
				crc = crc << 1 ~ 0x1021
			} else {
				crc <<= 1
			}
		}
	}
	return crc
}

beacon_decode_crc16 :: proc(frame: ^[BEACON_FRAME_SIZE]u8) -> u16 {
	return u16(frame[14]) << 8 | u16(frame[15])
}

beacon_crc16_valid :: proc(frame: ^[BEACON_FRAME_SIZE]u8) -> bool {
	return beacon_crc16(frame[:BEACON_FRAME_SIZE - 2]) == beacon_decode_crc16(frame)
}

beacon_decode_offset :: proc(frame: ^[BEACON_FRAME_SIZE]u8) -> int {
	encoded := int(frame[3]) << 8 | int(frame[4])
	if encoded >= 0x8000 {
		encoded -= 0x10000
	}
	return encoded
}

beacon_decode_repetition :: proc(frame: ^[BEACON_FRAME_SIZE]u8) -> int {
	return int(frame[10]) << 8 | int(frame[11])
}

beacon_corrupt_at :: proc(copy: ^Beacon_Copy, position: int, mask: u8) {
	if position < 0 || position >= BEACON_FRAME_SIZE || mask == 0 {
		return
	}
	copy.data[position] ~= mask
	copy.error_count += 1
}

beacon_simple_reconstruct :: proc(instance: ^Beacon_Instance) -> [BEACON_FRAME_SIZE]u8 {
	result: [BEACON_FRAME_SIZE]u8
	for position in 0..<BEACON_FRAME_SIZE {
		for bit in 0..<8 {
			ones := 0
			mask := u8(1 << u32(bit))
			for copy in instance.copies {
				if copy.data[position] & mask != 0 {
					ones += 1
				}
			}
			if ones * 2 > BEACON_COPY_COUNT {
				result[position] |= mask
			}
		}
	}
	return result
}

beacon_bit_llr :: proc(instance: ^Beacon_Instance, position, bit: int) -> int {
	result := 0
	mask := u8(1 << u32(bit))
	for copy in instance.copies {
		if copy.data[position] & mask != 0 {
			result += copy.llr_weight
		} else {
			result -= copy.llr_weight
		}
	}
	return result
}

beacon_soft_reconstruct :: proc(instance: ^Beacon_Instance) -> [BEACON_FRAME_SIZE]u8 {
	result: [BEACON_FRAME_SIZE]u8
	for position in 0..<BEACON_FRAME_SIZE {
		for bit in 0..<8 {
			if beacon_bit_llr(instance, position, bit) > 0 {
				result[position] |= u8(1 << u32(bit))
			}
		}
	}
	return result
}

beacon_weighted_reconstruct :: proc(instance: ^Beacon_Instance) -> [BEACON_FRAME_SIZE]u8 {
	return beacon_soft_reconstruct(instance)
}

generate_beacon_instance :: proc(seed: u64) -> Beacon_Instance {
	instance: Beacon_Instance
	instance.seed = seed
	state := seed
	instance.channel = BEACON_CHANNEL_MIN + rng_below(&state, BEACON_CHANNEL_MAX)
	instance.offset_ms = -180 + rng_below(&state, 361)

	instance.frame[0] = 0xD3
	instance.frame[1] = 0x01
	instance.frame[2] = u8(instance.channel)
	encoded_offset := instance.offset_ms
	if encoded_offset < 0 {
		encoded_offset += 0x10000
	}
	instance.frame[3] = u8(encoded_offset >> 8)
	instance.frame[4] = u8(encoded_offset)
	transmitter := "REP06"
	for index in 0..<len(transmitter) {
		instance.frame[5 + index] = transmitter[index]
	}
	instance.repetition_id = rng_below(&state, 0x10000)
	instance.frame[10] = u8(instance.repetition_id >> 8)
	instance.frame[11] = u8(instance.repetition_id)
	instance.frame[12] = u8(rng_below(&state, 0x100))
	instance.frame[13] = u8(rng_below(&state, 0x100))
	instance.crc16 = beacon_crc16(instance.frame[:BEACON_FRAME_SIZE - 2])
	instance.frame[14] = u8(instance.crc16 >> 8)
	instance.frame[15] = u8(instance.crc16)

	signal_bases := [BEACON_COPY_COUNT]int{-51, -59, -66, -76, -83, -88, -93, -97, -101}
	majority_positions := [3]int{2, 3, 10}
	majority_masks := [3]u8{0x40, 0x20, 0x08}

	// Las tres primeras copias conservan la mayor parte de la trama. Las seis
	// débiles comparten tres errores para derrotar la mayoría simple en todos
	// los campos que exige el enganche. Si los errores aleatorios adicionales
	// reducen demasiado el margen, se vuelve a muestrear sólo la recepción.
	for {
		instance.copies = [BEACON_COPY_COUNT]Beacon_Copy{}
		instance.min_llr_margin = 0
		instance.majority_failure_count = 0

		for copy_index in 0..<BEACON_COPY_COUNT {
			instance.copies[copy_index].data = instance.frame
			jitter_bound := 4 if copy_index < 4 else 3
			instance.copies[copy_index].signal_dbm = signal_bases[copy_index] - rng_below(&state, jitter_bound)
			instance.copies[copy_index].bit_error_ppm = beacon_bit_error_ppm(instance.copies[copy_index].signal_dbm)
			instance.copies[copy_index].llr_weight = beacon_signal_weight(instance.copies[copy_index].signal_dbm)
		}

		for copy_index in 3..<BEACON_COPY_COUNT {
			for position, index in majority_positions {
				beacon_corrupt_at(&instance.copies[copy_index], position, majority_masks[index])
			}
		}

		// Los errores adicionales crecen con cada eco. En las copias fuertes no
		// comparten posición, de modo que la suma ponderada conserva la verdad.
		strong_used: [BEACON_FRAME_SIZE]bool
		for position in majority_positions {
			strong_used[position] = true
		}
		for copy_index in 1..=2 {
			target := copy_index
			for instance.copies[copy_index].error_count < target {
				position := rng_below(&state, BEACON_FRAME_SIZE)
				if strong_used[position] {
					continue
				}
				strong_used[position] = true
				mask := u8(1 << u32(rng_below(&state, 8)))
				beacon_corrupt_at(&instance.copies[copy_index], position, mask)
			}
		}

		weak_targets := [BEACON_COPY_COUNT - 3]int{5, 7, 9, 11, 13, 15}
		for weak_index in 0..<len(weak_targets) {
			copy_index := weak_index + 3
			changed: [BEACON_FRAME_SIZE]bool
			for position in majority_positions {
				changed[position] = true
			}
			for instance.copies[copy_index].error_count < weak_targets[weak_index] {
				position := rng_below(&state, BEACON_FRAME_SIZE)
				if changed[position] {
					continue
				}
				changed[position] = true
				mask := u8(1 << u32(rng_below(&state, 8)))
				beacon_corrupt_at(&instance.copies[copy_index], position, mask)
			}
		}

		simple := beacon_simple_reconstruct(&instance)
		for position in 0..<BEACON_FRAME_SIZE {
			if simple[position] != instance.frame[position] {
				instance.majority_failure_count += 1
			}
		}
		soft := beacon_soft_reconstruct(&instance)
		instance.min_llr_margin = max(int)
		for position in 0..<BEACON_FRAME_SIZE {
			for bit in 0..<8 {
				margin := abs(beacon_bit_llr(&instance, position, bit))
				if margin < instance.min_llr_margin {
					instance.min_llr_margin = margin
				}
			}
		}
		if soft != instance.frame ||
		   !beacon_crc16_valid(&soft) ||
		   instance.min_llr_margin < BEACON_MIN_LLR_MARGIN {
			continue
		}
		return instance
	}
}

validate_beacon_tune :: proc(
	instance: ^Beacon_Instance,
	channel, offset_ms, repetition_id: int,
	crc16: u16,
) -> Submission_Result {
	if channel < BEACON_CHANNEL_MIN || channel > BEACON_CHANNEL_MAX ||
	   offset_ms < BEACON_OFFSET_MIN || offset_ms > BEACON_OFFSET_MAX ||
	   repetition_id < 0 || repetition_id > 0xFFFF {
		return .Format_Invalid
	}
	if channel != instance.channel ||
	   offset_ms != instance.offset_ms ||
	   repetition_id != instance.repetition_id ||
	   crc16 != instance.crc16 {
		return .Impossible
	}
	return .Valid
}

beacon_solution_text :: proc(instance: ^Beacon_Instance) -> string {
	return fmt.tprintf(
		"%d %d %d %s",
		instance.channel,
		instance.offset_ms,
		instance.repetition_id,
		hex_u16(instance.crc16),
	)
}
