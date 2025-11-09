package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

CONTROL_POINT_RADIUS :: 5.0
POINTS_PER_SEGMENT :: 8
EPSILON :: 0.0001

// 2D cross product scalar
cross2d :: proc(vecA: rl.Vector2, vecB: rl.Vector2) -> f32 {
    return vecA.x * vecB.y - vecA.y * vecB.x
}

// Check if the middle vertex is convex
is_convex :: proc(prev: rl.Vector2, curr: rl.Vector2, next: rl.Vector2) -> bool {
    a := next - curr
    b := prev - curr
    return cross2d(a, b) > EPSILON
}

// Check if a vertex is an ear
is_ear :: proc(prev: rl.Vector2, curr: rl.Vector2, next: rl.Vector2, points: [dynamic]rl.Vector2) -> bool {
    if !is_convex(prev, curr, next) do return false

    for point in points {
        if point != prev && point != curr && point != next {
            if rl.CheckCollisionPointTriangle(point, prev, curr, next) do return false
        }
    }
    return true
}

earcut_triangulation :: proc(points: [dynamic]rl.Vector2) -> []rl.Vector2 {
    working: [dynamic]rl.Vector2 = points // make a copy
    triangles: [dynamic]rl.Vector2
    i := 0
    full_cycle_without_removal := 0
    for len(working) > 3 {
        prev := working[i-1]
        curr := working[i]
        next := working[i+1]

        if is_ear(prev, curr, next, working) {
            append(&triangles, prev, curr, next)
            ordered_remove(&working, i)
            i = 0
            full_cycle_without_removal = 0
        } else {
            i += 1
            full_cycle_without_removal += 1

            if i >= len(working) { i = 0 } // wrap around
            if full_cycle_without_removal >= len(working) {
                fmt.println("no ear found — polygon may be malformed")
                break
            }
        }
    }

    // Append the last triangle
    if len(working) == 3 {
        append(&triangles, working[0], working[1], working[2])
    }

    return triangles[:]
}

sample_catmull_spline :: proc(control_points: []rl.Vector2, points_per_segment: int) -> [dynamic]rl.Vector2 {
    n := len(control_points) - 3
    sampled := make([dynamic]rl.Vector2, 0, n*points_per_segment)

    for i in 0..<n {
        p0 := control_points[i]
        p1 := control_points[i+1]
        p2 := control_points[i+2]
        p3 := control_points[i+3]

        for j in 0..<points_per_segment {
            t := f32(j) / f32(points_per_segment - 1)
            append(&sampled, rl.GetSplinePointCatmullRom(p0, p1, p2, p3, t))
        }
    }

    // Ensure CCW winding
    area: f32 = 0
    for i in 0..<len(sampled) {
        curr := sampled[i]
        next := sampled[(i+1) % len(sampled)]
        area += (next.x - curr.x) * (next.y + curr.y)
    }

    if area > 0 {
        reversed := make([dynamic]rl.Vector2, 0, len(sampled))
        for i := len(sampled)-1; i >= 0; i = i - 1 {
            append(&reversed, sampled[i])
        }
        sampled = reversed
    }

    return sampled
}

// Draw triangles
draw_triangulated_territory :: proc(triangles: []rl.Vector2) {
    for i := 0; i < len(triangles); i += 3 {
        rl.DrawTriangle(triangles[i], triangles[i+1], triangles[i+2], rl.YELLOW)
    }
}

// Extend control points for Catmull-Rom closed loop
generate_catmull_chain :: proc(control_points: [][2]f32) -> []rl.Vector2 {
    n := len(control_points)
    extended := make([dynamic]rl.Vector2, 0, n+3)
    for i in 0..<(n+3) {
        p := control_points[i % n]
        append(&extended, rl.Vector2{p[0], p[1]})
    }
    return extended[:]
}

main :: proc() {
    draggingIndex: int = -1
    rl.InitWindow(800, 800, "Spline Triangulation Demo")
    rl.SetTargetFPS(120)

    centerX, centerY: f32 = 400, 400
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
        sampled_points := sample_catmull_spline(catmull_points, POINTS_PER_SEGMENT)
        triangles := earcut_triangulation(sampled_points)
        draw_triangulated_territory(triangles)

        rl.DrawSplineCatmullRom(&catmull_points[0], i32(len(catmull_points)), CONTROL_POINT_RADIUS, rl.RED)

        for point in controlPoints {
            rl.DrawCircle(i32(point[0]), i32(point[1]), CONTROL_POINT_RADIUS, rl.GREEN)
        }

        mousePos := rl.GetMousePosition()
        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
            draggingIndex = -1
        }

        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            for idx in 0..<len(controlPoints) {
                p := controlPoints[idx]
                if rl.CheckCollisionPointCircle(mousePos, rl.Vector2{p[0], p[1]}, CONTROL_POINT_RADIUS) {
                    draggingIndex = idx
                }
            }
        }

        if draggingIndex != -1 {
            controlPoints[draggingIndex] = [2]f32{mousePos.x, mousePos.y}
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
