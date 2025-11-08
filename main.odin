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

generate_catmull_chain :: proc(control_points: [][2]f32) -> []rl.Vector2 {
    n := len(control_points)
    // extended length = n + 3
    extended := make([dynamic]rl.Vector2, 0, n + 3)

    // push control points in circular order, then append first 3 again
    for i in 0..<(n + 3) {
        p := control_points[i % n]
        append(&extended, rl.Vector2{p[0], p[1]})
    }

    return extended[:]
}


main :: proc() {
	rl.InitWindow(800, 800, "civlike raylib experiments")
	rl.SetTargetFPS(120)
	centerX: f32 = 400
	centerY: f32 = 400
	controlPoints: [4][2]f32 = {
		{centerX, centerY-50},
		{centerX-50, centerY},
		{centerX, centerY+50},
		{centerX+50, centerY}
	}
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLUE)
		catmull_points := generate_catmull_chain(controlPoints[:])

		rl.DrawSplineCatmullRom(&catmull_points[0], i32(len(catmull_points)), 3.0, rl.YELLOW)
		for point in controlPoints {
			rl.DrawCircle(i32(point[0]), i32(point[1]), 5, rl.RED)
		}
		if rl.IsKeyDown(rl.MouseButton.LEFT) {
			fmt.printl
		}
		//rl.DrawCircle(400, 100, 5.0, rl.RED); 
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
