#+build !js

package main

import "core:fmt"
import "core:testing"
import "core:strings"

flip_first_hex_digit :: proc(value: string) -> string {
	prefix := "1" if value[0] == '0' else "0"
	return fmt.tprintf("%s%s", prefix, value[1:])
}

@(test)
packet_submission_accepts_valid_result :: proc(t: ^testing.T) {
	instance := generate_packet_instance(1999)
	result := validate_packet_repair(&instance, packet_solution_hex(&instance))
	testing.expect_value(t, result, Submission_Result.Valid)
}

@(test)
raid6_field_arithmetic_uses_polynomial_0x11d :: proc(t: ^testing.T) {
	testing.expect_value(t, gf256_mul(0x02, 0x80), u8(0x1D))
	for value in 1..<0x100 {
		testing.expect_value(t, gf256_mul(u8(value), gf256_inverse(u8(value))), u8(1))
	}
}

@(test)
packet_repair_accepts_lowercase_and_surrounding_space :: proc(t: ^testing.T) {
	instance := generate_packet_instance(1999)
	lower := strings.to_lower(packet_solution_hex(&instance), context.temp_allocator)
	result := validate_packet_repair(&instance, fmt.tprintf(" %s ", lower))
	testing.expect_value(t, result, Submission_Result.Valid)
}

@(test)
packet_submission_distinguishes_format_from_impossible_data :: proc(t: ^testing.T) {
	instance := generate_packet_instance(1999)
	format_result := validate_packet_repair(&instance, "not-hex")
	mutated := flip_first_hex_digit(packet_solution_hex(&instance))
	impossible_result := validate_packet_repair(&instance, mutated)
	testing.expect_value(t, format_result, Submission_Result.Format_Invalid)
	testing.expect_value(t, impossible_result, Submission_Result.Impossible)
}

@(test)
packet_instances_are_deterministic_and_always_solvable :: proc(t: ^testing.T) {
	for seed in 1..=48 {
		first := generate_packet_instance(u64(seed))
		second := generate_packet_instance(u64(seed))
		testing.expect(t, first == second)
		for erased in first.erased {
			testing.expect(t, erased >= 0 && erased < PACKET_DATA_SLOT_COUNT)
		}
		testing.expect(t, first.erased[0] < first.erased[1])
		testing.expect_value(t, len(packet_solution_hex(&first)), PACKET_REPAIR_HEX_SIZE)
		recovered := packet_recover_erased(&first)
		testing.expect(t, recovered[0] == first.blocks[first.erased[0]])
		testing.expect(t, recovered[1] == first.blocks[first.erased[1]])

		solution := packet_solution_hex(&first)
		testing.expect_value(
			t,
			validate_packet_repair(&first, solution),
			Submission_Result.Valid,
		)
		testing.expect_value(
			t,
			validate_packet_repair(&first, flip_first_hex_digit(solution)),
			Submission_Result.Impossible,
		)
	}
}

@(test)
vertical_slice_reaches_tom_message :: proc(t: ^testing.T) {
	game := new_game(1999)
	_ = execute_command(&game, "MOVE taller")
	_ = execute_command(&game, "connect ctrl17")
	_ = execute_command(&game, "inspect record")
	repair := fmt.tprintf("repair emr06 %s", packet_solution_hex(&game.packet))
	result := execute_command(&game, repair)

	testing.expect_value(t, result.event, Event_Code.Repair_Valid)
	testing.expect_value(t, game.stage, Stage.Prototype_Complete)
	testing.expect(t, game.running)

	message := execute_command(&game, "messages")
	testing.expect_value(t, message.event, Event_Code.Messages_Recovered)
	testing.expect(t, game.signal_reviewed)
}

@(test)
vertical_slice_works_with_other_seeds :: proc(t: ^testing.T) {
	for seed in 2..=9 {
		game := new_game(u64(seed))
		_ = execute_command(&game, "move taller")
		_ = execute_command(&game, "connect controlador")
		_ = execute_command(&game, "inspect emr06")
		repair := fmt.tprintf("repair emr06 %s", packet_solution_hex(&game.packet))
		result := execute_command(&game, repair)
		testing.expect_value(t, result.event, Event_Code.Repair_Valid)
		testing.expect_value(t, game.stage, Stage.Prototype_Complete)
	}
}

@(test)
spanish_command_aliases_complete_the_slice :: proc(t: ^testing.T) {
	game := new_game(1999)

	testing.expect_value(t, execute_command(&game, "ayuda").event, Event_Code.Help)
	testing.expect_value(t, execute_command(&game, "estado").event, Event_Code.Status)
	testing.expect_value(t, execute_command(&game, "escanear").event, Event_Code.Scan_Annex)
	testing.expect_value(t, execute_command(&game, "mapa").event, Event_Code.Map)
	testing.expect_value(t, execute_command(&game, "ir taller").event, Event_Code.Move_Workshop)
	testing.expect_value(t, execute_command(&game, "conectar controlador").event, Event_Code.Connect_Success)
	testing.expect_value(t, execute_command(&game, "inspeccionar emr-06").event, Event_Code.Inspect_Success)
	testing.expect_value(t, execute_command(&game, "evidencia captura").event, Event_Code.Evidence_Capture)
	testing.expect_value(t, execute_command(&game, "evidencia protocolo").event, Event_Code.Evidence_Protocol)
	testing.expect_value(t, execute_command(&game, "evidencia diagnostico").event, Event_Code.Evidence_Diagnostic)
	testing.expect_value(t, execute_command(&game, "evidencia integridad").event, Event_Code.Evidence_Integrity)
	testing.expect_value(
		t,
		execute_command(
			&game,
			fmt.tprintf("reparar emr-06 %s", packet_solution_hex(&game.packet)),
		).event,
		Event_Code.Repair_Valid,
	)
}

@(test)
spanish_session_aliases_match_their_commands :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller

	testing.expect_value(t, execute_command(&game, "mensajes").event, Event_Code.Messages_Broken)
	testing.expect_value(t, execute_command(&game, "desconectar").event, Event_Code.Disconnected)
	testing.expect_value(t, execute_command(&game, "esperar").event, Event_Code.Waited)
	testing.expect_value(t, execute_command(&game, "salir").event, Event_Code.Quit)
}

@(test)
evidence_sources_are_read_only :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Packet_Ready
	window_before := game.window

	testing.expect_value(t, execute_command(&game, "evidence protocol").event, Event_Code.Evidence_Protocol)
	testing.expect_value(t, execute_command(&game, "evidence diagnostic").event, Event_Code.Evidence_Diagnostic)
	testing.expect_value(t, execute_command(&game, "evidence integrity").event, Event_Code.Evidence_Integrity)
	testing.expect(t, !game.capture_viewed)
	testing.expect_value(t, execute_command(&game, "evidence capture").event, Event_Code.Evidence_Capture)
	testing.expect(t, game.capture_viewed)
	testing.expect_value(t, game.window, window_before)
	testing.expect_value(t, game.exposure, Exposure.Anonymous)
}

@(test)
pseudocode_workflow_commands_are_not_part_of_the_incident :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Packet_Ready

	testing.expect_value(t, execute_command(&game, "manual 2").event, Event_Code.Unknown_Command)
	testing.expect_value(t, execute_command(&game, "analyze packet").event, Event_Code.Unknown_Command)
	testing.expect_value(t, execute_command(&game, "dump").event, Event_Code.Unknown_Command)
	testing.expect_value(t, execute_command(&game, "apply result").event, Event_Code.Unknown_Command)
}

@(test)
format_errors_do_not_consume_the_window :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Packet_Ready
	window_before := game.window

	result := execute_command(&game, "repair emr06 nope")

	testing.expect_value(t, result.event, Event_Code.Repair_Format_Invalid)
	testing.expect_value(t, game.window, window_before)
	testing.expect_value(t, game.exposure, Exposure.Anonymous)
}

@(test)
impossible_results_leave_a_trace :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Packet_Ready

	wrong := flip_first_hex_digit(packet_solution_hex(&game.packet))
	result := execute_command(&game, fmt.tprintf("repair emr06 %s", wrong))

	testing.expect_value(t, result.event, Event_Code.Repair_Impossible)
	testing.expect_value(t, game.window, 5)
	testing.expect_value(t, game.exposure, Exposure.Correlated)
}

@(test)
hint_menu_is_available_without_a_cost :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Packet_Ready
	window_before := game.window

	result := execute_command(&game, "hint")

	testing.expect_value(t, result.event, Event_Code.Hint_Menu)
	testing.expect_value(t, game.window, window_before)
	testing.expect_value(t, game.exposure, Exposure.Anonymous)
}

@(test)
hints_offer_five_free_levels :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Packet_Ready
	window_before := game.window

	first := execute_command(&game, "hint 1")
	second := execute_command(&game, "pista 2")
	third := execute_command(&game, "hint 3")
	fourth := execute_command(&game, "pista 4")
	fifth := execute_command(&game, "hint 5")

	testing.expect_value(t, first.event, Event_Code.Hint_One)
	testing.expect_value(t, second.event, Event_Code.Hint_Two)
	testing.expect_value(t, third.event, Event_Code.Hint_Three)
	testing.expect_value(t, fourth.event, Event_Code.Hint_Four)
	testing.expect_value(t, fifth.event, Event_Code.Hint_Five)
	testing.expect_value(t, game.window, window_before)
	testing.expect_value(t, game.exposure, Exposure.Anonymous)
}

@(test)
hint_request_without_an_operation_is_free :: proc(t: ^testing.T) {
	game := new_game(1999)

	result := execute_command(&game, "hint 5")

	testing.expect_value(t, result.event, Event_Code.Hint_No_Operation)
}

@(test)
story_log_command_is_free :: proc(t: ^testing.T) {
	game := new_game(1999)
	window_before := game.window

	result := execute_command(&game, "log")
	alias_result := execute_command(&game, "historia")

	testing.expect_value(t, result.event, Event_Code.Story_Log)
	testing.expect_value(t, alias_result.event, Event_Code.Story_Log)
	testing.expect_value(t, game.window, window_before)
	testing.expect_value(t, game.exposure, Exposure.Anonymous)
}

@(test)
story_log_ignores_duplicates_and_keeps_the_newest_scenes :: proc(t: ^testing.T) {
	game := new_game(1999)
	game_record_story(&game, .Move_Workshop)
	game_record_story(&game, .Move_Workshop)
	testing.expect_value(t, game.story_log_len, 2)

	for _ in 0..<10 {
		game_record_story(&game, .Connect_Success)
		game_record_story(&game, .Inspect_Success)
	}
	testing.expect_value(t, game.story_log_len, STORY_LOG_CAPACITY)
	testing.expect_value(t, game.story_log[STORY_LOG_CAPACITY - 1], Event_Code.Inspect_Success)
}

@(test)
restart_act_restores_each_checkpoint_with_the_same_seed_and_resources :: proc(t: ^testing.T) {
	game := new_game(4242)
	packet := game.packet
	route := game.route
	flow := game.flow
	beacon := game.beacon

	testing.expect_value(t, execute_command(&game, "restart act").event, Event_Code.Operation_Not_Ready)
	_ = execute_command(&game, "wait")
	_ = execute_command(&game, "quit")
	testing.expect(t, !game.running)
	testing.expect_value(t, execute_command(&game, "reiniciar acto").event, Event_Code.None)
	testing.expect(t, game.running)
	testing.expect_value(t, game.current_act, 1)
	testing.expect_value(t, game.stage, Stage.Evacuation)
	testing.expect_value(t, game.location, Location.Operations_Annex)
	testing.expect_value(t, game.window, 6)
	testing.expect_value(t, game.exposure, Exposure.Anonymous)
	testing.expect(t, game.packet == packet)
	testing.expect(t, game.route == route)
	testing.expect(t, game.flow == flow)
	testing.expect(t, game.beacon == beacon)

	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Prototype_Complete
	game.signal_reviewed = true
	game.window = 4
	game.exposure = .Correlated
	testing.expect_value(t, execute_command(&game, "continue").event, Event_Code.Act_Two_Begin)
	testing.expect_value(t, game.current_act, 2)
	game.stage = .Route_In_Transit
	game.location = .Bridge
	game.window = 0
	game.exposure = .Interception
	game.running = false
	testing.expect_value(t, execute_command(&game, "restart act").event, Event_Code.Act_Two_Begin)
	testing.expect_value(t, game.stage, Stage.Route_Ready)
	testing.expect_value(t, game.location, Location.Automated_Workshop)
	testing.expect_value(t, game.connection, Connection.None)
	testing.expect_value(t, game.window, 4)
	testing.expect_value(t, game.exposure, Exposure.Correlated)
	testing.expect(t, game.signal_reviewed)

	game.location = .Transit_Interchange
	game.connection = .Transit_Node
	game.stage = .Act_Two_Complete
	game.window = 3
	game.exposure = .Located
	testing.expect_value(t, execute_command(&game, "continue").event, Event_Code.Act_Three_Begin)
	testing.expect_value(t, game.current_act, 3)
	game.stage = .Flow_Ready
	game.location = .Service_Corridor
	game.connection = .Data_Gateway
	game.window = 0
	game.running = false
	testing.expect_value(t, execute_command(&game, "restart act").event, Event_Code.Act_Three_Begin)
	testing.expect_value(t, game.stage, Stage.Act_Three_Travel)
	testing.expect_value(t, game.location, Location.Transit_Interchange)
	testing.expect_value(t, game.connection, Connection.None)
	testing.expect_value(t, game.window, 3)
	testing.expect_value(t, game.exposure, Exposure.Located)
	testing.expect(t, game.route_applied)
	testing.expect(t, !game.repeater_powered)

	game.location = .Service_Corridor
	game.connection = .Data_Gateway
	game.stage = .Act_Three_Complete
	game.flow_applied = true
	game.repeater_powered = true
	game.window = 2
	testing.expect_value(t, execute_command(&game, "continue").event, Event_Code.Act_Four_Begin)
	testing.expect_value(t, game.current_act, 4)
	game.window = 0
	game.running = false
	testing.expect_value(t, execute_command(&game, "restart act").event, Event_Code.Act_Four_Begin)
	testing.expect_value(t, game.stage, Stage.Carrier_Ready)
	testing.expect_value(t, game.location, Location.Service_Corridor)
	testing.expect_value(t, game.connection, Connection.Data_Gateway)
	testing.expect_value(t, game.window, 2)
	testing.expect_value(t, game.exposure, Exposure.Located)
	testing.expect(t, game.flow_applied)
	testing.expect(t, game.repeater_powered)
	testing.expect(t, !game.carrier_locked)

	game.stage = .Carrier_Locked
	game.carrier_locked = true
	game.window = 1
	testing.expect_value(t, execute_command(&game, "continue").event, Event_Code.Hush_Begin)
	testing.expect_value(t, game.current_act, 5)
	game.stage = .Hush_Dead_Zone
	game.location = .Mesh_Boundary
	game.window = 0
	game.running = false
	testing.expect_value(t, execute_command(&game, "restart act").event, Event_Code.Hush_Begin)
	testing.expect_value(t, game.stage, Stage.Hush_Departure)
	testing.expect_value(t, game.location, Location.Service_Corridor)
	testing.expect_value(t, game.connection, Connection.None)
	testing.expect_value(t, game.window, 1)
	testing.expect_value(t, game.exposure, Exposure.Located)
	testing.expect(t, game.carrier_locked)
	testing.expect_value(t, game.seed, u64(4242))
}

@(test)
evidence_raw_returns_clean_copyable_data :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Packet_Ready
	window_before := game.window

	result := execute_command(&game, "evidence capture --raw")
	alias_result := execute_command(&game, "evidencia protocolo raw")

	testing.expect_value(t, result.event, Event_Code.Evidence_Capture)
	testing.expect(t, result.raw)
	testing.expect_value(t, alias_result.event, Event_Code.Evidence_Protocol)
	testing.expect(t, alias_result.raw)
	testing.expect(t, game.capture_viewed)
	testing.expect_value(t, game.window, window_before)

	raw := evidence_raw_text(&game, .Evidence_Capture)
	others := packet_other_slots(&game.packet)
	testing.expect(t, strings.contains(raw, "MESH ER2 RECEIVE RECORD"))
	testing.expect(t, strings.contains(raw, "integrity_expected="))
	testing.expect(t, strings.contains(raw, packet_slot_hex(&game.packet, others[0])))
	testing.expect(t, strings.contains(raw, "ERASURE"))
	testing.expect(t, !strings.contains(raw, "\x1b["))
	testing.expect(t, !strings.contains(raw, "│"))
}

@(test)
evidence_without_raw_flag_keeps_the_previous_contract :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Packet_Ready

	result := execute_command(&game, "evidence capture")

	testing.expect_value(t, result.event, Event_Code.Evidence_Capture)
	testing.expect(t, !result.raw)
}

// ---------------------------------------------------------------------------
// Incidente 2 // CIUDAD CERRADA
// ---------------------------------------------------------------------------

manual_route_instance :: proc() -> Route_Instance {
	instance: Route_Instance
	instance.node_count = 4
	instance.start = 0
	instance.goal = 3
	instance.edge_count = 5
	// Óptimo: TALLER>MERCADO>DEPOSITO, coste 20.
	instance.edges[0] = Route_Edge{
		from = 0, to = 1, minutes = 10,
		delay_max = 0,
		closed_from = -1, closed_to = -1,
		trace = 0, confidence = .Confirmed, report_age = 0,
	}
	instance.edges[1] = Route_Edge{
		from = 1, to = 3, minutes = 10,
		delay_max = 0,
		closed_from = -1, closed_to = -1,
		trace = 0, confidence = .Confirmed, report_age = 0,
	}
	// Alternativa viable: TALLER>PUENTE>DEPOSITO, coste 24 + 15 = 39.
	instance.edges[2] = Route_Edge{
		from = 0, to = 2, minutes = 15,
		delay_max = 5,
		closed_from = -1, closed_to = -1,
		trace = 1, confidence = .Probable, report_age = 25,
	}
	instance.edges[3] = Route_Edge{
		from = 2, to = 3, minutes = 15,
		delay_max = 0,
		closed_from = -1, closed_to = -1,
		trace = 0, confidence = .Confirmed, report_age = 0,
	}
	// Atajo cerrado al momento de usarlo.
	instance.edges[4] = Route_Edge{
		from = 0, to = 3, minutes = 5,
		delay_max = 0,
		closed_from = 0, closed_to = 60,
		trace = 0, confidence = .Confirmed, report_age = 0,
	}
	return instance
}

@(test)
route_solver_finds_the_cheapest_open_path :: proc(t: ^testing.T) {
	instance := manual_route_instance()
	solution := solve_route(&instance)

	testing.expect(t, solution.found)
	testing.expect_value(t, solution.cost, 20)
	testing.expect_value(t, solution.arrival, 20)
	testing.expect_value(t, route_solution_text(&instance, &solution), "WORKSHOP>MARKET>DEPOT")
}

@(test)
route_validator_classifies_optimal_viable_and_impossible :: proc(t: ^testing.T) {
	instance := manual_route_instance()

	optimal, optimal_cost := validate_route_submission(&instance, "WORKSHOP>MARKET>DEPOT")
	viable, viable_cost := validate_route_submission(&instance, "workshop > bridge > depot")
	closed, _ := validate_route_submission(&instance, "WORKSHOP>DEPOT")
	wrong_start, _ := validate_route_submission(&instance, "MARKET>DEPOT")
	unknown, _ := validate_route_submission(&instance, "WORKSHOP>RAIL")
	short, _ := validate_route_submission(&instance, "WORKSHOP")

	testing.expect_value(t, optimal, Validation_Result.Optimal)
	testing.expect_value(t, optimal_cost, 20)
	testing.expect_value(t, viable, Validation_Result.Viable)
	testing.expect_value(t, viable_cost, 39)
	testing.expect_value(t, closed, Validation_Result.Impossible)
	testing.expect_value(t, wrong_start, Validation_Result.Impossible)
	testing.expect_value(t, unknown, Validation_Result.Format_Invalid)
	testing.expect_value(t, short, Validation_Result.Format_Invalid)
}

@(test)
route_validator_uses_intervals_and_accepts_the_operational_margin :: proc(t: ^testing.T) {
	interval := manual_route_instance()
	interval.edges[0].delay_max = 3
	interval.edges[1].closed_from = 12
	interval.edges[1].closed_to = 18
	unsafe, _ := validate_route_submission(&interval, "WORKSHOP>MARKET>DEPOT")
	testing.expect_value(t, unsafe, Validation_Result.Impossible)

	near := manual_route_instance()
	near.edges[2].minutes = 10
	near.edges[2].delay_max = 0
	near.edges[2].trace = 0
	near.edges[3].minutes = 12
	near_optimal, near_cost := validate_route_submission(&near, "WORKSHOP>BRIDGE>DEPOT")
	testing.expect_value(t, near_optimal, Validation_Result.Optimal)
	testing.expect_value(t, near_cost, 22)
}

@(test)
route_instances_are_deterministic_bounded_and_solvable :: proc(t: ^testing.T) {
	for seed in 1..=48 {
		first := generate_route_instance(u64(seed))
		second := generate_route_instance(u64(seed))
		testing.expect(t, first == second)
		testing.expect_value(t, first.node_count, MAX_ROUTE_NODES)
		testing.expect_value(t, first.edge_count, MAX_ROUTE_EDGES)
		_, direct_edge := route_find_edge(&first, first.start, first.goal)
		testing.expect(t, !direct_edge)

		solution := solve_route(&first)
		testing.expect(t, solution.found)
		testing.expect_value(t, solution.path[0], first.start)
		testing.expect_value(t, solution.path[solution.length - 1], first.goal)

		// El solver de referencia siempre produce una solución aceptada.
		result, cost := validate_route_submission(&first, route_solution_text(&first, &solution))
		testing.expect_value(t, result, Validation_Result.Optimal)
		testing.expect_value(t, cost, solution.cost)
	}
}

@(test)
generated_routes_traverse_every_selected_node :: proc(t: ^testing.T) {
	for seed in 1..=48 {
		game := new_game(u64(seed))
		game.stage = .Route_Ready
		solution := solve_route(&game.route)
		result := execute_command(
			&game,
			fmt.tprintf("route ellie %s", route_solution_text(&game.route, &solution)),
		)
		testing.expect_value(t, result.event, Event_Code.Route_Optimal)
		testing.expect_value(t, game.stage, Stage.Route_In_Transit)

		steps := 0
		for game.stage == .Route_In_Transit {
			progress := execute_command(&game, "advance")
			testing.expect(t, progress.event != .Internal_Error)
			steps += 1
		}
		testing.expect_value(t, steps, solution.length - 1)
		testing.expect_value(t, game.stage, Stage.At_Interchange)
		testing.expect_value(t, game.location, Location.Transit_Interchange)
	}
}

@(test)
act_two_route_flow_reaches_the_interchange :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Automated_Workshop
	game.connection = .Legacy_Controller
	game.stage = .Prototype_Complete
	game.signal_reviewed = true

	begin := execute_command(&game, "continuar")
	testing.expect_value(t, begin.event, Event_Code.Act_Two_Begin)
	testing.expect_value(t, game.stage, Stage.Route_Ready)
	testing.expect_value(t, game.connection, Connection.None)

	solution := solve_route(&game.route)
	testing.expect(t, solution.found)
	submission := fmt.tprintf("ruta ellie %s", route_solution_text(&game.route, &solution))
	result := execute_command(&game, submission)

	testing.expect_value(t, result.event, Event_Code.Route_Optimal)
	testing.expect_value(t, game.stage, Stage.Route_In_Transit)
	testing.expect_value(t, game.location, Location.Automated_Workshop)
	testing.expect_value(t, game.connection, Connection.None)
	for game.stage == .Route_In_Transit {
		progress := execute_command(&game, "avanzar")
		testing.expect(t, progress.event != .Internal_Error)
	}

	testing.expect_value(t, game.stage, Stage.At_Interchange)
	testing.expect_value(t, game.location, Location.Transit_Interchange)
	testing.expect(t, game.route_applied)
	testing.expect_value(t, game.route_cost, solution.cost)

	testing.expect_value(t, execute_command(&game, "scan").event, Event_Code.Scan_Interchange)
	testing.expect_value(t, game.stage, Stage.Interchange_Scanned)
	testing.expect_value(
		t,
		execute_command(&game, "connect trn04").event,
		Event_Code.Connect_Transit_Success,
	)
	testing.expect_value(t, game.stage, Stage.Transit_Connected)
	testing.expect_value(t, game.connection, Connection.Transit_Node)
	testing.expect_value(
		t,
		execute_command(&game, "inspect trn04").event,
		Event_Code.Transit_Intel_Recovered,
	)
	testing.expect_value(t, game.stage, Stage.Act_Two_Complete)
}

@(test)
route_format_errors_are_free_and_impossible_routes_leave_a_trace :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.stage = .Route_Ready
	window_before := game.window

	format_result := execute_command(&game, "route ellie WORKSHOP")
	testing.expect_value(t, format_result.event, Event_Code.Route_Format_Invalid)
	testing.expect_value(t, game.window, window_before)
	testing.expect_value(t, game.exposure, Exposure.Anonymous)

	game.route.edge_count = 1
	game.route.edges[0] = Route_Edge{
		from = 0, to = 7, minutes = 5,
		closed_from = 0, closed_to = 60,
		trace = 0, confidence = .Confirmed, report_age = 0,
	}
	impossible := execute_command(&game, "route ellie WORKSHOP>INTERCHANGE")
	testing.expect_value(t, impossible.event, Event_Code.Route_Impossible)
	testing.expect_value(t, game.window, window_before - 1)
	testing.expect_value(t, game.exposure, Exposure.Correlated)
}

@(test)
suboptimal_route_is_rejected_in_expert_mode :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.stage = .Route_Ready
	game.route = manual_route_instance()
	window_before := game.window

	result := execute_command(&game, "route ellie WORKSHOP>BRIDGE>DEPOT")

	testing.expect_value(t, result.event, Event_Code.Route_Suboptimal)
	testing.expect_value(t, game.stage, Stage.Route_Ready)
	testing.expect(t, !game.route_applied)
	testing.expect_value(t, game.window, window_before - 1)
	testing.expect_value(t, game.exposure, Exposure.Correlated)
	testing.expect_value(t, execute_command(&game, "hint 5").event, Event_Code.Route_Hint_Five)
}

// ---------------------------------------------------------------------------
// Incidente 3 // CAPACIDAD RESIDUAL
// ---------------------------------------------------------------------------

@(test)
act_three_flow_reaches_the_repeater_channel :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Transit_Interchange
	game.connection = .Transit_Node
	game.stage = .Act_Two_Complete

	begin := execute_command(&game, "continuar")
	testing.expect_value(t, begin.event, Event_Code.Act_Three_Begin)
	testing.expect_value(t, game.stage, Stage.Act_Three_Travel)
	testing.expect_value(t, game.connection, Connection.None)

	arrival := execute_command(&game, "avanzar")
	testing.expect_value(t, arrival.event, Event_Code.Service_Corridor_Arrival)
	testing.expect_value(t, game.location, Location.Service_Corridor)
	testing.expect_value(t, game.stage, Stage.At_Service_Corridor)
	testing.expect_value(
		t,
		execute_command(&game, "connect gwt08").event,
		Event_Code.Connect_Corridor_Need_Scan,
	)
	testing.expect_value(t, execute_command(&game, "scan").event, Event_Code.Scan_Corridor)
	testing.expect_value(
		t,
		execute_command(&game, "conectar gwt-08").event,
		Event_Code.Connect_Corridor_Success,
	)
	testing.expect_value(t, game.stage, Stage.Flow_Ready)
	testing.expect_value(t, game.connection, Connection.Data_Gateway)
	testing.expect(t, game.repeater_powered)

	solution := flow_assignment_text(&game.flow)
	result := execute_command(&game, fmt.tprintf("asignar rep-06 %s", solution))
	testing.expect_value(t, result.event, Event_Code.Flow_Optimal)
	testing.expect_value(t, game.stage, Stage.Act_Three_Complete)
	testing.expect(t, game.flow_applied)
	testing.expect_value(t, game.flow_total, game.flow.demand)
	testing.expect_value(t, game.flow_cost, game.flow.optimal_cost)
	testing.expect(t, game.repeater_powered)
	testing.expect_value(t, game.exposure, Exposure.Correlated)
}

@(test)
flow_format_errors_are_free_and_hints_do_not_change_state :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Service_Corridor
	game.connection = .Data_Gateway
	game.stage = .Flow_Ready
	window_before := game.window

	format_result := execute_command(&game, "allocate rep06 invalid")
	testing.expect_value(t, format_result.event, Event_Code.Flow_Format_Invalid)
	for level in 1..=5 {
		hint := execute_command(&game, fmt.tprintf("pista %d", level))
		testing.expect(t, hint.event >= .Flow_Hint_One && hint.event <= .Flow_Hint_Five)
	}
	testing.expect_value(t, game.window, window_before)
	testing.expect_value(t, game.exposure, Exposure.Anonymous)
}

@(test)
flow_validator_enforces_capacity_and_conservation :: proc(t: ^testing.T) {
	instance := generate_flow_instance(1999)

	over, _, _ := validate_flow_submission(
		&instance,
		"P:S>A=999,A>T=999;B:S>C=1,C>T=1",
	)
	unbalanced, _, _ := validate_flow_submission(
		&instance,
		"P:S>A=1;B:S>C=1,C>T=1",
	)
	unknown, _, _ := validate_flow_submission(
		&instance,
		"P:S>T=1;B:S>C=1,C>T=1",
	)
	shared, _, _ := validate_flow_submission(
		&instance,
		"P:S>A=1,A>T=1;B:S>A=1,A>T=1",
	)
	garbage, _, _ := validate_flow_submission(&instance, "sin formato")
	zero, _, _ := validate_flow_submission(
		&instance,
		"P:S>A=0,A>T=0;B:S>C=1,C>T=1",
	)
	duplicate, _, _ := validate_flow_submission(
		&instance,
		"P:S>A=1,S>A=1,A>T=2;B:S>C=1,C>T=1",
	)

	testing.expect_value(t, over, Validation_Result.Impossible)
	testing.expect_value(t, unbalanced, Validation_Result.Impossible)
	testing.expect_value(t, unknown, Validation_Result.Impossible)
	testing.expect_value(t, shared, Validation_Result.Impossible)
	testing.expect_value(t, garbage, Validation_Result.Format_Invalid)
	testing.expect_value(t, zero, Validation_Result.Format_Invalid)
	testing.expect_value(t, duplicate, Validation_Result.Format_Invalid)
}

@(test)
flow_validator_distinguishes_insufficient_and_optimal :: proc(t: ^testing.T) {
	instance := generate_flow_instance(1999)

	insufficient, low_total, _ := validate_flow_submission(
		&instance,
		"P:S>A=1,A>T=1;B:S>C=1,C>T=1",
	)
	optimal, full_total, cost := validate_flow_submission(&instance, flow_assignment_text(&instance))

	testing.expect_value(t, insufficient, Validation_Result.Insufficient)
	testing.expect_value(t, low_total, 1)
	testing.expect_value(t, optimal, Validation_Result.Optimal)
	testing.expect_value(t, full_total, instance.demand)
	testing.expect_value(t, cost, instance.optimal_cost)

	instance.optimal_cost += 1
	better_than_reference, _, better_cost := validate_flow_submission(&instance, flow_assignment_text(&instance))
	testing.expect_value(t, better_than_reference, Validation_Result.Optimal)
	testing.expect(t, better_cost < instance.optimal_cost)
}

@(test)
flow_instances_keep_demand_inside_the_band :: proc(t: ^testing.T) {
	for seed in 1..=48 {
		first := generate_flow_instance(u64(seed))
		second := generate_flow_instance(u64(seed))
		testing.expect(t, first == second)
		testing.expect_value(t, first.node_count, MAX_FLOW_NODES)
		testing.expect_value(t, first.edge_count, MAX_FLOW_EDGES)
		testing.expect(t, first.demand >= 6)
		testing.expect(t, first.optimal_cost > 0)
		solution := flow_resilient_solution(&first)
		testing.expect(t, solution.found)
		testing.expect_value(t, solution.primary.total, first.demand)
		testing.expect_value(t, solution.backup.total, first.demand)
		testing.expect_value(t, solution.cost, first.optimal_cost)
		for edge_index in 0..<first.edge_count {
			edge := first.edges[edge_index]
			testing.expect(t, edge.reserve > 0)
			testing.expect(t, flow_plannable_capacity(edge) > 0)
			testing.expect(t, !(solution.primary.amounts[edge_index] > 0 && solution.backup.amounts[edge_index] > 0))
		}
	}
}

@(test)
flow_reference_assignment_is_accepted_as_optimal :: proc(t: ^testing.T) {
	for seed in 1..=24 {
		instance := generate_flow_instance(u64(seed))
		result, total, cost := validate_flow_submission(&instance, flow_assignment_text(&instance))
		testing.expect_value(t, result, Validation_Result.Optimal)
		testing.expect_value(t, total, instance.demand)
		testing.expect_value(t, cost, instance.optimal_cost)

		// Dos flujos conservados pero pequeños son insuficientes, no inválidos.
		if instance.demand > 1 {
			small, small_total, _ := validate_flow_submission(
				&instance,
				"P:S>A=1,A>T=1;B:S>C=1,C>T=1",
			)
			testing.expect_value(t, small, Validation_Result.Insufficient)
			testing.expect_value(t, small_total, 1)
		}
	}
}

@(test)
flow_suboptimal_failover_pair_is_rejected :: proc(t: ^testing.T) {
	found := false
	for seed in 1..=48 {
		instance := generate_flow_instance(u64(seed))
		first_primary, first_primary_ok := flow_pair_plan(&instance, 1, 2)
		first_backup, first_backup_ok := flow_pair_plan(&instance, 3, 4)
		second_primary, second_primary_ok := flow_pair_plan(&instance, 1, 4)
		second_backup, second_backup_ok := flow_pair_plan(&instance, 3, 2)
		if !first_primary_ok || !first_backup_ok || !second_primary_ok || !second_backup_ok {
			continue
		}
		first_cost := first_primary.cost + first_backup.cost
		second_cost := second_primary.cost + second_backup.cost
		if first_cost == second_cost {
			continue
		}
		primary := &first_primary
		backup := &first_backup
		if second_cost > first_cost {
			primary = &second_primary
			backup = &second_backup
		}
		submission := fmt.tprintf(
			"P:%s;B:%s",
			flow_plan_text(&instance, primary),
			flow_plan_text(&instance, backup),
		)
		validation, total, cost := validate_flow_submission(&instance, submission)
		testing.expect_value(t, validation, Validation_Result.Viable)
		testing.expect_value(t, total, instance.demand)
		testing.expect(t, cost > instance.optimal_cost)

		game := new_game(u64(seed))
		game.flow = instance
		game.location = .Service_Corridor
		game.connection = .Data_Gateway
		game.stage = .Flow_Ready
		result := execute_command(&game, fmt.tprintf("allocate rep06 %s", submission))
		testing.expect_value(t, result.event, Event_Code.Flow_Suboptimal)
		testing.expect_value(t, game.stage, Stage.Flow_Ready)
		testing.expect(t, !game.flow_applied)
		found = true
		break
	}
	testing.expect(t, found)
}

// ---------------------------------------------------------------------------
// Incidente 4 // ÚLTIMA PORTADORA
// ---------------------------------------------------------------------------

@(test)
beacon_instances_defeat_simple_majority_and_recover_by_weight :: proc(t: ^testing.T) {
	for seed in 1..=4096 {
		first := generate_beacon_instance(u64(seed))
		second := generate_beacon_instance(u64(seed))
		testing.expect(t, first == second)
		testing.expect(t, first.channel >= BEACON_CHANNEL_MIN && first.channel <= BEACON_CHANNEL_MAX)
		testing.expect(t, first.offset_ms >= BEACON_OFFSET_MIN && first.offset_ms <= BEACON_OFFSET_MAX)
		testing.expect_value(t, beacon_decode_offset(&first.frame), first.offset_ms)
		testing.expect_value(t, beacon_decode_repetition(&first.frame), first.repetition_id)
		testing.expect_value(t, beacon_decode_crc16(&first.frame), first.crc16)
		testing.expect(t, beacon_crc16_valid(&first.frame))

		simple := beacon_simple_reconstruct(&first)
		weighted := beacon_weighted_reconstruct(&first)
		failures := 0
		for index in 0..<BEACON_FRAME_SIZE {
			if simple[index] != first.frame[index] {
				failures += 1
			}
		}
		testing.expect(t, failures >= 3)
		testing.expect_value(t, failures, first.majority_failure_count)
		testing.expect(t, weighted == first.frame)
		testing.expect(t, beacon_crc16_valid(&weighted))
		testing.expect(t, first.min_llr_margin >= BEACON_MIN_LLR_MARGIN)

		expected_errors := [BEACON_COPY_COUNT]int{0, 1, 2, 5, 7, 9, 11, 13, 15}
		for copy_index in 0..<BEACON_COPY_COUNT {
			testing.expect_value(t, first.copies[copy_index].error_count, expected_errors[copy_index])
			if copy_index > 0 {
				testing.expect(
					t,
					first.copies[copy_index].signal_dbm < first.copies[copy_index - 1].signal_dbm,
				)
			}
		}
	}
}

@(test)
beacon_fallback_is_bounded_deterministic_and_valid :: proc(t: ^testing.T) {
	expected_errors := [BEACON_COPY_COUNT]int{0, 1, 2, 5, 7, 9, 11, 13, 15}
	for seed in 1..=256 {
		first := generate_beacon_instance(u64(seed))
		second := first
		beacon_apply_deterministic_fallback(&first)
		beacon_apply_deterministic_fallback(&second)

		testing.expect(t, first == second)
		testing.expect(t, beacon_candidate_valid(&first))
		testing.expect(t, beacon_soft_reconstruct(&first) == first.frame)
		testing.expect(t, first.min_llr_margin >= BEACON_MIN_LLR_MARGIN)
		for copy_index in 0..<BEACON_COPY_COUNT {
			testing.expect_value(t, first.copies[copy_index].error_count, expected_errors[copy_index])
		}
	}
}

@(test)
beacon_crc16_matches_ccitt_false_check_value :: proc(t: ^testing.T) {
	check := [9]u8{'1', '2', '3', '4', '5', '6', '7', '8', '9'}
	testing.expect_value(t, beacon_crc16(check[:]), u16(0x29B1))
}

@(test)
beacon_tune_distinguishes_ranges_from_wrong_physical_values :: proc(t: ^testing.T) {
	instance := generate_beacon_instance(1999)
	wrong_channel := instance.channel % BEACON_CHANNEL_MAX + 1
	wrong_repetition := (instance.repetition_id + 1) % 0x10000
	wrong_crc := instance.crc16 ~ 1

	testing.expect_value(
		t,
		validate_beacon_tune(&instance, 0, instance.offset_ms, instance.repetition_id, instance.crc16),
		Submission_Result.Format_Invalid,
	)
	testing.expect_value(
		t,
		validate_beacon_tune(
			&instance,
			instance.channel,
			BEACON_OFFSET_MAX + 1,
			instance.repetition_id,
			instance.crc16,
		),
		Submission_Result.Format_Invalid,
	)
	testing.expect_value(
		t,
		validate_beacon_tune(
			&instance,
			wrong_channel,
			instance.offset_ms,
			instance.repetition_id,
			instance.crc16,
		),
		Submission_Result.Impossible,
	)
	testing.expect_value(
		t,
		validate_beacon_tune(
			&instance,
			instance.channel,
			instance.offset_ms,
			wrong_repetition,
			instance.crc16,
		),
		Submission_Result.Impossible,
	)
	testing.expect_value(
		t,
		validate_beacon_tune(
			&instance,
			instance.channel,
			instance.offset_ms,
			instance.repetition_id,
			wrong_crc,
		),
		Submission_Result.Impossible,
	)
	testing.expect_value(
		t,
		validate_beacon_tune(
			&instance,
			instance.channel,
			instance.offset_ms,
			instance.repetition_id,
			instance.crc16,
		),
		Submission_Result.Valid,
	)

	game := new_game(1999)
	game.location = .Service_Corridor
	game.connection = .Data_Gateway
	game.stage = .Carrier_Ready
	game.exposure = .Located
	game_wrong_channel := game.beacon.channel % BEACON_CHANNEL_MAX + 1
	intercepted := execute_command(
		&game,
		fmt.tprintf(
			"tune rep06 %d %d %d %s",
			game_wrong_channel,
			game.beacon.offset_ms,
			game.beacon.repetition_id,
			hex_u16(game.beacon.crc16),
		),
	)
	testing.expect_value(t, intercepted.event, Event_Code.Carrier_Failure)
	testing.expect(t, !game.running)
	testing.expect_value(t, game.exposure, Exposure.Interception)
}

@(test)
acts_four_and_five_tune_the_carrier_then_reach_the_encounter_without_new_operations :: proc(t: ^testing.T) {
	game := new_game(1999)
	game.location = .Service_Corridor
	game.connection = .Data_Gateway
	game.stage = .Act_Three_Complete

	begin := execute_command(&game, "continuar")
	testing.expect_value(t, begin.event, Event_Code.Act_Four_Begin)
	testing.expect_value(t, game.stage, Stage.Carrier_Ready)
	testing.expect_value(t, game.connection, Connection.Data_Gateway)

	window_before := game.window
	evidence := execute_command(&game, "evidencia captura raw")
	testing.expect_value(t, evidence.event, Event_Code.Beacon_Evidence_Capture)
	testing.expect(t, evidence.raw)
	testing.expect(t, strings.contains(evidence_raw_text(&game, evidence.event), "ECHO|ARRIVED_AT|RSSI_DBM"))
	for level in 1..=5 {
		hint := execute_command(&game, fmt.tprintf("pista %d", level))
		testing.expect(t, hint.event >= .Beacon_Hint_One && hint.event <= .Beacon_Hint_Five)
	}
	testing.expect_value(t, game.window, window_before)

	format := execute_command(&game, "tune rep06 0 999 70000 ZZZZ")
	testing.expect_value(t, format.event, Event_Code.Tune_Format_Invalid)
	testing.expect_value(t, game.window, window_before)

	wrong_channel := game.beacon.channel % BEACON_CHANNEL_MAX + 1
	wrong := execute_command(
		&game,
		fmt.tprintf(
			"tune rep06 %d %d %d %s",
			wrong_channel,
			game.beacon.offset_ms,
			game.beacon.repetition_id,
			hex_u16(game.beacon.crc16),
		),
	)
	testing.expect_value(t, wrong.event, Event_Code.Tune_Impossible)
	testing.expect_value(t, game.window, window_before - 1)
	testing.expect_value(t, game.exposure, Exposure.Correlated)

	correct := execute_command(
		&game,
		fmt.tprintf("sintonizar rep06 %s", beacon_solution_text(&game.beacon)),
	)
	testing.expect_value(t, correct.event, Event_Code.Tune_Valid)
	testing.expect_value(t, game.stage, Stage.Carrier_Locked)
	testing.expect(t, game.carrier_locked)

	hush := execute_command(&game, "continue")
	testing.expect_value(t, hush.event, Event_Code.Hush_Begin)
	testing.expect_value(t, game.stage, Stage.Hush_Departure)
	testing.expect_value(t, game.connection, Connection.None)
	testing.expect_value(t, game.window, window_before - 1)

	testing.expect_value(t, execute_command(&game, "advance").event, Event_Code.Hush_Streets)
	testing.expect_value(t, game.location, Location.Silent_Streets)
	testing.expect_value(t, execute_command(&game, "advance").event, Event_Code.Hush_Loudspeakers)
	testing.expect_value(t, game.location, Location.Civic_Avenue)
	testing.expect_value(t, execute_command(&game, "advance").event, Event_Code.Hush_Dead_Zone)
	testing.expect_value(t, game.location, Location.Mesh_Boundary)
	testing.expect_value(t, execute_command(&game, "advance").event, Event_Code.Hush_Transmitter)
	testing.expect_value(t, game.location, Location.Repeater_Approach)
	testing.expect_value(t, execute_command(&game, "advance").event, Event_Code.Reunion)
	testing.expect_value(t, game.stage, Stage.Encounter)
	testing.expect_value(t, game.location, Location.Repeater_06)
	testing.expect_value(t, game.window, window_before - 1)
	// No expediente, reto o intervención aparece durante el Acto V.
	testing.expect_value(t, execute_command(&game, "hint 5").event, Event_Code.Hint_No_Operation)
	testing.expect_value(t, execute_command(&game, "tune rep06 1 0").event, Event_Code.Operation_Not_Ready)
}
