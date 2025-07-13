package main

import rl "vendor:raylib"
import "core:math"
import "core:strconv"

Unit_Stats :: struct {
	health: int,
	speed: int,
	position: [2]f32,
	range: int,
	movement_range: int,
	attack_range: int,
}

Unit_Modes :: enum {
	Moving,
	Engaging,
}

Warrior_Unit :: struct {
	stats: Unit_Stats,
	name: string,
}

// === GLOBAL STATE ===
selected_unit: ^Warrior_Unit = nil
control_points: [dynamic]rl.Vector2
dragging_point_index: int = -1
territory_radius: f32 = 100.0
territory_segments: int = 600
territory_confirmed: bool = false
max_territory_area: f32 = 40000.0

// === Generate Circle of Points Around Unit ===
generate_territory_points :: proc(center: rl.Vector2, radius: f32, segments: int) -> [dynamic]rl.Vector2 {
	points: [dynamic]rl.Vector2
	for i in 0..<segments {
		angle := (2.0 * math.PI * f32(i)) / f32(segments)
		point := rl.Vector2{
			center.x + math.cos(angle) * radius,
			center.y + math.sin(angle) * radius,
		}
		append(&points, point)
	}
	return points
}

// === Catmull-Rom Interpolation ===
catmull_rom :: proc(p0, p1, p2, p3: rl.Vector2, t: f32) -> rl.Vector2 {
	t2 := t * t
	t3 := t2 * t

	return rl.Vector2{
		0.5 * ((2.0 * p1.x) +
			(-p0.x + p2.x) * t +
			(2.0*p0.x - 5.0*p1.x + 4.0*p2.x - p3.x) * t2 +
			(-p0.x + 3.0*p1.x - 3.0*p2.x + p3.x) * t3),
		0.5 * ((2.0 * p1.y) +
			(-p0.y + p2.y) * t +
			(2.0*p0.y - 5.0*p1.y + 4.0*p2.y - p3.y) * t2 +
			(-p0.y + 3.0*p1.y - 3.0*p2.y + p3.y) * t3),
	}
}

// === Shoelace Polygon Area Calculation ===
calculate_area :: proc(points: [dynamic]rl.Vector2) -> f32 {
	area: f32 = 0
	n := len(points)
	for i in 0..<n {
		j := (i + 1) % n
		area += (points[i].x * points[j].y) - (points[j].x * points[i].y)
	}
	return math.abs(area) * 0.5
}

// === Draw Smooth Spline ===
draw_spline_loop :: proc(points: [dynamic]rl.Vector2) {
	count := len(points)
	steps := 20

	for i in 0..<count {
		p0 := points[(i - 1 + count) % count]
		p1 := points[i]
		p2 := points[(i + 1) % count]
		p3 := points[(i + 2) % count]

		for j in 0..<steps {
			t1 := f32(j) / f32(steps)
			t2 := f32(j+1) / f32(steps)

			pt1 := catmull_rom(p0, p1, p2, p3, t1)
			pt2 := catmull_rom(p0, p1, p2, p3, t2)

			rl.DrawLineV(pt1, pt2, rl.RED)
		}
	}
}

main :: proc() {
	rl.InitWindow(800, 800, "civlike raylib experiments")
	rl.SetTargetFPS(120)

	unit := Warrior_Unit{
		stats = Unit_Stats{
			position = [2]f32{400.0, 400.0},
			health = 100,
			speed = 10,
			range = 1,
			movement_range = 3,
			attack_range = 1,
		},
		name = "Warrior",
	}

	for !rl.WindowShouldClose() {
		mouse := rl.GetMousePosition()

		// === Select unit on click ===
		if rl.IsMouseButtonPressed(.LEFT) {
			unit_pos := rl.Vector2{ unit.stats.position[0], unit.stats.position[1] }
			if rl.CheckCollisionPointCircle(mouse, unit_pos, 15.0) {
				selected_unit = &unit
				control_points = generate_territory_points(unit_pos, territory_radius, territory_segments)
				territory_confirmed = false
			}
		}

		// === Drag control points ===
		if rl.IsMouseButtonDown(.LEFT) && len(control_points) > 0 && !territory_confirmed {
			if dragging_point_index == -1 {
				for i in 0..<len(control_points) {
					if rl.Vector2Distance(mouse, control_points[i]) < 10.0 {
						dragging_point_index = i
						break
					}
				}
			} else {
				control_points[dragging_point_index] = mouse
			}
		} else {
			dragging_point_index = -1
		}

		// === Confirm territory on right click ===
		if rl.IsMouseButtonPressed(.RIGHT) && len(control_points) > 0 && !territory_confirmed {
			area := calculate_area(control_points)
			if area <= max_territory_area {
				territory_confirmed = true
			}
		}

		// === DRAW ===
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLUE)

		unit_pos := rl.Vector2{ unit.stats.position[0], unit.stats.position[1] }
		rl.DrawCircleV(unit_pos, 15.0, rl.YELLOW)
		rl.DrawText("Click unit to create territory", 10, 10, 20, rl.WHITE)

		if len(control_points) > 0 {
			area := calculate_area(control_points)

			// Fill if confirmed
			if territory_confirmed {
                rl.DrawTriangleFan(&control_points[0], i32(len(control_points)), rl.Color{0, 200, 0, 100})
			}

			// Draw spline and points
			draw_spline_loop(control_points)
			for pt in control_points {
				rl.DrawCircleV(pt, 5.0, rl.DARKGREEN)
			}

            buffer: [20]u8
            area_str := strconv.itoa(buffer[:], int(area))
			// Area display
			rl.DrawText("Area: ", 10, 40, 20, rl.WHITE)
			if area > max_territory_area {
				rl.DrawText("Area too large!", 10, 70, 20, rl.RED)
			} else if !territory_confirmed {
				rl.DrawText("Right-click to confirm territory", 10, 70, 20, rl.LIME)
			}
		}

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
