const std = @import("std");
const liu = @import("liu");

const wasm = liu.wasm;
const gon = liu.gon;

const util = @import("./util.zig");

const erlang = @import("./erlang.zig");
const ext = erlang.ext;
const BBox = erlang.BBox;

const EntityId = liu.ecs.EntityId;
const Vec2 = liu.Vec2;
const FrameInput = liu.gamescreen.FrameInput;

pub fn unitSquareBBoxForPos(pos: Vec2) BBox {
    return BBox{
        .pos = @floor(pos),
        .width = 1,
        .height = 1,
    };
}

pub fn boxWillCollide(bbox: BBox) bool {
    var view = erlang.registry.view(struct {
        pos_c: erlang.PositionC,
        force_c: ?*const erlang.ForceC,
    });

    while (view.next()) |elem| {
        if (elem.force_c == null) continue;

        const overlap = elem.pos_c.bbox.overlap(bbox);
        if (overlap.result) return true;
    }

    return false;
}

pub const Tool = struct {
    const Self = @This();

    const VTable = struct {
        frame: fn (self: *anyopaque, input: FrameInput) void,
        reset: fn (self: *anyopaque) void,
    };

    name: []const u8,
    ptr: *anyopaque,
    vtable: *const VTable,

    pub fn create(alloc: std.mem.Allocator, obj: anytype) !Self {
        const val = try alloc.create(@TypeOf(obj));
        val.* = obj;

        return init(val);
    }

    pub fn init(obj: anytype) Self {
        const PtrT = @TypeOf(obj);
        const T = std.meta.Child(PtrT);

        return initWithVtable(T, obj, T);
    }

    pub fn initWithVtable(comptime T: type, obj: *T, comptime VtableType: type) Self {
        const info = std.meta.fieldInfo;

        const vtable = comptime VTable{
            .frame = @ptrCast(info(VTable, .frame).field_type, VtableType.frame),
            .reset = @ptrCast(info(VTable, .reset).field_type, VtableType.reset),
        };

        return Self{
            .name = if (@hasDecl(T, "tool_name")) T.tool_name else @typeName(T),
            .ptr = @ptrCast(*anyopaque, obj),
            .vtable = &vtable,
        };
    }

    pub fn reset(self: *Self) void {
        return self.vtable.reset(self.ptr);
    }

    pub fn frame(self: *Self, input: FrameInput) void {
        return self.vtable.frame(self.ptr, input);
    }
};

fn makeBox(pos: Vec2) !EntityId {
    const id = try erlang.registry.create("box");
    errdefer erlang.registry.delete(id);

    try erlang.registry.addComponent(id, erlang.PositionC{ .bbox = .{
        .pos = pos,
        .width = 1,
        .height = 1,
    } });
    try erlang.registry.addComponent(id, erlang.RenderC{
        .color = erlang.Vec4{ 0.2, 0.5, 0.3, 1 },
    });

    return id;
}

pub const ClickTool = struct {
    dummy: bool = false,

    pub fn reset(self: *@This()) void {
        _ = self;
    }

    pub fn frame(self: *@This(), input: FrameInput) void {
        if (!input.mouse.left_clicked and !input.mouse.right_clicked) return;
        _ = self;

        const bbox = unitSquareBBoxForPos(input.mouse.pos);
        if (input.mouse.left_clicked) {
            if (boxWillCollide(bbox)) return;

            // const mark = liu.TempMark;
            // defer liu.TempMark = mark;

            // const text = serializeLevel() catch return;

            // wasm.post(.log, "{s}", .{text});

            // readFromAsset(text) catch return;

            // wasm.post(.log, "{any}", .{mark});

            _ = makeBox(bbox.pos) catch return;

            return;
        }

        if (input.mouse.right_clicked) {
            var view = erlang.registry.view(struct {
                pos_c: erlang.PositionC,
                force_c: ?*const erlang.ForceC,
            });

            while (view.next()) |elem| {
                if (elem.force_c != null) continue;

                const overlap = elem.pos_c.bbox.overlap(bbox);
                if (overlap.result) {
                    _ = erlang.registry.delete(elem.id);
                }
            }
        }
    }
};

pub const LineTool = struct {
    data: ?Data = null,

    const Data = struct {
        entity: EntityId,
        pos: Vec2,
    };

    pub fn reset(self: *@This()) void {
        const data = self.data orelse return;
        self.data = null;
        _ = erlang.registry.delete(data.entity);
    }

    pub fn frame(self: *@This(), input: FrameInput) void {
        const pos = @floor(input.mouse.pos);

        if (input.mouse.right_clicked) {
            if (self.data) |data| {
                _ = erlang.registry.delete(data.entity);
            }

            self.data = null;

            return;
        }

        if (input.mouse.left_clicked) {
            if (self.data != null) {
                self.data = null;
            } else {
                const entity = makeBox(pos) catch return;
                self.data = .{ .entity = entity, .pos = pos };
            }

            return;
        }

        const data = self.data orelse return;

        const bbox = bbox: {
            // Project the floored mouse position onto the X and Y axes, so that
            // the line will always be straight horizontal or straight vertical
            const xProj = Vec2{ pos[0], data.pos[1] };
            const yProj = Vec2{ data.pos[0], pos[1] };

            // Get squared distance between each projection and line origin
            const xDiff = pos - xProj;
            const yDiff = pos - yProj;
            const xSqr = @reduce(.Add, xDiff * xDiff);
            const ySqr = @reduce(.Add, yDiff * yDiff);

            // Pick the projection with least distance
            const proj = if (xSqr < ySqr) xProj else yProj;

            // Translate position and projection into top-left pos0 and bottom-right
            // pos1
            const mask = proj < data.pos;
            const pos0 = @select(f32, mask, proj, data.pos);
            const pos1 = @select(f32, mask, data.pos, proj) + Vec2{ 1, 1 };

            break :bbox erlang.BBox{
                .pos = pos0,
                .width = pos1[0] - pos0[0],
                .height = pos1[1] - pos0[1],
            };
        };

        if (boxWillCollide(bbox)) return;

        var view = erlang.registry.view(struct {
            pos_c: *erlang.PositionC,
            render: *erlang.RenderC,
        });

        const val = view.get(data.entity) orelse {
            self.data = null;
            return;
        };

        val.pos_c.bbox = bbox;
    }
};

pub const DrawTool = struct {
    drawing: bool = false,

    pub fn reset(self: *@This()) void {
        self.drawing = false;
    }

    pub fn frame(self: *@This(), input: FrameInput) void {
        if (input.mouse.left_clicked) {
            self.drawing = !self.drawing;
        }

        if (!self.drawing) return;

        const bbox = unitSquareBBoxForPos(input.mouse.pos);
        if (boxWillCollide(bbox)) return;

        const new_solid = makeBox(bbox.pos) catch return;
        _ = new_solid;
    }
};

const AssetEntity = struct {
    move: ?erlang.MoveC,
    render: ?erlang.RenderC,
    pos: ?erlang.PositionC,
    force: ?erlang.ForceC,
    decide: ?erlang.DecisionC,
};

// Use stable declaration on type
pub fn serializeLevel() ![]const u8 {
    var entities = std.ArrayList(AssetEntity).init(liu.Temp);

    var view = erlang.registry.view(AssetEntity);
    while (view.next()) |elem| {
        try entities.append(.{
            .move = elem.move,
            .pos = elem.pos,
            .render = elem.render,
            .decide = elem.decide,
            .force = elem.force,
        });
    }

    const gon_data = try gon.Value.init(.{
        .entities = entities.items,
    });

    var output = std.ArrayList(u8).init(liu.Temp);

    try gon_data.write(output.writer(), true);

    return output.items;
}

pub fn readFromAsset(bytes: []const u8) !void {
    const registry = &erlang.registry;

    var view = registry.view(struct {});
    while (view.next()) |elem| {
        _ = registry.delete(elem.id);
    }

    const gon_data = try gon.parseGon(bytes);
    const asset_data = try gon_data.expect(struct {
        entities: []const AssetEntity,
    });

    for (asset_data.entities) |entity| {
        const id = try registry.create("");
        errdefer _ = registry.delete(id);

        if (entity.move) |move| {
            try registry.addComponent(id, move);
        }

        if (entity.pos) |pos| {
            try registry.addComponent(id, pos);
        }

        if (entity.render) |render| {
            try registry.addComponent(id, render);
        }

        if (entity.decide) |decide| {
            try registry.addComponent(id, decide);
        }

        if (entity.force) |force| {
            try registry.addComponent(id, force);
        }
    }
}
