#+build js

package main

import "core:fmt"

WEB_COMMAND_CAPACITY :: 4096

foreign import game_web "game_web"

@(default_calling_convention="contextless")
foreign game_web {
	read_command :: proc(buffer: []u8) -> int ---
	publish_state :: proc(
		seed: string,
		window: int,
		running, capture_viewed, signal_reviewed: bool,
		location, connection, stage, exposure: string,
		event, objective, next_command, detail, evidence_bundle: string,
		raw: bool,
	) ---
}

web_game: Game_State
web_ready: bool

web_stage_name :: proc(stage: Stage) -> string {
	switch stage {
	case .Evacuation:
		return "evacuation"
	case .At_Workshop:
		return "at_workshop"
	case .Packet_Ready:
		return "packet_ready"
	case .Prototype_Complete:
		return "prototype_complete"
	case .Route_Ready:
		return "route_ready"
	case .Route_In_Transit:
		return "route_in_transit"
	case .At_Interchange:
		return "at_interchange"
	case .Interchange_Scanned:
		return "interchange_scanned"
	case .Transit_Connected:
		return "transit_connected"
	case .Act_Two_Complete:
		return "act_two_complete"
	case .Act_Three_Travel:
		return "act_three_travel"
	case .At_Service_Corridor:
		return "at_service_corridor"
	case .Corridor_Scanned:
		return "corridor_scanned"
	case .Flow_Ready:
		return "flow_ready"
	case .Act_Three_Complete:
		return "act_three_complete"
	case .Carrier_Ready:
		return "carrier_ready"
	case .Carrier_Locked:
		return "carrier_locked"
	case .Hush_Departure:
		return "hush_departure"
	case .Hush_Streets:
		return "hush_streets"
	case .Hush_Loudspeakers:
		return "hush_loudspeakers"
	case .Hush_Dead_Zone:
		return "hush_dead_zone"
	case .Hush_Approach:
		return "hush_approach"
	case .Encounter:
		return "encounter"
	}
	return "unknown"
}

web_event_name :: proc(event: Event_Code) -> string {
	switch event {
	case .None: return "none"
	case .Help: return "help"
	case .Status: return "status"
	case .Map: return "map"
	case .Scan_Annex: return "scan_annex"
	case .Scan_Workshop: return "scan_workshop"
	case .Move_Workshop: return "move_workshop"
	case .Move_Unknown: return "move_unknown"
	case .Move_While_Connected: return "move_while_connected"
	case .Already_At_Workshop: return "already_at_workshop"
	case .Connect_Success: return "connect_success"
	case .Connect_Unknown: return "connect_unknown"
	case .Connect_Wrong_Location: return "connect_wrong_location"
	case .Already_Connected: return "already_connected"
	case .Messages_Broken: return "messages_broken"
	case .Messages_Recovered: return "messages_recovered"
	case .Story_Log: return "story_log"
	case .Inspect_Success: return "inspect_success"
	case .Inspect_Need_Connection: return "inspect_need_connection"
	case .Inspect_Unknown: return "inspect_unknown"
	case .Evidence_Capture: return "evidence_capture"
	case .Evidence_Protocol: return "evidence_protocol"
	case .Evidence_Diagnostic: return "evidence_diagnostic"
	case .Evidence_Integrity: return "evidence_integrity"
	case .Evidence_Usage: return "evidence_usage"
	case .Operation_Not_Ready: return "operation_not_ready"
	case .Hint_Menu: return "hint_menu"
	case .Hint_No_Operation: return "hint_no_operation"
	case .Hint_One: return "hint_one"
	case .Hint_Two: return "hint_two"
	case .Hint_Three: return "hint_three"
	case .Hint_Four: return "hint_four"
	case .Hint_Five: return "hint_five"
	case .Hint_Usage: return "hint_usage"
	case .Repair_Valid: return "repair_valid"
	case .Repair_Format_Invalid: return "repair_format_invalid"
	case .Repair_Impossible: return "repair_impossible"
	case .Act_Two_Begin: return "act_two_begin"
	case .Route_Hint_Menu: return "route_hint_menu"
	case .Route_Hint_One: return "route_hint_one"
	case .Route_Hint_Two: return "route_hint_two"
	case .Route_Hint_Three: return "route_hint_three"
	case .Route_Hint_Four: return "route_hint_four"
	case .Route_Hint_Five: return "route_hint_five"
	case .Route_Format_Invalid: return "route_format_invalid"
	case .Route_Impossible: return "route_impossible"
	case .Route_Suboptimal: return "route_suboptimal"
	case .Route_Optimal: return "route_optimal"
	case .Route_Market: return "route_market"
	case .Route_Bridge: return "route_bridge"
	case .Route_Depot: return "route_depot"
	case .Route_Tunnel: return "route_tunnel"
	case .Route_Plaza: return "route_plaza"
	case .Route_Rail: return "route_rail"
	case .Route_Arrival: return "route_arrival"
	case .Scan_Interchange: return "scan_interchange"
	case .Connect_Transit_Need_Scan: return "connect_transit_need_scan"
	case .Connect_Transit_Success: return "connect_transit_success"
	case .Transit_Intel_Recovered: return "transit_intel_recovered"
	case .Act_Three_Begin: return "act_three_begin"
	case .Service_Corridor_Arrival: return "service_corridor_arrival"
	case .Scan_Corridor: return "scan_corridor"
	case .Connect_Corridor_Need_Scan: return "connect_corridor_need_scan"
	case .Connect_Corridor_Success: return "connect_corridor_success"
	case .Flow_Format_Invalid: return "flow_format_invalid"
	case .Flow_Impossible: return "flow_impossible"
	case .Flow_Insufficient: return "flow_insufficient"
	case .Flow_Suboptimal: return "flow_suboptimal"
	case .Flow_Optimal: return "flow_optimal"
	case .Flow_Hint_Menu: return "flow_hint_menu"
	case .Flow_Hint_One: return "flow_hint_one"
	case .Flow_Hint_Two: return "flow_hint_two"
	case .Flow_Hint_Three: return "flow_hint_three"
	case .Flow_Hint_Four: return "flow_hint_four"
	case .Flow_Hint_Five: return "flow_hint_five"
	case .Act_Four_Begin: return "act_four_begin"
	case .Connect_Carrier_Success: return "connect_carrier_success"
	case .Beacon_Evidence_Context: return "beacon_evidence_context"
	case .Beacon_Evidence_Capture: return "beacon_evidence_capture"
	case .Beacon_Evidence_Diagnostic: return "beacon_evidence_diagnostic"
	case .Beacon_Evidence_Protocol: return "beacon_evidence_protocol"
	case .Beacon_Evidence_Policy: return "beacon_evidence_policy"
	case .Beacon_Hint_Menu: return "beacon_hint_menu"
	case .Beacon_Hint_One: return "beacon_hint_one"
	case .Beacon_Hint_Two: return "beacon_hint_two"
	case .Beacon_Hint_Three: return "beacon_hint_three"
	case .Beacon_Hint_Four: return "beacon_hint_four"
	case .Beacon_Hint_Five: return "beacon_hint_five"
	case .Tune_Format_Invalid: return "tune_format_invalid"
	case .Tune_Impossible: return "tune_impossible"
	case .Tune_Valid: return "tune_valid"
	case .Carrier_Failure: return "carrier_failure"
	case .Hush_Begin: return "hush_begin"
	case .Hush_Streets: return "hush_streets"
	case .Hush_Loudspeakers: return "hush_loudspeakers"
	case .Hush_Dead_Zone: return "hush_dead_zone"
	case .Hush_Transmitter: return "hush_transmitter"
	case .Reunion: return "reunion"
	case .Disconnected: return "disconnected"
	case .Not_Connected: return "not_connected"
	case .Waited: return "waited"
	case .Failure: return "failure"
	case .Quit: return "quit"
	case .Unknown_Command: return "unknown_command"
	case .Internal_Error: return "internal_error"
	}
	return "unknown"
}

web_objective :: proc(game: ^Game_State) -> string {
	if !game.running {
		return "Session ended"
	}
	switch game.stage {
	case .Evacuation:
		return "Evacuate the annex before lockdown"
	case .At_Workshop:
		if game.connection == .None {
			return "Open a local session with CTRL17"
		}
		return "Locate the emergency record"
	case .Packet_Ready:
		return "Reconstruct both missing EMR06 fragments"
	case .Prototype_Complete:
		if game.signal_reviewed {
			return "Leave CTRL17 and open the city route"
		}
		return "Read the recovered signal from Tom"
	case .Route_Ready:
		return "Find a robust near-minimax route to the Interchange"
	case .Route_In_Transit:
		if game.route_position + 1 < game.selected_route_len {
			return fmt.tprintf(
				"Cross the next segment toward %s",
				route_node_name(game.selected_route[game.route_position + 1]),
			)
		}
		return "Continue toward the Interchange"
	case .At_Interchange:
		return "Locate an active interface at the Interchange"
	case .Interchange_Scanned:
		return "Open a local session with TRN04"
	case .Transit_Connected:
		return "Recover the latest update from Tom"
	case .Act_Two_Complete:
		return "Leave TRN04 and move to the Service Corridor"
	case .Act_Three_Travel:
		return "Reach the cabinet in the Service Corridor"
	case .At_Service_Corridor:
		return "Locate a compatible data interface"
	case .Corridor_Scanned:
		return "Open a local session with GWT08"
	case .Flow_Ready:
		return "Build the minimum-cost primary and failover plans for REP06"
	case .Act_Three_Complete:
		return "Begin the final movement toward REP06"
	case .Carrier_Ready:
		return "Recover BCNR6 fields and CRC16 with bit-level soft decisions"
	case .Carrier_Locked:
		return "Begin Act V: HUSH; the channel is open and nobody answers"
	case .Hush_Departure:
		return "Leave the cabinet and walk the final route"
	case .Hush_Streets:
		return "Cross the empty streets toward Civic Avenue"
	case .Hush_Loudspeakers:
		return "Cross the last area covered by loudspeakers"
	case .Hush_Dead_Zone:
		return "Follow REP06 beyond MALLA range"
	case .Hush_Approach:
		return "Cross the final approach to Repeater 06"
	case .Encounter:
		return "Reunited"
	}
	return ""
}

web_next_command :: proc(game: ^Game_State) -> string {
	if !game.running {
		return "restart act"
	}
	switch game.stage {
	case .Evacuation:
		return "move workshop"
	case .At_Workshop:
		if game.connection == .None {
			return "connect controller"
		}
		return "inspect emr06"
	case .Packet_Ready:
		return "evidence capture"
	case .Prototype_Complete:
		if !game.signal_reviewed {
			return "messages"
		}
		return "continue"
	case .Route_Ready:
		return "route ellie"
	case .Route_In_Transit:
		return "advance"
	case .At_Interchange:
		return "scan"
	case .Interchange_Scanned:
		return "connect trn04"
	case .Transit_Connected:
		return "inspect trn04"
	case .Act_Two_Complete:
		return "continue"
	case .Act_Three_Travel:
		return "advance"
	case .At_Service_Corridor:
		return "scan"
	case .Corridor_Scanned:
		return "connect gwt08"
	case .Flow_Ready:
		return "allocate rep06"
	case .Act_Three_Complete:
		return "continue"
	case .Carrier_Ready:
		return "tune rep06"
	case .Carrier_Locked:
		return "continue"
	case .Hush_Departure, .Hush_Streets, .Hush_Loudspeakers, .Hush_Dead_Zone, .Hush_Approach:
		return "advance"
	case .Encounter:
		return ""
	}
	return ""
}

web_detail_text :: proc(game: ^Game_State, event: Event_Code) -> string {
	if evidence := evidence_raw_text(game, event); len(evidence) > 0 {
		return evidence
	}

	#partial switch event {
	case .Hint_Menu:
		return `OPTIONAL GUIDANCE // NO COST

Hints are cumulative. Each level reveals more than the one before it:
1 target · 2 useful relation · 3 equation · 4 partial result · 5 solution`
	case .Hint_One:
		return fmt.tprintf(`HINT 1 // TARGET

The octet capture is the reliable source. D[%d] and D[%d] are missing. P and Q
are recovery syndromes, not part of the message.`, game.packet.erased[0], game.packet.erased[1])
	case .Hint_Two:
		return `HINT 2 // USEFUL RELATION

Both equations apply independently at each of the sixteen octet positions. XOR
alone produces A XOR B; Q supplies the independent equation needed to separate
the two unknown octets. ERASURE does not mean zero.`
	case .Hint_Three:
		return fmt.tprintf(`HINT 3 // EQUATION

After removing every received block from P and Q, call the residual syndromes
p' and q'. Let A=D[%d][j], B=D[%d][j]. For every position:

%s

All multiplication and inversion are in GF(2^8) with polynomial 0x11D. A script
should iterate the 16 positions across the 10 received data slots.`,
			game.packet.erased[0],
			game.packet.erased[1],
			packet_recovery_equation_text(&game.packet),
		)
	case .Hint_Four:
		first_hex, first_ascii := packet_partial_result_text(&game.packet, 0)
		second_hex, second_ascii := packet_partial_result_text(&game.packet, 1)
		return fmt.tprintf(`HINT 4 // PARTIAL RESULTS

First four octets:

D[%d] = %s    // ASCII: "%s"
D[%d] = %s    // ASCII: "%s"`,
			game.packet.erased[0], first_hex, first_ascii,
			game.packet.erased[1], second_hex, second_ascii,
		)
	case .Hint_Five:
		recovered := packet_recover_erased(&game.packet)
		solution := packet_solution_hex(&game.packet)
		return fmt.tprintf(`HINT 5 // SOLUTION

D[%d] = %s
D[%d] = %s
CONCAT = %s

repair emr06 %s`,
			game.packet.erased[0], bytes_to_hex(recovered[0][:]),
			game.packet.erased[1], bytes_to_hex(recovered[1][:]),
			solution,
			solution,
		)
	case .Repair_Format_Invalid:
		return "Invalid format. Use exactly 64 hexadecimal digits: lower missing index first."
	case .Repair_Impossible:
		return `REPAIR REJECTED // WRITE LOGGED

The fragments fail P/Q syndromes or CRC. Window −1. Exposure increased.`
	case .Repair_Valid:
		return `REPAIR ACCEPTED // RAID-6 P/Q AND CRC32 VERIFIED

TOM> ROOFTOP. ROUTE TO REP06. OK!`
	case .Act_Two_Begin:
		return `ACT II // THE CITY CLOSES

CTRL17 is disconnected. The latest transit dump contains a directed network,
scheduled closures, and local reports. CR02 dossier available.`
	case .Route_Hint_Menu:
		return `CR02 GUIDANCE // NO COST

1 target · 2 interval rule · 3 robust objective · 4 acceptance band · 5 solution`
	case .Route_Hint_One:
		return `HINT 1 // TARGET

Find a route from WORKSHOP to INTERCHANGE that remains open for every travel
time inside the published bounds. It must fall inside the minimax tolerance.`
	case .Route_Hint_Two:
		return `HINT 2 // INTERVAL PROPAGATION

Track earliest and latest cumulative arrival. Before taking an edge, the whole
departure interval must lie before its closure or after it. Any overlap makes
that path non-robust.`
	case .Route_Hint_Three:
		return fmt.tprintf(`HINT 3 // ROBUST OBJECTIVE

For every robust simple path compute:
worst_case_arrival + 4 × total_trace.

DELAY_MAX already equals confidence_delay + floor(age/10). Acceptable cost is
at most minimax + %d. Enumerating simple paths is safe with eight nodes.`, ROUTE_ACCEPTANCE_MARGIN)
	case .Route_Hint_Four:
		solution := solve_route(&game.route)
		return fmt.tprintf(`HINT 4 // ROBUST ACCEPTANCE BAND

Minimax cost: %d
Accepted through: %d
Best-path arrival interval: t+%d..t+%d across %d segments.

Use these bounds to audit your solver without revealing the node sequence.`,
			solution.cost,
			solution.cost + ROUTE_ACCEPTANCE_MARGIN,
			solution.earliest_arrival,
			solution.arrival,
			solution.length - 1,
		)
	case .Route_Hint_Five:
		solution := solve_route(&game.route)
		path := route_solution_text(&game.route, &solution)
		return fmt.tprintf(`HINT 5 // MINIMAX SOLUTION

Robust cost %d · arrival t+%d..t+%d
%s

route ellie %s`, solution.cost, solution.earliest_arrival, solution.arrival, path, path)
	case .Route_Format_Invalid:
		return `INVALID ROUTE FORMAT // NO COST

Submit a sequence from WORKSHOP to INTERCHANGE. Example:
WORKSHOP>MARKET>INTERCHANGE`
	case .Route_Impossible:
		return `ROUTE REJECTED // SEGMENT MISSING OR CLOSED

The active check leaves a trace. Window −1. Exposure increased.`
	case .Route_Suboptimal:
		return fmt.tprintf(`ROBUSTNESS MARGIN EXCEEDED // WORST-CASE COST %d

The route is open throughout its uncertainty interval, but falls outside the
operational minimax tolerance. The check leaves a trace. Window −1. Exposure
increased.`, game.route_cost)
	case .Route_Optimal:
		return fmt.tprintf(`ROBUST ROUTE ACCEPTED // WORST-CASE COST %d

Every modeled departure remains outside scheduled closures. Window −1.
Itinerary locked. Begin the crossing.`, game.route_cost)
	case .Route_Market:
		return "MARKET // SEGMENT COMPLETE. The next closure continues to advance."
	case .Route_Bridge:
		return "BRIDGE // SEGMENT COMPLETE. A mobile checkpoint occupies the previous access."
	case .Route_Depot:
		return "DEPOT // SEGMENT COMPLETE. The automated yard falls behind."
	case .Route_Tunnel:
		return "TUNNEL // SEGMENT COMPLETE. MALLA coverage drops for ninety seconds."
	case .Route_Plaza:
		return "PLAZA // SEGMENT COMPLETE. Emergency screens repeat new detentions."
	case .Route_Rail:
		return "RAIL // SEGMENT COMPLETE. Civil convoys no longer accept passengers."
	case .Route_Arrival:
		return `INTERCHANGE REACHED // NO ACTIVE SESSION

The route closes behind Ellie. Scan the node before attempting a connection.`
	case .Scan_Interchange:
		return `LOCAL SCAN // 1 INTERFACE AVAILABLE

TRN04  LOCAL/MAINT  regional authority accepted  trunk link blocked`
	case .Connect_Transit_Need_Scan:
		return "TRN04 has not been identified. Scan local interfaces first."
	case .Connect_Transit_Success:
		return `LOCAL SESSION OPEN // TRN04

The node retains emergency movements and an update signed by REP06.`
	case .Transit_Intel_Recovered:
		return `ACT II COMPLETE // TOM POSITION UPDATED

REP06 confirms that Tom left the rooftop link and reached the Substation. The
next segment requires physical power and a data route.`
	case .Act_Three_Begin:
		return `ACT III // HOSTILE INFRASTRUCTURE

Ellie closes TRN04 before moving. The Service Corridor cabinet retains a local
route toward REP06, but it requires physical access.`
	case .Service_Corridor_Arrival:
		return `SERVICE CORRIDOR REACHED // WINDOW −1

The cabinet remains powered behind a mechanical gate. No session is active.`
	case .Scan_Corridor:
		return `LOCAL SCAN // 1 COMPATIBLE INTERFACE

GWT08  DATA/MAINT  regional certificate accepted  backbone degraded`
	case .Connect_Corridor_Need_Scan:
		return "GWT08 has not been identified. Scan the local cabinet first."
	case .Connect_Corridor_Success:
		return `LOCAL SESSION OPEN // GWT08

Tom restored power to REP06 physically. Interface T responds, but the data
channel still has no allocation. CAP03 dossier available.`
	case .Flow_Format_Invalid:
		return `INVALID ALLOCATION FORMAT // NO COST

Use two labeled plans separated by a semicolon:
P:S>A=2,A>T=2;B:S>C=2,C>T=2`
	case .Flow_Impossible:
		return `ALLOCATION REJECTED // WRITE LOGGED

A link exceeds PLANNABLE capacity, is shared by both plans, does not exist, or
breaks conservation. Window −1. Exposure increased.`
	case .Flow_Insufficient:
		return fmt.tprintf(`VALID BUT INSUFFICIENT FAILOVER // GUARANTEED %d

Both PRIMARY and BACKUP must independently carry %d units. The channel remains
closed. Window −1.`,
			game.flow_total, game.flow.demand)
	case .Flow_Suboptimal:
		return fmt.tprintf(`SURVIVABLE BUT SUBOPTIMAL // TOTAL COST %d

Both plans can carry the demand and tolerate one link failure, but a cheaper
disjoint reservation exists. Window −1. Exposure increased.`, game.flow_cost)
	case .Flow_Optimal:
		return fmt.tprintf(`REP06 SURVIVABLE CHANNEL OPEN // DEMAND %d · MIN COST %d

PRIMARY and BACKUP are link-disjoint, preserve per-link headroom, and each
supports the full demand. Window −1. Exposure increased.`, game.flow.demand, game.flow_cost)
	case .Flow_Hint_Menu:
		return `CAP03 GUIDANCE // NO COST

1 target · 2 usable capacity · 3 N-1 rule · 4 optimization · 5 solution`
	case .Flow_Hint_One:
		return fmt.tprintf(`HINT 1 // TARGET

Build two complete plans, P and B. Each must send at least %d units from S to T.`,
			game.flow.demand)
	case .Flow_Hint_Two:
		return `HINT 2 // PLANNABLE CAPACITY

Use PLANNABLE, not PHYSICAL or RESIDUAL. PROTECTED civil traffic and HEADROOM
remain untouched. Apply conservation separately inside each plan.`
	case .Flow_Hint_Three:
		return `HINT 3 // SINGLE-LINK FAILURE

P and B cannot use the same directed link. If any one link fails, the plan that
does not contain it must still carry the entire demand. Both plans therefore
need their own conserved S-to-T flow.`
	case .Flow_Hint_Four:
		return fmt.tprintf(`HINT 4 // MIN-COST PAIRING

A and C have source-side surplus; B and D have sink-side capacity. Each complete
plan must pair one surplus node with one deficit node through a cross-link.
Compare both disjoint pairings using sum(amount × UNIT_COST). The optimum total
cost is %d.`, game.flow.optimal_cost)
	case .Flow_Hint_Five:
		solution := flow_assignment_text(&game.flow)
		return fmt.tprintf(`HINT 5 // SOLUTION

%s

allocate rep06 %s`, solution, solution)
	case .Act_Four_Begin:
		return `ACT IV // LAST CARRIER

The data channel loses synchronization before reaching REP06. Nine echoes of
a BCNR6 frame still arrive with a weaker signal each time. BCNR6 dossier
available. Tom no longer responds.`
	case .Connect_Carrier_Success:
		return `LOCAL SESSION REOPENED // GWT08

The BCNR6 capture remains in memory. The receiver has no carrier lock.`
	case .Beacon_Hint_Menu:
		return `BCNR6 GUIDANCE // NO COST

1 copy identity · 2 bit probability · 3 LLR + CRC · 4 partial result · 5 solution`
	case .Beacon_Hint_One:
		return `HINT 1 // ONE FRAME

E1..E9 are receptions of the same recorded frame. Compare the same bit position
across all nine echoes. Do not concatenate copies or treat arrival order as data.`
	case .Beacon_Hint_Two:
		return `HINT 2 // BIT PROBABILITIES

The numerical majority includes six weak receptions. Use the documented bit
error probability p and its LLR weight ln((1-p)/p)×100. Even weak observations
carry a small amount of evidence; none are blindly discarded.`
	case .Beacon_Hint_Three:
		return `HINT 3 // SOFT DECISION + INTEGRITY

For each bit add +weight for 1 and -weight for 0. Use the sign as the decision
and require |sum| ≥ 100. Reassemble bytes, then verify CRC-16/CCITT-FALSE over
octets 0..13 against big-endian octets 14..15.`
	case .Beacon_Hint_Four:
		reconstructed := beacon_soft_reconstruct(&game.beacon)
		return fmt.tprintf(`HINT 4 // RECOVERED FIELDS

Octets 0..4 of the soft decision: %s
Minimum bit margin across the frame: %d
Octets 10..15 remain for you to reconstruct as REPETITION_ID and CRC16.

The channel is octet 2. The offset is the signed int16 in octets 3..4, using
big endian order and two's complement.`, bytes_to_hex(reconstructed[:5]), game.beacon.min_llr_margin)
	case .Beacon_Hint_Five:
		solution := beacon_solution_text(&game.beacon)
		return fmt.tprintf(`HINT 5 // SOLUTION

Channel %d · offset %d ms · repetition %d · CRC16 %s

tune rep06 %s`, game.beacon.channel, game.beacon.offset_ms, game.beacon.repetition_id, hex_u16(game.beacon.crc16), solution)
	case .Tune_Format_Invalid:
		return fmt.tprintf(`INVALID TUNING FORMAT // NO COST

Use tune rep06 <CHANNEL> <OFFSET_MS> <REPETITION_ID> <CRC16_HEX>.
Physical ranges: channel %d..%d · offset %d..%d ms · repetition 0..65535.
CRC16_HEX must contain exactly four hexadecimal digits.`,
			BEACON_CHANNEL_MIN,
			BEACON_CHANNEL_MAX,
			BEACON_OFFSET_MIN,
			BEACON_OFFSET_MAX,
		)
	case .Tune_Impossible:
		return `NO CARRIER LOCK // ATTEMPT LOGGED

One or more recovered fields, or CRC16, do not match the repeated frame.
Window −1. Exposure increased.`
	case .Tune_Valid:
		return `CARRIER LOCKED // BIT CONFIDENCE AND CRC16 CONSISTENT

The receiver opens the channel toward REP06. No confirmation arrives. No voice
arrives. Only the noise of a connection that finally works.

END OF ACT IV // LAST CARRIER`
	case .Carrier_Failure:
		return `INTERCEPTION // GWT08 RECEIVER

The final scan correlates the regional key with the Service Corridor. GWT08
cuts the session before searching for the carrier again.`
	case .Hush_Begin:
		return `ACT V // HUSH // SESSION CLOSED

Ellie removes the physical key and puts away the laptop. No dossiers,
parameters, or technical commands remain. The beacon sounds alone beyond the
corridor.`
	case .Hush_Streets:
		return `STREETS UNDER CURFEW

Shops are dark. Traffic lights change for an avenue without vehicles while the
REP06 signal pulses in Ellie's pocket.`
	case .Hush_Loudspeakers:
		return `CIVIC AVENUE // LAST ORDER

MALLA> REGIONAL SIGNATURE LOCATED. SECTOR 06 LOCKDOWN NOW.

Loudspeakers repeat the order a few seconds apart. Ellie keeps walking. The
repeater tower is visible between the buildings.`
	case .Hush_Dead_Zone:
		return `MESH BOUNDARY // 22:27

JUNTA> NEAREST UNIT, INTERCEPT

[CENTRAL CARRIER LOST]

The order cuts out. For the first time since the annex, MALLA does not know
where Ellie is.`
	case .Hush_Transmitter:
		return `REPEATER 06 APPROACH

The service door was left open. A red light pulses inside the cabinet.

[BCNR6 // LOCAL TRANSMISSION]

Tom's transmitter repeats the final frame without knowing anyone heard it.`
	case .Reunion:
		return `REUNION // 22:31

Tom appears behind the open cabinet with grease on his hands.

TOM> You made it.
ELLIE> So did you.

The city is still occupied. Their promise is not.`
	case .Failure:
		return "INTERCEPTION // The local session was cut and the route was correlated."
	case .Unknown_Command:
		return fmt.tprintf("Command not recognized. Try this now: %s", web_next_command(game))
	case .Internal_Error:
		return "The engine could not interpret the request."
	}
	return ""
}

web_evidence_bundle :: proc(game: ^Game_State) -> string {
	if game.stage == .Carrier_Ready || game.stage == .Carrier_Locked {
		return fmt.tprintf(`---BEACON-SOURCE:CONTEXT---
%s
---BEACON-SOURCE:CAPTURE---
%s
---BEACON-SOURCE:DIAGNOSTIC---
%s
---BEACON-SOURCE:PROTOCOL---
%s
---BEACON-SOURCE:POLICY---
%s`,
			beacon_context_text(&game.beacon),
			beacon_capture_text(&game.beacon),
			beacon_diagnostic_text(),
			beacon_protocol_text(),
			beacon_policy_text(),
		)
	}

	if game.stage == .Flow_Ready || game.stage == .Act_Three_Complete {
		return fmt.tprintf(`---FLOW-SOURCE:INTERFACES---
%s
---FLOW-SOURCE:TELEMETRY---
%s
---FLOW-SOURCE:RESERVATIONS---
%s
---FLOW-SOURCE:REPAIR---
%s
---FLOW-SOURCE:POLICY---
%s`,
			flow_interfaces_text(&game.flow),
			flow_telemetry_text(&game.flow),
			flow_reservations_text(&game.flow),
			flow_repair_text(),
			flow_policy_text(&game.flow),
		)
	}

	if game.stage == .Route_Ready ||
	   game.stage == .Route_In_Transit ||
	   game.stage == .At_Interchange ||
	   game.stage == .Interchange_Scanned ||
	   game.stage == .Transit_Connected ||
	   game.stage == .Act_Two_Complete {
		return fmt.tprintf(`---ROUTE-SOURCE:EDGES---
%s
---ROUTE-SOURCE:CLOSURES---
%s
---ROUTE-SOURCE:REPORTS---
%s
---ROUTE-SOURCE:POLICY---
%s`,
			route_edges_text(&game.route),
			route_closures_text(&game.route),
			route_reports_text(&game.route),
			route_policy_text(),
		)
	}

	if game.stage == .Packet_Ready || game.stage == .Prototype_Complete {
		return fmt.tprintf(`---EMR-SOURCE:CAPTURE---
%s
---EMR-SOURCE:PROTOCOL---
%s
---EMR-SOURCE:DIAGNOSTIC---
%s
---EMR-SOURCE:INTEGRITY---
%s`,
		evidence_raw_text(game, .Evidence_Capture),
		evidence_raw_text(game, .Evidence_Protocol),
		evidence_raw_text(game, .Evidence_Diagnostic),
		evidence_raw_text(game, .Evidence_Integrity),
		)
	}

	return ""
}

web_publish :: proc(result: Command_Result) {
	defer free_all(context.temp_allocator)

	detail := web_detail_text(&web_game, result.event)
	evidence_bundle := web_evidence_bundle(&web_game)
	publish_state(
		fmt.tprintf("%d", web_game.seed),
		web_game.window,
		web_game.running,
		web_game.capture_viewed,
		web_game.signal_reviewed,
		location_name(web_game.location),
		connection_name(web_game.connection),
		web_stage_name(web_game.stage),
		exposure_name(web_game.exposure),
		web_event_name(result.event),
		web_objective(&web_game),
		web_next_command(&web_game),
		detail,
		evidence_bundle,
		result.raw,
	)
}

@(export, link_name="game_init")
web_init :: proc(seed: u64) {
	web_game = new_game(seed)
	web_ready = true
	web_publish({event = .None})
}

@(export, link_name="game_dispatch")
web_dispatch :: proc() {
	if !web_ready {
		web_publish({event = .Internal_Error})
		return
	}

	buffer: [WEB_COMMAND_CAPACITY]u8
	length := read_command(buffer[:])
	if length < 0 || length > len(buffer) {
		web_publish({event = .Internal_Error})
		return
	}

	result := execute_command(&web_game, string(buffer[:length]))
	web_publish(result)
}

main :: proc() {}
