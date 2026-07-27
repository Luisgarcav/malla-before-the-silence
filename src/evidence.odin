package main

import "core:fmt"
import "core:strings"

// Evidencia estructurada que el motor entrega a la interfaz web mediante WebAssembly.
// El motor entrega datos y documentación; cada adaptador decide cómo mostrarlos.
evidence_raw_text :: proc(game: ^Game_State, event: Event_Code) -> string {
	#partial switch event {
	case .Evidence_Capture:
		return packet_capture_text(&game.packet)
	case .Evidence_Protocol:
		return fmt.tprintf(`MESH ER2 // MAINTENANCE NOTE 3.0 EXCERPT

A record is divided into %d ordered data slots D[0]..D[%d]. Two additional
slots store independent recovery syndromes P and Q. For each octet position j:

%s
%s

Q uses multiplication in GF(2^8), primitive polynomial 0x11D, with α=0x02.
P/Q can reconstruct any two slots marked ERASURE. Three losses exceed this
profile. Slots contain octets; hexadecimal is only their printed
representation. Submit the lower-index missing slot first, immediately followed
by the higher-index slot.`, PACKET_DATA_SLOT_COUNT, PACKET_DATA_SLOT_COUNT - 1, packet_p_equation_text(), packet_q_equation_text())
	case .Evidence_Diagnostic:
		return packet_diagnostic_text(&game.packet)
	case .Evidence_Integrity:
		return fmt.tprintf(`INTEGRITY PROFILE // CRC32 / ISO HDLC
width=32
poly=0x04C11DB7
init=0xFFFFFFFF
refin=true
refout=true
xorout=0xFFFFFFFF
expected=%s

The expected checksum belongs to the authenticated header. It is calculated
over the binary concatenation %s, without hexadecimal text or separators.
CTRL17 repeats this check when repairing the record.`,
			hex_u32(game.packet.crc),
			packet_integrity_scope_text(),
		)
	case .Beacon_Evidence_Context:
		return beacon_context_text(&game.beacon)
	case .Beacon_Evidence_Capture:
		return beacon_capture_text(&game.beacon)
	case .Beacon_Evidence_Diagnostic:
		return beacon_diagnostic_text()
	case .Beacon_Evidence_Protocol:
		return beacon_protocol_text()
	case .Beacon_Evidence_Policy:
		return beacon_policy_text()
	}
	return ""
}

route_edges_text :: proc(instance: ^Route_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(
		&builder,
		fmt.tprintf(`CITY ROUTE EXPORT // CR02
route_id=CR02
origin=%s
destination=%s
clock_origin=t+00
edge_count=%d

FROM|TO|MINUTES
`, route_node_name(instance.start), route_node_name(instance.goal), instance.edge_count),
	)
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		_ = strings.write_string(
			&builder,
			fmt.tprintf(
				"%s|%s|%d\n",
				route_node_name(edge.from),
				route_node_name(edge.to),
				edge.minutes,
			),
		)
	}
	return strings.to_string(builder)
}

route_closures_text :: proc(instance: ^Route_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(&builder, "CITY CLOSURE BULLETIN // CR02\nFROM|TO|CLOSED_FROM|CLOSED_TO\n")
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		if edge.closed_from < 0 {
			_ = strings.write_string(
				&builder,
				fmt.tprintf("%s|%s|OPEN|OPEN\n", route_node_name(edge.from), route_node_name(edge.to)),
			)
		} else {
			_ = strings.write_string(
				&builder,
				fmt.tprintf(
					"%s|%s|t+%d|t+%d\n",
					route_node_name(edge.from),
					route_node_name(edge.to),
					edge.closed_from,
					edge.closed_to,
				),
			)
		}
	}
	return strings.to_string(builder)
}

route_reports_text :: proc(instance: ^Route_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(&builder, "LOCAL REPORT MERGE // CR02\nFROM|TO|TRACE|CONFIDENCE|AGE_MIN|DELAY_MAX\n")
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		_ = strings.write_string(
			&builder,
			fmt.tprintf(
				"%s|%s|%d|%s|%d|%d\n",
				route_node_name(edge.from),
				route_node_name(edge.to),
				edge.trace,
				confidence_name(edge.confidence),
				edge.report_age,
				edge.delay_max,
			),
		)
	}
	return strings.to_string(builder)
}

route_policy_text :: proc() -> string {
	return fmt.tprintf(`DISPATCH POLICY // LOCAL TRANSIT 4.0 / ROBUST MODE

Every segment is directed: FROM>TO does not imply that TO>FROM exists.
The clock begins at t+00. Each duration is an interval:
[MINUTES, MINUTES + DELAY_MAX]. Propagate both arrival bounds.

DELAY_MAX = confidence delay + floor(report_age / 10)
CONFIRMED=0 · PROBABLE=3 · UNVERIFIED=8

A segment is robustly open only when the entire possible departure interval
falls outside [CLOSED_FROM, CLOSED_TO). A route that might encounter a closure
is unsafe even if its nominal schedule passes.

robust_cost = worst_case_arrival + 4 * total_trace

Emergency mode accepts any robust route within %d points of the minimax cost.
This tolerance avoids false precision between statistically equivalent routes.
The controller derives every total and only needs the node sequence.`, ROUTE_ACCEPTANCE_MARGIN)
}

flow_reserved_capacity :: proc(instance: ^Flow_Instance, edge_index: int) -> int {
	state := instance.seed ~ (u64(edge_index + 1) * 0x9E3779B97F4A7C15)
	return 1 + rng_below(&state, 4)
}

flow_service_name :: proc(edge_index: int) -> string {
	services := [4]string{"HOSPITAL", "WATER", "DISPATCH", "SHELTER"}
	return services[edge_index % len(services)]
}

flow_interfaces_text :: proc(instance: ^Flow_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(
		&builder,
		fmt.tprintf(`DATA PATH INVENTORY // CAP03
incident_id=CAP03
source=%s
destination=%s
node_count=%d
edge_count=%d
failure_model=ANY_SINGLE_LINK

LINK|FROM|TO
`,
			flow_node_name(instance, instance.source),
			flow_node_name(instance, instance.sink),
			instance.node_count,
			instance.edge_count,
		),
	)
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		_ = strings.write_string(
			&builder,
			fmt.tprintf(
				"L%02d|%s|%s\n",
				index + 1,
				flow_node_name(instance, edge.from),
				flow_node_name(instance, edge.to),
			),
		)
	}
	return strings.to_string(builder)
}

flow_telemetry_text :: proc(instance: ^Flow_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(
		&builder,
		"GWT08 // CAPACITY TELEMETRY // 22:14:52\nLINK|PHYSICAL|OBSERVED|CAPTURED_AT\n",
	)
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		reserved := flow_reserved_capacity(instance, index)
		_ = strings.write_string(
			&builder,
			fmt.tprintf("L%02d|%d|%d|22:14:52\n", index + 1, edge.capacity + reserved, reserved),
		)
	}
	return strings.to_string(builder)
}

flow_reservations_text :: proc(instance: ^Flow_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(
		&builder,
		"CIVIL TRAFFIC + FAILOVER RESERVES // IMMUTABLE\nLINK|SERVICE|PROTECTED|RESIDUAL|HEADROOM|PLANNABLE|UNIT_COST\n",
	)
	for index in 0..<instance.edge_count {
		edge := instance.edges[index]
		reserved := flow_reserved_capacity(instance, index)
		_ = strings.write_string(
			&builder,
			fmt.tprintf(
				"L%02d|%s|%d|%d|%d|%d|%d\n",
				index + 1,
				flow_service_name(index),
				reserved,
				edge.capacity,
				edge.reserve,
				flow_plannable_capacity(edge),
				edge.cost,
			),
		)
	}
	return strings.to_string(builder)
}

flow_repair_text :: proc() -> string {
	return `REP06 // FIELD REPAIR LOG // TXTOM04
22:13:07  cabinet opened with mechanical override
22:13:44  auxiliary bus isolated from failed controller
22:14:11  local supply restored
22:14:18  data interface T carrier detected
22:14:19  data allocation absent; channel remains closed

Tom restored power physically. CAP03 distributes data traffic and does not
represent loads or flows in the electrical network.`
}

flow_policy_text :: proc(instance: ^Flow_Instance) -> string {
	return fmt.tprintf(`SURVIVABLE CHANNEL POLICY // REP06 / N-1
minimum_demand=%d
source=%s
destination=%s
failure_model=ANY_SINGLE_LINK
objective=MIN_TOTAL_RESERVED_UNIT_COST

Create PRIMARY (P) and BACKUP (B) plans. Each must independently carry at least
the minimum demand from S to T. They may not share any link, so failure of any
single link leaves one complete plan available.

Use only PLANNABLE capacity; HEADROOM remains untouched. Every amount must be
positive. Conservation applies separately to P and B at A, B, C, and D.

Minimize sum(amount * UNIT_COST) across both plans. Format:
P:S>A=<N>,A>T=<N>,...;B:S>C=<N>,C>T=<N>,...

Omit unused links and zeroes. Labels may be written PRIMARY/BACKUP. The
controller derives throughput and cost; do not declare either.`,
		instance.demand,
		flow_node_name(instance, instance.source),
		flow_node_name(instance, instance.sink),
	)
}

beacon_context_text :: proc(instance: ^Beacon_Instance) -> string {
	return fmt.tprintf(`BCNR6 INCIDENT CONTEXT // LAST CARRIER
incident_id=BCNR6
receiver=GWT08/REP06
captured_at=22:18:03
frame_octets=%d
copy_count=%d
carrier_lock=LOST
central_integrity=UNREACHABLE
return_channel=NO_RESPONSE
soft_decision=BIT_LLR
minimum_frame_margin=%d

REP06 changed channel and offset when power returned. The beacon repeats the
last synchronization frame Tom recorded. It is not a live response. All %d
receptions belong to the same frame and arrive with lower quality as the
battery fades.`, BEACON_FRAME_SIZE, BEACON_COPY_COUNT, BEACON_MIN_LLR_MARGIN, BEACON_COPY_COUNT)
}

beacon_probability_text :: proc(ppm: int) -> string {
	return fmt.tprintf("0.%06d", ppm)
}

beacon_capture_text :: proc(instance: ^Beacon_Instance) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	_ = strings.write_string(&builder, `BCNR6 DIVERSITY CAPTURE // GWT08
encoding=octets/hex
signal_unit=dBm
copies_are_same_transmitted_frame=true

ECHO|ARRIVED_AT|RSSI_DBM|BIT_ERROR_PROB|LLR_X100|FRAME_HEX
`)
	milliseconds := [BEACON_COPY_COUNT]string{"108", "421", "774", "119", "588", "064", "601", "247", "932"}
	seconds := [BEACON_COPY_COUNT]int{3, 3, 3, 4, 4, 5, 5, 6, 6}
	for index in 0..<BEACON_COPY_COUNT {
		copy := instance.copies[index]
		_ = strings.write_string(
			&builder,
			fmt.tprintf(
				"E%d|22:18:%02d.%s|%d|%s|%d|%s\n",
				index + 1,
				seconds[index],
				milliseconds[index],
				copy.signal_dbm,
				beacon_probability_text(copy.bit_error_ppm),
				copy.llr_weight,
				bytes_to_hex(copy.data[:]),
			),
		)
	}
	return strings.to_string(builder)
}

beacon_diagnostic_text :: proc() -> string {
	return `GWT08 // RX QUALITY CALIBRATION // LAST 60 MIN
sample_scope=BCNR6 hard bits
decision=SIGNED LOG-LIKELIHOOD SUM PER BIT

RSSI_RANGE_DBM|BIT_ERROR_PROBABILITY|LLR_WEIGHT_X100
>=-56|0.005|530
-57..-63|0.020|389
-64..-71|0.100|220
-72..-80|0.300|85
BELOW_-80|0.450|20

For every bit, add +LLR_WEIGHT when the received bit is 1 and -LLR_WEIGHT when
it is 0. Decide 1 for a positive sum and 0 for a negative sum. The absolute sum
is the confidence margin. Every reconstructed bit must reach margin 100.`
}

beacon_protocol_text :: proc() -> string {
	return `BCNR6 // FRAME SPECIFICATION 1.3 EXCERPT
frame_size=16 octets
byte_order=big-endian
signed_encoding=two's-complement

FIELD|OCTETS|ENCODING
SYNC|0|constant 0xD3
VERSION|1|unsigned
CHANNEL|2|unsigned
CLOCK_OFFSET_MS|3..4|signed int16, big-endian
TRANSMITTER_ID|5..9|ASCII
REPETITION_ID|10..11|unsigned, frozen with recorded frame
RESERVED|12..13|opaque
CRC16|14..15|CRC-16/CCITT-FALSE, big-endian

The beacon retransmits the recorded frame without changing REPETITION_ID.
Reconstruct each bit using receiver calibration. CRC parameters: width=16,
poly=0x1021, init=0xFFFF, refin=false, refout=false, xorout=0x0000. The CRC is
calculated over octets 0..13. No central signature is available.`
}

beacon_policy_text :: proc() -> string {
	return fmt.tprintf(`REP06 CARRIER LOCK POLICY // DEGRADED MODE
channel_min=%d
channel_max=%d
offset_min_ms=%d
offset_max_ms=%d
attempt_logging=enabled
minimum_abs_llr=%d

The degraded receiver requires channel, offset, frozen REPETITION_ID, and the
CRC16 recovered from the same frame. Format:
tune rep06 <CHANNEL> <CLOCK_OFFSET_MS> <REPETITION_ID> <CRC16_HEX>

REPETITION_ID is an unsigned 16-bit integer (0..65535). Values outside the
physical ranges are rejected without cost. Every incorrect attempt is logged,
consumes one window unit, and increases exposure.`,
		BEACON_CHANNEL_MIN,
		BEACON_CHANNEL_MAX,
		BEACON_OFFSET_MIN,
		BEACON_OFFSET_MAX,
		BEACON_MIN_LLR_MARGIN,
	)
}
