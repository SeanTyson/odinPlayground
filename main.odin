package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"


Settler :: struct {
    position: rl.Vector2,
    radius: f32
}

ColourPicker :: struct{
    Colours: [9]rl.Color,
    Position: rl.Vector2
}

ColourPoint :: struct {
    Colour: rl.Color,
    Position: rl.Vector2
}

points: [dynamic]ColourPoint


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
    spline_points: [dynamic]rl.Vector2
    fan_points: [dynamic]rl.Vector2
    colour_picker: ColourPicker
    colour_picker.Colours = {rl.RED, rl.BLUE, rl.ORANGE, rl.YELLOW, rl.BLACK, rl.GRAY, rl.PINK, rl.DARKPURPLE, rl.GREEN}
    colour := rl.RED;
    shape_closed: bool = false
    territory_dirty := false
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        rl.DrawRectangle(700,500,10,10,rl.RED)
        mouse_pos := rl.GetMousePosition()
        for i in 0..<len(colour_picker.Colours) {
            rl.DrawRectangle(i32(700+i*10),i32(500+i*10),10,10,colour_picker.Colours[i])
        }
        if(rl.IsMouseButtonPressed(.LEFT)){
            for i in 0..<len(colour_picker.Colours) {
                if rl.CheckCollisionPointRec(mouse_pos, rl.Rectangle{f32(700+i*10),f32(500+i*10),10,10}) {
                    colour = colour_picker.Colours[i]
                }   
            }
        }
        // Left click adds points if shape not closed
        if rl.IsMouseButtonDown(.LEFT) {
            rl.DrawCircleV(mouse_pos, 5, colour)
            append(&points, ColourPoint{Position = mouse_pos, Colour = colour})
        }

        if(len(points) != 0) {
            for i in 0..<len(points) {
                rl.DrawCircleV(points[i].Position, 5, points[i].Colour)
            }
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
