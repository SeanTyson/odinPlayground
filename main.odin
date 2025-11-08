package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

CONTROL_POINT_RADIUS :: 5.0
POINTS_PER_SEGMENT :: 12

// --- Utility Functions ---
// --- Spline Utilities ---

sample_catmull_spline :: proc(control_points: []rl.Vector2, points_per_segment: int) -> []rl.Vector2 {
    n := len(control_points) - 3;
    sampled := make([dynamic]rl.Vector2, 0, n*points_per_segment);

    for i in 0..<n {
        p0 := control_points[i];
        p1 := control_points[i+1];
        p2 := control_points[i+2];
        p3 := control_points[i+3];

        for j in 0..<points_per_segment {
            t := f32(j) / f32(points_per_segment - 1);
            pt := rl.GetSplinePointCatmullRom(p0, p1, p2, p3, t);
            append(&sampled, pt);
        }
    }
    return sampled[:];
}

generate_catmull_chain :: proc(control_points: [][2]f32) -> []rl.Vector2 {
    n := len(control_points);
    extended := make([dynamic]rl.Vector2, 0, n+3);
    for i in 0..<(n+3) {
        p := control_points[i % n];
        append(&extended, rl.Vector2{p[0], p[1]});
    }
    return extended[:];
}

main :: proc() {
    draggingIndex: int = -1;
    rl.InitWindow(800, 800, "Spline Triangulation Demo");
    rl.SetTargetFPS(120);

    centerX, centerY: f32 = 400, 400;
    controlPoints: [4][2]f32 = {
        {centerX, centerY-50},
        {centerX-50, centerY},
        {centerX, centerY+50},
        {centerX+50, centerY}
    };

    for !rl.WindowShouldClose() {
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLUE);

        catmull_points := generate_catmull_chain(controlPoints[:]);
        sampled_points := sample_catmull_spline(catmull_points, POINTS_PER_SEGMENT);
        rl.DrawSplineCatmullRom(&catmull_points[0], i32(len(catmull_points)), CONTROL_POINT_RADIUS, rl.RED);

        for point in controlPoints {
            rl.DrawCircle(i32(point[0]), i32(point[1]), CONTROL_POINT_RADIUS, rl.GREEN);
        }

        mousePos := rl.GetMousePosition();
        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
            draggingIndex = -1;
        }

        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            for idx in 0..<len(controlPoints) {
                p := controlPoints[idx];
                if rl.CheckCollisionPointCircle(mousePos, rl.Vector2{p[0], p[1]}, CONTROL_POINT_RADIUS) {
                    draggingIndex = idx;
                }
            }
        }

        if draggingIndex != -1 {
            controlPoints[draggingIndex] = [2]f32{mousePos.x, mousePos.y};
        }

        rl.EndDrawing();
    }

    rl.CloseWindow();
}
