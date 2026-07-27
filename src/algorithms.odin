package main

// Algoritmos puros y deterministas. Ninguno se expone durante una partida
// normal: los solvers existen para generar instancias y para las pruebas,
// tal como exige el plan (§6, reglas comunes).

// ---------------------------------------------------------------------------
// RNG determinista (splitmix64). No se consulta entropía global: la semilla
// entra explícita y cada generador avanza su propio estado.
// ---------------------------------------------------------------------------

splitmix64 :: proc(state: ^u64) -> u64 {
	state^ += 0x9E3779B97F4A7C15
	z := state^
	z = (z ~ (z >> 30)) * 0xBF58476D1CE4E5B9
	z = (z ~ (z >> 27)) * 0x94D049BB133111EB
	return z ~ (z >> 31)
}

rng_below :: proc(state: ^u64, bound: int) -> int {
	if bound <= 0 {
		return 0
	}
	return int(splitmix64(state) % u64(bound))
}

// ---------------------------------------------------------------------------
// Reto 2 // CIUDAD CERRADA: solver de referencia.
// Enumeración exhaustiva de caminos simples: los grafos están acotados
// (MAX_ROUTE_NODES) y la corrección evidente importa más que la velocidad.
// Cada arista tiene un intervalo de duración [minutes, minutes+delay_max]. El
// solver propaga las cotas de llegada y minimiza el peor caso más el rastro.
// Una ruta sólo es robusta si ninguna posible salida intersecta un cierre.
// ---------------------------------------------------------------------------

route_edge_open :: proc(edge: Route_Edge, departure: int) -> bool {
	if edge.closed_from < 0 {
		return true
	}
	return departure < edge.closed_from || departure >= edge.closed_to
}

route_edge_robust_open :: proc(edge: Route_Edge, earliest, latest: int) -> bool {
	if edge.closed_from < 0 {
		return true
	}
	return latest < edge.closed_from || earliest >= edge.closed_to
}

route_edge_uncertainty :: proc(edge: Route_Edge) -> int {
	return edge.delay_max
}

route_edge_cost :: proc(edge: Route_Edge) -> int {
	return edge.minutes + 4 * edge.trace + route_edge_uncertainty(edge)
}

Route_Solution :: struct {
	found:   bool,
	cost:    int,
	arrival: int, // peor caso
	earliest_arrival: int,
	length:  int,
	path:    [MAX_ROUTE_NODES]int,
}

solve_route :: proc(instance: ^Route_Instance) -> Route_Solution {
	best: Route_Solution
	best.cost = max(int)
	visited: [MAX_ROUTE_NODES]bool
	path: [MAX_ROUTE_NODES]int
	visited[instance.start] = true
	path[0] = instance.start
	route_dfs(instance, instance.start, 0, 0, 0, 1, &visited, &path, &best)
	return best
}

route_dfs :: proc(
	instance: ^Route_Instance,
	node, earliest, latest, cost, length: int,
	visited: ^[MAX_ROUTE_NODES]bool,
	path: ^[MAX_ROUTE_NODES]int,
	best: ^Route_Solution,
) {
	if node == instance.goal {
		if cost < best.cost {
			best.found = true
			best.cost = cost
			best.arrival = latest
			best.earliest_arrival = earliest
			best.length = length
			best.path = path^
		}
		return
	}
	for edge_index in 0..<instance.edge_count {
		edge := instance.edges[edge_index]
		if edge.from != node || visited[edge.to] {
			continue
		}
		if !route_edge_robust_open(edge, earliest, latest) {
			continue
		}
		visited[edge.to] = true
		path[length] = edge.to
		route_dfs(
			instance,
			edge.to,
			earliest + edge.minutes,
			latest + edge.minutes + edge.delay_max,
			cost + route_edge_cost(edge),
			length + 1,
			visited,
			path,
			best,
		)
		visited[edge.to] = false
	}
}
