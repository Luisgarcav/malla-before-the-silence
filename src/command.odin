package main

import "core:strings"
import "core:strconv"

Event_Code :: enum {
	None,
	Help,
	Status,
	Map,
	Scan_Annex,
	Scan_Workshop,
	Move_Workshop,
	Move_Unknown,
	Move_While_Connected,
	Already_At_Workshop,
	Connect_Success,
	Connect_Unknown,
	Connect_Wrong_Location,
	Already_Connected,
	Messages_Broken,
	Messages_Recovered,
	Story_Log,
	Inspect_Success,
	Inspect_Need_Connection,
	Inspect_Unknown,
	Evidence_Capture,
	Evidence_Protocol,
	Evidence_Diagnostic,
	Evidence_Integrity,
	Evidence_Usage,
	Operation_Not_Ready,
	Hint_Menu,
	Hint_No_Operation,
	Hint_One,
	Hint_Two,
	Hint_Three,
	Hint_Four,
	Hint_Five,
	Hint_Usage,
	Repair_Valid,
	Repair_Format_Invalid,
	Repair_Impossible,
	Act_Two_Begin,
	Route_Hint_Menu,
	Route_Hint_One,
	Route_Hint_Two,
	Route_Hint_Three,
	Route_Hint_Four,
	Route_Hint_Five,
	Route_Format_Invalid,
	Route_Impossible,
	Route_Suboptimal,
	Route_Optimal,
	Route_Market,
	Route_Bridge,
	Route_Depot,
	Route_Tunnel,
	Route_Plaza,
	Route_Rail,
	Route_Arrival,
	Scan_Interchange,
	Connect_Transit_Need_Scan,
	Connect_Transit_Success,
	Transit_Intel_Recovered,
	Act_Three_Begin,
	Service_Corridor_Arrival,
	Scan_Corridor,
	Connect_Corridor_Need_Scan,
	Connect_Corridor_Success,
	Flow_Format_Invalid,
	Flow_Impossible,
	Flow_Insufficient,
	Flow_Suboptimal,
	Flow_Optimal,
	Flow_Hint_Menu,
	Flow_Hint_One,
	Flow_Hint_Two,
	Flow_Hint_Three,
	Flow_Hint_Four,
	Flow_Hint_Five,
	Act_Four_Begin,
	Connect_Carrier_Success,
	Beacon_Evidence_Context,
	Beacon_Evidence_Capture,
	Beacon_Evidence_Diagnostic,
	Beacon_Evidence_Protocol,
	Beacon_Evidence_Policy,
	Beacon_Hint_Menu,
	Beacon_Hint_One,
	Beacon_Hint_Two,
	Beacon_Hint_Three,
	Beacon_Hint_Four,
	Beacon_Hint_Five,
	Tune_Format_Invalid,
	Tune_Impossible,
	Tune_Valid,
	Carrier_Failure,
	Hush_Begin,
	Hush_Streets,
	Hush_Loudspeakers,
	Hush_Dead_Zone,
	Hush_Transmitter,
	Reunion,
	Disconnected,
	Not_Connected,
	Waited,
	Failure,
	Quit,
	Unknown_Command,
	Internal_Error,
}

Command_Result :: struct {
	event: Event_Code,
	raw:   bool,
}

command_matches :: proc(input, command: string, minimum: int) -> bool {
	if len(input) < minimum || len(input) > len(command) {
		return false
	}
	return strings.equal_fold(input, command[:len(input)])
}

argument_matches :: proc(input: string, choices: ..string) -> bool {
	for choice in choices {
		if strings.equal_fold(input, choice) {
			return true
		}
	}
	return false
}

repair_failure_cost :: proc(game: ^Game_State) -> Event_Code {
	game.window -= 1
	increase_exposure(game)
	if is_failed(game) {
		game.running = false
		return .Failure
	}
	return .Repair_Impossible
}

route_submission_text :: proc(fields: []string) -> string {
	builder: strings.Builder
	_ = strings.builder_init(&builder, context.temp_allocator)
	for field in fields {
		_ = strings.write_string(&builder, field)
	}
	return strings.to_string(builder)
}

apply_route_cost :: proc(game: ^Game_State, window_cost: int, leaves_trace: bool) -> bool {
	game.window -= window_cost
	if leaves_trace {
		increase_exposure(game)
	}
	if is_failed(game) {
		game.running = false
		return false
	}
	return true
}

store_selected_route :: proc(game: ^Game_State, submission: string) -> bool {
	nodes: [MAX_ROUTE_SUBMISSION_NODES]int
	count, ok := parse_route_nodes(&game.route, submission, &nodes)
	if !ok {
		return false
	}
	game.selected_route = nodes
	game.selected_route_len = count
	game.route_position = 0
	game.location = route_location(nodes[0])
	return true
}

route_progress_event :: proc(node: int) -> Event_Code {
	switch node {
	case 1:
		return .Route_Market
	case 2:
		return .Route_Bridge
	case 3:
		return .Route_Depot
	case 4:
		return .Route_Tunnel
	case 5:
		return .Route_Plaza
	case 6:
		return .Route_Rail
	}
	return .Internal_Error
}

apply_flow_success_cost :: proc(game: ^Game_State) -> bool {
	game.window -= 1
	increase_exposure(game)
	if is_failed(game) {
		game.running = false
		return false
	}
	return true
}

restart_current_act :: proc(game: ^Game_State) -> Event_Code {
	act := game.current_act
	if act < 1 || act > 5 {
		act = 1
	}
	seed := game.seed
	start_window := game.act_start_window
	start_exposure := game.act_start_exposure

	game^ = new_game(seed)
	game.current_act = act
	game.act_start_window = start_window
	game.act_start_exposure = start_exposure
	game.window = start_window
	game.exposure = start_exposure

	switch act {
	case 1:
		return .None
	case 2:
		game.location = .Automated_Workshop
		game.stage = .Route_Ready
		game.capture_viewed = true
		game.signal_reviewed = true
		return .Act_Two_Begin
	case 3:
		game.location = .Transit_Interchange
		game.stage = .Act_Three_Travel
		game.capture_viewed = true
		game.signal_reviewed = true
		game.route_applied = true
		return .Act_Three_Begin
	case 4:
		game.location = .Service_Corridor
		game.connection = .Data_Gateway
		game.stage = .Carrier_Ready
		game.capture_viewed = true
		game.signal_reviewed = true
		game.route_applied = true
		game.flow_applied = true
		game.repeater_powered = true
		return .Act_Four_Begin
	case 5:
		game.location = .Service_Corridor
		game.stage = .Hush_Departure
		game.capture_viewed = true
		game.signal_reviewed = true
		game.route_applied = true
		game.flow_applied = true
		game.repeater_powered = true
		game.carrier_locked = true
		return .Hush_Begin
	}
	return .Internal_Error
}

execute_command :: proc(game: ^Game_State, line: string) -> Command_Result {
	trimmed := strings.trim_space(line)
	if len(trimmed) == 0 {
		return {event = .None}
	}

	fields, fields_error := strings.fields(trimmed)
	if fields_error != nil {
		return {event = .Internal_Error}
	}
	defer delete(fields)
	command := fields[0]

	if command_matches(command, "restart", 3) || command_matches(command, "reiniciar", 3) {
		if game.running || len(fields) != 2 || !argument_matches(fields[1], "act", "acto") {
			return {event = .Operation_Not_Ready}
		}
		return {event = restart_current_act(game)}
	}

	if command_matches(command, "help", 1) || command_matches(command, "ayuda", 2) {
		return {event = .Help}
	}
	if command_matches(command, "status", 2) || command_matches(command, "estado", 2) {
		return {event = .Status}
	}
	if command_matches(command, "scan", 2) || command_matches(command, "escanear", 2) {
		if game.stage == .At_Service_Corridor {
			game.stage = .Corridor_Scanned
			return {event = .Scan_Corridor}
		}
		if game.stage == .Corridor_Scanned ||
		   game.stage == .Flow_Ready ||
		   game.stage == .Act_Three_Complete ||
		   game.stage == .Carrier_Ready ||
		   game.stage == .Carrier_Locked {
			return {event = .Scan_Corridor}
		}
		if game.stage == .At_Interchange {
			game.stage = .Interchange_Scanned
			return {event = .Scan_Interchange}
		}
		if game.stage == .Interchange_Scanned ||
		   game.stage == .Transit_Connected ||
		   game.stage == .Act_Two_Complete {
			return {event = .Scan_Interchange}
		}
		if game.location == .Operations_Annex {
			return {event = .Scan_Annex}
		}
		return {event = .Scan_Workshop}
	}
	if command_matches(command, "map", 3) || command_matches(command, "mapa", 3) {
		return {event = .Map}
	}
	if command_matches(command, "move", 3) ||
	   command_matches(command, "mover", 3) ||
	   command_matches(command, "ir", 2) {
		if game.connection != .None {
			return {event = .Move_While_Connected}
		}
		if game.stage != .Evacuation && game.location != .Automated_Workshop {
			return {event = .Operation_Not_Ready}
		}
		if len(fields) != 2 || !argument_matches(fields[1], "workshop", "taller", "taller-automatizado") {
			return {event = .Move_Unknown}
		}
		if game.location == .Automated_Workshop {
			return {event = .Already_At_Workshop}
		}
		game.location = .Automated_Workshop
		game.stage = .At_Workshop
		game.window -= 1
		return {event = .Move_Workshop}
	}
	if command_matches(command, "connect", 1) || command_matches(command, "conectar", 3) {
		if game.connection != .None {
			return {event = .Already_Connected}
		}
		if game.location == .Service_Corridor {
			if game.stage == .Carrier_Ready {
				if len(fields) != 2 ||
				   !argument_matches(fields[1], "gwt08", "gwt-08", "gateway", "pasarela") {
					return {event = .Connect_Unknown}
				}
				game.connection = .Data_Gateway
				return {event = .Connect_Carrier_Success}
			}
			if game.stage == .At_Service_Corridor {
				return {event = .Connect_Corridor_Need_Scan}
			}
			if game.stage != .Corridor_Scanned ||
			   len(fields) != 2 ||
			   !argument_matches(fields[1], "gwt08", "gwt-08", "gateway", "pasarela") {
				return {event = .Connect_Unknown}
			}
			game.connection = .Data_Gateway
			game.repeater_powered = true
			game.stage = .Flow_Ready
			return {event = .Connect_Corridor_Success}
		}
		if game.location == .Transit_Interchange {
			if game.stage == .At_Interchange {
				return {event = .Connect_Transit_Need_Scan}
			}
			if game.stage != .Interchange_Scanned ||
			   len(fields) != 2 ||
			   !argument_matches(fields[1], "trn04", "trn-04", "node", "transit", "nodo", "transito", "tránsito") {
				return {event = .Connect_Unknown}
			}
			game.connection = .Transit_Node
			game.stage = .Transit_Connected
			return {event = .Connect_Transit_Success}
		}
		if game.location != .Automated_Workshop {
			return {event = .Connect_Wrong_Location}
		}
		if len(fields) != 2 || !argument_matches(fields[1], "controller", "ctrl17", "controlador", "ctrl-17", "legado") {
			return {event = .Connect_Unknown}
		}
		game.connection = .Legacy_Controller
		return {event = .Connect_Success}
	}
	if command_matches(command, "messages", 3) || command_matches(command, "mensajes", 3) {
		if game.stage == .Prototype_Complete {
			game.signal_reviewed = true
			return {event = .Messages_Recovered}
		}
		return {event = .Messages_Broken}
	}
	if command_matches(command, "log", 3) || command_matches(command, "historia", 4) {
		return {event = .Story_Log}
	}
	if command_matches(command, "continue", 3) || command_matches(command, "continuar", 3) {
		if game.stage == .Prototype_Complete && game.signal_reviewed {
			game.connection = .None
			game.stage = .Route_Ready
			game_begin_act(game, 2)
			return {event = .Act_Two_Begin}
		}
		if game.stage == .Act_Two_Complete {
			game.connection = .None
			game.stage = .Act_Three_Travel
			game_begin_act(game, 3)
			return {event = .Act_Three_Begin}
		}
		if game.stage == .Act_Three_Complete {
			game.stage = .Carrier_Ready
			game_begin_act(game, 4)
			return {event = .Act_Four_Begin}
		}
		if game.stage == .Carrier_Locked {
			game.connection = .None
			game.stage = .Hush_Departure
			game_begin_act(game, 5)
			return {event = .Hush_Begin}
		}
		return {event = .Operation_Not_Ready}
	}
	if command_matches(command, "inspect", 3) || command_matches(command, "inspeccionar", 3) {
		if game.connection == .Transit_Node {
			if game.stage != .Transit_Connected ||
			   len(fields) != 2 ||
			   !argument_matches(fields[1], "trn04", "trn-04", "node", "transit", "nodo", "transito", "tránsito") {
				return {event = .Inspect_Unknown}
			}
			game.stage = .Act_Two_Complete
			return {event = .Transit_Intel_Recovered}
		}
		if game.connection != .Legacy_Controller {
			return {event = .Inspect_Need_Connection}
		}
		if len(fields) != 2 || !argument_matches(fields[1], "record", "emr06", "registro", "captura", "emr-06") {
			return {event = .Inspect_Unknown}
		}
		game.stage = .Packet_Ready
		game.capture_viewed = false
		return {event = .Inspect_Success}
	}
	if command_matches(command, "evidence", 2) || command_matches(command, "evidencia", 3) {
		if game.connection == .Data_Gateway && game.stage == .Carrier_Ready {
			raw_requested := len(fields) == 3 && argument_matches(fields[2], "--raw", "raw")
			if len(fields) != 2 && !raw_requested {
				return {event = .Evidence_Usage}
			}
			if argument_matches(fields[1], "context", "contexto") {
				return {event = .Beacon_Evidence_Context, raw = raw_requested}
			}
			if argument_matches(fields[1], "capture", "captura", "ecos") {
				return {event = .Beacon_Evidence_Capture, raw = raw_requested}
			}
			if argument_matches(fields[1], "diagnostic", "diagnostico", "diagnóstico", "rssi") {
				return {event = .Beacon_Evidence_Diagnostic, raw = raw_requested}
			}
			if argument_matches(fields[1], "protocol", "bcnr6", "protocolo", "bcn-r6") {
				return {event = .Beacon_Evidence_Protocol, raw = raw_requested}
			}
			if argument_matches(fields[1], "policy", "politica", "política", "aplicacion", "aplicación") {
				return {event = .Beacon_Evidence_Policy, raw = raw_requested}
			}
			return {event = .Evidence_Usage}
		}
		if game.connection != .Legacy_Controller || game.stage != .Packet_Ready {
			return {event = .Operation_Not_Ready}
		}
		raw_requested := len(fields) == 3 && argument_matches(fields[2], "--raw", "raw")
		if len(fields) != 2 && !raw_requested {
			return {event = .Evidence_Usage}
		}
		if argument_matches(fields[1], "capture", "captura") {
			game.capture_viewed = true
			return {event = .Evidence_Capture, raw = raw_requested}
		}
		if argument_matches(fields[1], "protocol", "mesher2", "protocolo", "mesh-er/2") {
			return {event = .Evidence_Protocol, raw = raw_requested}
		}
		if argument_matches(fields[1], "diagnostic", "diagnostico", "diagnóstico", "log") {
			return {event = .Evidence_Diagnostic, raw = raw_requested}
		}
		if argument_matches(fields[1], "integrity", "integridad", "crc32") {
			return {event = .Evidence_Integrity, raw = raw_requested}
		}
		return {event = .Evidence_Usage}
	}
	if command_matches(command, "hint", 2) || command_matches(command, "pista", 2) {
		if game.stage == .Carrier_Ready {
			if len(fields) == 1 {
				return {event = .Beacon_Hint_Menu}
			}
			if len(fields) != 2 {
				return {event = .Hint_Usage}
			}
			switch fields[1] {
			case "1": return {event = .Beacon_Hint_One}
			case "2": return {event = .Beacon_Hint_Two}
			case "3": return {event = .Beacon_Hint_Three}
			case "4": return {event = .Beacon_Hint_Four}
			case "5": return {event = .Beacon_Hint_Five}
			}
			return {event = .Hint_Usage}
		}
		if game.stage == .Flow_Ready {
			if len(fields) == 1 {
				return {event = .Flow_Hint_Menu}
			}
			if len(fields) != 2 {
				return {event = .Hint_Usage}
			}
			switch fields[1] {
			case "1": return {event = .Flow_Hint_One}
			case "2": return {event = .Flow_Hint_Two}
			case "3": return {event = .Flow_Hint_Three}
			case "4": return {event = .Flow_Hint_Four}
			case "5": return {event = .Flow_Hint_Five}
			}
			return {event = .Hint_Usage}
		}
		if game.stage == .Route_Ready {
			if len(fields) == 1 {
				return {event = .Route_Hint_Menu}
			}
			if len(fields) != 2 {
				return {event = .Hint_Usage}
			}
			switch fields[1] {
			case "1": return {event = .Route_Hint_One}
			case "2": return {event = .Route_Hint_Two}
			case "3": return {event = .Route_Hint_Three}
			case "4": return {event = .Route_Hint_Four}
			case "5": return {event = .Route_Hint_Five}
			}
			return {event = .Hint_Usage}
		}
		if game.stage != .Packet_Ready {
			return {event = .Hint_No_Operation}
		}
		if len(fields) == 1 {
			return {event = .Hint_Menu}
		}
		if len(fields) != 2 {
			return {event = .Hint_Usage}
		}
		switch fields[1] {
		case "1":
			return {event = .Hint_One}
		case "2":
			return {event = .Hint_Two}
		case "3":
			return {event = .Hint_Three}
		case "4":
			return {event = .Hint_Four}
		case "5":
			return {event = .Hint_Five}
		}
		return {event = .Hint_Usage}
	}
	if command_matches(command, "repair", 3) || command_matches(command, "reparar", 3) {
		if game.connection != .Legacy_Controller || game.stage != .Packet_Ready {
			return {event = .Operation_Not_Ready}
		}
		if len(fields) != 3 || !argument_matches(fields[1], "emr06", "emr-06", "record", "registro") {
			return {event = .Repair_Format_Invalid}
		}
		validation := validate_packet_repair(&game.packet, fields[2])
		switch validation {
		case .Format_Invalid:
			return {event = .Repair_Format_Invalid}
		case .Impossible:
			return {event = repair_failure_cost(game)}
		case .Valid:
			game.stage = .Prototype_Complete
			return {event = .Repair_Valid}
		}
	}
	if command_matches(command, "route", 3) || command_matches(command, "ruta", 3) {
		if game.stage != .Route_Ready {
			return {event = .Operation_Not_Ready}
		}
		if len(fields) < 3 || !argument_matches(fields[1], "ellie", "elia") {
			return {event = .Route_Format_Invalid}
		}
		submission := route_submission_text(fields[2:])
		validation, cost := validate_route_submission(&game.route, submission)
		game.route_cost = cost
		switch validation {
		case .Format_Invalid:
			return {event = .Route_Format_Invalid}
		case .Impossible, .Insufficient:
			failure_event := repair_failure_cost(game)
			if failure_event == .Failure {
				return {event = .Failure}
			}
			return {event = .Route_Impossible}
		case .Viable:
			failure_event := repair_failure_cost(game)
			if failure_event == .Failure {
				return {event = .Failure}
			}
			return {event = .Route_Suboptimal}
		case .Optimal:
			if !apply_route_cost(game, 1, false) {
				return {event = .Failure}
			}
			if !store_selected_route(game, submission) {
				return {event = .Internal_Error}
			}
			game.route_applied = true
			game.connection = .None
			game.stage = .Route_In_Transit
			return {event = .Route_Optimal}
		}
	}
	if command_matches(command, "advance", 3) || command_matches(command, "avanzar", 3) {
		if game.stage == .Hush_Departure {
			game.location = .Silent_Streets
			game.stage = .Hush_Streets
			return {event = .Hush_Streets}
		}
		if game.stage == .Hush_Streets {
			game.location = .Civic_Avenue
			game.stage = .Hush_Loudspeakers
			return {event = .Hush_Loudspeakers}
		}
		if game.stage == .Hush_Loudspeakers {
			game.location = .Mesh_Boundary
			game.stage = .Hush_Dead_Zone
			return {event = .Hush_Dead_Zone}
		}
		if game.stage == .Hush_Dead_Zone {
			game.location = .Repeater_Approach
			game.stage = .Hush_Approach
			return {event = .Hush_Transmitter}
		}
		if game.stage == .Hush_Approach {
			game.location = .Repeater_06
			game.stage = .Encounter
			return {event = .Reunion}
		}
		if game.stage == .Act_Three_Travel {
			game.window -= 1
			if is_failed(game) {
				game.running = false
				return {event = .Failure}
			}
			game.location = .Service_Corridor
			game.stage = .At_Service_Corridor
			return {event = .Service_Corridor_Arrival}
		}
		if game.stage != .Route_In_Transit ||
		   game.selected_route_len < 2 ||
		   game.route_position + 1 >= game.selected_route_len {
			return {event = .Operation_Not_Ready}
		}
		game.route_position += 1
		node := game.selected_route[game.route_position]
		game.location = route_location(node)
		if node == game.route.goal {
			game.stage = .At_Interchange
			return {event = .Route_Arrival}
		}
		return {event = route_progress_event(node)}
	}
	if command_matches(command, "allocate", 3) || command_matches(command, "asignar", 3) {
		if game.connection != .Data_Gateway || game.stage != .Flow_Ready {
			return {event = .Operation_Not_Ready}
		}
		if len(fields) < 3 || !argument_matches(fields[1], "rep06", "rep-06", "repeater", "repetidor") {
			return {event = .Flow_Format_Invalid}
		}
		submission := route_submission_text(fields[2:])
		validation, total, cost := validate_flow_submission(&game.flow, submission)
		game.flow_total = total
		game.flow_cost = cost
		switch validation {
		case .Format_Invalid:
			return {event = .Flow_Format_Invalid}
		case .Impossible:
			failure_event := repair_failure_cost(game)
			if failure_event == .Failure {
				return {event = .Failure}
			}
			return {event = .Flow_Impossible}
		case .Insufficient:
			game.window -= 1
			if is_failed(game) {
				game.running = false
				return {event = .Failure}
			}
			return {event = .Flow_Insufficient}
		case .Viable:
			failure_event := repair_failure_cost(game)
			if failure_event == .Failure {
				return {event = .Failure}
			}
			return {event = .Flow_Suboptimal}
		case .Optimal:
			if !apply_flow_success_cost(game) {
				return {event = .Failure}
			}
			game.flow_applied = true
			game.stage = .Act_Three_Complete
			return {event = .Flow_Optimal}
		}
	}
	if command_matches(command, "tune", 2) || command_matches(command, "sintonizar", 3) {
		if game.connection != .Data_Gateway || game.stage != .Carrier_Ready {
			return {event = .Operation_Not_Ready}
		}
		if len(fields) != 6 || !argument_matches(fields[1], "rep06", "rep-06", "repeater", "repetidor") {
			return {event = .Tune_Format_Invalid}
		}
		channel, channel_ok := strconv.parse_int(fields[2])
		offset_ms, offset_ok := strconv.parse_int(fields[3])
		repetition_id, repetition_ok := strconv.parse_int(fields[4])
		crc16, crc_ok := parse_hex_u16(fields[5])
		if !channel_ok || !offset_ok || !repetition_ok || !crc_ok {
			return {event = .Tune_Format_Invalid}
		}
		validation := validate_beacon_tune(&game.beacon, channel, offset_ms, repetition_id, crc16)
		switch validation {
		case .Format_Invalid:
			return {event = .Tune_Format_Invalid}
		case .Impossible:
			game.window -= 1
			increase_exposure(game)
			if is_failed(game) {
				game.running = false
				return {event = .Carrier_Failure}
			}
			return {event = .Tune_Impossible}
		case .Valid:
			game.carrier_locked = true
			game.stage = .Carrier_Locked
			return {event = .Tune_Valid}
		}
	}
	if command_matches(command, "disconnect", 2) || command_matches(command, "desconectar", 3) {
		if game.connection == .None {
			return {event = .Not_Connected}
		}
		if game.connection == .Transit_Node && game.stage == .Transit_Connected {
			game.stage = .Interchange_Scanned
		}
		if game.connection == .Data_Gateway && game.stage == .Flow_Ready {
			game.stage = .Corridor_Scanned
		}
		game.connection = .None
		return {event = .Disconnected}
	}
	if command_matches(command, "wait", 1) || command_matches(command, "esperar", 2) {
		game.window -= 1
		if is_failed(game) {
			game.running = false
			return {event = .Failure}
		}
		return {event = .Waited}
	}
	if command_matches(command, "quit", 1) || command_matches(command, "salir", 2) {
		game.running = false
		return {event = .Quit}
	}

	return {event = .Unknown_Command}
}
