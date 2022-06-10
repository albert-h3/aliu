const std = @import("std");
const liu = @import("liu");

const editor = @import("./editor.zig");

const util = @import("./util.zig");
const mouse = util.mouse;
const rows = util.rows;
const keys = util.keys;
const camera = util.camera;

// https://youtu.be/SFKR5rZBu-8?t=2202
// https://stackoverflow.com/questions/22511158/how-to-profile-web-workers-in-chrome

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const Vec2 = liu.Vec2;
const Vec3 = liu.Vec3;
const Vec4 = liu.Vec4;
pub const BBox = struct {
    pos: Vec2,
    width: f32,
    height: f32,

    const Overlap = struct {
        result: bool,
        x: bool,
        y: bool,
    };

    pub fn init(pos: Vec2, collision_c: CollisionC) @This() {
        return BBox{
            .pos = pos,
            .width = collision_c.width,
            .height = collision_c.height,
        };
    }

    pub fn overlap(self: @This(), other: @This()) Overlap {
        const pos1 = self.pos + Vec2{ self.width, self.height };
        const other_pos1 = other.pos + Vec2{ other.width, other.height };
        const x = self.pos[0] < other_pos1[0] and other.pos[0] < pos1[0];
        const y = self.pos[1] < other_pos1[1] and other.pos[1] < pos1[1];

        return .{
            .result = x and y,
            .y = y,
            .x = x,
        };
    }
};

pub const ext = struct {
    pub extern fn fillStyle(r: f32, g: f32, b: f32, a: f32) void;
    pub extern fn fillRect(x: i32, y: i32, width: i32, height: i32) void;
    pub extern fn setFont(font: wasm.Obj) void;
    pub extern fn fillText(text: wasm.Obj, x: i32, y: i32) void;
};

const RenderC = struct {
    color: Vec4,
    sprite_width: f32,
    sprite_height: f32,
};

const PositionC = struct {
    pos: Vec2,
};

const CollisionC = struct {
    width: f32,
    height: f32,
};

const MoveC = struct {
    velocity: Vec2,
};

const ForceC = struct {
    accel: Vec2,
    friction: f32,
    is_airborne: bool = false,
};

const DecisionC = union(enum) {
    player: void,
};

export fn init() void {
    wasm.initIfNecessary();

    initErr() catch @panic("meh");

    wasm.post(.info, "WASM initialized!", .{});
}

const Registry = liu.ecs.Registry(&.{
    PositionC,
    MoveC,
    RenderC,
    DecisionC,
    CollisionC,
    ForceC,
});

const norm_color: Vec4 = Vec4{ 0.3, 0.3, 0.3, 0.6 };
fn initErr() !void {
    large_font = wasm.make.fmt(.manual, "bold 48px sans-serif", .{});
    small_font = wasm.make.fmt(.manual, "10px sans-serif", .{});

    const draw_tool = try Static.create(editor.DrawTool);
    try tools.append(Static, editor.Tool.init(draw_tool));

    registry = try Registry.init(16, liu.Pages);

    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        var color = norm_color;
        color[i] = 1;

        const box = try registry.create("bar");
        try registry.addComponent(box, PositionC{
            .pos = Vec2{ @intToFloat(f32, i) + 5, 3 },
        });
        try registry.addComponent(box, RenderC{
            .color = color,
            .sprite_width = 0.5,
            .sprite_height = 3,
        });
        try registry.addComponent(box, CollisionC{
            .width = 0.5,
            .height = 3,
        });
        try registry.addComponent(box, MoveC{
            .velocity = Vec2{ 0, 0 },
        });
        try registry.addComponent(box, DecisionC{ .player = {} });

        try registry.addComponent(box, ForceC{
            .accel = Vec2{ 0, -14 },
            .friction = 0.05,
        });
    }

    const bump = try registry.create("bump");
    try registry.addComponent(bump, PositionC{
        .pos = Vec2{ 10, 4 },
    });
    try registry.addComponent(bump, CollisionC{
        .width = 1,
        .height = 1,
    });
    try registry.addComponent(bump, RenderC{
        .color = Vec4{ 0.1, 0.5, 0.3, 1 },
        .sprite_width = 1,
        .sprite_height = 1,
    });

    const ground = try registry.create("ground");
    try registry.addComponent(ground, PositionC{
        .pos = Vec2{ 0, 0 },
    });
    try registry.addComponent(ground, CollisionC{
        .width = 100,
        .height = 1,
    });
    try registry.addComponent(ground, RenderC{
        .color = Vec4{ 0.2, 0.5, 0.3, 1 },
        .sprite_width = 100,
        .sprite_height = 1,
    });
}

var frame_id: u64 = 0;
var start_time: f64 = undefined;
var previous_time: f64 = undefined;
var static_storage: liu.Bump = liu.Bump.init(1024, liu.Pages);
const Static: std.mem.Allocator = static_storage.allocator();

var tools: std.ArrayListUnmanaged(editor.Tool) = .{};
var tool_index: u32 = 0;

pub var large_font: wasm.Obj = undefined;
pub var small_font: wasm.Obj = undefined;
pub var registry: Registry = undefined;

export fn setInitialTime(timestamp: f64) void {
    start_time = timestamp;
    previous_time = timestamp;
}

export fn run(timestamp: f64) void {
    defer util.frameCleanup();
    defer frame_id += 1;
    defer previous_time = timestamp;

    // Wait for a bit, because otherwise the world will start running
    // before its visible
    if (timestamp - start_time < 300) return;

    const delta = @floatCast(f32, timestamp - previous_time);
    if (delta > 66) return;

    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    // Input

    {}

    skip_this: {
        if (!mouse.clicked) break :skip_this;

        const pos = @floor(mouse.pos);
        const pos1 = @ceil(mouse.pos);
        const bbox = BBox{
            .pos = pos,
            .width = pos1[0] - pos[0],
            .height = pos1[1] - pos[1],
        };

        var view = registry.view(struct {
            pos_c: PositionC,
            collision_c: CollisionC,
            decide_c: DecisionC,
        });

        while (view.next()) |elem| {
            if (elem.decide_c != .player) continue;

            const elem_bbox = BBox.init(elem.pos_c.pos, elem.collision_c);
            if (elem_bbox.overlap(bbox).result) break :skip_this;
        }

        const new_solid = registry.create("box") catch break :skip_this;
        registry.addComponent(new_solid, PositionC{
            .pos = pos,
        }) catch registry.delete(new_solid);
        registry.addComponent(new_solid, CollisionC{
            .width = 1,
            .height = 1,
        }) catch registry.delete(new_solid);
        registry.addComponent(new_solid, RenderC{
            .color = Vec4{ 0.2, 0.5, 0.3, 1 },
            .sprite_width = 1,
            .sprite_height = 1,
        }) catch registry.delete(new_solid);

        _ = new_solid;
    }

    {
        var view = registry.view(struct {
            move_c: *MoveC,
            decide_c: DecisionC,
            force_c: ForceC,
        });

        while (view.next()) |elem| {
            const move_c = elem.move_c;

            if (elem.decide_c != .player) continue;

            if (keys[11].pressed) {
                move_c.velocity[1] -= 8;
            }

            if (keys[1].pressed) {
                move_c.velocity[1] += 8;
            }

            if (elem.force_c.is_airborne) {
                if (keys[10].pressed) {
                    move_c.velocity[0] -= 8;
                }

                if (keys[12].pressed) {
                    move_c.velocity[0] += 8;
                }
            } else {
                if (keys[10].down) {
                    move_c.velocity[0] -= 8;
                    move_c.velocity[0] = std.math.clamp(move_c.velocity[0], -8, 0);
                }

                if (keys[12].down) {
                    move_c.velocity[0] += 8;
                    move_c.velocity[0] = std.math.clamp(move_c.velocity[0], 0, 8);
                }
            }
        }
    }

    // Gameplay

    // Collisions
    {
        var view = registry.view(struct {
            pos_c: *PositionC,
            collision_c: CollisionC,

            move_c: *MoveC,
            force_c: *ForceC,
        });

        const StableObject = struct {
            pos_c: PositionC,
            collision_c: CollisionC,

            move_c: ?*const MoveC,
            force_c: ?*ForceC,
        };

        var stable = registry.view(StableObject);

        while (view.next()) |elem| {
            const pos_c = elem.pos_c;
            const move_c = elem.move_c;
            const collision_c = elem.collision_c;

            // move the thing
            var new_pos = pos_c.pos + move_c.velocity * @splat(2, delta / 1000);

            const bbox = BBox{
                .pos = pos_c.pos,
                .width = collision_c.width,
                .height = collision_c.height,
            };
            const new_bbox = BBox{
                .pos = new_pos,
                .width = collision_c.width,
                .height = collision_c.height,
            };

            elem.force_c.is_airborne = true;

            stable.reset();
            while (stable.next()) |solid| {
                // No move/force component means it can't even be made to move, so we'll
                // think of it as a stable piece of the environment
                if (solid.force_c != null) continue;

                const found = BBox{
                    .pos = solid.pos_c.pos,
                    .width = solid.collision_c.width,
                    .height = solid.collision_c.height,
                };

                const overlap = new_bbox.overlap(found);
                if (!overlap.result) continue;

                const prev_overlap = bbox.overlap(found);

                if (prev_overlap.x) {
                    if (pos_c.pos[1] < found.pos[1]) {
                        new_pos[1] = found.pos[1] - collision_c.height;
                    } else {
                        new_pos[1] = found.pos[1] + found.height;
                        elem.force_c.is_airborne = false;
                    }

                    move_c.velocity[1] = 0;
                }

                if (prev_overlap.y) {
                    if (pos_c.pos[0] < found.pos[0]) {
                        new_pos[0] = found.pos[0] - collision_c.width;
                    } else {
                        new_pos[0] = found.pos[0] + found.width;
                    }

                    move_c.velocity[0] = 0;
                }
            }

            pos_c.pos = new_pos;

            // const cam_pos0 = camera.pos;
            // const cam_dims = Vec2{ camera.width, camera.height };
            // const cam_pos1 = cam_pos0 + cam_dims;

            // const new_x = std.math.clamp(pos_c.pos[0], cam_pos0[0], cam_pos1[0] - collision_c.width);
            // if (new_x != pos_c.pos[0])
            //     move_c.velocity[0] = 0;
            // pos_c.pos[0] = new_x;

            // const new_y = std.math.clamp(pos_c.pos[1], cam_pos0[1], cam_pos1[1] - collision_c.height);
            // if (new_y != pos_c.pos[1])
            //     move_c.velocity[1] = 0;
            // pos_c.pos[1] = new_y;
        }
    }

    {
        var view = registry.view(struct {
            move_c: *MoveC,
            force_c: ForceC,
        });

        while (view.next()) |elem| {
            const move = elem.move_c;
            const force = elem.force_c;

            // apply gravity
            move.velocity += force.accel * @splat(2, delta / 1000);

            // applies a friction force when mario hits the ground.
            if (!force.is_airborne and move.velocity[0] != 0) {
                // Friction is applied in the opposite direction of velocity
                // You cannot gain speed in the opposite direction from friction
                const friction: f32 = force.friction * delta;
                if (move.velocity[0] > 0) {
                    move.velocity[0] = std.math.clamp(
                        move.velocity[0] - friction,
                        0,
                        std.math.inf(f32),
                    );
                } else {
                    move.velocity[0] = std.math.clamp(
                        move.velocity[0] + friction,
                        -std.math.inf(f32),
                        0,
                    );
                }
            }
        }
    }

    // Camera Lock
    {
        var view = registry.view(struct {
            pos_c: PositionC,
            decision_c: DecisionC,
        });

        while (view.next()) |elem| {
            if (elem.decision_c != .player) continue;

            util.moveCamera(elem.pos_c.pos);
            break;
        }
    }

    // Rendering
    {
        var view = registry.view(struct {
            pos_c: *PositionC,
            render: RenderC,
        });

        while (view.next()) |elem| {
            const pos_c = elem.pos_c;
            const render = elem.render;

            const color = render.color;
            ext.fillStyle(color[0], color[1], color[2], color[3]);
            const bbox = camera.getScreenBoundingBox(BBox{
                .pos = pos_c.pos,
                .width = render.sprite_width,
                .height = render.sprite_height,
            });

            ext.fillRect(
                @floatToInt(i32, bbox.pos[0]),
                @floatToInt(i32, bbox.pos[1]),
                @floatToInt(i32, bbox.width),
                @floatToInt(i32, bbox.height),
            );
        }
    }

    // USER INTERFACE
    renderDebugInfo(delta);
}

pub fn renderDebugInfo(delta: f64) void {
    ext.fillStyle(0.5, 0.5, 0.5, 1);

    ext.setFont(large_font);

    const fps_message = wasm.out.fmt("FPS: {d:.2}", .{1000 / delta});
    ext.fillText(fps_message, 5, 160);

    const tool_name = wasm.out.string(tools.items[tool_index].name);
    ext.fillText(tool_name, 500, 75);

    ext.setFont(small_font);

    // Show other tools in line
    // ext.fillStyle(0.7, 0.7, 0.7, 1);

    var begin: u32 = 0;
    var topY: i32 = 5;

    for (rows) |row| {
        var leftX = row.leftX;
        const end = row.end;

        for (keys[begin..row.end]) |key| {
            const color: f32 = if (key.down) 0.3 else 0.5;
            ext.fillStyle(color, color, color, 1);

            ext.fillRect(leftX, topY, 30, 30);

            ext.fillStyle(1, 1, 1, 1);
            const s = &[_]u8{@truncate(u8, key.code)};
            const letter = wasm.out.fmt("{s}", .{s});
            ext.fillText(letter, leftX + 15, topY + 10);

            leftX += 35;
        }

        topY += 35;

        begin = end;
    }
}
