package main

Location :: enum {
	Operations_Annex,
	Automated_Workshop,
	Market,
	Bridge,
	Depot,
	Tunnel,
	Plaza,
	Rail,
	Transit_Interchange,
	Service_Corridor,
	Silent_Streets,
	Civic_Avenue,
	Mesh_Boundary,
	Repeater_Approach,
	Repeater_06,
}

Connection :: enum {
	None,
	Legacy_Controller,
	Transit_Node,
	Data_Gateway,
}

Stage :: enum {
	Evacuation,
	At_Workshop,
	Packet_Ready,
	Prototype_Complete,
	Route_Ready,
	Route_In_Transit,
	At_Interchange,
	Interchange_Scanned,
	Transit_Connected,
	Act_Two_Complete,
	Act_Three_Travel,
	At_Service_Corridor,
	Corridor_Scanned,
	Flow_Ready,
	Act_Three_Complete,
	Carrier_Ready,
	Carrier_Locked,
	Hush_Departure,
	Hush_Streets,
	Hush_Loudspeakers,
	Hush_Dead_Zone,
	Hush_Approach,
	Encounter,
}

Exposure :: enum {
	Anonymous,
	Correlated,
	Located,
	Interception,
}

STORY_LOG_CAPACITY :: 6

Game_State :: struct {
	location:          Location,
	connection:        Connection,
	stage:             Stage,
	exposure:          Exposure,
	window:            int,
	capture_viewed:     bool,
	signal_reviewed:    bool,
	seed:              u64,
	running:           bool,
	current_act:       int,
	act_start_window:  int,
	act_start_exposure: Exposure,
	story_log:         [STORY_LOG_CAPACITY]Event_Code,
	story_log_len:     int,
	packet:            Packet_Instance,
	route:             Route_Instance,
	route_applied:     bool,
	route_cost:        int,
	selected_route:    [MAX_ROUTE_SUBMISSION_NODES]int,
	selected_route_len: int,
	route_position:    int,
	flow:              Flow_Instance,
	flow_applied:      bool,
	flow_total:        int,
	flow_cost:         int,
	repeater_powered:  bool,
	beacon:            Beacon_Instance,
	carrier_locked:    bool,
}

new_game :: proc(seed: u64) -> Game_State {
	game := Game_State {
		location   = .Operations_Annex,
		connection = .None,
		stage      = .Evacuation,
		exposure   = .Anonymous,
		window     = 6,
		seed       = seed,
		running    = true,
		current_act = 1,
		act_start_window = 6,
		act_start_exposure = .Anonymous,
	}
	game.story_log[0] = .None
	game.story_log_len = 1
	game.packet = generate_packet_instance(seed)
	game.route = generate_route_instance(seed ~ 0x43495459524F5554)
	game.flow = generate_flow_instance(seed ~ 0x4341504143495459)
	game.beacon = generate_beacon_instance(seed ~ 0x42434E2D52360004)
	return game
}

game_begin_act :: proc(game: ^Game_State, act: int) {
	game.current_act = act
	game.act_start_window = game.window
	game.act_start_exposure = game.exposure
}

game_record_story :: proc(game: ^Game_State, event: Event_Code) {
	if game.story_log_len > 0 && game.story_log[game.story_log_len - 1] == event {
		return
	}
	if game.story_log_len == STORY_LOG_CAPACITY {
		for index in 1..<STORY_LOG_CAPACITY {
			game.story_log[index - 1] = game.story_log[index]
		}
		game.story_log_len -= 1
	}
	game.story_log[game.story_log_len] = event
	game.story_log_len += 1
}

increase_exposure :: proc(game: ^Game_State) {
	switch game.exposure {
	case .Anonymous:
		game.exposure = .Correlated
	case .Correlated:
		game.exposure = .Located
	case .Located:
		game.exposure = .Interception
	case .Interception:
	}
}

is_failed :: proc(game: ^Game_State) -> bool {
	return game.window <= 0 || game.exposure == .Interception
}

location_name :: proc(location: Location) -> string {
	switch location {
	case .Operations_Annex:
		return "OPERATIONS ANNEX"
	case .Automated_Workshop:
		return "AUTOMATED WORKSHOP"
	case .Market:
		return "MARKET"
	case .Bridge:
		return "BRIDGE"
	case .Depot:
		return "DEPOT"
	case .Tunnel:
		return "TUNNEL"
	case .Plaza:
		return "PLAZA"
	case .Rail:
		return "RAIL"
	case .Transit_Interchange:
		return "TRANSIT INTERCHANGE"
	case .Service_Corridor:
		return "SERVICE CORRIDOR"
	case .Silent_Streets:
		return "CURFEW STREETS"
	case .Civic_Avenue:
		return "CIVIC AVENUE"
	case .Mesh_Boundary:
		return "MESH BOUNDARY"
	case .Repeater_Approach:
		return "REPEATER 06 APPROACH"
	case .Repeater_06:
		return "REPEATER 06"
	}
	return "UNKNOWN"
}

route_location :: proc(node: int) -> Location {
	switch node {
	case 0:
		return .Automated_Workshop
	case 1:
		return .Market
	case 2:
		return .Bridge
	case 3:
		return .Depot
	case 4:
		return .Tunnel
	case 5:
		return .Plaza
	case 6:
		return .Rail
	case 7:
		return .Transit_Interchange
	}
	return .Automated_Workshop
}

connection_name :: proc(connection: Connection) -> string {
	switch connection {
	case .None:
		return "DISCONNECTED"
	case .Legacy_Controller:
		return "CTRL17 / LEGACY PORT"
	case .Transit_Node:
		return "TRN04 / LOCAL NODE"
	case .Data_Gateway:
		return "GWT08 / LOCAL GATEWAY"
	}
	return "UNKNOWN"
}

exposure_name :: proc(exposure: Exposure) -> string {
	switch exposure {
	case .Anonymous:
		return "ANONYMOUS"
	case .Correlated:
		return "CORRELATED"
	case .Located:
		return "LOCATED"
	case .Interception:
		return "INTERCEPTED"
	}
	return "UNKNOWN"
}
