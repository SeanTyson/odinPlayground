package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"


Settler :: struct {
    position: rl.Vector2,
    radius: f32
}

draw_triangle_fan_manual :: proc(center: rl.Vector2, ring: [dynamic]rl.Vector2, color: rl.Color) {
    count := len(ring)
    for i in 0..<count-1 {
        rl.DrawTriangle(center, ring[i+1], ring[i], color)
    }
    // Close the loop
    rl.DrawTriangle(center, ring[0], ring[count-1], color)
}


main :: proc() {
    rl.InitWindow(800, 600, "civlike")
    rl.SetTargetFPS(60)
    settler: Settler
    settler.position = {400.0,300.0}
    settler.radius = 5.0
    points: [dynamic]rl.Vector2
    spline_points: [dynamic]rl.Vector2
    fan_points: [dynamic]rl.Vector2
    shape_closed: bool = false
    territory_dirty := false
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        rl.DrawCircleV(settler.position, settler.radius, rl.RED)
        mouse_pos := rl.GetMousePosition()

        // Left click adds points if shape not closed
        if territory_dirty || !shape_closed && rl.IsMouseButtonDown(.LEFT) {
            if  rl.CheckCollisionPointCircle(mouse_pos, settler.position, settler.radius) {
                territory_dirty = true
                num_segments := 8
                radius: f32 = 100.0
                spline_points = nil // clear before rebuilding
                for i in 0..<num_segments {
                    angle := 2.0 * rl.PI * f32(i) / f32(num_segments) 
                    x := settler.position.x + math.cos(angle) * radius
                    y := settler.position.y + math.sin(angle) * radius
                    append(&spline_points, rl.Vector2{x, y})
                }
                num_segments = 100
                fan_points = nil

                for i in 0..<num_segments {
                    angle := 2.0 * math.PI * f32(i) / f32(num_segments)
                    x := settler.position.x + math.cos(angle) * radius
                    y := settler.position.y + math.sin(angle) * radius
                    append(&fan_points, rl.Vector2{x, y})
                }
                // Add first 3 points again to loop the spline
                append(&spline_points, spline_points[0])
                append(&spline_points, spline_points[1])
                append(&spline_points, spline_points[2])
                fan_points[0] = settler.position
                rl.DrawSplineCatmullRom(raw_data(spline_points), i32(len(spline_points)), 4, rl.RED)
                draw_triangle_fan_manual(settler.position, fan_points, rl.GREEN)

           }
            else {
                append(&points, mouse_pos)
                rl.DrawCircleV(mouse_pos, 2, rl.DARKGRAY)
            }
        }

        // Right click closes the shape
        if !shape_closed && rl.IsMouseButtonPressed(.RIGHT) && len(points) >= 3 {
            shape_closed = true
        }



        // Draw lines connecting points (open shape)
        if len(points) >= 2 {
            for i in 0..<(len(points)-2) {
                rl.DrawLineV(points[i], points[i+1], rl.BLACK)
            }
            if shape_closed {
                // Close the shape by connecting last to first
                rl.DrawLineV(points[len(points)-1], points[0], rl.BLACK)
            }
        }

        // Fill shape if closed
        if shape_closed {
            // Draw filled polygon using Triangle Fan
            // Note: works best if shape is convex or mildly concave
            rl.DrawTriangleFan(raw_data(points), i32(len(points)), rl.Fade(rl.GREEN, 0.5))
        }

        // UI Instructions
        rl.DrawText("Left-click to add points", 10, 10, 20, rl.DARKGRAY)
        rl.DrawText("Right-click to close and fill shape", 10, 40, 20, rl.DARKGRAY)
        if shape_closed {
            rl.DrawText("Shape closed! Press R to reset.", 10, 70, 20, rl.RED)
        }

        // Reset on 'R'
        if rl.IsKeyPressed(.R) {
            points = nil
            shape_closed = false
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
